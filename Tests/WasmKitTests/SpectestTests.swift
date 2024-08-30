import XCTest

@available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class SpectestTests: XCTestCase {

    /// Run all the tests in the spectest suite.
    func testRunAll() async throws {
        let projectDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let testsuite = projectDir
            .appendingPathComponent("Vendor/testsuite")
        let environment = ProcessInfo.processInfo.environment
        let ok = try await spectest(
            path: [
                testsuite.path,
                testsuite.appendingPathComponent("proposals/memory64").path,
                projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
            ],
            include: environment["WASMKIT_SPECTEST_INCLUDE"],
            exclude: environment["WASMKIT_SPECTEST_EXCLUDE"],
            parallel: true
        )
        XCTAssertTrue(ok)
    }
}
