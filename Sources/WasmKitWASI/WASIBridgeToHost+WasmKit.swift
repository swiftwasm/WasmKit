import WASI
import WasmKit

public typealias WASIBridgeToHost = WASI.WASIBridgeToHost

extension WASIBridgeToHost {
    public var hostModules: [String: HostModule] {
        wasiHostModules.mapValues { (module: WASIHostModule) -> HostModule in
            HostModule(
                functions: module.functions.mapValues { function -> HostFunction in
                    makeHostFunction(function)
                })
        }
    }

    private func makeHostFunction(_ function: WASIHostFunction) -> HostFunction {
        HostFunction(type: function.type) { caller, values -> [Value] in
            guard case let .memory(memory) = caller.instance?.export("memory") else {
                throw WASIError(description: "Missing required \"memory\" export")
            }
            return try function.implementation(memory, values)
        }
    }

    public func start(_ instance: Instance, runtime: Runtime) throws -> UInt32 {
        do {
            _ = try runtime.invoke(instance, function: "_start")
        } catch let code as WASIExitCode {
            return code.code
        }
        return 0
    }
}
