import WASI
import WasmKit

public typealias WASIBridgeToHost = WASI.WASIBridgeToHost
public typealias MemoryFileSystem = WASI.MemoryFileSystem

/// A group of WASI functions that can be linked on its own.
///
/// Specialised for WasmKit's guest memory, which is what the engine hands to
/// host functions.
public typealias WASICapability = WASI.WASICapability<Memory>

extension WASIBridgeToHost {

    /// Register the WASI implementation to the given `imports`.
    ///
    /// - Parameters:
    ///   - imports: The imports scope to register the WASI implementation.
    ///   - store: The store to create the host functions.
    public func link(to imports: inout Imports, store: Store) {
        link(to: &imports, store: store, capabilities: WASICapability.all)
    }

    /// Register only the selected parts of the WASI implementation.
    ///
    /// Linking a subset keeps the unselected implementations unreferenced, so a
    /// linker running `--gc-sections` over code built with
    /// `-Xfrontend -function-sections` can drop them. On a host build this is
    /// only an import-surface question; on a constrained target it is the
    /// difference between paying for all of WASI and paying for what you use.
    ///
    /// - Parameters:
    ///   - capabilities: The groups to register.
    ///   - stubUnlinked: When true (the default), preview1 functions that no
    ///     linked capability provides are registered as stubs returning
    ///     `ENOSYS`. Guests import a fixed list regardless of what they call,
    ///     so turning this off risks instantiation failures on unused imports.
    public func link(
        to imports: inout Imports,
        store: Store,
        capabilities: [WASICapability],
        stubUnlinked: Bool = true
    ) {
        let functions = hostFunctions(capabilities: capabilities, stubUnlinked: stubUnlinked)
        for (name, function) in functions {
            imports.define(
                module: "wasi_snapshot_preview1",
                name: name,
                Function(store: store, type: function.type, body: makeHostFunction(function))
            )
        }
    }

    @available(*, deprecated, renamed: "link(to:store:)", message: "Use `Engine`-based API instead")
    public var hostModules: [String: HostModule] {
        wasiHostModules(Memory.self).mapValues { (module: WASIHostModule<Memory>) -> HostModule in
            HostModule(
                functions: module.functions.mapValues { function -> HostFunction in
                    HostFunction(type: function.type, implementation: makeHostFunction(function))
                })
        }
    }

    private func makeHostFunction(_ function: WASIHostFunction<Memory>) -> Function.Implementation {
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

    @available(*, deprecated, message: "Use `Engine`-based API instead")
    public func start(_ instance: Instance, runtime: Runtime) throws -> UInt32 {
        return try start(instance)
    }
}
