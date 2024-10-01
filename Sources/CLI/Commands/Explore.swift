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
        // Instruction dumping requires token threading model for now
        let configuration = EngineConfiguration(threadingModel: .token)
        let engine = Engine(configuration: configuration)
        let store = Store(engine: engine)

        var imports: Imports = [:]
        for importEntry in module.imports {
            switch importEntry.descriptor {
            case .function(let typeIndex):
                let type = module.types[Int(typeIndex)]
                imports.define(
                    module: importEntry.module,
                    name: importEntry.name,
                    Function(store: store, type: type) { _, _ in
                        fatalError("unreachable")
                    }
                )
            default:
                fatalError("Import \(importEntry) not supported in explore mode yet")
            }
        }
        let instance = try module.instantiate(store: store, imports: imports)
        var stdout = Stdout()
        try instance.dumpFunctions(to: &stdout, module: module)
    }
}
