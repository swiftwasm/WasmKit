import Foundation
import Testing
import WasmKit
import WasmKitFuzzing

@Suite
struct FuzzTranslatorRegressionTests {

    struct Case: CustomStringConvertible {
        let path: URL
        let description: String
    }

    static let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    static func failCases() throws -> [Case] {
        let failCasesDir = sourceRoot.appendingPathComponent("FuzzTesting/FailCases/FuzzTranslator")
        return try FileManager.default.contentsOfDirectory(atPath: failCasesDir.path).map {
            let url = failCasesDir.appendingPathComponent($0)
            return Case(path: url, description: String(url.path.dropFirst(sourceRoot.path.count + 1)))
        }
    }

    #if !os(Android)
        @Test(
            .disabled("unable to run fuzz translator regression tests on Android due to missing files on emulator", platforms: [.android]),
            arguments: try failCases()
        )
        func run(test: Case) throws {
            let data = try Data(contentsOf: test.path)
            do {
                try WasmKitFuzzing.fuzzInstantiation(bytes: Array(data))
            } catch {
                // Skip exceptions without crash
            }
        }
    #endif

    @Test
    func instantiatesModuleWithConcreteImportTypes() throws {
        // (module (type $t (func)) (import "m" "f" (func (param (ref null $t))))
        //   (import "m" "t" (table 1 (ref null $t))))
        try WasmKitFuzzing.fuzzInstantiation(bytes: [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x09, 0x02, 0x60, 0x00, 0x00, 0x60, 0x01, 0x63, 0x00, 0x00,
            0x02, 0x10, 0x02, 0x01, 0x6D, 0x01, 0x66, 0x00, 0x01, 0x01, 0x6D, 0x01, 0x74, 0x01, 0x63, 0x00, 0x00, 0x01,
        ])
    }
}
