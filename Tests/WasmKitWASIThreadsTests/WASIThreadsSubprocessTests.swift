import Foundation
import Testing

@Suite(.serialized) struct WASIThreadsSubprocessTests {
    private struct UpstreamTest: CustomStringConvertible {
        let module: URL
        let expectedExitCode: Int32
        let requiresThreads: Bool

        var description: String { module.lastPathComponent }
    }

    private struct Manifest: Decodable {
        let exit_code: Int32?
    }

    private static let projectDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static func discoverUpstreamTests() throws -> [UpstreamTest] {
        let directory = projectDirectory.appendingPathComponent("Vendor/wasi-threads/test/testsuite")
        return try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "wat" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { module in
                let manifestURL = module.deletingPathExtension().appendingPathExtension("json")
                let manifest = try? JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
                let source = try String(contentsOf: module, encoding: .utf8)
                return UpstreamTest(
                    module: module,
                    expectedExitCode: manifest?.exit_code ?? 0,
                    requiresThreads: source.contains("shared")
                )
            }
    }

    @Test func workerProcExitTerminatesTheCLI() throws {
        let result = try runFixture("wasi-threads-worker-exit.wat")
        #expect(result.status == 7)
    }

    @Test func workerTrapTerminatesTheCLIWithDiagnostic() throws {
        let result = try runFixture("wasi-threads-worker-trap.wat")
        #expect(result.status == 1)
        #expect(result.standardError.contains("WASI thread failed:"))
    }

    @Test func mainReturnTerminatesTheCLIWithLiveWorker() throws {
        let result = try runFixture("wasi-threads-main-return.wat")
        #expect(result.status == 0)
    }

    @Test func threadSpawnIsNotLinkedWithoutTheOptInFlag() throws {
        let result = try runFixture("wasi-threads-worker-exit.wat", threadsEnabled: false)
        #expect(result.status == 1)
        #expect(result.standardError.contains("thread-spawn"))
    }

    @Test(arguments: try discoverUpstreamTests())
    private func upstreamWASIThreadsTestSuite(test: UpstreamTest) throws {
        let result = try runModule(test.module, threadsEnabled: test.requiresThreads)
        #expect(result.status == test.expectedExitCode)
    }

    private func runFixture(_ name: String, threadsEnabled: Bool = true) throws -> (status: Int32, standardError: String) {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let fixture = testsDirectory.appendingPathComponent("Fixtures").appendingPathComponent(name)
        return try runModule(fixture, threadsEnabled: threadsEnabled)
    }

    private func runModule(_ module: URL, threadsEnabled: Bool) throws -> (status: Int32, standardError: String) {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let executable = try cliExecutable(testsDirectory: testsDirectory)

        let process = Process()
        process.executableURL = executable
        process.arguments = threadsEnabled
            ? ["run", "--feature", "threads", "--wasi-threads", module.path]
            : ["run", "--feature", "threads", module.path]
        let error = Pipe()
        // Keep stdin open without supplying data so the upstream `fd_read`
        // cases actually block until process-oriented termination ends them.
        let input = Pipe()
        process.standardInput = input
        process.standardError = error
        try process.run()

        let deadline = Date().addingTimeInterval(3)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        if process.isRunning {
            process.terminate()
            throw SubprocessError.timedOut(module.lastPathComponent)
        }
        let standardError = String(decoding: error.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return (process.terminationStatus, standardError)
    }

    private func cliExecutable(testsDirectory: URL) throws -> URL {
        let buildDirectory = testsDirectory.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build")
        let debugExecutable = buildDirectory.appendingPathComponent("debug/wasmkit-cli")
        if FileManager.default.isExecutableFile(atPath: debugExecutable.path) {
            return debugExecutable
        }
        let candidates = (FileManager.default.enumerator(at: buildDirectory, includingPropertiesForKeys: [.isRegularFileKey])?.allObjects as? [URL] ?? [])
            .filter { $0.lastPathComponent == "wasmkit-cli" && FileManager.default.isExecutableFile(atPath: $0.path) }
        guard let executable = candidates.first else {
            throw SubprocessError.missingExecutable(buildDirectory.path)
        }
        return executable
    }

    private enum SubprocessError: Error {
        case timedOut(String)
        case missingExecutable(String)
    }
}
