// A differential oracle for resumable calls.
//
// The reference runs every export with a plain call and a fixed fuel budget. The subject runs the
// same exports as `ResumableCall`s, suspended by tiny fuel slices, by forced epoch deadlines and
// by epoch ticks from the guest, and resumed until they finish. Both must agree on results,
// traps, memory, globals and the fuel each call consumed.

import WAT
import WasmParser
@_spi(Fuzzing) import WasmKit

public struct Finding: Error, CustomStringConvertible {
    public let description: String
}

struct HostFailure: Error, CustomStringConvertible {
    let value: UInt32
    var description: String { "host failure \(value)" }
}

struct Cancelled: Error {}

/// What a call ended with.
enum Outcome: Equatable, CustomStringConvertible {
    case returned([Value])
    case failed(String)
    case outOfFuel

    init(error: any Error) {
        switch error {
        case let trap as Trap:
            let line = String(String(describing: trap).split(separator: "\n", maxSplits: 1).first ?? "")
            self = line == "Trap: out of fuel" ? .outOfFuel : .failed(line)
        case is WasmKitException:
            self = .failed("uncaught exception")
        default:
            self = .failed(String(describing: error))
        }
    }

    var description: String {
        switch self {
        case .returned(let values): return "returned \(values)"
        case .failed(let message): return "failed: \(message)"
        case .outOfFuel: return "out of fuel"
        }
    }
}

/// The observable state of an instance after a call.
struct Snapshot: Equatable {
    let memory: [UInt8]
    let g: Value
    let h: Value
    /// The table, each function numbered by where it first appears, since function addresses
    /// differ between stores. -1 is null.
    let table: [Int]

    init(_ instance: Instance) {
        memory = instance.exports[memory: "mem"]!.data
        g = instance.exports[global: "g"]!.value
        h = instance.exports[global: "h"]!.value
        let tab = instance.exports[table: "tab"]!
        var numbers: [Reference: Int] = [:]
        table = (0..<8).map { index in
            let element = tab[index]
            if case .function(nil) = element { return -1 }
            if let number = numbers[element] { return number }
            numbers[element] = numbers.count
            return numbers.count - 1
        }
    }
}

/// The per-call fuel budget. Both sides give every call exactly this much.
let budget: UInt64 = 200_000
/// The fuel a plain call made by the `reenter` host function gets.
let reenterBudget: UInt64 = 3_000

/// Host state shared by the imports of one store.
final class Host {
    let store: Store
    /// Ticks the guest and the harness made. With `racing`, another thread ticks too.
    var epoch: UInt64 = 0
    /// The absolute deadline the harness last set.
    var deadline: UInt64 = .max
    let racing: Bool

    init(store: Store, racing: Bool) {
        self.store = store
        self.racing = racing
    }

    func setDeadline(ticks: UInt64) {
        let (sum, overflow) = epoch.addingReportingOverflow(ticks)
        deadline = overflow ? .max : sum
        store.setEpochDeadline(ticksBeyondCurrent: racing ? max(ticks, 1) : ticks)
    }

    func tick() {
        epoch += 1
        store.engine.epochTicker.increment()
    }

    /// Runs `body` with a fixed fuel budget and no deadline, then puts both back, so that a
    /// host function behaves the same inside a plain call and inside a resumable one.
    func isolated<T>(fuel: UInt64, _ body: () throws -> T) rethrows -> T {
        let savedFuel = store.fuel
        let savedDeadline = deadline
        store.fuel = Fuel(remaining: fuel)
        store.setEpochDeadline(ticksBeyondCurrent: .max)
        deadline = .max
        defer {
            store.fuel = savedFuel
            if savedDeadline == .max {
                store.setEpochDeadline(ticksBeyondCurrent: .max)
            } else if racing {
                store.setEpochDeadline(ticksBeyondCurrent: 1)
            } else {
                store.setEpochDeadline(ticksBeyondCurrent: savedDeadline > epoch ? savedDeadline - epoch : 0)
            }
            deadline = savedDeadline
        }
        return try body()
    }

    func imports(for instance: InstanceBox) -> Imports {
        var imports = Imports()
        imports.define(
            module: "env", name: "tick",
            Function(store: store, parameters: [], results: []) { [unowned self] _, _ in
                self.tick()
                return []
            })
        imports.define(
            module: "env", name: "reenter",
            Function(store: store, parameters: [.i32], results: [.i32]) { [unowned self] _, args in
                let f0 = instance.instance!.exports[function: "f0"]!
                guard instance.takeNestedCall() else { return [.i32(UInt32(bitPattern: -3))] }
                return self.isolated(fuel: reenterBudget) {
                    do {
                        return try f0([.i32(args[0].i32 &- 1)])
                    } catch {
                        return [.i32(UInt32(bitPattern: -1))]
                    }
                }
            })
        imports.define(
            module: "env", name: "nested",
            Function(store: store, parameters: [.i32], results: [.i32]) { [unowned self] _, args in
                let f0 = instance.instance!.exports[function: "f0"]!
                guard instance.takeNestedCall() else { return [.i32(UInt32(bitPattern: -3))] }
                return self.isolated(fuel: 41) {
                    do {
                        let call = try ResumableCall(function: f0, arguments: [.i32(args[0].i32 &- 1)])
                        for _ in 0..<500 {
                            switch try call.resume() {
                            case .returned(let results):
                                return results
                            case .suspended:
                                self.store.fuel = Fuel(remaining: 41)
                            }
                        }
                        try call.resume(throwing: Cancelled())
                    } catch is Cancelled {
                        return [.i32(UInt32(bitPattern: -2))]
                    } catch {
                        return [.i32(UInt32(bitPattern: -1))]
                    }
                }
            })
        imports.define(
            module: "env", name: "fail",
            Function(store: store, parameters: [.i32], results: []) { _, args in
                if args[0].i32 & 3 == 0 { throw HostFailure(value: args[0].i32) }
                return []
            })
        return imports
    }
}

final class StackBox {
    var stack: ExecutionStack?
}

final class InstanceBox {
    var instance: Instance?
    /// How many more nested calls host functions may make during the current export call.
    /// Their fuel is not charged to the caller, so without a bound a loop of them never ends.
    var nestedCallsLeft = 0
    static let nestedCallBudget = 32

    func startExportCall() { nestedCallsLeft = Self.nestedCallBudget }

    /// Takes one nested call from the budget, or says there is none left.
    func takeNestedCall() -> Bool {
        guard nestedCallsLeft > 0 else { return false }
        nestedCallsLeft -= 1
        return true
    }
}

let features: WasmFeatureSet = [.referenceTypes, .exceptionHandling, .tailCall]

func makeEngine(_ rng: inout ByteRng, epochInterruption: Bool) -> Engine {
    let threadingModel: EngineConfiguration.ThreadingModel = rng.chance(50) ? .direct : .token
    let compilationMode: EngineConfiguration.CompilationMode = rng.chance(50) ? .eager : .lazy
    if ResumableOracle.trace {
        print("engine \(threadingModel) \(compilationMode) epochInterruption \(epochInterruption)")
    }
    return Engine(
        configuration: EngineConfiguration(
            threadingModel: threadingModel, compilationMode: compilationMode, features: features,
            fuelMetering: true, epochInterruption: epochInterruption))
}

/// The boxes made during one ``ResumableOracle/run(bytes:startRacer:)``. Each host function
/// holds its box and each box its instance, so the store would never be freed if the boxes
/// were not emptied at the end.
nonisolated(unsafe) var liveBoxes: [InstanceBox] = []

func instantiate(_ module: Module, host: Host) throws -> (Instance, InstanceBox) {
    let box = InstanceBox()
    liveBoxes.append(box)
    let instance = try module.instantiate(store: host.store, imports: host.imports(for: box))
    box.instance = instance
    return (instance, box)
}

/// One call of the reference sequence.
struct ReferenceStep {
    let outcome: Outcome
    let consumed: UInt64
    let snapshot: Snapshot
}

public enum ResumableOracle {
    /// For triage: run the subject without slicing, deadlines or cancellation.
    public static var unsliced = false
    public static var noDeadlines = false
    public static var bigSlices = false
    public static var trace = false

    /// Runs one fuzzer input. Throws a ``Finding`` when the two sides disagree or an invariant
    /// breaks; returns normally otherwise, including for inputs that generate nothing useful.
    ///
    /// - Parameter startRacer: Starts ticking the subject's epoch from another thread, and
    ///   returns how to stop it. Not reproducible, so only for the standalone driver.
    public static func run(bytes: [UInt8], startRacer: ((EpochTicker) -> () -> Void)? = nil) throws {
        let racing = startRacer != nil
        defer {
            for box in liveBoxes { box.instance = nil }
            liveBoxes = []
        }
        var generator = ProgramGenerator(rng: ByteRng(bytes))
        let wat = generator.generate()
        var rng = generator.remainingRng
        let module: Module
        do {
            module = try parseWasm(bytes: try wat2wasm(wat, features: features), features: features)
        } catch {
            throw Finding(description: "generator produced an invalid module: \(error)\n\(wat)")
        }
        let exports = generator.exportedFunctions
        let arguments = exports.map { _ in UInt32(1 + rng.below(4)) }
        let instanceCount = rng.chance(30) ? 2 : 1

        // Reference: plain calls, one instance after the other.
        let referenceStore = Store(engine: makeEngine(&rng, epochInterruption: rng.chance(50)))
        let referenceHost = Host(store: referenceStore, racing: false)
        var reference: [[ReferenceStep]] = []
        for _ in 0..<instanceCount {
            let (instance, box) = try instantiate(module, host: referenceHost)
            var steps: [ReferenceStep] = []
            for (name, argument) in zip(exports, arguments) {
                referenceStore.fuel = Fuel(remaining: budget)
                box.startExportCall()
                let outcome: Outcome
                do {
                    outcome = .returned(try instance.exports[function: name]!([.i32(argument)]))
                } catch {
                    outcome = Outcome(error: error)
                }
                if ResumableOracle.trace {
                    print("reference \(name)(\(argument)) \(outcome) consumed \(budget - referenceStore.fuel!.remaining)")
                }
                steps.append(
                    ReferenceStep(
                        outcome: outcome, consumed: budget - referenceStore.fuel!.remaining,
                        snapshot: Snapshot(instance)))
                // A plain call charges a bulk operation after doing it, a resumable one
                // suspends before it, so their states differ once fuel runs out.
                if outcome == .outOfFuel { break }
            }
            reference.append(steps)
        }

        // Subject: resumable calls, sliced, interleaved across instances.
        let store = Store(engine: makeEngine(&rng, epochInterruption: true))
        let host = Host(store: store, racing: racing)
        let stopRacer = startRacer?(store.engine.epochTicker)
        defer { stopRacer?() }
        var subjects: [Subject] = []
        for index in 0..<instanceCount {
            let (instance, box) = try instantiate(module, host: host)
            subjects.append(
                Subject(index: index, instance: instance, box: box, exports: exports, arguments: arguments, expected: reference[index]))
        }
        var context = Context(rng: rng, host: host, wat: wat)
        var steps = 0
        while let active = subjects.indices.filter({ !subjects[$0].isDone }).randomElement(using: &context.rng) {
            steps += 1
            if steps > 2_000_000 {
                throw context.finding("no progress after \(steps) resumes")
            }
            try subjects[active].step(&context)
        }
    }
}

extension ByteRng: RandomNumberGenerator {
    public mutating func next() -> UInt64 {
        var value: UInt64 = 0
        for _ in 0..<8 { value = value << 8 | UInt64(byte()) }
        return value
    }
}

struct Context {
    var rng: ByteRng
    let host: Host
    let wat: String
    var store: Store { host.store }

    func finding(_ message: String) -> Finding {
        Finding(description: "\(message)\n--- module ---\n\(wat)")
    }
}

/// The calls of one instance, run in order, one resume at a time.
struct Subject {
    let index: Int
    let instance: Instance
    let box: InstanceBox
    let exports: [String]
    let arguments: [UInt32]
    let expected: [ReferenceStep]

    var next = 0
    var call: ResumableCall?
    let stack = StackBox()
    /// The fuel this call has not been given yet.
    var pool: UInt64 = 0
    /// What the store held for this call when another call took over.
    var left: UInt64 = 0
    var resumes = 0
    /// Whether this call last stopped for fuel, so that the next resume makes progress even
    /// with a deadline of zero.
    var lastWasFuel = true
    /// Set once a call was cancelled: the instance's state no longer matches the reference,
    /// so the rest only has to run without crashing.
    var diverged = false

    init(index: Int, instance: Instance, box: InstanceBox, exports: [String], arguments: [UInt32], expected: [ReferenceStep]) {
        self.index = index
        self.instance = instance
        self.box = box
        self.exports = exports
        self.arguments = arguments
        self.expected = expected
    }

    var isDone: Bool { next >= (diverged ? exports.count : expected.count) && call == nil }

    mutating func step(_ context: inout Context) throws {
        let store = context.store
        if call == nil {
            let function = instance.exports[function: exports[next]]!
            let argument: [Value] = [.i32(arguments[next])]
            box.startExportCall()
            if context.rng.chance(50), let reused = stack.stack.take() {
                call = try ResumableCall(function: function, arguments: argument, on: reused)
            } else {
                call = try ResumableCall(function: function, arguments: argument)
            }
            let drawn = UInt64(context.rng.below(200))
            let first = ResumableOracle.unsliced || ResumableOracle.bigSlices ? budget : drawn
            pool = budget - first
            left = first
            resumes = 0
            lastWasFuel = true
        }
        let call = self.call!
        store.fuel = Fuel(remaining: left)
        if !context.host.racing {
            let forceStop = lastWasFuel && context.rng.chance(20)
            let soon = !forceStop && context.rng.chance(10)
            let ticks = soon ? UInt64(context.rng.below(3)) + 1 : 0
            if !ResumableOracle.unsliced && !ResumableOracle.noDeadlines {
                if forceStop {
                    context.host.setDeadline(ticks: 0)
                } else if soon {
                    context.host.setDeadline(ticks: ticks)
                }
            }
        }
        resumes += 1
        // Only the resume itself may fail with a guest error: a finding thrown by the checks
        // below must reach the caller as it is.
        let status: ResumableCall.Status
        do {
            status = try call.resume()
        } catch let error as ResumableCallError {
            throw context.finding("instance \(index) \(exports[next]): \(error)")
        } catch {
            try finish(Outcome(error: error), &context)
            return
        }
        switch status {
        case .returned(let values):
            try finish(.returned(values), &context)
        case .suspended(let suspension):
            try suspended(suspension, &context)
            if self.call == nil { return }
            if call.isFinished {
                try finish(.failed("cancelled"), &context)
                return
            }
            left = store.fuel!.remaining
        }
    }

    mutating func suspended(_ suspension: Suspension, _ context: inout Context) throws {
        let store = context.store
        if ResumableOracle.trace {
            print("instance \(index) \(exports[next]) suspended \(suspension.reason) left \(store.fuel!.remaining) pool \(pool)")
        }
        let call = self.call!
        if call.suspension?.reason != suspension.reason {
            throw context.finding("suspension reported \(String(describing: call.suspension)), resume returned \(suspension)")
        }
        if !diverged, context.rng.chance(2), !ResumableOracle.unsliced {
            do {
                try call.resume(throwing: Cancelled())
            } catch is Cancelled {
                diverged = true
                return
            }
        }
        switch suspension.reason {
        case .outOfFuel(let required):
            lastWasFuel = true
            let left = store.fuel!.remaining
            if left >= required {
                throw context.finding("suspended for \(required) fuel with \(left) left")
            }
            if pool + left < required {
                // Give the rest of the budget: the reference ran out here too.
                store.fuel = Fuel(remaining: left + pool)
                pool = 0
                let retried: ResumableCall.Status
                do {
                    retried = try call.resume()
                } catch {
                    throw context.finding("retrying a charge of \(required) with \(store.fuel!.remaining) threw \(error)")
                }
                guard case .suspended(let again) = retried, again.reason == .outOfFuel(required: required) else {
                    throw context.finding("retrying a charge of \(required) with \(store.fuel!.remaining) did not suspend again")
                }
                do { try call.resume(throwing: Cancelled()) } catch is Cancelled {}
                try finish(.outOfFuel, &context)
                return
            }
            let extra = min(pool, required - left + UInt64(context.rng.below(64)))
            pool -= extra
            store.fuel = Fuel(remaining: left + extra)
        case .epochDeadlineReached:
            lastWasFuel = false
            if !context.host.racing && context.host.epoch < context.host.deadline {
                throw context.finding("suspended at epoch \(context.host.epoch) before the deadline \(context.host.deadline)")
            }
            context.host.setDeadline(ticks: context.rng.chance(50) ? .max : UInt64(context.rng.below(3)) + 1)
        case .hostCall(let tag, _):
            // The generated programs' host functions never ask to suspend.
            throw context.finding("suspended at a host call with tag \(tag)")
        }
    }

    mutating func finish(_ outcome: Outcome, _ context: inout Context) throws {
        let store = context.store
        let call = self.call!
        if !call.isFinished {
            throw context.finding("call ended with \(outcome) but is not finished")
        }
        self.call = nil
        stack.stack = call.takeStack()
        defer { next += 1 }
        if diverged || outcome == .failed("cancelled") {
            diverged = true
            return
        }
        guard next < expected.count else { return }
        let expected = self.expected[next]
        let name = "instance \(index) \(exports[next])(\(arguments[next]))"
        if outcome == .outOfFuel, case .failed(let message) = expected.outcome, message.contains("out of bounds") {
            // A resumable call suspends for a bulk operation's fuel before the operation checks
            // its bounds, so at the end of a budget it runs out where a plain call traps.
            return
        }
        if outcome != expected.outcome {
            throw context.finding("\(name): reference \(expected.outcome), resumable \(outcome)")
        }
        if outcome == .outOfFuel { return }
        let consumed = budget - pool - store.fuel!.remaining
        if consumed != expected.consumed {
            throw context.finding("\(name): reference consumed \(expected.consumed) fuel, resumable \(consumed)")
        }
        let snapshot = Snapshot(instance)
        if snapshot != expected.snapshot {
            let firstDifference = zip(snapshot.memory, expected.snapshot.memory).enumerated().first { $0.element.0 != $0.element.1 }
            throw context.finding(
                "\(name): state differs; g \(expected.snapshot.g) vs \(snapshot.g), h \(expected.snapshot.h) vs \(snapshot.h), table \(expected.snapshot.table) vs \(snapshot.table), memory size \(expected.snapshot.memory.count) vs \(snapshot.memory.count), first byte difference \(String(describing: firstDifference))"
            )
        }
    }
}
