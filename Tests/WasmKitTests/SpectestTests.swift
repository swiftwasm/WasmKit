import WasmKit
import XCTest

@available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class SpectestTests: XCTestCase {
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
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
        ]
    }

    /// Run all the tests in the spectest suite.
    func testRunAll() async throws {
        #if os(Android)
        throw XCTSkip("unable to run spectest on Android due to missing files on emulator")
        #endif
        let defaultConfig = EngineConfiguration()
        let ok = try await spectest(
            path: Self.testPaths,
            include: [],
            exclude: [],
            parallel: true,
            configuration: defaultConfig
        )
        XCTAssertTrue(ok)
    }

    func testRunAllWithTokenThreading() async throws {
        #if os(Android)
        throw XCTSkip("unable to run spectest on Android due to missing files on emulator")
        #endif
        let defaultConfig = EngineConfiguration()
        guard defaultConfig.threadingModel != .token else { return }
        // Sanity check that non-default threading models work.
        var config = defaultConfig
        config.threadingModel = .token
        let ok = try await spectest(
            path: Self.testPaths,
            parallel: true,
            configuration: config
        )
        XCTAssertTrue(ok)
    }
}
