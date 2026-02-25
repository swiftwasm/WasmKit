import WASI
import WasmKit

public typealias WASIBridgeToHost = WASI.WASIBridgeToHost
public typealias MemoryFileSystem = WASI.MemoryFileSystem

extension WASIBridgeToHost {

    /// Register the WASI implementation to the given `imports`, optionally
    /// including `wasi-threads` support.
    ///
    /// - Parameters:
    ///   - imports: The imports scope to register the WASI implementation.
    ///   - store: The store to create the host functions.
    ///   - threadManager: If non-nil, registers the `"wasi"."thread-spawn"` import.
    public func link(to imports: inout Imports, store: Store, threadManager: WASIThreadManager? = nil) {
        for (moduleName, module) in wasiHostModules {
            for (name, function) in module.functions {
                imports.define(
                    module: moduleName,
                    name: name,
                    Function(store: store, type: function.type, body: makeHostFunction(function))
                )
            }
        }

        if let threadManager {
            imports.define(
                module: "wasi",
                name: "thread-spawn",
                Function(
                    store: store,
                    type: FunctionType(parameters: [.i32], results: [.i32])
                ) { caller, values -> [Value] in
                    let startArg = values[0].i32
                    let result = threadManager.spawnThread(store: caller.store, startArg: startArg)
                    return [.i32(UInt32(bitPattern: result))]
                }
            )
        }
    }

    private func makeHostFunction(_ function: WASIHostFunction) -> ((Caller, [Value]) throws -> [Value]) {
        { caller, values -> [Value] in
            guard case .memory(let memory) = caller.instance?.export("memory") else {
                throw WASIError(description: "Missing required \"memory\" export")
            }
            return try function.implementation(memory, values)
        }
    }

    /// Start a WASI application as a `command` instance.
    ///
    /// See <https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md>
    /// for more information about the WASI Preview 1 Application ABI.
    ///
    /// - Parameter instance: The WASI application instance.
    /// - Returns: The exit code returned by the WASI application.
    public func start(_ instance: Instance) throws -> UInt32 {
        do {
            guard let start = instance.exports[function: "_start"] else {
                throw WASIError(description: "Missing required \"_start\" function")
            }
            _ = try start()
        } catch let code as WASIExitCode {
            return code.code
        }
        return 0
    }

    /// Start a WASI application as a `reactor` instance.
    ///
    /// See <https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md>
    /// for more information about the WASI Preview 1 Application ABI.
    ///
    /// - Parameter instance: The WASI application instance.
    public func initialize(_ instance: Instance) throws {
        if let initialize = instance.exports[function: "_initialize"] {
            // Call the optional `_initialize` function.
            _ = try initialize()
        }
    }

}
