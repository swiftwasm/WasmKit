import XCTest
import WasmKit

@available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class SpectestTests: XCTestCase {
    static let projectDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let testsuite = projectDir
        .appendingPathComponent("Vendor/testsuite")
    static var testPaths: [String] {
        [
            Self.testsuite.path,
            Self.testsuite.appendingPathComponent("proposals/memory64").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
        ]
    }

    /// Run all the tests in the spectest suite.
    func testRunAll() async throws {
        let defaultConfig = EngineConfiguration()
        let ok = try await spectest(
            path: Self.testPaths,
            include: [],
            exclude: [
                "exports.wast",
                "func.wast",
                "func_ptrs.wast",
                "global.wast",
                "if.wast",
                "imports.wast",
                "labels.wast",
                "load.wast",
                "local_get.wast",
                "loop.wast",
                "memory.wast",
                "memory_grow.wast",
                "memory_size.wast",
                "proposals/memory64/align64.wast",
                "proposals/memory64/call_indirect.wast",
                "proposals/memory64/load64.wast",
                "proposals/memory64/memory64.wast",
                "proposals/memory64/table_copy_mixed.wast",
                "proposals/memory64/table_get.wast",
                "proposals/memory64/table_grow.wast",
                "proposals/memory64/table_size.wast",
                "ref_func.wast",
                "select.wast",
                "start.wast",
                "table-sub.wast",
                "table.wast",
                "table_get.wast",
                "table_grow.wast",
                "table_size.wast",
                "unreached-invalid.wast",
            ],
            parallel: true,
            configuration: defaultConfig
        )
        XCTAssertTrue(ok)
    }

    func testRunAllWithTokenThreading() async throws {
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
