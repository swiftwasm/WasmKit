import Testing
import WAT
import WasmParser

@testable import WasmKit

/// Suspending a ``ResumableCall`` at a host call, and completing that host call later.
///
/// The host functions record every run, so a test can tell a continued call from a replayed one.
@Suite
struct ResumableHostCallTests {
    static let features: WasmFeatureSet = [.referenceTypes, .exceptionHandling, .tailCall, .memory64]

    /// A module instantiated with host functions, and the arguments each host function ran with.
    final class Fixture {
        let store: Store
        let instance: Instance
        /// The arguments of each run of a host function, in order, by import name.
        var calls: [String: [[Value]]] = [:]

        /// Instantiates `wat`, importing each host function in `hosts` by name.
        ///
        /// - Parameters:
        ///   - fuel: A fuel budget, which also turns fuel metering on.
        ///   - hosts: Host functions by import name. Each is given the fixture and its arguments.
        init(
            _ wat: String,
            threadingModel: EngineConfiguration.ThreadingModel,
            fuel: UInt64? = nil,
            memoryBoundsChecking: EngineConfiguration.MemoryBoundsChecking? = nil,
            hosts: [String: (Fixture, [Value]) throws -> [Value]]
        ) throws {
            let module = try parseWasm(bytes: wat2wasm(wat, features: features), features: features)
            let store = Store(
                engine: Engine(
                    configuration: EngineConfiguration(
                        threadingModel: threadingModel, features: features,
                        memoryBoundsChecking: memoryBoundsChecking, fuelMetering: fuel != nil)))
            if let fuel { store.fuel = Fuel(remaining: fuel) }
            self.store = store
            let box = Box()
            var imports = Imports()
            var index: FunctionIndex = 0
            for entry in module.imports {
                guard case .function = entry.descriptor else { continue }
                defer { index += 1 }
                guard let host = hosts[entry.name] else { continue }
                let name = entry.name
                let function = Function(store: store, type: try module.resolveFunctionType(index)) { _, arguments in
                    let fixture = try #require(box.fixture)
                    fixture.calls[name, default: []].append(arguments)
                    return try host(fixture, arguments)
                }
                imports.define(entry, .function(function))
            }
            instance = try module.instantiate(store: store, imports: imports)
            box.fixture = self
        }

        func export(_ name: String) throws -> Function {
            try #require(instance.exports[function: name])
        }

        func count(_ name: String) -> Int { calls[name]?.count ?? 0 }
    }

    /// A late-bound reference from the host functions to their fixture.
    final class Box {
        weak var fixture: Fixture?
    }

    struct HostFailure: Error, Equatable {}

    /// A host function that always asks to suspend, with tag 7.
    static func suspend(_: Fixture, _: [Value]) throws -> [Value] {
        throw SuspensionRequest(tag: 7)
    }

    static func suspension(
        _ status: ResumableCall.Status, sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Suspension {
        switch status {
        case .suspended(let suspension): return suspension
        case .returned(let results):
            Issue.record("expected a suspension, returned \(results)", sourceLocation: sourceLocation)
            throw HostFailure()
        }
    }

    static func results(
        _ status: ResumableCall.Status, sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> [Value] {
        switch status {
        case .returned(let results): return results
        case .suspended(let suspension):
            Issue.record("expected results, suspended with \(suspension.reason)", sourceLocation: sourceLocation)
            throw HostFailure()
        }
    }

    /// The description of the ``ResumableCallError`` that `body` throws, or `nil` when it throws
    /// nothing or something else.
    static func refusal(
        sourceLocation: SourceLocation = #_sourceLocation, _ body: () throws -> ResumableCall.Status
    ) -> String? {
        do {
            let status = try body()
            Issue.record("expected a refusal, got \(status)", sourceLocation: sourceLocation)
        } catch let error as ResumableCallError {
            return error.description
        } catch {
            Issue.record("expected a refusal, got \(error)", sourceLocation: sourceLocation)
        }
        return nil
    }

    // MARK: Continuing the guest

    /// Nested frames with locals, two suspensions, and host calls that run on both sides of them.
    static let nested = """
        (module
          (import "env" "suspend" (func $suspend (param i32) (result i32)))
          (import "env" "effect" (func $effect (param i32)))
          (global $writes (mut i32) (i32.const 0))
          (func $inner (param $x i32) (result i32)
            (local $a i32) (local $b i32)
            (local.set $a (i32.mul (local.get $x) (i32.const 10)))
            (call $effect (i32.const 1))
            (global.set $writes (i32.add (global.get $writes) (i32.const 1)))
            (local.set $b (call $suspend (local.get $a)))
            (call $effect (i32.const 2))
            (local.set $b
              (i32.add (local.get $b) (call $suspend (i32.add (local.get $a) (local.get $b)))))
            (global.set $writes (i32.add (global.get $writes) (i32.const 1)))
            (i32.add (local.get $a) (local.get $b)))
          (func (export "run") (param $x i32) (result i32)
            (local $keep i32)
            (local.set $keep (i32.add (local.get $x) (i32.const 1000)))
            (i32.add (local.get $keep) (call $inner (local.get $x))))
          (func (export "writes") (result i32) (global.get $writes)))
        """

    @Test(arguments: testedThreadingModels)
    func answersContinueTheGuestWithoutRunningTheHostFunctionAgain(
        threadingModel: EngineConfiguration.ThreadingModel
    ) throws {
        // The same answers from a synchronous host function give the reference result.
        var answered = 0
        let synchronous = try Fixture(
            Self.nested, threadingModel: threadingModel,
            hosts: [
                "suspend": { _, arguments in
                    answered += 1
                    return [.i32(answered == 1 ? arguments[0].i32 + 5 : arguments[0].i32 * 2)]
                },
                "effect": { _, _ in [] },
            ])
        let reference = try synchronous.export("run")([.i32(3)])
        #expect(reference == [.i32(1198)])

        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(3)])
        let first = try Self.suspension(try call.resume())
        #expect(first.reason == .hostCall(tag: 7, arguments: [.i32(30)]))
        #expect(call.suspension?.reason == first.reason)
        #expect(fixture.calls["effect"] == [[.i32(1)]])
        let second = try Self.suspension(try call.resume(returning: [.i32(35)], answering: first))
        #expect(second.reason == .hostCall(tag: 7, arguments: [.i32(65)]))
        #expect(try Self.results(try call.resume(returning: [.i32(130)], answering: second)) == reference)
        // Every step ran once: two effects, two host calls that suspended, two global writes.
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(2)]])
        #expect(fixture.count("suspend") == 2)
        #expect(try fixture.export("writes")() == [.i32(2)])
        #expect(call.isFinished)
        #expect(call.suspension == nil)
        #expect(fixture.store.isSuspendable == false)
    }

    static let shapes = """
        (module
          (import "env" "wait" (func $wait))
          (import "env" "triple" (func $triple (param i32) (result i32 i64 f64)))
          (func (export "void") (result i32) (call $wait) (i32.const 7))
          (func (export "multi") (param i32) (result f64)
            (local $a i32) (local $b i64) (local $c f64)
            (call $triple (local.get 0))
            (local.set $c) (local.set $b) (local.set $a)
            (f64.add
              (f64.add (f64.convert_i32_s (local.get $a)) (f64.convert_i64_s (local.get $b)))
              (local.get $c))))
        """

    @Test(arguments: testedThreadingModels)
    func hostFunctionsWithoutResultsAndWithSeveral(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.shapes, threadingModel: threadingModel, hosts: ["wait": Self.suspend, "triple": Self.suspend])
        let wait = try ResumableCall(function: try fixture.export("void"))
        let waiting = try Self.suspension(try wait.resume())
        #expect(waiting.reason == .hostCall(tag: 7, arguments: []))
        // A host call without results is completed explicitly too. A plain resume neither runs the
        // host function again nor skips it.
        #expect(Self.refusal { try wait.resume() } == ResumableCallError.suspendedAtHostCall.description)
        #expect(wait.suspension?.reason == waiting.reason)
        #expect(fixture.count("wait") == 1)
        #expect(try Self.results(try wait.resume(returning: [], answering: waiting)) == [.i32(7)])
        #expect(fixture.count("wait") == 1)

        let triple = try ResumableCall(function: try fixture.export("multi"), arguments: [.i32(4)])
        let tripled = try Self.suspension(try triple.resume())
        #expect(tripled.reason == .hostCall(tag: 7, arguments: [.i32(4)]))
        let results = try Self.results(
            try triple.resume(returning: [.i32(1), .i64(20), .f64(Double(0.5).bitPattern)], answering: tripled))
        #expect(results == [.f64(Double(21.5).bitPattern)])
    }

    @Test(arguments: testedThreadingModels)
    func aRawHostFunctionSuspendsWithACopyOfItsArguments(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Store(engine: Engine(configuration: EngineConfiguration(threadingModel: threadingModel)))
        var runs = 0
        var imports = Imports()
        imports.define(
            module: "env", name: "suspend",
            Function(
                store: store, parameters: [.i32, .i64], results: [.i32],
                raw: { _, arguments, _ in
                    runs += 1
                    throw SuspensionRequest(tag: UInt64(arguments[1].i64))
                }))
        let wat = """
            (module
              (import "env" "suspend" (func $suspend (param i32 i64) (result i32)))
              (func (export "f") (param i32) (result i32)
                (i32.sub (call $suspend (local.get 0) (i64.const 42)) (i32.const 1))))
            """
        let instance = try parseWasm(bytes: wat2wasm(wat)).instantiate(store: store, imports: imports)
        let call = try ResumableCall(function: try #require(instance.exports[function: "f"]), arguments: [.i32(5)])
        let suspension = try Self.suspension(try call.resume())
        // Another call runs the host function again before the first suspension is read.
        let other = try ResumableCall(function: try #require(instance.exports[function: "f"]), arguments: [.i32(6)])
        _ = try Self.suspension(try other.resume())
        #expect(suspension.reason == .hostCall(tag: 42, arguments: [.i32(5), .i64(42)]))
        #expect(call.suspension?.reason == .hostCall(tag: 42, arguments: [.i32(5), .i64(42)]))
        #expect(try Self.results(try call.resume(returning: [.i32(10)], answering: suspension)) == [.i32(9)])
        #expect(runs == 2)
    }

    /// `pass` gets a function reference and an extern reference, and returns an extern reference
    /// and a function reference. `f` calls the returned function through a table, so a function
    /// reference that did not survive the suspension could not reach `$target`.
    static let references = """
        (module
          (import "env" "pass" (func $pass (param funcref externref) (result externref funcref)))
          (type $answer (func (result i32)))
          (table $t 1 funcref)
          (elem declare func $target)
          (func $target (result i32) (i32.const 42))
          (func (export "f") (param externref) (result externref i32)
            (local $function funcref)
            (call $pass (ref.func $target) (local.get 0))
            (local.set $function)
            (table.set $t (i32.const 0) (local.get $function))
            (call_indirect $t (type $answer) (i32.const 0))))
        """

    @Test(arguments: testedThreadingModels)
    func referencesCrossASuspension(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var suspends = false
        let fixture = try Fixture(
            Self.references, threadingModel: threadingModel,
            hosts: [
                "pass": { fixture, arguments in
                    if suspends { return try Self.suspend(fixture, arguments) }
                    return [.ref(.extern(99)), arguments[0]]
                }
            ])
        // A synchronous host function shows what the guest passes and what it makes of the answer.
        let reference = try fixture.export("f")([.ref(.extern(5))])
        #expect(reference == [.ref(.extern(99)), .i32(42)])
        let passed = try #require(fixture.calls["pass"]?.first)
        guard case .ref(.function(let address?)) = passed[0] else {
            Issue.record("expected a function reference, got \(passed)")
            return
        }

        suspends = true
        let call = try ResumableCall(function: try fixture.export("f"), arguments: [.ref(.extern(5))])
        let suspension = try Self.suspension(try call.resume())
        // The suspension carries the same references, and the function reference names the same
        // function of this store.
        #expect(suspension.reason == .hostCall(tag: 7, arguments: [.ref(.function(address)), .ref(.extern(5))]))
        #expect(
            Self.refusal { try call.resume(returning: [.ref(.function(address)), .ref(.extern(99))], answering: suspension) }
                != nil)
        let results = try Self.results(
            try call.resume(returning: [.ref(.extern(99)), .ref(.function(address))], answering: suspension))
        #expect(results == reference)
        #expect(fixture.count("pass") == 2)
    }

    // MARK: Answers that do not fit

    @Test(arguments: testedThreadingModels)
    func wrongResultsAreRefusedBeforeTheGuestRuns(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.shapes, threadingModel: threadingModel, hosts: ["wait": Self.suspend, "triple": Self.suspend])
        let call = try ResumableCall(function: try fixture.export("multi"), arguments: [.i32(4)])
        let suspension = try Self.suspension(try call.resume())
        let mismatch = ResumableCallError.resultTypesMismatch(expected: [.i32, .i64, .f64], got: [.i32(1)])
        #expect(Self.refusal { try call.resume(returning: [.i32(1)], answering: suspension) } == mismatch.description)
        #expect(
            Self.refusal {
                try call.resume(returning: [.i32(1), .i32(2), .f64(0), .i32(3)], answering: suspension)
            } != nil)
        #expect(
            Self.refusal { try call.resume(returning: [.i32(1), .i32(2), .f64(0)], answering: suspension) }
                != nil)
        #expect(call.suspension?.reason == suspension.reason)
        // The same suspension takes the right results afterwards, and the guest sees only them.
        let results = try Self.results(
            try call.resume(returning: [.i32(1), .i64(2), .f64(Double(3).bitPattern)], answering: suspension))
        #expect(results == [.f64(Double(6).bitPattern)])
        #expect(fixture.count("triple") == 1)
    }

    @Test(arguments: testedThreadingModels)
    func anAnswerForAnotherSuspensionIsRefused(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let run = try fixture.export("run")
        let cancelled = try ResumableCall(function: run, arguments: [.i32(3)])
        let late = try Self.suspension(try cancelled.resume())
        #expect(throws: HostFailure.self) { try cancelled.resume(throwing: HostFailure()) }

        let call = try ResumableCall(function: run, arguments: [.i32(3)])
        let first = try Self.suspension(try call.resume())
        // Both suspensions describe the same host call, and still only the call's own one fits.
        #expect(late.reason == first.reason)
        let other = ResumableCallError.otherSuspension.description
        #expect(Self.refusal { try call.resume(returning: [.i32(35)], answering: late) } == other)
        #expect(Self.refusal { try call.resume(failing: HostFailure(), answering: late) } == other)
        #expect(Self.refusal { try cancelled.resume(returning: [.i32(35)], answering: late) } != nil)
        let second = try Self.suspension(try call.resume(returning: [.i32(35)], answering: first))
        // An answer to the call's own earlier suspension is refused too.
        #expect(Self.refusal { try call.resume(returning: [.i32(130)], answering: first) } == other)
        #expect(try Self.results(try call.resume(returning: [.i32(130)], answering: second)) == [.i32(1198)])
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(1)], [.i32(2)]])
    }

    @Test(arguments: testedThreadingModels)
    func onlyACallSuspendedAtAHostCallTakesAnAnswer(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, fuel: 0,
            hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(3)])
        let notAtHostCall = ResumableCallError.notSuspendedAtHostCall.description
        let elsewhere = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(4)])
        fixture.store.fuel = Fuel(remaining: 1 << 20)
        let hostSuspension = try Self.suspension(try elsewhere.resume())
        fixture.store.fuel = Fuel(remaining: 0)
        // Not started yet.
        #expect(Self.refusal { try call.resume(returning: [.i32(1)], answering: hostSuspension) } == notAtHostCall)
        // Suspended for fuel.
        let outOfFuel = try Self.suspension(try call.resume())
        guard case .outOfFuel = outOfFuel.reason else {
            Issue.record("expected an out-of-fuel suspension, got \(outOfFuel.reason)")
            return
        }
        #expect(Self.refusal { try call.resume(returning: [], answering: outOfFuel) } == notAtHostCall)
        #expect(Self.refusal { try call.resume(failing: HostFailure(), answering: outOfFuel) } == notAtHostCall)
        #expect(call.suspension?.reason == outOfFuel.reason)
        fixture.store.fuel = Fuel(remaining: 1 << 20)
        let suspension = try Self.suspension(try call.resume())
        #expect(suspension.reason == .hostCall(tag: 7, arguments: [.i32(30)]))
        _ = try Self.suspension(try call.resume(returning: [.i32(35)], answering: suspension))
        #expect(throws: Trap.self) { try call.resume(throwing: Trap(.message(.init("cancelled")))) }
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(1)], [.i32(2)]])
    }

    // MARK: Two calls of one store

    /// `run` suspends with its argument as the tag and then records the answer.
    static let twoCalls = """
        (module
          (import "env" "suspend" (func $suspend (param i32) (result i32)))
          (import "env" "after" (func $after (param i32)))
          (import "env" "drive" (func $drive (result i32)))
          (func (export "run") (param $x i32) (result i32)
            (local $r i32)
            (local.set $r (call $suspend (local.get $x)))
            (call $after (local.get $r))
            (i32.add (local.get $r) (local.get $x)))
          (func (export "trapAfter") (param $x i32) (result i32)
            (drop (call $suspend (local.get $x)))
            unreachable)
          (func (export "outer") (result i32)
            (i32.add (call $drive) (call $suspend (i32.const 9)))))
        """

    static func suspendWithArgument(_: Fixture, _ arguments: [Value]) throws -> [Value] {
        throw SuspensionRequest(tag: UInt64(arguments[0].i32))
    }

    @Test(arguments: testedThreadingModels)
    func twoSuspendedCallsOfOneStoreFinishInEitherOrder(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.twoCalls, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspendWithArgument, "after": { _, _ in [] }, "drive": { _, _ in throw HostFailure() },
            ])
        let a = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(1)])
        let b = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(2)])
        let aSuspension = try Self.suspension(try a.resume())
        let bSuspension = try Self.suspension(try b.resume())
        #expect(aSuspension.reason == .hostCall(tag: 1, arguments: [.i32(1)]))
        #expect(bSuspension.reason == .hostCall(tag: 2, arguments: [.i32(2)]))

        // Answers for the other call are refused, and both calls stay suspended.
        let other = ResumableCallError.otherSuspension.description
        #expect(Self.refusal { try a.resume(returning: [.i32(10)], answering: bSuspension) } == other)
        #expect(Self.refusal { try b.resume(failing: HostFailure(), answering: aSuspension) } == other)
        #expect(Self.refusal { try a.resume(returning: [.i64(10)], answering: aSuspension) } != nil)
        #expect(fixture.count("after") == 0)

        // Each finishes with its own answer, the later one first.
        #expect(try Self.results(try b.resume(returning: [.i32(20)], answering: bSuspension)) == [.i32(22)])
        #expect(try Self.results(try a.resume(returning: [.i32(10)], answering: aSuspension)) == [.i32(11)])
        #expect(fixture.calls["after"] == [[.i32(20)], [.i32(10)]])
        #expect(fixture.store.isSuspendable == false)
    }

    @Test(arguments: testedThreadingModels)
    func anAnswerFromAnotherStoreIsRefused(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let hosts: [String: (Fixture, [Value]) throws -> [Value]] = [
            "suspend": Self.suspendWithArgument, "after": { _, _ in [] }, "drive": { _, _ in throw HostFailure() },
        ]
        let left = try Fixture(Self.twoCalls, threadingModel: threadingModel, hosts: hosts)
        let right = try Fixture(Self.twoCalls, threadingModel: threadingModel, hosts: hosts)
        let a = try ResumableCall(function: try left.export("run"), arguments: [.i32(1)])
        let b = try ResumableCall(function: try right.export("run"), arguments: [.i32(1)])
        let aSuspension = try Self.suspension(try a.resume())
        let bSuspension = try Self.suspension(try b.resume())
        // The two suspensions describe equal host calls, so only their identity tells them apart.
        #expect(aSuspension.reason == bSuspension.reason)
        let other = ResumableCallError.otherSuspension.description
        #expect(Self.refusal { try a.resume(returning: [.i32(10)], answering: bSuspension) } == other)
        #expect(Self.refusal { try b.resume(failing: HostFailure(), answering: aSuspension) } == other)
        #expect(left.count("after") + right.count("after") == 0)
        #expect(try Self.results(try b.resume(returning: [.i32(20)], answering: bSuspension)) == [.i32(21)])
        #expect(try Self.results(try a.resume(returning: [.i32(10)], answering: aSuspension)) == [.i32(11)])
        #expect(left.calls["after"] == [[.i32(10)]])
        #expect(right.calls["after"] == [[.i32(20)]])
    }

    /// Calls that a host function of a running call finishes or refuses.
    final class Pending {
        var first: ResumableCall?
        var firstSuspension: Suspension?
        var second: ResumableCall?
        var secondSuspension: Suspension?
        var refused: String?
        var firstResults: [Value]?
        var secondTrapped = false
    }

    @Test(arguments: testedThreadingModels)
    func aHostFunctionFinishesOtherCallsAndItsOwnCallStillSuspends(
        threadingModel: EngineConfiguration.ThreadingModel
    ) throws {
        let pending = Pending()
        let fixture = try Fixture(
            Self.twoCalls, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspendWithArgument, "after": { _, _ in [] },
                "drive": { fixture, _ in
                    let first = try #require(pending.first)
                    let firstSuspension = try #require(pending.firstSuspension)
                    let second = try #require(pending.second)
                    let secondSuspension = try #require(pending.secondSuspension)
                    // A refusal leaves the other call suspended and this one running.
                    pending.refused = Self.refusal { try first.resume(returning: [], answering: firstSuspension) }
                    #expect(fixture.store.isSuspendable)
                    pending.firstResults = try Self.results(
                        try first.resume(returning: [.i32(100)], answering: firstSuspension))
                    #expect(fixture.store.isSuspendable)
                    do {
                        _ = try second.resume(returning: [.i32(0)], answering: secondSuspension)
                    } catch let trap as Trap {
                        if case .unreachable = trap.reason { pending.secondTrapped = true }
                    }
                    #expect(fixture.store.isSuspendable)
                    return [.i32(1)]
                },
            ])
        pending.first = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(5)])
        pending.firstSuspension = try Self.suspension(try #require(pending.first).resume())
        pending.second = try ResumableCall(function: try fixture.export("trapAfter"), arguments: [.i32(6)])
        pending.secondSuspension = try Self.suspension(try #require(pending.second).resume())

        let outer = try ResumableCall(function: try fixture.export("outer"))
        let suspension = try Self.suspension(try outer.resume())
        #expect(suspension.reason == .hostCall(tag: 9, arguments: [.i32(9)]))
        #expect(pending.refused != nil)
        #expect(pending.firstResults == [.i32(105)])
        #expect(pending.secondTrapped)
        #expect(try Self.results(try outer.resume(returning: [.i32(1000)], answering: suspension)) == [.i32(1001)])
        #expect(fixture.calls["after"] == [[.i32(100)]])
        #expect(fixture.store.isSuspendable == false)
    }

    // MARK: Calls into the host

    /// The host's parameter area holds three parameters and two results, and the tail callers'
    /// frames are smaller and larger than it, so the frame moves both ways before the suspension.
    /// ``ResumableHostCallTailTests`` covers arguments that reach the tail caller's saved slots.
    static let tailCalls = """
        (module
          (import "env" "suspend" (func $suspend (param i32 i64 i32) (result i64 i32)))
          (func $small (param i32) (result i64 i32)
            (return_call $suspend (local.get 0) (i64.extend_i32_u (local.get 0)) (i32.const 9)))
          (func $large (param i32) (result i64 i32)
            (local i64 i64 i64 i64 i64 i64)
            (local.set 1 (i64.const 3))
            (return_call $suspend
              (local.get 0) (i64.add (local.get 1) (i64.extend_i32_u (local.get 0))) (i32.const 8)))
          (func $sum (param i64 i32) (result i64)
            (i64.add (local.get 0) (i64.extend_i32_u (local.get 1))))
          (func (export "small") (param i32) (result i64)
            (call $sum (call $small (local.get 0))))
          (func (export "large") (param i32) (result i64)
            (call $sum (call $large (local.get 0)))))
        """

    @Test(arguments: testedThreadingModels)
    func aTailCallToTheHostResumesInTheMovedFrame(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.tailCalls, threadingModel: threadingModel, hosts: ["suspend": Self.suspend])
        let small = try ResumableCall(function: try fixture.export("small"), arguments: [.i32(5)])
        let smallSuspension = try Self.suspension(try small.resume())
        #expect(smallSuspension.reason == .hostCall(tag: 7, arguments: [.i32(5), .i64(5), .i32(9)]))
        #expect(
            try Self.results(try small.resume(returning: [.i64(1000), .i32(7)], answering: smallSuspension))
                == [.i64(1007)])
        let large = try ResumableCall(function: try fixture.export("large"), arguments: [.i32(5)])
        let largeSuspension = try Self.suspension(try large.resume())
        #expect(largeSuspension.reason == .hostCall(tag: 7, arguments: [.i32(5), .i64(8), .i32(8)]))
        #expect(
            try Self.results(try large.resume(returning: [.i64(2000), .i32(30)], answering: largeSuspension))
                == [.i64(2030)])
    }

    static let indirectCalls = """
        (module
          (import "env" "suspend" (func $suspend (param i32) (result i32)))
          (type $unary (func (param i32) (result i32)))
          (table 1 funcref)
          (elem (i32.const 0) func $suspend)
          (func $tail (param i32) (result i32)
            (return_call_indirect (type $unary) (local.get 0) (i32.const 0)))
          (func (export "indirect") (param i32) (result i32)
            (i32.add
              (call_indirect (type $unary) (local.get 0) (i32.const 0))
              (call $tail (i32.add (local.get 0) (i32.const 1))))))
        """

    @Test(arguments: testedThreadingModels)
    func indirectCallsToTheHostSuspend(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(Self.indirectCalls, threadingModel: threadingModel, hosts: ["suspend": Self.suspend])
        let call = try ResumableCall(function: try fixture.export("indirect"), arguments: [.i32(10)])
        let first = try Self.suspension(try call.resume())
        #expect(first.reason == .hostCall(tag: 7, arguments: [.i32(10)]))
        // The second suspension comes from a tail call through the table.
        let second = try Self.suspension(try call.resume(returning: [.i32(100)], answering: first))
        #expect(second.reason == .hostCall(tag: 7, arguments: [.i32(11)]))
        #expect(try Self.results(try call.resume(returning: [.i32(1000)], answering: second)) == [.i32(1100)])
        #expect(fixture.count("suspend") == 2)
    }

    // MARK: Failing a host call, and cancelling

    static let failures = """
        (module
          (import "env" "suspend" (func $suspend (result i32)))
          (import "env" "effect" (func $effect))
          (tag $t (param i32))
          (func (export "raise") (param i32) (throw $t (local.get 0)))
          (func (export "trap") (unreachable))
          (func (export "guarded") (result i32)
            (block $h (result i32)
              (try_table (result i32) (catch $t $h)
                (i32.add (call $suspend) (i32.const 1000)))))
          (func $callee (result i32) (i32.mul (call $suspend) (i32.const 3)))
          (func (export "caller") (result i32)
            (block $h (result i32)
              (try_table (result i32) (catch $t $h) (call $callee))))
          (func (export "unguarded") (result i32)
            (local $r i32)
            (local.set $r (call $suspend))
            (call $effect)
            (local.get $r))
          (func (export "deep") (result i32) (i32.add (call $middle) (i32.const 1)))
          (func $middle (result i32)
            (local $r i32)
            (local.set $r (call $suspend))
            (call $effect)
            (local.get $r)))
        """

    static func exceptionAndTrap(_ fixture: Fixture) throws -> (WasmKitException, Trap) {
        var exception: WasmKitException?
        do { _ = try fixture.export("raise")([.i32(77)]) } catch let error as WasmKitException { exception = error }
        var trap: Trap?
        do { _ = try fixture.export("trap")() } catch let error as Trap { trap = error }
        return (try #require(exception), try #require(trap))
    }

    @Test(arguments: testedThreadingModels)
    func exceptionHandlersSurviveAHostCallSuspension(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let (exception, _) = try Self.exceptionAndTrap(fixture)
        // The handler belongs to the caller's frame, and the call suspends in the callee.
        let caller = try ResumableCall(function: try fixture.export("caller"))
        let suspension = try Self.suspension(try caller.resume())
        #expect(try Self.results(try caller.resume(returning: [.i32(5)], answering: suspension)) == [.i32(15)])
        let delivered = try ResumableCall(function: try fixture.export("caller"))
        let next = try Self.suspension(try delivered.resume())
        #expect(try Self.results(try delivered.resume(failing: exception, answering: next)) == [.i32(77)])
    }

    /// The suspended call sits in a `try_table` with a tagged clause before a `catch_all`.
    /// `ordered` returns the payload when the tagged clause catches and -1 when `catch_all` does.
    /// `exited` suspends again after the catch, outside the `try_table`.
    static let catchClauses = """
        (module
          (import "env" "suspend" (func $suspend (result i32)))
          (tag $t (param i32))
          (func (export "raise") (param i32) (throw $t (local.get 0)))
          (func (export "ordered") (result i32)
            (block $all
              (block $first (result i32)
                (try_table (result i32) (catch $t $first) (catch_all $all)
                  (call $suspend)))
              (return))
            (i32.const -1))
          (func (export "exited") (result i32)
            (block $all
              (block $first (result i32)
                (try_table (result i32) (catch $t $first) (catch_all $all)
                  (call $suspend)))
              (drop)
              (return (call $suspend)))
            (i32.const -1)))
        """

    @Test(arguments: testedThreadingModels)
    func aFailedHostCallFollowsTheCatchClauses(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(Self.catchClauses, threadingModel: threadingModel, hosts: ["suspend": Self.suspend])
        var exception: WasmKitException?
        do { _ = try fixture.export("raise")([.i32(77)]) } catch let error as WasmKitException { exception = error }
        let raised = try #require(exception)

        // The clauses are tried in source order, so the tagged clause catches before catch_all.
        let ordered = try ResumableCall(function: try fixture.export("ordered"))
        let suspension = try Self.suspension(try ordered.resume())
        #expect(try Self.results(try ordered.resume(failing: raised, answering: suspension)) == [.i32(77)])

        // A catch leaves the whole try_table, so its catch_all no longer handles a later failure.
        let exited = try ResumableCall(function: try fixture.export("exited"))
        let first = try Self.suspension(try exited.resume())
        let second = try Self.suspension(try exited.resume(failing: raised, answering: first))
        #expect(throws: WasmKitException.self) { try exited.resume(failing: raised, answering: second) }
        #expect(exited.isFinished)
    }

    @Test(arguments: testedThreadingModels)
    func failingThrowsWhatASynchronousHostFunctionWouldThrow(
        threadingModel: EngineConfiguration.ThreadingModel
    ) throws {
        var synchronousFailure: (any Error)?
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel,
            hosts: [
                "suspend": { fixture, arguments in
                    if let failure = synchronousFailure { throw failure }
                    return try Self.suspend(fixture, arguments)
                },
                "effect": { _, _ in [] },
            ])
        let (exception, trap) = try Self.exceptionAndTrap(fixture)

        // A handler in the suspended frame catches the exception, and the addition after the call
        // never runs.
        let guarded = try ResumableCall(function: try fixture.export("guarded"))
        let guardedSuspension = try Self.suspension(try guarded.resume())
        #expect(try Self.results(try guarded.resume(failing: exception, answering: guardedSuspension)) == [.i32(77)])

        // Without a handler, the exception finishes the call.
        let unguarded = try ResumableCall(function: try fixture.export("unguarded"))
        let unguardedSuspension = try Self.suspension(try unguarded.resume())
        #expect(throws: WasmKitException.self) { try unguarded.resume(failing: exception, answering: unguardedSuspension) }
        #expect(unguarded.isFinished)

        // A trap finishes the call with the backtrace a synchronous host function's trap gets.
        let trapped = try ResumableCall(function: try fixture.export("deep"))
        let trappedSuspension = try Self.suspension(try trapped.resume())
        var resumed: Trap?
        do { _ = try trapped.resume(failing: trap, answering: trappedSuspension) } catch let error as Trap { resumed = error }
        synchronousFailure = trap
        var synchronous: Trap?
        do { _ = try fixture.export("deep")() } catch let error as Trap { synchronous = error }
        let resumedBacktrace = try #require(resumed?.backtrace)
        let synchronousBacktrace = try #require(synchronous?.backtrace)
        #expect(resumedBacktrace.trapSite == synchronousBacktrace.trapSite)
        #expect(resumedBacktrace.symbols.count == 2)
        #expect(resumedBacktrace.symbols.map(\.name) == synchronousBacktrace.symbols.map(\.name))
        // The root frame returns to code that a plain call and a resumable call keep apart.
        #expect(
            resumedBacktrace.symbols.dropLast().map(\.address) == synchronousBacktrace.symbols.dropLast().map(\.address))
        #expect(trapped.isFinished)

        // Any other error finishes the call as it is.
        synchronousFailure = nil
        let failed = try ResumableCall(function: try fixture.export("unguarded"))
        let failedSuspension = try Self.suspension(try failed.resume())
        #expect(throws: HostFailure.self) { try failed.resume(failing: HostFailure(), answering: failedSuspension) }
        #expect(failed.isFinished)
        // The guest never continued past any of the host calls it was suspended in.
        #expect(fixture.count("effect") == 0)
    }

    @Test(arguments: testedThreadingModels)
    func cancellingKeepsTheGuestFromCatchingAnything(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var synchronousFailure: (any Error)?
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel,
            hosts: [
                "suspend": { fixture, arguments in
                    if let failure = synchronousFailure { throw failure }
                    return try Self.suspend(fixture, arguments)
                },
                "effect": { _, _ in [] },
            ])
        let (exception, trap) = try Self.exceptionAndTrap(fixture)
        let call = try ResumableCall(
            function: try fixture.export("guarded"), on: ExecutionStack(engine: fixture.store.engine))
        let suspension = try Self.suspension(try call.resume())
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: exception) }
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: SuspensionRequest(tag: 1)) }
        #expect(call.suspension?.reason == suspension.reason)

        var cancelled: Trap?
        do { try call.resume(throwing: trap) } catch let error as Trap { cancelled = error }
        synchronousFailure = trap
        var synchronous: Trap?
        do { _ = try fixture.export("guarded")() } catch let error as Trap { synchronous = error }
        #expect(try #require(cancelled?.backtrace).trapSite == (try #require(synchronous?.backtrace)).trapSite)
        #expect(call.isFinished)
        #expect(Self.refusal { try call.resume(returning: [.i32(1)], answering: suspension) } != nil)

        // The finished call keeps its stack until it is taken, and the stack runs another call.
        guard let stack = call.takeStack() else {
            Issue.record("expected the stack back")
            return
        }
        synchronousFailure = nil
        let next = try ResumableCall(function: try fixture.export("unguarded"), on: stack)
        let nextSuspension = try Self.suspension(try next.resume())
        #expect(try Self.results(try next.resume(returning: [.i32(3)], answering: nextSuspension)) == [.i32(3)])
        #expect(fixture.count("effect") == 1)
    }

    /// How a call suspended in `unguarded` ends.
    enum Ending: CaseIterable {
        case returned, trapped, raised, failed, cancelled
    }

    @Test(arguments: testedThreadingModels)
    func aFinishedCallHandsBackItsStackHoweverItEnded(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let (exception, trap) = try Self.exceptionAndTrap(fixture)
        let unguarded = try fixture.export("unguarded")
        // One stack passes through every call in turn.
        var stack = ExecutionStack(engine: fixture.store.engine)
        for ending in Ending.allCases {
            let call = try ResumableCall(function: unguarded, on: stack)
            let suspension = try Self.suspension(try call.resume())
            do {
                switch ending {
                case .returned:
                    #expect(try Self.results(try call.resume(returning: [.i32(3)], answering: suspension)) == [.i32(3)])
                case .trapped:
                    #expect(throws: Trap.self) { try call.resume(failing: trap, answering: suspension) }
                case .raised:
                    #expect(throws: WasmKitException.self) { try call.resume(failing: exception, answering: suspension) }
                case .failed:
                    #expect(throws: HostFailure.self) { try call.resume(failing: HostFailure(), answering: suspension) }
                case .cancelled:
                    #expect(throws: HostFailure.self) { try call.resume(throwing: HostFailure()) }
                }
            }
            #expect(call.isFinished, "\(ending)")
            guard let next = call.takeStack() else {
                Issue.record("expected the stack back after \(ending)")
                return
            }
            let tookAgain = !Self.isNone(call.takeStack())
            #expect(!tookAgain)
            stack = next
        }
        // Only the answered call went on past its host call.
        #expect(fixture.count("effect") == 1)
        #expect(fixture.count("suspend") == Ending.allCases.count)
    }

    @Test(arguments: testedThreadingModels)
    func aSuspensionRequestCannotCompleteOrCancelACall(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("unguarded"))
        let suspension = try Self.suspension(try call.resume())
        #expect(
            Self.refusal { try call.resume(failing: SuspensionRequest(tag: 2), answering: suspension) }
                == ResumableCallError.requestNotThrowable.description)
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: SuspensionRequest(tag: 2)) }
        #expect(call.suspension?.reason == suspension.reason)
        #expect(fixture.count("suspend") == 1)
        #expect(try Self.results(try call.resume(returning: [.i32(4)], answering: suspension)) == [.i32(4)])
    }

    // MARK: Calls that cannot be suspended

    static let reentry = """
        (module
          (import "env" "suspend" (func $suspend (result i32)))
          (import "env" "reenter" (func $reenter (param i32) (result i32)))
          (memory (export "memory") 1)
          (func (export "grow") (result i32) (memory.grow (i32.const 1)))
          (func (export "double") (param i32) (result i32) (i32.mul (local.get 0) (i32.const 2)))
          (func (export "mem") (result i32)
            (i32.store (i32.const 16) (i32.const 41))
            (drop (call $suspend))
            (i32.store (i32.const 65636) (i32.const 5))
            (i32.add
              (i32.add (i32.load (i32.const 16)) (i32.load (i32.const 20)))
              (i32.add (memory.size) (i32.load (i32.const 65636)))))
          (func (export "outer") (param i32) (result i32) (call $reenter (local.get 0)))
          (func (export "inner") (result i32) (call $suspend)))
        """

    static func isNone(_ stack: consuming ExecutionStack?) -> Bool {
        switch consume stack {
        case .none: return true
        case .some: return false
        }
    }

    static func expectSuspensionUnavailable(
        _ error: (any Error)?, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard let trap = error as? Trap, case .suspensionUnavailable = trap.reason else {
            Issue.record("expected a suspensionUnavailable trap, got \(String(describing: error))", sourceLocation: sourceLocation)
            return
        }
    }

    @Test(arguments: testedThreadingModels)
    func aPlainCallTrapsInsteadOfSuspending(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var nested: (any Error)?
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    // A plain call cannot be suspended, because this host function's native
                    // frames would have to be kept. Its trap does not end the outer call.
                    do { _ = try fixture.export("inner")() } catch { nested = error }
                    #expect(fixture.store.isSuspendable)
                    throw SuspensionRequest(tag: UInt64(arguments[0].i32))
                },
            ])
        var plain: (any Error)?
        do { _ = try fixture.export("inner")() } catch { plain = error }
        Self.expectSuspensionUnavailable(plain)
        #expect((plain as? Trap)?.backtrace?.symbols.isEmpty == false)

        let call = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(21)])
        let suspension = try Self.suspension(try call.resume())
        Self.expectSuspensionUnavailable(nested)
        #expect(suspension.reason == .hostCall(tag: 21, arguments: [.i32(21)]))
        #expect(try Self.results(try call.resume(returning: [.i32(8)], answering: suspension)) == [.i32(8)])
        #expect(fixture.count("suspend") == 2)
        #expect(fixture.store.isSuspendable == false)
    }

    @Test(arguments: testedThreadingModels)
    func aHostFunctionCalledWithoutAGuestCannotSuspend(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var inner: [String: any Error] = [:]
        var pausing: Function?
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    let pausing = try #require(pausing)
                    if arguments[0] == .i32(1) {
                        // Rethrown as it comes, which must not suspend the outer call.
                        return try pausing()
                    }
                    do { _ = try pausing() } catch { inner["invoke"] = error }
                    let call = try ResumableCall(function: pausing)
                    do { _ = try call.resume() } catch { inner["resumable"] = error }
                    #expect(call.isFinished)
                    #expect(call.suspension == nil)
                    #expect(fixture.store.isSuspendable)
                    return [.i32(5)]
                },
            ])
        pausing = Function(store: fixture.store, parameters: [], results: [.i32]) { _, _ in
            throw SuspensionRequest(tag: 3)
        }
        let host = try #require(pausing)
        // From the embedder, with and without a stack of its own.
        var error: (any Error)?
        do { _ = try host() } catch let caught { error = caught }
        Self.expectSuspensionUnavailable(error)
        var stack = ExecutionStack(engine: fixture.store.engine)
        error = nil
        do { _ = try host.invoke([], on: &stack) } catch let caught { error = caught }
        Self.expectSuspensionUnavailable(error)
        let call = try ResumableCall(function: host)
        error = nil
        do { _ = try call.resume() } catch let caught { error = caught }
        Self.expectSuspensionUnavailable(error)
        #expect(call.isFinished)
        #expect(call.suspension == nil)
        let tookStack = !Self.isNone(call.takeStack())
        #expect(tookStack)

        // From a host function that a resumable call's guest called.
        let outer = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(0)])
        #expect(try Self.results(try outer.resume()) == [.i32(5)])
        Self.expectSuspensionUnavailable(inner["invoke"])
        Self.expectSuspensionUnavailable(inner["resumable"])
        let rethrowing = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(1)])
        error = nil
        do { _ = try rethrowing.resume() } catch let caught { error = caught }
        Self.expectSuspensionUnavailable(error)
        #expect(rethrowing.isFinished)
        #expect(fixture.store.isSuspendable == false)
    }

    @Test(arguments: testedThreadingModels)
    func cancellingFromAHostFunctionDoesNotSuspendItsCaller(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var inner: ResumableCall?
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    let call = try #require(inner)
                    // Rethrown as it comes. A request passed on here would suspend the outer call.
                    if arguments[0] == .i32(1) {
                        try call.resume(throwing: SuspensionRequest(tag: 4))
                    }
                    let suspension = try #require(call.suspension)
                    return try Self.results(try call.resume(failing: SuspensionRequest(tag: 4), answering: suspension))
                },
            ])
        inner = try ResumableCall(function: try fixture.export("inner"))
        let innerSuspension = try Self.suspension(try #require(inner).resume())
        for argument: Int32 in [0, 1] {
            let outer = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(UInt32(argument))])
            #expect(throws: ResumableCallError.self) { _ = try outer.resume() }
            #expect(outer.isFinished)
        }
        #expect(try #require(inner).suspension?.reason == innerSuspension.reason)
        #expect(fixture.store.isSuspendable == false)
    }

    // MARK: Nesting

    @Test(arguments: testedThreadingModels)
    func aResumableCallInsideAHostFunctionSuspendsOnItsOwn(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var innerSuspensions = 0
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    // A synchronous call into the guest finishes before anything suspends.
                    let doubled = try fixture.export("double")([arguments[0]])
                    let call = try ResumableCall(function: try fixture.export("inner"))
                    let suspension = try Self.suspension(try call.resume())
                    innerSuspensions += 1
                    #expect(fixture.store.isSuspendable == (arguments[0] != .i32(.max)))
                    let results = try Self.results(try call.resume(returning: doubled, answering: suspension))
                    // Then this host function's own call suspends, unless a plain call reached it.
                    throw SuspensionRequest(tag: UInt64(results[0].i32))
                },
            ])
        let outer = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(21)])
        let suspension = try Self.suspension(try outer.resume())
        #expect(suspension.reason == .hostCall(tag: 42, arguments: [.i32(21)]))
        #expect(try Self.results(try outer.resume(returning: [.i32(7)], answering: suspension)) == [.i32(7)])
        #expect(innerSuspensions == 1)

        // Reached through a plain call, the host function still suspends its own resumable call,
        // and its request to suspend the plain call traps.
        var error: (any Error)?
        do { _ = try fixture.export("outer")([.i32(.max)]) } catch let caught { error = caught }
        Self.expectSuspensionUnavailable(error)
        #expect(innerSuspensions == 2)
        #expect(fixture.store.isSuspendable == false)
    }

    @Test(arguments: testedThreadingModels)
    func aCallCannotBeAnsweredWhileItRuns(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var call: ResumableCall?
        var first: Suspension?
        var refusals: [String?] = []
        let fixture = try Fixture(
            #"(module (import "env" "h" (func $h (result i32))) (func (export "f") (result i32) (i32.add (call $h) (call $h))))"#,
            threadingModel: threadingModel,
            hosts: [
                "h": { _, _ in
                    let running = try #require(call)
                    guard let first else { throw SuspensionRequest(tag: 1) }
                    // The second host call runs inside the answer to the first suspension.
                    #expect(running.suspension == nil)
                    refusals.append(Self.refusal { try running.resume(returning: [.i32(1)], answering: first) })
                    refusals.append(Self.refusal { try running.resume() })
                    return [.i32(2)]
                }
            ])
        call = try ResumableCall(function: try fixture.export("f"))
        let suspension = try Self.suspension(try #require(call).resume())
        first = suspension
        #expect(try Self.results(try #require(call).resume(returning: [.i32(40)], answering: suspension)) == [.i32(42)])
        let running = ResumableCallError.alreadyRunning.description
        #expect(refusals == [running, running])
    }

    @Test(arguments: testedThreadingModels)
    func refusedAnswersKeepTheCallAndDroppingItReleasesIt(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let run = try fixture.export("run")
        let other = try ResumableCall(function: run, arguments: [.i32(4)])
        let otherSuspension = try Self.suspension(try other.resume())
        weak var dropped: ResumableCall?
        do {
            let call = try ResumableCall(function: run, arguments: [.i32(3)])
            let suspension = try Self.suspension(try call.resume())
            #expect(Self.refusal { try call.resume(returning: [], answering: suspension) } != nil)
            #expect(Self.refusal { try call.resume(returning: [.i64(1)], answering: suspension) } != nil)
            #expect(Self.refusal { try call.resume(returning: [.i32(1), .i32(2)], answering: suspension) } != nil)
            #expect(Self.refusal { try call.resume(returning: [.i32(1)], answering: otherSuspension) } != nil)
            #expect(Self.refusal { try call.resume() } != nil)
            #expect(Self.refusal { try call.resume(failing: SuspensionRequest(), answering: suspension) } != nil)
            #expect(throws: ResumableCallError.self) { try call.resume(throwing: SuspensionRequest()) }
            #expect(call.suspension?.reason == suspension.reason)
            #expect(!call.isFinished)
            dropped = call
        }
        #expect(dropped == nil)
        // Neither the refusals nor the drop let the guest go on past the host call.
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(1)]])
        #expect(try fixture.export("writes")() == [.i32(2)])
        #expect(fixture.count("suspend") == 2)
        // The other call of the store still takes its answer.
        _ = try Self.suspension(try other.resume(returning: [.i32(45)], answering: otherSuspension))
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(1)], [.i32(2)]])
    }

    // MARK: Memory

    @Test(arguments: testedThreadingModels, [EngineConfiguration.MemoryBoundsChecking.mprotect, .software])
    func memoryWrittenAndGrownDuringASuspensionIsSeen(
        threadingModel: EngineConfiguration.ThreadingModel,
        memoryBoundsChecking: EngineConfiguration.MemoryBoundsChecking
    ) throws {
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel, memoryBoundsChecking: memoryBoundsChecking,
            hosts: ["suspend": Self.suspend, "reenter": { _, _ in [.i32(0)] }])
        let call = try ResumableCall(function: try fixture.export("mem"))
        let suspension = try Self.suspension(try call.resume())
        let memory = try #require(fixture.instance.exports[memory: "memory"])
        // Only a memory in a reserved region keeps its base when it grows. The engine can keep
        // `.mprotect` and still place the memory in one allocation, as it does on Android.
        let reserved = memory.handle.withValue { $0.trapGuardReservationSize } > 0
        func base() -> UInt {
            memory.withUnsafeMutableBufferPointer(offset: 0, count: 1) { UInt(bitPattern: $0.baseAddress) }
        }
        let before = base()
        memory.withUnsafeMutableBufferPointer(offset: 20, count: 4) { bytes in
            bytes.storeBytes(of: UInt32(100).littleEndian, as: UInt32.self)
        }
        // A plain call grows the memory while the call is suspended. A memory in one allocation
        // is replaced by growing, so the guest has to find it anew.
        #expect(try fixture.export("grow")() == [.i32(1)])
        #expect((base() != before) == !reserved)
        #expect(try Self.results(try call.resume(returning: [.i32(0)], answering: suspension)) == [.i32(41 + 100 + 2 + 5)])
    }

    static let outOfBounds = """
        (module
          (import "env" "suspend" (func $suspend (result i32)))
          (memory 1)
          (func (export "load") (result i32)
            (i32.load (i32.add (call $suspend) (i32.const 65528)))))
        """

    @Test(arguments: testedThreadingModels, [EngineConfiguration.MemoryBoundsChecking.mprotect, .software])
    func anOutOfBoundsAccessAfterAnAnswerTraps(
        threadingModel: EngineConfiguration.ThreadingModel,
        memoryBoundsChecking: EngineConfiguration.MemoryBoundsChecking
    ) throws {
        let fixture = try Fixture(
            Self.outOfBounds, threadingModel: threadingModel, memoryBoundsChecking: memoryBoundsChecking,
            hosts: ["suspend": Self.suspend])
        let inBounds = try ResumableCall(function: try fixture.export("load"))
        let first = try Self.suspension(try inBounds.resume())
        #expect(try Self.results(try inBounds.resume(returning: [.i32(0)], answering: first)) == [.i32(0)])
        let outside = try ResumableCall(function: try fixture.export("load"))
        let second = try Self.suspension(try outside.resume())
        var error: (any Error)?
        do { _ = try outside.resume(returning: [.i32(8)], answering: second) } catch let caught { error = caught }
        guard let trap = error as? Trap, case .memoryOutOfBounds = trap.reason else {
            Issue.record("expected an out-of-bounds trap, got \(String(describing: error))")
            return
        }
    }
}
