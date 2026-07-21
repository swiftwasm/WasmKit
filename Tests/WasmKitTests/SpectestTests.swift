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
    /// Whether the default engine can back a shared memory here (requires mprotect: not ASan,
    /// not token threading, 64-bit macOS/Linux). The threads proposal tests declare shared
    /// memories, so they are skipped where one cannot be created.
    static let sharedMemorySupported: Bool = {
        let store = Store(engine: Engine(configuration: EngineConfiguration()))
        return (try? Memory(store: store, type: MemoryType(min: 1, max: 1, shared: true))) != nil
    }()

    static var testPaths: [String] {
        var paths = [
            Self.testsuite.path,
            Self.testsuite.appendingPathComponent("proposals/memory64").path,
            Self.testsuite.appendingPathComponent("proposals/tail-call").path,
            Self.testsuite.appendingPathComponent("proposals/exception-handling").path,
            Self.testsuite.appendingPathComponent("proposals/extended-const").path,
            Self.testsuite.appendingPathComponent("proposals/relaxed-simd").path,
            Self.projectDir.appendingPathComponent("Tests/WasmKitTests/ExtraSuite").path,
        ]
        if sharedMemorySupported {
            paths.append(Self.testsuite.appendingPathComponent("proposals/threads").path)
        }
        return paths
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
