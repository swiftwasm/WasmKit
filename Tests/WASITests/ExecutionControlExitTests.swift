import Testing
import WasmKit
import WasmKitWASI

@testable import WASI

/// Host completion checks through the actual WASI command-start conversion boundary.
@Suite
struct ExecutionControlExitTests {
    /// Keeps a native exit error from converting a requested interruption into successful startup.
    ///
    /// - Parameters:
    ///   - wrapped: Whether a WASM entrypoint calls the host import or directly reexports it.
    ///   - reason: The permanent store termination requested before the host throws its exit code.
    /// - Throws: Controller, fixture, or WASI provider setup failures.
    @Test(arguments: [false, true], [ExecutionTermination.interrupted, .deadlineExceeded])
    func interruptionWinsOverHostExit(wrapped: Bool, reason: ExecutionTermination) throws {
        let control = try ExecutionControl()
        let store = try Store(engine: Engine(configuration: EngineConfiguration(threadingModel: .token)), executionControl: control)
        let instance = try entrypoint(store: store, wrapped: wrapped) { _, _ in
            control.requestInterruption(reason: reason)
            throw WASIExitCode(code: 17)
        }
        let wasi = try WASIBridgeToHost()
        defer { try? wasi.close() }
        #expect(throws: reason) { try wasi.start(instance) }
        #expect(control.termination == reason)
    }

    /// Retains the ordinary WASI exit-code result when the controlled store remains live.
    ///
    /// - Parameter wrapped: Whether startup goes through a WASM caller before the host error.
    /// - Throws: Controller, fixture, provider, or normal command-start failures.
    @Test(arguments: [false, true])
    func liveHostExitKeepsItsExitCode(wrapped: Bool) throws {
        let control = try ExecutionControl()
        let store = try Store(engine: Engine(configuration: EngineConfiguration(threadingModel: .token)), executionControl: control)
        let instance = try entrypoint(store: store, wrapped: wrapped) { _, _ in
            throw WASIExitCode(code: 17)
        }
        let wasi = try WASIBridgeToHost()
        defer { try? wasi.close() }
        #expect(try wasi.start(instance) == 17)
        #expect(control.termination == nil)
    }

    /// Preserves the requested stop when a host returns values outside its declared signature.
    ///
    /// - Parameters:
    ///   - wrapped: Whether a WASM entrypoint calls the host import or directly reexports it.
    ///   - reason: The permanent store termination requested before the invalid host return.
    /// - Throws: Controller, fixture, or WASI provider setup failures.
    @Test(arguments: [false, true], [ExecutionTermination.interrupted, .deadlineExceeded])
    func interruptionWinsOverInvalidHostResults(wrapped: Bool, reason: ExecutionTermination) throws {
        let control = try ExecutionControl()
        let store = try Store(engine: Engine(configuration: EngineConfiguration(threadingModel: .token)), executionControl: control)
        let instance = try entrypoint(store: store, wrapped: wrapped) { _, _ in
            control.requestInterruption(reason: reason)
            return [.i32(42)]
        }
        let wasi = try WASIBridgeToHost()
        defer { try? wasi.close() }
        #expect(throws: reason) { try wasi.start(instance) }
        #expect(control.termination == reason)
    }

    /// Retains host result validation when the controlled store has no requested termination.
    ///
    /// - Parameter wrapped: Whether startup goes through a WASM caller before the host return.
    /// - Throws: Controller, fixture, or WASI provider setup failures.
    @Test(arguments: [false, true])
    func liveInvalidHostResultsStillTrap(wrapped: Bool) throws {
        let control = try ExecutionControl()
        let store = try Store(engine: Engine(configuration: EngineConfiguration(threadingModel: .token)), executionControl: control)
        let instance = try entrypoint(store: store, wrapped: wrapped) { _, _ in
            [.i32(42)]
        }
        let wasi = try WASIBridgeToHost()
        defer { try? wasi.close() }
        #expect {
            try wasi.start(instance)
        } throws: { error in
            guard let trap = error as? Trap else { return false }
            return trap.reason.description.hasPrefix("result types don't match")
        }
        #expect(control.termination == nil)
    }

    /// Preserves unrelated host errors with both controlled and ordinary stores.
    ///
    /// - Parameters:
    ///   - wrapped: Whether a WASM entrypoint calls the host import or directly reexports it.
    ///   - controlled: Whether the store has a live interruption controller.
    /// - Throws: Controller, fixture, or WASI provider setup failures.
    @Test(arguments: [false, true], [false, true])
    func unrelatedHostFailuresKeepTheirIdentity(wrapped: Bool, controlled: Bool) throws {
        let engine = Engine(configuration: EngineConfiguration(threadingModel: .token))
        let store: Store
        if controlled {
            store = try Store(engine: engine, executionControl: ExecutionControl())
        } else {
            store = Store(engine: engine)
        }
        let instance = try entrypoint(store: store, wrapped: wrapped) { _, _ in
            throw HostFailure.fixture
        }
        let wasi = try WASIBridgeToHost()
        defer { try? wasi.close() }
        #expect(throws: HostFailure.fixture) { try wasi.start(instance) }
    }

    /// Builds one host import and one WASM wrapper with the selected function exported as _start.
    ///
    /// The fixed binary avoids adding a text-parser dependency to the WASI test target. Both
    /// exported shapes use the same host function and zero-parameter, zero-result signature.
    ///
    /// - Parameters:
    ///   - store: The sole owner of the imported function and resulting instance.
    ///   - wrapped: Selects function one, which calls imported function zero, when true.
    ///   - body: The native implementation whose success or error leaves the interpreter.
    /// - Returns: The instantiated command fixture with a direct host or WASM _start export.
    /// - Throws: Invalid fixture bytes or import-instantiation failures.
    private func entrypoint(store: Store, wrapped: Bool, body: @escaping Function.Implementation) throws -> Instance {
        let bytes: [UInt8] = [
            0, 97, 115, 109, 1, 0, 0, 0,
            1, 4, 1, 0x60, 0, 0,
            2, 13, 1, 4, 104, 111, 115, 116, 4, 101, 120, 105, 116, 0, 0,
            3, 2, 1, 0,
            7, 10, 1, 6, 95, 115, 116, 97, 114, 116, 0, wrapped ? 1 : 0,
            10, 6, 1, 4, 0, 0x10, 0, 0x0b,
        ]
        var imports = Imports()
        imports.define(module: "host", name: "exit", Function(store: store, parameters: [], body: body))
        return try parseWasm(bytes: bytes).instantiate(store: store, imports: imports)
    }
}

/// A recognizable native error that must survive when no store interruption was requested.
private enum HostFailure: Error, Equatable {
    /// The ordinary failure thrown by both host-entry shapes in the fixture.
    case fixture
}
