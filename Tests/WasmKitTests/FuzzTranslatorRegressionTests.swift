import WasmKit
import XCTest

final class FuzzTranslatorRegressionTests: XCTestCase {
    func testRunAll() async throws {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let failCasesDir =
            sourceRoot
            .appendingPathComponent("FuzzTesting/FailCases/FuzzTranslator")

        for file in try FileManager.default.contentsOfDirectory(atPath: failCasesDir.path) {
            let path = failCasesDir.appendingPathComponent(file).path
            print("Fuzz regression test: \(path.dropFirst(sourceRoot.path.count + 1))")

            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            do {
                let module = try WasmKit.parseWasm(bytes: Array(data))
                let engine = Engine(configuration: EngineConfiguration(compilationMode: .eager))
                let store = Store(engine: engine)
                var imports = Imports()
                for importEntry in module.imports {
                    let value: ExternalValueConvertible
                    switch importEntry.descriptor {
                    case .function(let typeIndex):
                        let type = module.types[Int(typeIndex)]
                        value = Function(store: store, type: type) { _, _ in
                            fatalError("unreachable")
                        }
                    case .global(let globalType):
                        value = Global(store: store, type: globalType, value: .i32(0))
                    case .memory(let memoryType):
                        value = try Memory(store: store, type: memoryType)
                    case .table(let tableType):
                        value = try Table(store: store, type: tableType)
                    }
                    imports.define(module: importEntry.module, name: importEntry.name, value.externalValue)
                }
                _ = try module.instantiate(store: store, imports: imports)
            } catch {
                // Explicit errors are ok
            }
        }
    }
}
