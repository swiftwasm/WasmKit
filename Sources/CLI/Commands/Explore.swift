import ArgumentParser
import SystemPackage
@_spi(OnlyForCLI) import WasmKit

struct Explore: ParsableCommand {
    @Argument
    var path: String

    struct Stdout: TextOutputStream {
        func write(_ string: String) {
            print(string, terminator: "")
        }
    }

    func run() throws {
        let module = try parseWasm(filePath: FilePath(path))
        var hostModuleStubs: [String: HostModule] = [:]
        for importEntry in module.imports {
            var hostModule = hostModuleStubs[importEntry.module] ?? HostModule()
            switch importEntry.descriptor {
            case .function(let typeIndex):
                let type = module.types[Int(typeIndex)]
                hostModule.functions[importEntry.name] = HostFunction(type: type) { _, _ in
                    fatalError("unreachable")
                }
            default:
                fatalError("Import \(importEntry) not supported in explore mode yet")
            }
            hostModuleStubs[importEntry.module] = hostModule
        }
        // Instruction dumping requires token threading model for now
        let configuration = EngineConfiguration(threadingModel: .token)
        let runtime = Runtime(hostModules: hostModuleStubs, configuration: configuration)
        let instance = try runtime.instantiate(module: module)
        var stdout = Stdout()
        try instance.dumpFunctions(to: &stdout, module: module, runtime: runtime)
    }
}
