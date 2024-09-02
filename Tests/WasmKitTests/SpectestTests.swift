import XCTest
import WasmKit

@available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class SpectestTests: XCTestCase {
    static let projectDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let testsuite = projectDir
        .appendingPathComponent("Vendor/testsuite")

    /// Run all the tests in the spectest suite.
    func testRunAll() async throws {
        let defaultConfig = RuntimeConfiguration()
        let environment = ProcessInfo.processInfo.environment
        let ok = try await spectest(
            path: [
                Self.testsuite.path,
                Self.testsuite.appendingPathComponent("proposals/memory64").path,
                Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
            ],
            include: environment["WASMKIT_SPECTEST_INCLUDE"],
            exclude: environment["WASMKIT_SPECTEST_EXCLUDE"],
            parallel: true,
            configuration: defaultConfig
        )
        XCTAssertTrue(ok)

        if defaultConfig.threadingModel != .token {
            // Sanity check that non-default threading models work.
            var config = defaultConfig
            config.threadingModel = .token
            let ok = try await spectest(
                path: [Self.testsuite.appendingPathComponent("forward.wast").path,],
                include: nil, exclude: nil,
                configuration: config
            )
            XCTAssertTrue(ok)
        }
    }
}
