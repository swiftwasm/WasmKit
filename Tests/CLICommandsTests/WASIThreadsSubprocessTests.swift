import Foundation
import Testing

@Suite(.serialized) struct WASIThreadsSubprocessTests {
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

    private func runFixture(_ name: String, threadsEnabled: Bool = true) throws -> (status: Int32, standardError: String) {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let fixture = testsDirectory.appendingPathComponent("Fixtures").appendingPathComponent(name)
        let executable = try cliExecutable(testsDirectory: testsDirectory)

        let process = Process()
        process.executableURL = executable
        process.arguments = threadsEnabled ? ["run", "--wasi-threads", fixture.path] : ["run", fixture.path]
        let error = Pipe()
        process.standardError = error
        try process.run()

        let deadline = Date().addingTimeInterval(3)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        if process.isRunning {
            process.terminate()
            throw SubprocessError.timedOut(name)
        }
        let standardError = String(decoding: error.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return (process.terminationStatus, standardError)
    }

    private func cliExecutable(testsDirectory: URL) throws -> URL {
        let buildDirectory = testsDirectory.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build")
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
