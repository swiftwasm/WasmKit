import Dispatch
import Foundation
import Synchronization
import Testing
import WAT

@testable import WasmKit

/// Control-flow, error-propagation, and ownership checks for the grouped-dispatch controller.
@Suite(.serialized)
struct ExecutionInterruptionTests {
    /// Stops cycles formed by ordinary branches, tables, tail calls, and caught guest exceptions.
    ///
    /// - Parameter shape: The control-flow form that must reach an interruption checkpoint.
    /// - Throws: Fixture construction, export lookup, or controller configuration failures.
    @Test(arguments: ["branch", "conditional", "table", "tail", "exception"])
    func stopsEveryCycle(_ shape: String) throws {
        let bodies = [
            "branch": "(loop $again (br $again))",
            "conditional": "(loop $again (br_if $again (i32.const 1)))",
            "table": "(loop $again (br_table $again (i32.const 0)))",
            "tail": "(return_call $spin)",
            "exception": "(loop $again (try_table (catch_all $again) (throw $failure)))",
        ]
        let body = try #require(bodies[shape])
        do {
            try watchdog {
                let control = try ExecutionControl(recordsCheckpoints: true)
                let store = try controlledStore(control)
                let module = try parseWasm(
                    bytes: wat2wasm(
                        """
                        (module (tag $failure)
                            (func $spin (export "spin") \(body))
                            (func (export "answer") (result i32) i32.const 42))
                        """), features: .all)
                let instance = try module.instantiate(store: store)
                let spin = try #require(instance.exports[function: "spin"])
                try stopAfterProgress(control) {
                    #expect(throws: ExecutionTermination.interrupted) { try spin() }
                }
                let answer = try #require(instance.exports[function: "answer"])
                #expect(throws: ExecutionTermination.interrupted) { try answer() }
            }
        }
    }

    /// Preserves finite straight-line results while inserting checkpoints in long functions.
    ///
    /// - Throws: Fixture construction, configuration, or invocation failures.
    @Test
    func straightLineCodeHasCheckpoints() throws {
        let work = Array(repeating: "global.get 0 i32.const 1 i32.add global.set 0", count: 5000).joined(separator: "\n")
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module (global (mut i32) (i32.const 0))
                    (func (export "work") (result i32) \(work) global.get 0))
                """))
        do {
            let control = try ExecutionControl(pollingInterval: 256, recordsCheckpoints: true)
            let instance = try module.instantiate(store: controlledStore(control))
            let function = try #require(instance.exports[function: "work"])
            #expect(try function() == [.i32(5000)])
            #expect(control.observedCheckpointCount > 20)
        }
    }

    /// Prevents a native import from swallowing stop and executing a later guest memory store.
    ///
    /// - Throws: Fixture, configuration, or export failures.
    @Test
    func nativeReentryCannotResumeStoppedGuest() throws {
        do {
            let control = try ExecutionControl()
            let store = try controlledStore(control)
            var imports = Imports()
            imports.define(
                module: "host", name: "catch",
                Function(store: store, parameters: []) { caller, _ in
                    control.requestInterruption()
                    guard let answer = caller.instance?.exports[function: "answer"] else { throw FixtureError.export }
                    do { _ = try answer() } catch is ExecutionTermination { return [] }
                    throw FixtureError.termination
                })
            let instance = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (import "host" "catch" (func $catch))
                        (memory (export "memory") 1)
                        (func (export "answer") (result i32) i32.const 42)
                        (func (export "outer")
                            call $catch
                            i32.const 0 i32.const 1 i32.store))
                    """)
            ).instantiate(store: store, imports: imports)
            let outer = try #require(instance.exports[function: "outer"])
            #expect(throws: ExecutionTermination.interrupted) { try outer() }
            let memory = try #require(instance.exports[memory: "memory"])
            let firstByte = memory.withUnsafeBufferPointer(offset: 0, count: 1) { $0[0] }
            #expect(firstByte == 0)
        }
    }

    /// Preserves normal guest catches and rejects a stop raised inside their dynamic scope.
    ///
    /// - Throws: Fixture, configuration, or export failures.
    @Test
    func guestCatchCannotHideStop() throws {
        do {
            let control = try ExecutionControl()
            let store = try controlledStore(control)
            var imports = Imports()
            imports.define(
                module: "host", name: "stop",
                Function(store: store, parameters: []) { _, _ in
                    control.requestInterruption(reason: .deadlineExceeded)
                    return []
                })
            let instance = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module (import "host" "stop" (func $stop)) (tag $failure)
                        (func (export "caught") (result i32)
                            (block $caught (try_table (catch_all $caught) (throw $failure))
                                (return (i32.const 0))) i32.const 42)
                        (func (export "stopped") (result i32)
                            (block $caught (try_table (catch_all $caught) (call $stop))) i32.const 99))
                    """)
            ).instantiate(store: store, imports: imports)
            let caught = try #require(instance.exports[function: "caught"])
            #expect(try caught() == [.i32(42)])
            let stopped = try #require(instance.exports[function: "stopped"])
            #expect(throws: ExecutionTermination.deadlineExceeded) { try stopped() }
        }
    }

    /// Checks startup interruption before instantiation returns an instance to the host.
    ///
    /// - Throws: Fixture or configuration failures.
    @Test
    func moduleStartIsCovered() throws {
        do {
            try watchdog {
                let control = try ExecutionControl(recordsCheckpoints: true)
                let store = try controlledStore(control)
                let module = try parseWasm(bytes: wat2wasm("(module (func $start (loop $again (br $again))) (start $start))"))
                try stopAfterProgress(control) {
                    #expect(throws: ExecutionTermination.interrupted) { try module.instantiate(store: store) }
                }
            }
        }
    }

    /// Verifies disabled diagnostics, idle waiting, first-reason ownership, and unique store use.
    ///
    /// - Throws: Fixture, configuration, or normal invocation failures.
    @Test
    func controllerLifetime() throws {
        #expect(throws: ExecutionControlError.invalidPollingInterval) { try ExecutionControl(pollingInterval: 0) }
        let control = try ExecutionControl()
        let direct = Engine(configuration: EngineConfiguration(threadingModel: .direct))
        #expect(throws: ExecutionControlError.unsupportedThreadingModel) { try Store(engine: direct, executionControl: control) }
        let store = try controlledStore(control)
        #expect(throws: ExecutionControlError.reusedControl) { try controlledStore(control) }
        let instance = try parseWasm(bytes: wat2wasm("(module (func (export \"answer\") (result i32) i32.const 42))")).instantiate(store: store)
        let answer = try #require(instance.exports[function: "answer"])
        #expect(try answer() == [.i32(42)])
        Thread.sleep(forTimeInterval: 0.02)
        #expect(try answer() == [.i32(42)])
        #expect(control.observedCheckpointCount == 0)
        control.requestInterruption(reason: .deadlineExceeded)
        control.requestInterruption()
        #expect(control.termination == .deadlineExceeded)
        #expect(throws: ExecutionTermination.deadlineExceeded) { try answer() }
    }

    /// Constructs the serial token store with all parser features needed by the control-flow cases.
    ///
    /// - Parameter control: The unused signal bound to this store.
    /// - Returns: The store used for one fixture and its exported invocations.
    /// - Throws: Unsupported configuration or reused controller failures.
    private func controlledStore(_ control: ExecutionControl) throws -> Store {
        try Store(
            engine: Engine(
                configuration: EngineConfiguration(
                    threadingModel: .token, compilationMode: .eager, features: .all
                )), executionControl: control)
    }

    /// Signals only after the active guest has executed at least eight checkpoints.
    ///
    /// - Parameters:
    ///   - control: The independently readable controller with diagnostic recording enabled.
    ///   - body: The operation expected to remain active until the signal arrives.
    /// - Throws: The fixture operation's own failure.
    private func stopAfterProgress(_ control: ExecutionControl, body: () throws -> Void) throws {
        let observed = Mutex(false)
        let completed = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            let deadline = ContinuousClock.now.advanced(by: .seconds(2))
            while control.observedCheckpointCount < 8, ContinuousClock.now < deadline {
                Thread.sleep(forTimeInterval: 0.0001)
            }
            observed.withLock { $0 = control.observedCheckpointCount >= 8 }
            control.requestInterruption()
            completed.signal()
        }
        try body()
        #expect(completed.wait(timeout: .now() + 3) == .success)
        #expect(observed.withLock { $0 })
    }

    /// Terminates only this isolated test process if interpreter control regresses completely.
    ///
    /// - Parameter body: The fixture expected to unwind before the watchdog expires.
    /// - Throws: The fixture operation's own failure.
    private func watchdog(_ body: () throws -> Void) rethrows {
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now() + 20)
        timer.setEventHandler {
            FileHandle.standardError.write(Data("Checkpoint test watchdog expired.\n".utf8))
            exit(124)
        }
        timer.resume()
        defer { timer.cancel() }
        try body()
    }
}

/// Fixture failures that indicate missing exports or an interruption swallowed by native code.
private enum FixtureError: Error {
    /// The fixture failed to export its known helper function.
    case export
    /// Native reentry unexpectedly completed after its controller was stopped.
    case termination
}
