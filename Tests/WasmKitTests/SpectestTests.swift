import Foundation
import Testing
import WASTRunner
import WasmKit

@Suite
struct SpectestTests {
    static let projectDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let testsuite =
        projectDir
        .appendingPathComponent("Vendor/testsuite")
    /// Whether the default engine can back a shared memory here (requires mprotect: not ASan,
    /// not token threading, 64-bit macOS/Linux).
    static let sharedMemorySupported: Bool = {
        // A shared memory type only validates with the threads feature.
        var configuration = EngineConfiguration()
        configuration.features.insert(.threads)
        let store = Store(engine: Engine(configuration: configuration))
        return (try? Memory(store: store, type: MemoryType(min: 1, max: 1, shared: true))) != nil
    }()

    static var testPaths: [String] {
        return [
            // Wasm 3.0, which includes memory64, tail calls, exception handling, extended
            // constant expressions, relaxed SIMD, typed function references and multi-memory.
            Self.testsuite.path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/memory64").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/function-references").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/multi-memory").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/fuel").path,
        ]
    }

    /// The threads proposal tests declare shared memories, so they are skipped where one
    /// cannot be created. Token threading never has one, as it checks bounds in software.
    static var sharedMemoryTestPaths: [String] {
        guard sharedMemorySupported else { return [] }
        return [
            Self.testsuite.appendingPathComponent("proposals/threads").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/multi-memory/threads").path,
        ]
    }

    static func testCases(in paths: [String]) throws -> [TestCase] {
        var exclude = SpectestDiscovery(path: []).exclude
        exclude += UnsupportedSpectests.files.map { "Vendor/testsuite/\($0)" }
        return try SpectestDiscovery(path: paths, exclude: exclude).discover()
    }

    static func run(test: TestCase, configuration: EngineConfiguration) throws {
        let fileName = URL(fileURLWithPath: test.path).lastPathComponent
        let isTopLevel = test.path.hasSuffix("Vendor/testsuite/\(fileName)")
        let skip = isTopLevel ? UnsupportedSpectests.directives[fileName] ?? [:] : [:]
        try SpectestRunner(configuration: configuration)
            .run(test: test, reporter: NullSpectestProgressReporter(), skip: skip)
    }

    #if !os(Android)
        @Test(
            .disabled("unable to run spectest on Android due to missing files on emulator", platforms: [.android]),
            arguments: try SpectestTests.testCases(in: SpectestTests.testPaths + SpectestTests.sharedMemoryTestPaths)
        )
        func run(test: TestCase) throws {
            try Self.run(test: test, configuration: EngineConfiguration())
        }

        @Test(
            .disabled("unable to run spectest on Android due to missing files on emulator", platforms: [.android]),
            arguments: try SpectestTests.testCases(in: SpectestTests.testPaths)
        )
        func runWithTokenThreading(test: TestCase) throws {
            var defaultConfig = EngineConfiguration()
            guard defaultConfig.threadingModel != .token else { return }
            defaultConfig.threadingModel = .token
            // Sanity check that non-default threading models work.
            try Self.run(test: test, configuration: defaultConfig)
        }
    #endif
}
