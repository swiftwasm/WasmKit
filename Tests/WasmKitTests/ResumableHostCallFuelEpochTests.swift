import Testing
import WAT
import WasmParser

@testable import WasmKit

/// Suspensions at host calls in calls that fuel metering or epoch interruption also suspend.
///
/// Answering a host call charges no fuel and checks no epoch. The guest pays the fuel and passes
/// the epoch checks of the same guest with a synchronous host function, and stops at the same
/// places.
@Suite
struct ResumableHostCallFuelEpochTests {
    static let features: WasmFeatureSet = [.referenceTypes, .exceptionHandling, .tailCall]

    /// `f` adds up `ask(i)` for each `i` below `n`, and reports each step to `note` after `ask`
    /// answered. The loop header is the only epoch check after the first one.
    static let asking = """
        (module
          (import "env" "ask" (func $ask (param i32) (result i32)))
          (import "env" "note" (func $note (param i32)))
          (func (export "f") (param $n i32) (result i32) (local $i i32) (local $sum i32)
            (loop $l
              (local.set $sum (i32.add (local.get $sum) (call $ask (local.get $i))))
              (call $note (local.get $i))
              (local.set $i (i32.add (local.get $i) (i32.const 1)))
              (br_if $l (i32.lt_u (local.get $i) (local.get $n))))
            (local.get $sum)))
        """

    /// What the host functions of a ``Guest`` do and saw.
    final class Log {
        /// Whether `ask` suspends rather than answers.
        var suspends = false
        /// The `ask` call, counted from zero, that empties the store's fuel before it answers.
        var emptiesFuelAt: UInt32?
        /// Every host call, in order, as `ask i` or `note i`.
        var events: [String] = []

        func count(_ prefix: String) -> Int {
            events.filter { $0.hasPrefix(prefix) }.count
        }
    }

    /// ``asking`` instantiated on a store of its own.
    struct Guest {
        let store: Store
        let function: Function
        let log: Log

        /// - Parameters:
        ///   - fuel: A budget, which also turns fuel metering on.
        ///   - epochInterruption: Whether the engine instruments the guest with epoch checks. The
        ///     store's deadline stays at "never" until a test sets one.
        init(threadingModel: EngineConfiguration.ThreadingModel, fuel: UInt64? = nil, epochInterruption: Bool = false)
            throws
        {
            let store = Store(
                engine: Engine(
                    configuration: EngineConfiguration(
                        threadingModel: threadingModel, features: ResumableHostCallFuelEpochTests.features,
                        fuelMetering: fuel != nil, epochInterruption: epochInterruption)))
            let configuration = store.engine.configuration
            #expect(configuration.threadingModel == threadingModel)
            #expect(configuration.fuelMetering == (fuel != nil))
            #expect(configuration.epochInterruption == epochInterruption)
            if let fuel { store.fuel = Fuel(remaining: fuel) }
            let log = Log()
            var imports = Imports()
            imports.define(
                module: "env", name: "ask",
                Function(store: store, parameters: [.i32], results: [.i32]) { caller, arguments in
                    let step = arguments[0].i32
                    log.events.append("ask \(step)")
                    if log.emptiesFuelAt == step { caller.store.fuel = Fuel(remaining: 0) }
                    if log.suspends { throw SuspensionRequest(tag: UInt64(step)) }
                    return [.i32(step * 2)]
                })
            imports.define(
                module: "env", name: "note",
                Function(store: store, parameters: [.i32], results: []) { _, arguments in
                    log.events.append("note \(arguments[0].i32)")
                    return []
                })
            let module = try parseWasm(
                bytes: wat2wasm(ResumableHostCallFuelEpochTests.asking, features: ResumableHostCallFuelEpochTests.features),
                features: ResumableHostCallFuelEpochTests.features)
            let instance = try module.instantiate(store: store, imports: imports)
            self.store = store
            self.function = try #require(instance.exports[function: "f"])
            self.log = log
        }

        var remainingFuel: UInt64 {
            get throws { try #require(store.fuel).remaining }
        }
    }

    /// Counts the fuel a run spends while the test refills the store from time to time.
    struct Meter {
        private(set) var spent: UInt64 = 0
        private var given: UInt64

        init(_ guest: Guest) throws { given = try guest.remainingFuel }

        /// Records what was spent since the last refill, and refills the store with `fuel`.
        mutating func refill(_ guest: Guest, with fuel: UInt64) throws {
            spent += given - (try guest.remainingFuel)
            guest.store.fuel = Fuel(remaining: fuel)
            given = fuel
        }

        /// Records what was spent since the last refill.
        mutating func finish(_ guest: Guest) throws {
            spent += given - (try guest.remainingFuel)
            given = try guest.remainingFuel
        }
    }

    static let budget: UInt64 = 1 << 40
    static let steps: UInt32 = 6
    static let sum: [Value] = [.i32((0..<steps).reduce(0) { $0 + $1 * 2 })]

    /// The result and the fuel of a plain call with a synchronous `ask`.
    static func synchronousRun(
        _ threadingModel: EngineConfiguration.ThreadingModel, epochInterruption: Bool = false
    ) throws -> (results: [Value], fuel: UInt64, events: [String]) {
        let guest = try Guest(threadingModel: threadingModel, fuel: budget, epochInterruption: epochInterruption)
        let results = try guest.function([.i32(steps)])
        return (results, budget - (try guest.remainingFuel), guest.log.events)
    }

    // MARK: Fuel

    @Test(arguments: testedThreadingModels)
    func aHostSuspensionPaysNoFuel(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let reference = try Self.synchronousRun(threadingModel)
        #expect(reference.results == Self.sum)

        let guest = try Guest(threadingModel: threadingModel, fuel: Self.budget)
        guest.log.suspends = true
        let call = try ResumableCall(function: guest.function, arguments: [.i32(Self.steps)])
        var status = try call.resume()
        while case .suspended(let suspension) = status {
            guard case .hostCall(let tag, _) = suspension.reason else {
                Issue.record("expected only host call suspensions, got \(suspension.reason)")
                return
            }
            guard guest.log.count("ask") <= Int(Self.steps) else {
                Issue.record("the host function ran again at step \(tag)")
                return
            }
            // The answer is due, so a plain resume is refused rather than read as a fuel retry.
            #expect(throws: ResumableCallError.self) { try call.resume() }
            status = try call.resume(returning: [.i32(UInt32(tag) * 2)], answering: suspension)
        }
        #expect(try ResumableHostCallTests.results(status) == reference.results)
        #expect(Self.budget - (try guest.remainingFuel) == reference.fuel)
        #expect(guest.log.events == reference.events)
    }

    /// An answer given while the store has no fuel goes on to the next charge and suspends there,
    /// at the place where a synchronous host function that emptied the fuel makes a plain call
    /// trap. Topping up then retries that charge and nothing before it.
    @Test(arguments: testedThreadingModels)
    func anAnswerWithoutFuelSuspendsAtTheNextCharge(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let reference = try Self.synchronousRun(threadingModel)
        let emptied = try Guest(threadingModel: threadingModel, fuel: Self.budget)
        emptied.log.emptiesFuelAt = 0
        let trap = #expect(throws: Trap.self) { try emptied.function([.i32(Self.steps)]) }
        guard let trap, case .outOfFuel = trap.reason else {
            Issue.record("expected an out-of-fuel trap, got \(String(describing: trap))")
            return
        }

        let guest = try Guest(threadingModel: threadingModel, fuel: Self.budget)
        guest.log.suspends = true
        var meter = try Meter(guest)
        let call = try ResumableCall(function: guest.function, arguments: [.i32(Self.steps)])
        let first = try ResumableHostCallTests.suspension(try call.resume())
        #expect(first.reason == .hostCall(tag: 0, arguments: [.i32(0)]))
        try meter.refill(guest, with: 0)
        let outOfFuel = try ResumableHostCallTests.suspension(try call.resume(returning: [.i32(0)], answering: first))
        guard case .outOfFuel(let required) = outOfFuel.reason else {
            Issue.record("expected an out-of-fuel suspension, got \(outOfFuel.reason)")
            return
        }
        // The guest ran exactly as far as the synchronous one, and the host function ran once.
        #expect(guest.log.events == emptied.log.events)
        #expect(guest.log.count("ask") == 1)
        #expect(
            ResumableHostCallTests.refusal { try call.resume(returning: [.i32(0)], answering: outOfFuel) }
                == ResumableCallError.notSuspendedAtHostCall.description)
        #expect(
            ResumableHostCallTests.refusal { try call.resume(returning: [.i32(0)], answering: first) }
                == ResumableCallError.notSuspendedAtHostCall.description)

        // With just enough fuel each time, the rest of the call alternates between both kinds.
        try meter.refill(guest, with: required)
        var status = try call.resume()
        var fuelSuspensions = 1
        var hostCalls = 1
        while case .suspended(let suspension) = status {
            switch suspension.reason {
            case .outOfFuel(let required):
                fuelSuspensions += 1
                try meter.refill(guest, with: required)
                status = try call.resume()
            case .hostCall(let tag, _):
                hostCalls += 1
                guard hostCalls <= Int(Self.steps) else {
                    Issue.record("the host function ran again at step \(tag)")
                    return
                }
                status = try call.resume(returning: [.i32(UInt32(tag) * 2)], answering: suspension)
            case .epochDeadlineReached:
                Issue.record("unexpected epoch suspension")
                return
            }
        }
        try meter.finish(guest)
        #expect(try ResumableHostCallTests.results(status) == reference.results)
        #expect(meter.spent == reference.fuel)
        #expect(guest.log.events == reference.events)
        // Every later step pays at its loop header, with nothing left to pay from.
        #expect(fuelSuspensions >= Int(Self.steps) - 1, "\(fuelSuspensions) fuel suspensions")
    }

    // MARK: Epoch

    /// The epoch passes the deadline while the call waits at a host call. The answer is taken
    /// and the guest goes on to the next epoch check, the loop header, where it stops. The step
    /// it reports in between runs first. The last answer leaves the loop without passing a check,
    /// so the call returns although the deadline has passed.
    @Test(arguments: testedThreadingModels)
    func theEpochPassingDuringAHostSuspensionStopsTheGuestAtTheNextCheck(
        threadingModel: EngineConfiguration.ThreadingModel
    ) throws {
        let guest = try Guest(threadingModel: threadingModel, epochInterruption: true)
        guest.log.suspends = true
        let ticker = guest.store.engine.epochTicker
        guest.store.setEpochDeadline(ticksBeyondCurrent: 1)
        let call = try ResumableCall(function: guest.function, arguments: [.i32(Self.steps)])
        var stops: [String] = []
        var status = try call.resume()
        while case .suspended(let suspension) = status {
            switch suspension.reason {
            case .hostCall(let tag, _):
                stops.append("host \(tag)")
                guard guest.log.count("ask") <= Int(Self.steps) else {
                    Issue.record("the host function ran again at step \(tag)")
                    return
                }
                let seen = guest.log.events.count
                ticker.increment()
                // A plain resume neither retries the host call nor checks the epoch.
                #expect(throws: ResumableCallError.self) { try call.resume() }
                status = try call.resume(returning: [.i32(UInt32(tag) * 2)], answering: suspension)
                #expect(guest.log.events[seen...] == ["note \(tag)"])
            case .epochDeadlineReached:
                stops.append("epoch")
                #expect(throws: ResumableCallError.self) { try call.resume(returning: [.i32(0)], answering: suspension) }
                guest.store.setEpochDeadline(ticksBeyondCurrent: 1)
                status = try call.resume()
            case .outOfFuel:
                Issue.record("unexpected fuel suspension")
                return
            }
        }
        #expect(try ResumableHostCallTests.results(status) == Self.sum)
        let expected = (0..<Self.steps).flatMap { step in step + 1 < Self.steps ? ["host \(step)", "epoch"] : ["host \(step)"] }
        #expect(stops == expected)
        #expect(guest.log.count("ask") == Int(Self.steps))
    }

    // MARK: Both

    /// Fuel, epoch and host call suspensions in one call keep their reasons, and each continues
    /// only the way its reason allows. The fuel spent is that of a plain call on the same engine.
    @Test(arguments: testedThreadingModels)
    func fuelEpochAndHostSuspensionsKeepApart(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let reference = try Self.synchronousRun(threadingModel, epochInterruption: true)
        #expect(reference.results == Self.sum)

        let guest = try Guest(threadingModel: threadingModel, fuel: 0, epochInterruption: true)
        guest.log.suspends = true
        let ticker = guest.store.engine.epochTicker
        var meter = try Meter(guest)
        let call = try ResumableCall(function: guest.function, arguments: [.i32(Self.steps)])
        var kinds: Set<String> = []
        var hostCalls = 0
        var status = try call.resume()
        while case .suspended(let suspension) = status {
            switch suspension.reason {
            case .outOfFuel(let required):
                kinds.insert("fuel")
                #expect(
                    ResumableHostCallTests.refusal { try call.resume(returning: [], answering: suspension) }
                        == ResumableCallError.notSuspendedAtHostCall.description)
                try meter.refill(guest, with: required)
                status = try call.resume()
            case .epochDeadlineReached:
                kinds.insert("epoch")
                #expect(
                    ResumableHostCallTests.refusal { try call.resume(returning: [], answering: suspension) }
                        == ResumableCallError.notSuspendedAtHostCall.description)
                guest.store.setEpochDeadline(ticksBeyondCurrent: 1)
                status = try call.resume()
            case .hostCall(let tag, _):
                kinds.insert("host")
                hostCalls += 1
                guard hostCalls <= Int(Self.steps) else {
                    Issue.record("the host function ran again at step \(tag)")
                    return
                }
                #expect(
                    ResumableHostCallTests.refusal { try call.resume() }
                        == ResumableCallError.suspendedAtHostCall.description)
                // The deadline passes while the call waits for its answer.
                guest.store.setEpochDeadline(ticksBeyondCurrent: 1)
                ticker.increment()
                status = try call.resume(returning: [.i32(UInt32(tag) * 2)], answering: suspension)
            }
        }
        try meter.finish(guest)
        #expect(try ResumableHostCallTests.results(status) == reference.results)
        #expect(meter.spent == reference.fuel)
        #expect(guest.log.events == reference.events)
        #expect(kinds == ["fuel", "epoch", "host"])
    }
}
