#if canImport(Testing)
    import WasmKit
    import WasmKitFuzzing
    import Foundation
    import Testing

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
    }

#endif
