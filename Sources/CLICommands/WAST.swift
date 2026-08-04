import ArgumentParser
import Foundation
import WASTRunner
import WAT
import WasmKit

package struct WAST: ParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "wast",
        abstract: "Run WebAssembly spec test scripts",
        discussion: """
            Executes the directives of each `.wast` script and reports how many assertions passed.
            Exits non-zero if any assertion failed.
            """
    )

    @Argument(help: "Paths to .wast files, or directories holding them")
    var paths: [String]

    @Flag(name: .shortAndLong, help: "Report passing and skipped assertions, not just failures")
    var verbose = false

    package init() {}

    package func run() throws {
        if let unreadable = paths.first(where: {
            !FileManager.default.isReadableFile(atPath: $0) && !isDirectory($0)
        }) {
            throw ValidationError("Cannot read '\(unreadable)'")
        }

        let tests = try TestCase.load(include: [], exclude: [], in: paths)
        let discovered = Set(tests.map(\.path))
        for path in paths where !isDirectory(path) {
            guard !discovered.contains(URL(fileURLWithPath: path).path) else { continue }
            throw ValidationError("'\(path)' is on the spec-test runner's exclusion list")
        }
        guard !tests.isEmpty else {
            throw ValidationError("No .wast script to run in \(paths.joined(separator: ", "))")
        }

        let runner = try SpectestRunner(configuration: EngineConfiguration())
        let reporter = StandardOutputProgressReporter(isVerbose: verbose)
        var totalPassed = 0
        var totalFailed = 0

        for test in tests {
            let outcome = try runner.evaluate(test: test, reporter: reporter)
            totalPassed += outcome.passed
            totalFailed += outcome.failed
            var line = "\(test.relativePath): \(outcome.passed) passed"
            if outcome.failed > 0 {
                line += ", \(outcome.failed) failed"
            }
            print(line)
        }

        if tests.count > 1 {
            print("total: \(totalPassed) passed, \(totalFailed) failed across \(tests.count) files")
        }

        if totalFailed > 0 {
            throw ExitCode.failure
        }
    }

    private func isDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

private struct StandardOutputProgressReporter: SpectestProgressReporter {
    let isVerbose: Bool

    func log(_ message: String, verbose: Bool) {
        guard isVerbose || !verbose else { return }
        print(message)
    }

    func log(_ message: String, path: String, location: Location, verbose: Bool) {
        guard isVerbose || !verbose else { return }
        let (line, _) = location.computeLineAndColumn()
        print("\(path):\(line): \(message)")
    }
}
