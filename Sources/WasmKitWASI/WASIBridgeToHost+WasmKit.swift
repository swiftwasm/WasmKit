import WASI
import WasmKit

public typealias WASIBridgeToHost = WASI.WASIBridgeToHost

extension WASIBridgeToHost {
    public func link(to imports: inout Imports, store: Store) {
        var imports = Imports()
        for (moduleName, module) in wasiHostModules {
            for (name, function) in module.functions {
                imports.define(
                    module: moduleName,
                    name: name,
                    Function(store: store, type: function.type, body: makeHostFunction(function))
                )
            }
        }
    }

    public var hostModules: [String: HostModule] {
        wasiHostModules.mapValues { (module: WASIHostModule) -> HostModule in
            HostModule(
                functions: module.functions.mapValues { function -> HostFunction in
                    HostFunction(type: function.type, implementation: makeHostFunction(function))
                })
        }
    }

    private func makeHostFunction(_ function: WASIHostFunction) -> ((Caller, [Value]) throws -> [Value]) {
        { caller, values -> [Value] in
            guard case let .memory(memory) = caller.instance?.export("memory") else {
                throw WASIError(description: "Missing required \"memory\" export")
            }
            return try function.implementation(memory, values)
        }
    }

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

    public func start(_ instance: Instance, runtime: Runtime) throws -> UInt32 {
        return try start(instance)
    }
}
