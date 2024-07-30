import WASI
import WasmKit

public typealias WASIBridgeToHost = WASI.WASIBridgeToHost

extension WASIBridgeToHost {
    public var hostModules: [String: HostModule] {
        wasiHostModules.mapValues {
            HostModule(
                functions: $0.functions.mapValues { function in
                    HostFunction(type: function.type) { caller, values in
                        guard case let .memory(memoryAddr) = caller.instance?.exports["memory"] else {
                            throw WASIError(description: "Missing required \"memory\" export")
                        }
                        let memory = WasmKitGuestMemory(store: caller.store, address: memoryAddr)
                        return try function.implementation(memory, values)
                    }
                })
        }
    }

    public func start(_ instance: ModuleInstance, runtime: Runtime) throws -> UInt32 {
        do {
            _ = try runtime.invoke(instance, function: "_start")
        } catch let code as WASIExitCode {
            return code.code
        }
        return 0
    }
}
