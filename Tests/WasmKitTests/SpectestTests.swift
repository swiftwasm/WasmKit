import Foundation
import Testing
import WasmKit

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
    #endif
}
