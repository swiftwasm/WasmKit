import Foundation
import SystemPackage
import Testing
import WasmParser
import WasmKit
import WAT

@Suite
struct SpectestTests {
    static let projectDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let testsuite =
        projectDir
        .appendingPathComponent("Vendor/testsuite")
    static var testPaths: [String] {
        [
            Self.testsuite.path,
            Self.testsuite.appendingPathComponent("proposals/memory64").path,
            Self.testsuite.appendingPathComponent("proposals/tail-call").path,
            Self.testsuite.appendingPathComponent("proposals/threads").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
        ]
    }

    #if !os(Android)
        @Test(
            .disabled("unable to run spectest on Android due to missing files on emulator", platforms: [.android]),
            arguments: try SpectestDiscovery(path: SpectestTests.testPaths).discover()
        )
        func run(test: TestCase) throws {
            let defaultConfig = EngineConfiguration()
            let runner = try SpectestRunner(configuration: defaultConfig)
            try runner.run(test: test, reporter: NullSpectestProgressReporter())
        }

        @Test(
            .disabled("unable to run spectest on Android due to missing files on emulator", platforms: [.android]),
            arguments: try SpectestDiscovery(path: SpectestTests.testPaths).discover()
        )
        func runWithTokenThreading(test: TestCase) throws {
            let defaultConfig = EngineConfiguration()
            guard defaultConfig.threadingModel != .token else { return }
            // Sanity check that non-default threading models work.
            let runner = try SpectestRunner(configuration: defaultConfig)
            try runner.run(test: test, reporter: NullSpectestProgressReporter())
        }

        @Test(arguments: try SpectestDiscovery(path: SpectestTests.testPaths).discover())
        func roundTrip(test: TestCase) throws {
            guard let data = FileManager.default.contents(atPath: test.path) else { return }
            let rootPath = FilePath(test.path).removingLastComponent()
            let features = WastRunContext.deriveFeatureSet(rootPath: rootPath)
            var content = try parseWAST(String(data: data, encoding: .utf8)!, features: features)

            while let (directive, _) = try content.nextDirective() {
                guard case .module(let moduleDirective) = directive else { continue }
                let binary: [UInt8]
                switch moduleDirective.source {
                case .text(let wat): binary = try wat.encode()
                case .binary:
                    // Binary modules may use non-canonical encodings (e.g. non-minimal LEB128).
                    continue
                case .quote(let text): binary = try wat2wasm(String(decoding: text, as: UTF8.self), features: features)
                }

                let text = try wasm2wat(StaticByteStream(bytes: binary), features: features)
                let binary2 = try wat2wasm(text, features: features)
                #expect(binary == binary2, "Round-trip mismatch in \(test.relativePath)")
            }
        }
    #endif
}
