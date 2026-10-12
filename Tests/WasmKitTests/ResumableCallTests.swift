import Testing
import WAT
import WasmParser

@testable import WasmKit

#if canImport(Foundation)
    import Foundation
#endif

@Suite
struct ResumableCallTests {
    private static func makeStore(
        threadingModel: EngineConfiguration.ThreadingModel, fuelMetering: Bool = true, epochInterruption: Bool = false
    ) -> Store {
        Store(
            engine: Engine(
                configuration: EngineConfiguration(
                    threadingModel: threadingModel, compilationMode: .eager,
                    features: [.referenceTypes, .exceptionHandling, .tailCall, .memory64],
                    fuelMetering: fuelMetering, epochInterruption: epochInterruption)))
    }

    private static func instantiate(_ wat: String, store: Store, imports: Imports = Imports()) throws -> Instance {
        let features: WasmFeatureSet = [.referenceTypes, .exceptionHandling, .tailCall, .memory64]
        return try parseWasm(bytes: wat2wasm(wat, features: features), features: features)
            .instantiate(store: store, imports: imports)
    }

    /// Resumes `call` until it returns, giving the store exactly the fuel each suspension asks
    /// for. Returns the results, the number of suspensions and the fuel paid in total.
    private static func runSliced(
        _ call: ResumableCall, store: Store, initialFuel: UInt64
    ) throws -> (results: [Value], suspensions: Int, paid: UInt64) {
        store.fuel = Fuel(remaining: initialFuel)
        var paid = initialFuel
        var suspensions = 0
        while true {
            switch try call.resume() {
            case .returned(let results):
                paid -= try #require(store.fuel).remaining
                return (results, suspensions, paid)
            case .suspended(let suspension):
                suspensions += 1
                guard case .outOfFuel(let required) = suspension.reason else {
                    Issue.record("unexpected suspension \(suspension.reason)")
                    return ([], suspensions, paid)
                }
                // The failed charge deducted nothing, so whatever was left still counts.
                let left = try #require(store.fuel).remaining
                #expect(left < required)
                store.fuel = Fuel(remaining: required)
                paid += required - left
            }
        }
    }

    /// The fuel a plain call of `name` with `arguments` consumes.
    private static func fuelOfPlainCall(
        _ wat: String, _ name: String = "f", arguments: [Value], threadingModel: EngineConfiguration.ThreadingModel
    ) throws -> (results: [Value], consumed: UInt64) {
        let store = makeStore(threadingModel: threadingModel)
        let instance = try instantiate(wat, store: store)
        store.fuel = Fuel(remaining: 1 << 40)
        let function = try #require(instance.exports[function: name])
        let results = try function(arguments)
        return (results, (1 << 40) - (try #require(store.fuel).remaining))
    }

    static let sumLoop = """
        (module
          (func (export "f") (param $n i32) (result i32) (local $i i32) (local $sum i32)
            (loop $l
              (local.set $sum (i32.add (local.get $sum) (call $double (local.get $i))))
              (local.set $i (i32.add (local.get $i) (i32.const 1)))
              (br_if $l (i32.lt_u (local.get $i) (local.get $n))))
            (local.get $sum))
          (func $double (param i32) (result i32)
            (i32.add (local.get 0) (local.get 0))))
        """

    @Test(arguments: testedThreadingModels)
    func slicedRunPaysWhatAnUnslicedRunPays(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let plain = try Self.fuelOfPlainCall(Self.sumLoop, arguments: [.i32(1000)], threadingModel: threadingModel)
        #expect(plain.results == [.i32(999 * 1000)])

        let store = Self.makeStore(threadingModel: threadingModel)
        let f = try #require(try Self.instantiate(Self.sumLoop, store: store).exports[function: "f"])
        let call = try ResumableCall(function: f, arguments: [.i32(1000)])
        let sliced = try Self.runSliced(call, store: store, initialFuel: 0)
        #expect(sliced.results == plain.results)
        #expect(sliced.paid == plain.consumed)
        // Every charge suspends once: the store never has more than the charge asks for.
        #expect(sliced.suspensions > 1000)
        #expect(call.isFinished)
        #expect(call.suspension == nil)
    }

    @Test(arguments: testedThreadingModels)
    func resumesAcrossCallsIndirectCallsAndTailCalls(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let wat = """
            (module
              (type $t (func (param i32 i32) (result i32)))
              (table funcref (elem $count))
              (func (export "f") (param $n i32) (result i32)
                (call_indirect (type $t) (local.get $n) (i32.const 0) (i32.const 0)))
              (func $count (param $n i32) (param $acc i32) (result i32)
                (if (i32.eqz (local.get $n)) (then (return (local.get $acc))))
                (return_call $count
                  (i32.sub (local.get $n) (i32.const 1))
                  (i32.add (local.get $acc) (call $id (local.get $n)))))
              (func $id (param i32) (result i32) (local.get 0)))
            """
        let plain = try Self.fuelOfPlainCall(wat, arguments: [.i32(300)], threadingModel: threadingModel)
        let store = Self.makeStore(threadingModel: threadingModel)
        let f = try #require(try Self.instantiate(wat, store: store).exports[function: "f"])
        let sliced = try Self.runSliced(try ResumableCall(function: f, arguments: [.i32(300)]), store: store, initialFuel: 3)
        #expect(sliced.results == [.i32(300 * 301 / 2)])
        #expect(sliced.paid == plain.consumed)
    }

    @Test(arguments: testedThreadingModels)
    func exceptionHandlersSurviveSuspension(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let wat = """
            (module
              (tag $e (param i32))
              (func (export "f") (param $n i32) (result i32)
                (block $caught (result i32)
                  (try_table (catch $e $caught)
                    (call $spinThenThrow (local.get $n)))
                  (i32.const -1)))
              (func $spinThenThrow (param $n i32) (local $i i32)
                (loop $l
                  (local.set $i (i32.add (local.get $i) (i32.const 1)))
                  (br_if $l (i32.lt_u (local.get $i) (local.get $n))))
                (throw $e (local.get $i))))
            """
        let store = Self.makeStore(threadingModel: threadingModel)
        let f = try #require(try Self.instantiate(wat, store: store).exports[function: "f"])
        let sliced = try Self.runSliced(try ResumableCall(function: f, arguments: [.i32(200)]), store: store, initialFuel: 0)
        #expect(sliced.results == [.i32(200)])
        #expect(sliced.suspensions > 200)
    }

    @Test(arguments: testedThreadingModels)
    func memoryGrownWhileSuspendedIsSeenOnResume(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let wat = """
            (module
              (memory (export "mem") 1)
              (func (export "grow") (drop (memory.grow (i32.const 1))))
              (func (export "f") (result i32)
                (i32.store (i32.const 0) (i32.const 7))
                (loop $l (br_if $l (i32.lt_u (memory.size) (i32.const 64))))
                (i32.store (i32.const 0x3f_0000) (i32.const 35))
                (i32.add (i32.load (i32.const 0)) (i32.load (i32.const 0x3f_0000)))))
            """
        let store = Self.makeStore(threadingModel: threadingModel)
        let instance = try Self.instantiate(wat, store: store)
        let f = try #require(instance.exports[function: "f"])
        let grow = try #require(instance.exports[function: "grow"])
        let call = try ResumableCall(function: f)
        store.fuel = Fuel(remaining: 10)
        var status = try call.resume()
        var grown = 0
        while case .suspended(let suspension) = status {
            guard case .outOfFuel(let required) = suspension.reason else { break }
            // Grow one page at a time, so that the memory moves under the suspended guest.
            store.fuel = nil
            if grown < 63 {
                try grow()
                grown += 1
            }
            store.fuel = Fuel(remaining: max(required, 10))
            status = try call.resume()
        }
        guard case .returned(let results) = status else { throw ResumableCallError.finished }
        #expect(results == [.i32(42)])
    }

    // MARK: Bulk operations

    static let fill = """
        (module
          (memory (export "mem") 1)
          (table $t 16 funcref)
          (elem declare func 0)
          (func (export "fill") (param $n i32)
            (memory.fill (i32.const 0) (i32.const 0xab) (local.get $n)))
          (func (export "tableFill") (param $n i32)
            (table.fill $t (i32.const 0) (ref.func 0) (local.get $n))))
        """

    private static func byte(of memory: WasmKit.Memory, at offset: UInt) -> UInt8 {
        memory.withUnsafeBufferPointer(offset: offset, count: 1) { $0[0] }
    }

    @Test(arguments: testedThreadingModels)
    func bulkOperationSuspendsBeforeItDoesAnything(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let plain = try Self.fuelOfPlainCall(Self.fill, "fill", arguments: [.i32(64 * 100)], threadingModel: threadingModel)
        let store = Self.makeStore(threadingModel: threadingModel)
        let instance = try Self.instantiate(Self.fill, store: store)
        let memory = try #require(instance.exports[memory: "mem"])
        let call = try ResumableCall(function: try #require(instance.exports[function: "fill"]), arguments: [.i32(64 * 100)])
        // Enough for the function's own region, not for the bytes.
        store.fuel = Fuel(remaining: plain.consumed - 100)
        guard case .suspended(let suspension) = try call.resume() else {
            Issue.record("expected a suspension")
            return
        }
        #expect(suspension.reason == .outOfFuel(required: 100))
        #expect(Self.byte(of: memory, at: 0) == 0)
        #expect(try #require(store.fuel).remaining == 0)
        store.fuel = Fuel(remaining: 100)
        guard case .returned = try call.resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(Self.byte(of: memory, at: 0) == 0xab)
        #expect(Self.byte(of: memory, at: 64 * 100 - 1) == 0xab)
        #expect(try #require(store.fuel).remaining == 0)
    }

    @Test(arguments: testedThreadingModels)
    func tableOperationSuspendsAndRetries(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let plain = try Self.fuelOfPlainCall(Self.fill, "tableFill", arguments: [.i32(16)], threadingModel: threadingModel)
        let store = Self.makeStore(threadingModel: threadingModel)
        let instance = try Self.instantiate(Self.fill, store: store)
        let call = try ResumableCall(function: try #require(instance.exports[function: "tableFill"]), arguments: [.i32(16)])
        let sliced = try Self.runSliced(call, store: store, initialFuel: 0)
        #expect(sliced.paid == plain.consumed)
    }

    /// Every bulk operation, each with its own immediate layout, so each resumes from its own
    /// head slot.
    static let bulk: String = {
        let segment = String(repeating: "\\2a", count: 4096)
        let elements = String(repeating: " $f", count: 64)
        return """
            (module
              (memory 1 100)
              (table $t 64 funcref)
              (table $u 64 funcref)
              (data $d "\(segment)")
              (elem $e func\(elements))
              (elem declare func $f)
              (func $f)
              (func (export "memory.copy") (result i32)
                (memory.fill (i32.const 0) (i32.const 7) (i32.const 4096))
                (memory.copy (i32.const 8192) (i32.const 0) (i32.const 4096))
                (i32.load8_u (i32.const 12287)))
              (func (export "memory.init") (result i32)
                (memory.init $d (i32.const 100) (i32.const 0) (i32.const 4096))
                (i32.load8_u (i32.const 4195)))
              (func (export "memory.grow") (result i32)
                (drop (memory.grow (i32.const 2)))
                (memory.size))
              (func (export "table.copy") (result i32)
                (table.fill $t (i32.const 0) (ref.func $f) (i32.const 64))
                (table.copy $u $t (i32.const 0) (i32.const 0) (i32.const 64))
                (ref.is_null (table.get $u (i32.const 63))))
              (func (export "table.init") (result i32)
                (table.init $u $e (i32.const 0) (i32.const 0) (i32.const 64))
                (ref.is_null (table.get $u (i32.const 63))))
              (func (export "table.grow") (result i32)
                (drop (table.grow $t (ref.null func) (i32.const 64)))
                (table.size $t)))
            """
    }()

    @Test(arguments: testedThreadingModels, ["memory.copy", "memory.init", "memory.grow", "table.copy", "table.init", "table.grow"])
    func everyBulkOperationResumesFromItsHeadSlot(threadingModel: EngineConfiguration.ThreadingModel, name: String) throws {
        let plain = try Self.fuelOfPlainCall(Self.bulk, name, arguments: [], threadingModel: threadingModel)
        let store = Self.makeStore(threadingModel: threadingModel)
        let function = try #require(try Self.instantiate(Self.bulk, store: store).exports[function: name])
        let sliced = try Self.runSliced(try ResumableCall(function: function), store: store, initialFuel: 0)
        #expect(sliced.results == plain.results)
        #expect(sliced.paid == plain.consumed)
        // One suspension for the function's region, at least one more for the bulk operation.
        #expect(sliced.suspensions >= 2)
    }

    @Test(arguments: testedThreadingModels)
    func outOfBoundsBulkOperationTrapsOnceResumed(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let instance = try Self.instantiate(Self.fill, store: store)
        let call = try ResumableCall(function: try #require(instance.exports[function: "fill"]), arguments: [.i32(65536 + 64)])
        store.fuel = Fuel(remaining: 100)
        guard case .suspended(let suspension) = try call.resume(),
            case .outOfFuel(let required) = suspension.reason
        else {
            Issue.record("expected a suspension")
            return
        }
        store.fuel = Fuel(remaining: required)
        #expect(throws: Trap.self) { try call.resume() }
        #expect(call.isFinished)
    }

    static let wide = """
        (module
          (memory i64 1)
          (table $t i64 1 funcref)
          (func (export "memory.fill") (memory.fill (i64.const 0) (i32.const 0) (i64.const -1)))
          (func (export "table.fill") (table.fill $t (i64.const 0) (ref.null func) (i64.const -1)))
          (func (export "table.copy") (table.copy $t $t (i64.const 0) (i64.const 0) (i64.const -1))))
        """

    /// An offset or count no `Int` can hold is out of bounds too: it suspends first.
    @Test(arguments: testedThreadingModels, ["memory.fill", "table.fill", "table.copy"])
    func unrepresentableBulkOperationTrapsOnceResumed(threadingModel: EngineConfiguration.ThreadingModel, name: String) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let instance = try Self.instantiate(Self.wide, store: store)
        let call = try ResumableCall(function: try #require(instance.exports[function: name]))
        store.fuel = Fuel(remaining: 100)
        guard case .suspended(let suspension) = try call.resume(),
            case .outOfFuel(let required) = suspension.reason
        else {
            Issue.record("expected a suspension")
            return
        }
        store.fuel = Fuel(remaining: required)
        #expect(throws: Trap.self) { try call.resume() }
        #expect(call.isFinished)
    }

    // MARK: Nesting

    static let spin = """
        (module
          (func (export "spin") (param $n i32) (result i32) (local $i i32)
            (loop $l
              (local.set $i (i32.add (local.get $i) (i32.const 1)))
              (br_if $l (i32.lt_u (local.get $i) (local.get $n))))
            (local.get $i)))
        """

    /// A host function stands between the resumable call and a plain call it makes, so the plain
    /// call cannot be suspended: it traps, and the resumable call carries on.
    @Test(arguments: testedThreadingModels)
    func plainCallInsideHostFunctionTrapsInsteadOfSuspending(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        var nested = "not reached"
        var imports = Imports()
        imports.define(
            module: "env", name: "h",
            Function(store: store, parameters: [], results: []) { _, _ in
                do {
                    _ = try spin([.i32(100_000)])
                    nested = "returned"
                } catch let trap as Trap {
                    nested = "trapped: \(trap.reason)"
                }
                return []
            })
        let f = try #require(
            try Self.instantiate(
                #"(module (import "env" "h" (func $h)) (func (export "f") (result i32) (call $h) (i32.const 1)))"#,
                store: store, imports: imports
            ).exports[function: "f"])
        store.fuel = Fuel(remaining: 2_000)
        let status = try ResumableCall(function: f).resume()
        #expect(nested == "trapped: out of fuel")
        guard case .returned(let results) = status else {
            Issue.record("expected the call to return")
            return
        }
        #expect(results == [.i32(1)])
        #expect(store.isSuspendable == false)
    }

    /// A resumable call made by a host function has its own stack, so it can suspend back into
    /// the host function while the outer one keeps running.
    @Test(arguments: testedThreadingModels)
    func resumableCallInsideHostFunction(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        var innerSuspensions = 0
        var imports = Imports()
        imports.define(
            module: "env", name: "h",
            Function(store: store, parameters: [], results: [.i32]) { _, _ in
                let inner = try ResumableCall(function: spin, arguments: [.i32(500)])
                let saved = store.fuel
                store.fuel = Fuel(remaining: 50)
                defer { store.fuel = saved }
                while true {
                    switch try inner.resume() {
                    case .returned(let results): return results
                    case .suspended:
                        innerSuspensions += 1
                        store.fuel = Fuel(remaining: 50)
                    }
                }
            })
        let f = try #require(
            try Self.instantiate(
                #"(module (import "env" "h" (func $h (result i32))) (func (export "f") (result i32) (call $h)))"#,
                store: store, imports: imports
            ).exports[function: "f"])
        store.fuel = Fuel(remaining: 1_000)
        guard case .returned(let results) = try ResumableCall(function: f).resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(results == [.i32(500)])
        #expect(innerSuspensions > 0)
    }

    @Test(arguments: testedThreadingModels)
    func callsOnOneStoreInterleave(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        let calls = try (1...3).map { try ResumableCall(function: spin, arguments: [.i32(Int32(100 * $0).unsigned)]) }
        var results: [Int: [Value]] = [:]
        while results.count < calls.count {
            for (index, call) in calls.enumerated() where !call.isFinished {
                store.fuel = Fuel(remaining: 17)
                if case .returned(let values) = try call.resume() { results[index] = values }
            }
        }
        #expect(results == [0: [.i32(100)], 1: [.i32(200)], 2: [.i32(300)]])
    }

    // MARK: Epoch interruption

    private static func epochStore(threadingModel: EngineConfiguration.ThreadingModel) -> Store {
        makeStore(threadingModel: threadingModel, fuelMetering: false, epochInterruption: true)
    }

    @Test(arguments: testedThreadingModels)
    func epochDeadlineSuspendsUntilItIsMoved(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.epochStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        let call = try ResumableCall(function: spin, arguments: [.i32(1000)])
        store.setEpochDeadline(ticksBeyondCurrent: 2)
        guard case .returned(let unexpired) = try ResumableCall(function: spin, arguments: [.i32(10)]).resume() else {
            Issue.record("expected the call to return before the deadline")
            return
        }
        #expect(unexpired == [.i32(10)])

        store.engine.epochTicker.increment()
        store.engine.epochTicker.increment()
        for _ in 0..<2 {
            // The resumed call checks again where it stopped, so it stays put until the deadline moves.
            guard case .suspended(let suspension) = try call.resume() else {
                Issue.record("expected a suspension")
                return
            }
            #expect(suspension.reason == .epochDeadlineReached)
        }
        store.setEpochDeadline(ticksBeyondCurrent: 1)
        guard case .returned(let results) = try call.resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(results == [.i32(1000)])
    }

    /// A host function ticks the epoch on every iteration, so the call stops at every loop header
    /// and carries on from the iteration it stopped at.
    @Test(arguments: testedThreadingModels)
    func everyLoopHeaderIsACheckpoint(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.epochStore(threadingModel: threadingModel)
        var imports = Imports()
        imports.define(
            module: "env", name: "tick",
            Function(store: store, parameters: [], results: []) { _, _ in
                store.engine.epochTicker.increment()
                return []
            })
        let f = try #require(
            try Self.instantiate(
                """
                (module
                  (import "env" "tick" (func $tick))
                  (func (export "f") (param $n i32) (result i32) (local $i i32) (local $sum i32)
                    (loop $l
                      (call $tick)
                      (local.set $sum (i32.add (local.get $sum) (local.get $i)))
                      (local.set $i (i32.add (local.get $i) (i32.const 1)))
                      (br_if $l (i32.lt_u (local.get $i) (local.get $n))))
                    (local.get $sum)))
                """, store: store, imports: imports
            ).exports[function: "f"])
        let call = try ResumableCall(function: f, arguments: [.i32(100)])
        var suspensions = 0
        while true {
            store.setEpochDeadline(ticksBeyondCurrent: 1)
            switch try call.resume() {
            case .returned(let results):
                #expect(results == [.i32(4950)])
                #expect(suspensions == 99)
                return
            case .suspended(let suspension):
                #expect(suspension.reason == .epochDeadlineReached)
                suspensions += 1
            }
        }
    }

    @Test(arguments: testedThreadingModels)
    func plainCallTrapsAtEpochDeadline(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.epochStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        store.setEpochDeadline(ticksBeyondCurrent: 0)
        #expect {
            try spin([.i32(10)])
        } throws: { error in
            (error as? Trap)?.reason.description == "epoch deadline reached"
        }
        store.setEpochDeadline(ticksBeyondCurrent: 1)
        #expect(try spin([.i32(10)]) == [.i32(10)])
    }

    /// The epoch analogue of ``plainCallInsideHostFunctionTrapsInsteadOfSuspending(threadingModel:)``.
    @Test(arguments: testedThreadingModels)
    func plainCallInsideHostFunctionTrapsAtEpochDeadline(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.epochStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        var nested = "not reached"
        var imports = Imports()
        imports.define(
            module: "env", name: "h",
            Function(store: store, parameters: [], results: []) { _, _ in
                store.setEpochDeadline(ticksBeyondCurrent: 0)
                defer { store.setEpochDeadline(ticksBeyondCurrent: .max) }
                do {
                    _ = try spin([.i32(100)])
                    nested = "returned"
                } catch let trap as Trap {
                    nested = "trapped: \(trap.reason)"
                }
                return []
            })
        let f = try #require(
            try Self.instantiate(
                #"(module (import "env" "h" (func $h)) (func (export "f") (result i32) (call $h) (i32.const 1)))"#,
                store: store, imports: imports
            ).exports[function: "f"])
        let status = try ResumableCall(function: f).resume()
        #expect(nested == "trapped: epoch deadline reached")
        guard case .returned(let results) = status else {
            Issue.record("expected the call to return")
            return
        }
        #expect(results == [.i32(1)])
    }

    @Test(arguments: testedThreadingModels)
    func epochDeadlineIsIgnoredWithoutEpochInterruption(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel, fuelMetering: false)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        store.setEpochDeadline(ticksBeyondCurrent: 0)
        #expect(try spin([.i32(10)]) == [.i32(10)])
    }

    #if canImport(Foundation)
        @Test(arguments: testedThreadingModels)
        func anotherThreadInterruptsAnInfiniteLoop(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let store = Self.epochStore(threadingModel: threadingModel)
            let f = try #require(
                try Self.instantiate(#"(module (func (export "f") (loop $l (br $l))))"#, store: store).exports[function: "f"])
            let call = try ResumableCall(function: f)
            store.setEpochDeadline(ticksBeyondCurrent: 1)
            let ticker = store.engine.epochTicker
            let ticked = DispatchSemaphore(value: 0)
            // A thread of its own: on platforms where Swift concurrency runs on Dispatch's
            // global queues, a block queued there can wait behind the spinning guests.
            Thread.detachNewThread {
                Thread.sleep(forTimeInterval: 0.01)
                ticker.increment()
                ticked.signal()
            }
            guard case .suspended(let suspension) = try call.resume() else {
                Issue.record("expected a suspension")
                return
            }
            ticked.wait()
            #expect(suspension.reason == .epochDeadlineReached)
            #expect(throws: Trap.self) { try call.resume(throwing: Trap(.message(.init("cancelled")))) }
        }
    #endif

    // MARK: API

    @Test(arguments: testedThreadingModels)
    func misuseLeavesTheCallAsItWas(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        var call: ResumableCall?
        var reentered: ResumableCallError?
        var imports = Imports()
        imports.define(
            module: "env", name: "h",
            Function(store: store, parameters: [], results: []) { _, _ in
                do {
                    _ = try call!.resume()
                } catch let error as ResumableCallError {
                    reentered = error
                }
                return []
            })
        let f = try #require(
            try Self.instantiate(
                #"(module (import "env" "h" (func $h)) (func (export "f") (call $h)))"#,
                store: store, imports: imports
            ).exports[function: "f"])
        call = try ResumableCall(function: f)
        guard case .returned = try call!.resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(reentered?.description == ResumableCallError.alreadyRunning.description)
        #expect(throws: ResumableCallError.self) { try call!.resume() }
        #expect(throws: Trap.self) { try ResumableCall(function: f, arguments: [.i32(1)]) }
    }

    @Test(arguments: testedThreadingModels)
    func hostFunctionCallIsRunningWhileItRuns(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        var call: ResumableCall?
        var reentered: ResumableCallError?
        var finishedWhileRunning: Bool?
        let host = Function(store: store, parameters: [], results: []) { _, _ in
            finishedWhileRunning = call!.isFinished
            do {
                _ = try call!.resume()
            } catch let error as ResumableCallError {
                reentered = error
            }
            return []
        }
        call = try ResumableCall(function: host)
        _ = try call!.resume()
        #expect(finishedWhileRunning == false)
        #expect(reentered?.description == ResumableCallError.alreadyRunning.description)
        #expect(call!.isFinished)
    }

    @Test(arguments: testedThreadingModels)
    func cancellingThrowsWithTheGuestBacktrace(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        let call = try ResumableCall(function: spin, arguments: [.i32(1000)])
        store.fuel = Fuel(remaining: 10)
        guard case .suspended = try call.resume() else {
            Issue.record("expected a suspension")
            return
        }
        // A wasm exception has nowhere to go at a fuel check.
        let thrower = try #require(
            try Self.instantiate(#"(module (tag $e) (func (export "f") (throw $e)))"#, store: store).exports[function: "f"])
        var caught: WasmKitException?
        do { try thrower() } catch let exception as WasmKitException { caught = exception }
        let exception = try #require(caught)
        #expect(throws: ResumableCallError.self) { try call.resume(throwing: exception) }
        #expect(call.suspension != nil)

        do {
            try call.resume(throwing: Trap(.message(.init("cancelled"))))
        } catch let trap as Trap {
            #expect(trap.backtrace?.symbols.isEmpty == false)
        }
        #expect(call.isFinished)
    }

    private static func isNone(_ stack: consuming ExecutionStack?) -> Bool {
        switch consume stack {
        case .none: return true
        case .some: return false
        }
    }

    @Test(arguments: testedThreadingModels)
    func stackIsTakenBackOnceFinished(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel)
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        let first = try ResumableCall(function: spin, arguments: [.i32(100)], on: ExecutionStack(engine: store.engine))
        store.fuel = Fuel(remaining: 10)
        _ = try first.resume()
        let takenWhileSuspended = Self.isNone(first.takeStack())
        #expect(takenWhileSuspended)
        store.fuel = nil
        _ = try first.resume()
        guard let stack = first.takeStack() else {
            Issue.record("expected the stack back")
            return
        }
        let takenTwice = Self.isNone(first.takeStack())
        #expect(takenTwice)

        let second = try ResumableCall(function: spin, arguments: [.i32(7)], on: stack)
        guard case .returned(let results) = try second.resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(results == [.i32(7)])
    }

    @Test(arguments: testedThreadingModels)
    func hostFunctionAndUnmeteredEngineRunToCompletion(threadingModel: EngineConfiguration.ThreadingModel) throws {
        let store = Self.makeStore(threadingModel: threadingModel, fuelMetering: false)
        let host = Function(store: store, parameters: [.i32], results: [.i32]) { _, args in [args[0]] }
        guard case .returned(let hostResults) = try ResumableCall(function: host, arguments: [.i32(3)]).resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(hostResults == [.i32(3)])
        let spin = try #require(try Self.instantiate(Self.spin, store: store).exports[function: "spin"])
        store.fuel = Fuel(remaining: 0)
        guard case .returned(let results) = try ResumableCall(function: spin, arguments: [.i32(50)]).resume() else {
            Issue.record("expected the call to return")
            return
        }
        #expect(results == [.i32(50)])
    }
}
