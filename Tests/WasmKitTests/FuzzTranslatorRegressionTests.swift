import WasmKit
import WasmKitFuzzing
import XCTest

final class FuzzTranslatorRegressionTests: XCTestCase {
    func testRunAll() throws {
        #if os(Android)
        throw XCTSkip("Test skipped due to absolute path #filePath unavailable on emulator")
        #endif
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
                try WasmKitFuzzing.fuzzInstantiation(bytes: Array(data))
            } catch {
                // Skip exceptions without crash
            }
        }
    }
}
