import WasmKit
import XCTest

final class FuzzTranslatorRegressionTests: XCTestCase {
    func testRunAll() async throws {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let failCasesDir = sourceRoot
            .appendingPathComponent("FuzzTesting/FailCases/FuzzTranslator")

        for file in try FileManager.default.contentsOfDirectory(atPath: failCasesDir.path) {
            let path = failCasesDir.appendingPathComponent(file).path
            print("Fuzz regression test: \(path.dropFirst(sourceRoot.path.count + 1))")

            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            do {
                var module = try WasmKit.parseWasm(bytes: Array(data))
                try module.materializeAll()
            } catch {
                // Explicit errors are ok
            }
        }
    }
}
