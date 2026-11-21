import Testing
import WAT
import WasmParser

@testable import WasmKit

/// Suspending a ``ResumableCall`` at a host call and resuming it.
@Suite
struct ResumableHostCallTests {
    static let features: WasmFeatureSet = [.referenceTypes, .exceptionHandling, .tailCall, .memory64]

    /// A module instantiated with recording host functions.
    final class Fixture {
        let store: Store
        let instance: Instance
        /// The arguments of every host call, by import name.
        var calls: [String: [[Value]]] = [:]

        /// Instantiates `wat` with `hosts` by import name. A `fuel` budget turns fuel metering on.
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

    /// A host function that suspends with the identifier 7.
    static func suspend(_: Fixture, _: [Value]) throws -> [Value] {
        throw SuspensionRequest(id: 7)
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

    /// The description of the ``ResumableCallError`` that `body` throws, or `nil`.
    static func resumableCallError(
        sourceLocation: SourceLocation = #_sourceLocation, _ body: () throws -> ResumableCall.Status
    ) -> String? {
        do {
            let status = try body()
            Issue.record("expected a ResumableCallError, got \(status)", sourceLocation: sourceLocation)
        } catch let error as ResumableCallError {
            return error.description
        } catch {
            Issue.record("expected a ResumableCallError, got \(error)", sourceLocation: sourceLocation)
        }
        return nil
    }

    // MARK: Continuing the guest

    /// Nested frames with locals, two suspensions, and host calls before and after each suspension.
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
    func resultsContinueGuestWithoutRerunningHostFunction(
        threadingModel: EngineConfiguration.ThreadingModel
    ) throws {
        var runs = 0
        let synchronous = try Fixture(
            Self.nested, threadingModel: threadingModel,
            hosts: [
                "suspend": { _, arguments in
                    runs += 1
                    return [.i32(runs == 1 ? arguments[0].i32 + 5 : arguments[0].i32 * 2)]
                },
                "effect": { _, _ in [] },
            ])
        let reference = try synchronous.export("run")([.i32(3)])
        #expect(reference == [.i32(1198)])

        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(3)])
        let first = try Self.suspension(try call.resume())
        #expect(first.reason == .hostCall(id: 7, arguments: [.i32(30)]))
        #expect(call.suspension?.reason == first.reason)
        #expect(fixture.calls["effect"] == [[.i32(1)]])
        let second = try Self.suspension(try call.resume(returning: [.i32(35)]))
        #expect(second.reason == .hostCall(id: 7, arguments: [.i32(65)]))
        #expect(try Self.results(try call.resume(returning: [.i32(130)])) == reference)
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
    func hostFunctionsWithNoOrManyResults(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.shapes, threadingModel: threadingModel, hosts: ["wait": Self.suspend, "triple": Self.suspend])
        let wait = try ResumableCall(function: try fixture.export("void"))
        let waiting = try Self.suspension(try wait.resume())
        #expect(waiting.reason == .hostCall(id: 7, arguments: []))
        #expect(Self.resumableCallError { try wait.resume() } == ResumableCallError.suspendedAtHostCall.description)
        #expect(wait.suspension?.reason == waiting.reason)
        #expect(fixture.count("wait") == 1)
        #expect(try Self.results(try wait.resume(returning: [])) == [.i32(7)])
        #expect(fixture.count("wait") == 1)

        let triple = try ResumableCall(function: try fixture.export("multi"), arguments: [.i32(4)])
        let tripled = try Self.suspension(try triple.resume())
        #expect(tripled.reason == .hostCall(id: 7, arguments: [.i32(4)]))
        let results = try Self.results(
            try triple.resume(returning: [.i32(1), .i64(20), .f64(Double(0.5).bitPattern)]))
        #expect(results == [.f64(Double(21.5).bitPattern)])
    }

    @Test(arguments: testedThreadingModels)
    func rawHostFunctionSuspendsWithCopyOfArguments(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Store(engine: Engine(configuration: EngineConfiguration(threadingModel: threadingModel)))
        var runs = 0
        var imports = Imports()
        imports.define(
            module: "env", name: "suspend",
            Function(
                store: store, parameters: [.i32, .i64], results: [.i32],
                raw: { _, arguments, _ in
                    runs += 1
                    throw SuspensionRequest(id: UInt64(arguments[1].i64))
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
        // Another suspension must not overwrite the first one's arguments.
        let other = try ResumableCall(function: try #require(instance.exports[function: "f"]), arguments: [.i32(6)])
        _ = try Self.suspension(try other.resume())
        #expect(suspension.reason == .hostCall(id: 42, arguments: [.i32(5), .i64(42)]))
        #expect(call.suspension?.reason == .hostCall(id: 42, arguments: [.i32(5), .i64(42)]))
        #expect(try Self.results(try call.resume(returning: [.i32(10)])) == [.i32(9)])
        #expect(runs == 2)
    }

    /// `f` calls the function reference that `pass` returns, so a broken reference cannot reach
    /// `$target`.
    static let references = """
        (module
          (import "env" "pass" (func $pass (param funcref externref) (result externref funcref)))
          (type $nullary (func (result i32)))
          (table $t 1 funcref)
          (elem declare func $target)
          (func $target (result i32) (i32.const 42))
          (func (export "f") (param externref) (result externref i32)
            (local $function funcref)
            (call $pass (ref.func $target) (local.get 0))
            (local.set $function)
            (table.set $t (i32.const 0) (local.get $function))
            (call_indirect $t (type $nullary) (i32.const 0))))
        """

    @Test(arguments: testedThreadingModels)
    func referencesSurviveSuspension(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var suspends = false
        let fixture = try Fixture(
            Self.references, threadingModel: threadingModel,
            hosts: [
                "pass": { fixture, arguments in
                    if suspends { return try Self.suspend(fixture, arguments) }
                    return [.ref(.extern(99)), arguments[0]]
                }
            ])
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
        #expect(suspension.reason == .hostCall(id: 7, arguments: [.ref(.function(address)), .ref(.extern(5))]))
        #expect(
            Self.resumableCallError { try call.resume(returning: [.ref(.function(address)), .ref(.extern(99))]) }
                != nil)
        let results = try Self.results(
            try call.resume(returning: [.ref(.extern(99)), .ref(.function(address))]))
        #expect(results == reference)
        #expect(fixture.count("pass") == 2)
    }

    // MARK: Rejected results and suspensions

    @Test(arguments: testedThreadingModels)
    func wrongResultsThrowBeforeGuestRuns(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.shapes, threadingModel: threadingModel, hosts: ["wait": Self.suspend, "triple": Self.suspend])
        let call = try ResumableCall(function: try fixture.export("multi"), arguments: [.i32(4)])
        let suspension = try Self.suspension(try call.resume())
        let mismatch = ResumableCallError.resultTypesMismatch(expected: [.i32, .i64, .f64], got: [.i32(1)])
        #expect(Self.resumableCallError { try call.resume(returning: [.i32(1)]) } == mismatch.description)
        #expect(
            Self.resumableCallError {
                try call.resume(returning: [.i32(1), .i32(2), .f64(0), .i32(3)])
            } != nil)
        #expect(
            Self.resumableCallError { try call.resume(returning: [.i32(1), .i32(2), .f64(0)]) }
                != nil)
        #expect(call.suspension?.reason == suspension.reason)
        let results = try Self.results(
            try call.resume(returning: [.i32(1), .i64(2), .f64(Double(3).bitPattern)]))
        #expect(results == [.f64(Double(6).bitPattern)])
        #expect(fixture.count("triple") == 1)
    }

    @Test(arguments: testedThreadingModels)
    func onlyCallSuspendedAtHostCallTakesResults(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, fuel: 0,
            hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(3)])
        let notAtHostCall = ResumableCallError.notSuspendedAtHostCall.description
        #expect(Self.resumableCallError { try call.resume(returning: [.i32(1)]) } == notAtHostCall)
        let outOfFuel = try Self.suspension(try call.resume())
        guard case .outOfFuel = outOfFuel.reason else {
            Issue.record("expected an out-of-fuel suspension, got \(outOfFuel.reason)")
            return
        }
        #expect(Self.resumableCallError { try call.resume(returning: []) } == notAtHostCall)
        #expect(Self.resumableCallError { try call.resume(failing: HostFailure()) } == notAtHostCall)
        #expect(call.suspension?.reason == outOfFuel.reason)
        fixture.store.fuel = Fuel(remaining: 1 << 20)
        let suspension = try Self.suspension(try call.resume())
        #expect(suspension.reason == .hostCall(id: 7, arguments: [.i32(30)]))
        _ = try Self.suspension(try call.resume(returning: [.i32(35)]))
        #expect(throws: Trap.self) { try call.resume(throwing: Trap(.message(.init("cancelled")))) }
        #expect(Self.resumableCallError { try call.resume(returning: [.i32(1)]) } == ResumableCallError.finished.description)
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(2)]])
    }

    // MARK: Two calls of one store

    /// `run` suspends with its argument as the identifier and then passes the result to `after`.
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
        throw SuspensionRequest(id: UInt64(arguments[0].i32))
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
        #expect(aSuspension.reason == .hostCall(id: 1, arguments: [.i32(1)]))
        #expect(bSuspension.reason == .hostCall(id: 2, arguments: [.i32(2)]))

        #expect(Self.resumableCallError { try a.resume(returning: [.i64(10)]) } != nil)
        #expect(fixture.count("after") == 0)

        #expect(try Self.results(try b.resume(returning: [.i32(20)])) == [.i32(22)])
        #expect(try Self.results(try a.resume(returning: [.i32(10)])) == [.i32(11)])
        #expect(fixture.calls["after"] == [[.i32(20)], [.i32(10)]])
        #expect(fixture.store.isSuspendable == false)
    }

    /// The suspended calls that `drive` resumes, and what it saw.
    final class Pending {
        var first: ResumableCall?
        var second: ResumableCall?
        var error: String?
        var firstResults: [Value]?
        var secondTrapped = false
    }

    @Test(arguments: testedThreadingModels)
    func hostFunctionFinishesOtherCallsBeforeItsOwnCallSuspends(
        threadingModel: EngineConfiguration.ThreadingModel
    ) throws {
        let pending = Pending()
        let fixture = try Fixture(
            Self.twoCalls, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspendWithArgument, "after": { _, _ in [] },
                "drive": { fixture, _ in
                    let first = try #require(pending.first)
                    let second = try #require(pending.second)
                    pending.error = Self.resumableCallError { try first.resume(returning: []) }
                    #expect(fixture.store.isSuspendable)
                    pending.firstResults = try Self.results(
                        try first.resume(returning: [.i32(100)]))
                    #expect(fixture.store.isSuspendable)
                    do {
                        _ = try second.resume(returning: [.i32(0)])
                    } catch let trap as Trap {
                        if case .unreachable = trap.reason { pending.secondTrapped = true }
                    }
                    #expect(fixture.store.isSuspendable)
                    return [.i32(1)]
                },
            ])
        pending.first = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(5)])
        _ = try Self.suspension(try #require(pending.first).resume())
        pending.second = try ResumableCall(function: try fixture.export("trapAfter"), arguments: [.i32(6)])
        _ = try Self.suspension(try #require(pending.second).resume())

        let outer = try ResumableCall(function: try fixture.export("outer"))
        let suspension = try Self.suspension(try outer.resume())
        #expect(suspension.reason == .hostCall(id: 9, arguments: [.i32(9)]))
        #expect(pending.error != nil)
        #expect(pending.firstResults == [.i32(105)])
        #expect(pending.secondTrapped)
        #expect(try Self.results(try outer.resume(returning: [.i32(1000)])) == [.i32(1001)])
        #expect(fixture.calls["after"] == [[.i32(100)]])
        #expect(fixture.store.isSuspendable == false)
    }

    // MARK: Calls into the host

    /// The tail-called frame moves down in `small` and up in `large`.
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
    func tailCallToHostResumesInMovedFrame(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.tailCalls, threadingModel: threadingModel, hosts: ["suspend": Self.suspend])
        let small = try ResumableCall(function: try fixture.export("small"), arguments: [.i32(5)])
        let smallSuspension = try Self.suspension(try small.resume())
        #expect(smallSuspension.reason == .hostCall(id: 7, arguments: [.i32(5), .i64(5), .i32(9)]))
        #expect(
            try Self.results(try small.resume(returning: [.i64(1000), .i32(7)]))
                == [.i64(1007)])
        let large = try ResumableCall(function: try fixture.export("large"), arguments: [.i32(5)])
        let largeSuspension = try Self.suspension(try large.resume())
        #expect(largeSuspension.reason == .hostCall(id: 7, arguments: [.i32(5), .i64(8), .i32(8)]))
        #expect(
            try Self.results(try large.resume(returning: [.i64(2000), .i32(30)]))
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
    func indirectCallsToHostSuspend(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(Self.indirectCalls, threadingModel: threadingModel, hosts: ["suspend": Self.suspend])
        let call = try ResumableCall(function: try fixture.export("indirect"), arguments: [.i32(10)])
        let first = try Self.suspension(try call.resume())
        #expect(first.reason == .hostCall(id: 7, arguments: [.i32(10)]))
        let second = try Self.suspension(try call.resume(returning: [.i32(100)]))
        #expect(second.reason == .hostCall(id: 7, arguments: [.i32(11)]))
        #expect(try Self.results(try call.resume(returning: [.i32(1000)])) == [.i32(1100)])
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
    func exceptionHandlersSurviveHostCallSuspension(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let (exception, _) = try Self.exceptionAndTrap(fixture)
        let caller = try ResumableCall(function: try fixture.export("caller"))
        _ = try Self.suspension(try caller.resume())
        #expect(try Self.results(try caller.resume(returning: [.i32(5)])) == [.i32(15)])
        let delivered = try ResumableCall(function: try fixture.export("caller"))
        _ = try Self.suspension(try delivered.resume())
        #expect(try Self.results(try delivered.resume(failing: exception)) == [.i32(77)])
    }

    /// `ordered` returns the payload when the tagged clause catches and -1 when `catch_all` does.
    /// `exited` suspends again outside the `try_table`.
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
    func failedHostCallFollowsCatchClauses(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(Self.catchClauses, threadingModel: threadingModel, hosts: ["suspend": Self.suspend])
        var exception: WasmKitException?
        do { _ = try fixture.export("raise")([.i32(77)]) } catch let error as WasmKitException { exception = error }
        let raised = try #require(exception)

        let ordered = try ResumableCall(function: try fixture.export("ordered"))
        _ = try Self.suspension(try ordered.resume())
        #expect(try Self.results(try ordered.resume(failing: raised)) == [.i32(77)])

        // After a catch, the try_table's catch_all no longer applies.
        let exited = try ResumableCall(function: try fixture.export("exited"))
        _ = try Self.suspension(try exited.resume())
        _ = try Self.suspension(try exited.resume(failing: raised))
        #expect(throws: WasmKitException.self) { try exited.resume(failing: raised) }
        #expect(exited.isFinished)
    }

    @Test(arguments: testedThreadingModels)
    func failingThrowsLikeSynchronousHostFunction(
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

        let guarded = try ResumableCall(function: try fixture.export("guarded"))
        _ = try Self.suspension(try guarded.resume())
        #expect(try Self.results(try guarded.resume(failing: exception)) == [.i32(77)])

        let unguarded = try ResumableCall(function: try fixture.export("unguarded"))
        _ = try Self.suspension(try unguarded.resume())
        #expect(throws: WasmKitException.self) { try unguarded.resume(failing: exception) }
        #expect(unguarded.isFinished)

        let trapped = try ResumableCall(function: try fixture.export("deep"))
        _ = try Self.suspension(try trapped.resume())
        var resumed: Trap?
        do { _ = try trapped.resume(failing: trap) } catch let error as Trap { resumed = error }
        synchronousFailure = trap
        var synchronous: Trap?
        do { _ = try fixture.export("deep")() } catch let error as Trap { synchronous = error }
        let resumedBacktrace = try #require(resumed?.backtrace)
        let synchronousBacktrace = try #require(synchronous?.backtrace)
        #expect(resumedBacktrace.trapSite == synchronousBacktrace.trapSite)
        #expect(resumedBacktrace.symbols.count == 2)
        #expect(resumedBacktrace.symbols.map(\.name) == synchronousBacktrace.symbols.map(\.name))
        // `invoke` and a resumable call return to different code.
        #expect(
            resumedBacktrace.symbols.dropLast().map(\.address) == synchronousBacktrace.symbols.dropLast().map(\.address))
        #expect(trapped.isFinished)

        synchronousFailure = nil
        let failed = try ResumableCall(function: try fixture.export("unguarded"))
        _ = try Self.suspension(try failed.resume())
        #expect(throws: HostFailure.self) { try failed.resume(failing: HostFailure()) }
        #expect(failed.isFinished)
        #expect(fixture.count("effect") == 0)
    }

    @Test(arguments: testedThreadingModels)
    func cancellingKeepsGuestFromCatchingAnything(threadingModel: EngineConfiguration.ThreadingModel) throws {
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
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: SuspensionRequest(id: 1)) }
        #expect(call.suspension?.reason == suspension.reason)

        var cancelled: Trap?
        do { try call.resume(throwing: trap) } catch let error as Trap { cancelled = error }
        synchronousFailure = trap
        var synchronous: Trap?
        do { _ = try fixture.export("guarded")() } catch let error as Trap { synchronous = error }
        #expect(try #require(cancelled?.backtrace).trapSite == (try #require(synchronous?.backtrace)).trapSite)
        #expect(call.isFinished)
        #expect(Self.resumableCallError { try call.resume(returning: [.i32(1)]) } != nil)

        guard let stack = call.takeStack() else {
            Issue.record("expected the stack back")
            return
        }
        synchronousFailure = nil
        let next = try ResumableCall(function: try fixture.export("unguarded"), on: stack)
        _ = try Self.suspension(try next.resume())
        #expect(try Self.results(try next.resume(returning: [.i32(3)])) == [.i32(3)])
        #expect(fixture.count("effect") == 1)
    }

    /// How a call suspended in `unguarded` ends.
    enum Ending: CaseIterable {
        case returned, trapped, raised, failed, cancelled
    }

    @Test(arguments: testedThreadingModels)
    func finishedCallReturnsStackHoweverItEnded(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let (exception, trap) = try Self.exceptionAndTrap(fixture)
        let unguarded = try fixture.export("unguarded")
        var stack = ExecutionStack(engine: fixture.store.engine)
        for ending in Ending.allCases {
            let call = try ResumableCall(function: unguarded, on: stack)
            _ = try Self.suspension(try call.resume())
            do {
                switch ending {
                case .returned:
                    #expect(try Self.results(try call.resume(returning: [.i32(3)])) == [.i32(3)])
                case .trapped:
                    #expect(throws: Trap.self) { try call.resume(failing: trap) }
                case .raised:
                    #expect(throws: WasmKitException.self) { try call.resume(failing: exception) }
                case .failed:
                    #expect(throws: HostFailure.self) { try call.resume(failing: HostFailure()) }
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
        #expect(fixture.count("effect") == 1)
        #expect(fixture.count("suspend") == Ending.allCases.count)
    }

    @Test(arguments: testedThreadingModels)
    func suspensionRequestCannotCompleteOrCancelCall(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.failures, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("unguarded"))
        let suspension = try Self.suspension(try call.resume())
        #expect(
            Self.resumableCallError { try call.resume(failing: SuspensionRequest(id: 2)) }
                == ResumableCallError.requestNotThrowable.description)
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: SuspensionRequest(id: 2)) }
        #expect(call.suspension?.reason == suspension.reason)
        #expect(fixture.count("suspend") == 1)
        #expect(try Self.results(try call.resume(returning: [.i32(4)])) == [.i32(4)])
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
    func invokeTrapsInsteadOfSuspending(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var nested: (any Error)?
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    // A suspension cannot save this host function's native frames.
                    do { _ = try fixture.export("inner")() } catch { nested = error }
                    #expect(fixture.store.isSuspendable)
                    throw SuspensionRequest(id: UInt64(arguments[0].i32))
                },
            ])
        var direct: (any Error)?
        do { _ = try fixture.export("inner")() } catch { direct = error }
        Self.expectSuspensionUnavailable(direct)
        #expect((direct as? Trap)?.backtrace?.symbols.isEmpty == false)

        let call = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(21)])
        let suspension = try Self.suspension(try call.resume())
        Self.expectSuspensionUnavailable(nested)
        #expect(suspension.reason == .hostCall(id: 21, arguments: [.i32(21)]))
        #expect(try Self.results(try call.resume(returning: [.i32(8)])) == [.i32(8)])
        #expect(fixture.count("suspend") == 2)
        #expect(fixture.store.isSuspendable == false)
    }

    @Test(arguments: testedThreadingModels)
    func hostFunctionCalledWithoutGuestCannotSuspend(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var inner: [String: any Error] = [:]
        var pausing: Function?
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    let pausing = try #require(pausing)
                    if arguments[0] == .i32(1) {
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
            throw SuspensionRequest(id: 3)
        }
        let host = try #require(pausing)
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
    func cancellingFromHostFunctionDoesNotSuspendCaller(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var inner: ResumableCall?
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    let call = try #require(inner)
                    if arguments[0] == .i32(1) {
                        try call.resume(throwing: SuspensionRequest(id: 4))
                    }
                    try #require(call.suspension != nil)
                    return try Self.results(try call.resume(failing: SuspensionRequest(id: 4)))
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
    func resumableCallInsideHostFunctionSuspendsOnItsOwn(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var innerSuspensions = 0
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel,
            hosts: [
                "suspend": Self.suspend,
                "reenter": { fixture, arguments in
                    let doubled = try fixture.export("double")([arguments[0]])
                    let call = try ResumableCall(function: try fixture.export("inner"))
                    _ = try Self.suspension(try call.resume())
                    innerSuspensions += 1
                    #expect(fixture.store.isSuspendable == (arguments[0] != .i32(.max)))
                    let results = try Self.results(try call.resume(returning: doubled))
                    throw SuspensionRequest(id: UInt64(results[0].i32))
                },
            ])
        let outer = try ResumableCall(function: try fixture.export("outer"), arguments: [.i32(21)])
        let suspension = try Self.suspension(try outer.resume())
        #expect(suspension.reason == .hostCall(id: 42, arguments: [.i32(21)]))
        #expect(try Self.results(try outer.resume(returning: [.i32(7)])) == [.i32(7)])
        #expect(innerSuspensions == 1)

        var error: (any Error)?
        do { _ = try fixture.export("outer")([.i32(.max)]) } catch let caught { error = caught }
        Self.expectSuspensionUnavailable(error)
        #expect(innerSuspensions == 2)
        #expect(fixture.store.isSuspendable == false)
    }

    @Test(arguments: testedThreadingModels)
    func runningCallCannotBeResumed(threadingModel: EngineConfiguration.ThreadingModel) throws {
        var call: ResumableCall?
        var suspended = false
        var errors: [String?] = []
        let fixture = try Fixture(
            #"(module (import "env" "h" (func $h (result i32))) (func (export "f") (result i32) (i32.add (call $h) (call $h))))"#,
            threadingModel: threadingModel,
            hosts: [
                "h": { _, _ in
                    let running = try #require(call)
                    guard suspended else { throw SuspensionRequest(id: 1) }
                    #expect(running.suspension == nil)
                    errors.append(Self.resumableCallError { try running.resume(returning: [.i32(1)]) })
                    errors.append(Self.resumableCallError { try running.resume() })
                    return [.i32(2)]
                }
            ])
        call = try ResumableCall(function: try fixture.export("f"))
        _ = try Self.suspension(try #require(call).resume())
        suspended = true
        #expect(try Self.results(try #require(call).resume(returning: [.i32(40)])) == [.i32(42)])
        let running = ResumableCallError.alreadyRunning.description
        #expect(errors == [running, running])
    }

    @Test(arguments: testedThreadingModels)
    func rejectedResumesKeepCallSuspended(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        let call = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(3)])
        let suspension = try Self.suspension(try call.resume())
        #expect(Self.resumableCallError { try call.resume(returning: []) } != nil)
        #expect(Self.resumableCallError { try call.resume(returning: [.i64(1)]) } != nil)
        #expect(Self.resumableCallError { try call.resume(returning: [.i32(1), .i32(2)]) } != nil)
        #expect(Self.resumableCallError { try call.resume() } != nil)
        #expect(Self.resumableCallError { try call.resume(failing: SuspensionRequest()) } != nil)
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: SuspensionRequest()) }
        #expect(call.suspension?.reason == suspension.reason)
        #expect(!call.isFinished)
        #expect(fixture.calls["effect"] == [[.i32(1)]])
        #expect(try fixture.export("writes")() == [.i32(1)])
        #expect(fixture.count("suspend") == 1)
        _ = try Self.suspension(try call.resume(returning: [.i32(35)]))
        #expect(fixture.calls["effect"] == [[.i32(1)], [.i32(2)]])
    }

    @Test(arguments: testedThreadingModels)
    func droppingSuspendedCallReleasesIt(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let fixture = try Fixture(
            Self.nested, threadingModel: threadingModel, hosts: ["suspend": Self.suspend, "effect": { _, _ in [] }])
        weak var dropped: ResumableCall?
        do {
            let call = try ResumableCall(function: try fixture.export("run"), arguments: [.i32(3)])
            _ = try Self.suspension(try call.resume())
            dropped = call
        }
        #expect(dropped == nil)
        #expect(fixture.calls["effect"] == [[.i32(1)]])
    }

    // MARK: Memory

    @Test(arguments: testedThreadingModels, [EngineConfiguration.MemoryBoundsChecking.mprotect, .software])
    func memoryWrittenAndGrownDuringSuspensionIsSeen(
        threadingModel: EngineConfiguration.ThreadingModel,
        memoryBoundsChecking: EngineConfiguration.MemoryBoundsChecking
    ) throws {
        let fixture = try Fixture(
            Self.reentry, threadingModel: threadingModel, memoryBoundsChecking: memoryBoundsChecking,
            hosts: ["suspend": Self.suspend, "reenter": { _, _ in [.i32(0)] }])
        let call = try ResumableCall(function: try fixture.export("mem"))
        _ = try Self.suspension(try call.resume())
        let memory = try #require(fixture.instance.exports[memory: "memory"])
        // `.mprotect` may still allocate the memory without a reservation, as on Android.
        let reserved = memory.handle.withValue { $0.trapGuardReservationSize } > 0
        func base() -> UInt {
            memory.withUnsafeMutableBufferPointer(offset: 0, count: 1) { UInt(bitPattern: $0.baseAddress) }
        }
        let before = base()
        memory.withUnsafeMutableBufferPointer(offset: 20, count: 4) { bytes in
            bytes.storeBytes(of: UInt32(100).littleEndian, as: UInt32.self)
        }
        // Without a reservation the memory moves, and the guest must find it again.
        #expect(try fixture.export("grow")() == [.i32(1)])
        #expect((base() != before) == !reserved)
        #expect(try Self.results(try call.resume(returning: [.i32(0)])) == [.i32(41 + 100 + 2 + 5)])
    }

    static let outOfBounds = """
        (module
          (import "env" "suspend" (func $suspend (result i32)))
          (memory 1)
          (func (export "load") (result i32)
            (i32.load (i32.add (call $suspend) (i32.const 65528)))))
        """

    @Test(arguments: testedThreadingModels, [EngineConfiguration.MemoryBoundsChecking.mprotect, .software])
    func outOfBoundsAccessAfterResumingTraps(
        threadingModel: EngineConfiguration.ThreadingModel,
        memoryBoundsChecking: EngineConfiguration.MemoryBoundsChecking
    ) throws {
        let fixture = try Fixture(
            Self.outOfBounds, threadingModel: threadingModel, memoryBoundsChecking: memoryBoundsChecking,
            hosts: ["suspend": Self.suspend])
        let inBounds = try ResumableCall(function: try fixture.export("load"))
        _ = try Self.suspension(try inBounds.resume())
        #expect(try Self.results(try inBounds.resume(returning: [.i32(0)])) == [.i32(0)])
        let outside = try ResumableCall(function: try fixture.export("load"))
        _ = try Self.suspension(try outside.resume())
        var error: (any Error)?
        do { _ = try outside.resume(returning: [.i32(8)]) } catch let caught { error = caught }
        guard let trap = error as? Trap, case .memoryOutOfBounds = trap.reason else {
            Issue.record("expected an out-of-bounds trap, got \(String(describing: error))")
            return
        }
    }
}
