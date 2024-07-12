import ArgumentParser
import Foundation
import SystemPackage
import WasmKit
import WAT

@main
@available(macOS 11, *)
struct Spectest: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [Run.self, ParseWat.self],
        defaultSubcommand: Run.self
    )
}

@available(macOS 11, *)
struct Run: AsyncParsableCommand {
    @Argument
    var path: String

    @Option
    var include: String?

    @Option
    var exclude: String?

    @Flag
    var verbose = false

    @Flag(inversion: .prefixedNo)
    var parallel: Bool = true

    func run() async throws {
        let printVerbose = self.verbose
        @Sendable func log(_ message: String, verbose: Bool = false) {
            if !verbose || printVerbose {
                fputs(message + "\n", stderr)
            }
        }

        let include = self.include.flatMap { $0.split(separator: ",").map(String.init) } ?? []
        let exclude = self.exclude.flatMap { $0.split(separator: ",").map(String.init) } ?? []

        let testCases: [TestCase]
        do {
            testCases = try TestCase.load(include: include, exclude: exclude, in: path, log: { log($0) })
        } catch {
            fatalError("failed to load test: \(error)")
        }

        let rootPath: String
        let filePath = FilePath(path)
        if isDirectory(filePath) {
            rootPath = path
        } else {
            rootPath = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }

        // https://github.com/WebAssembly/spec/tree/8a352708cffeb71206ca49a0f743bdc57269fb1a/interpreter#spectest-host-module
        let hostModulePath = FilePath(rootPath).appending("host.wasm")
        let hostModule = try parseWasm(filePath: hostModulePath)

        @Sendable func runTestCase(testCase: TestCase) throws -> [Result] {
            var testCaseResults = [Result]()
            try testCase.run(spectestModule: hostModule) { testCase, command, result in
                switch result {
                case let .failed(reason):
                    log("\(testCase.content.sourceFilename):\(command.line): \(result.banner) \(reason)")
                case let .skipped(reason):
                    log("\(testCase.content.sourceFilename):\(command.line): \(result.banner) \(reason)", verbose: true)
                case .passed:
                    log("\(testCase.content.sourceFilename):\(command.line): \(result.banner)", verbose: true)
                default:
                    log("\(testCase.content.sourceFilename):\(command.line): \(result.banner)")
                }
                testCaseResults.append(result)
            }

            return testCaseResults
        }

        let results: [Result]

        if parallel {
            results = try await withThrowingTaskGroup(of: [Result].self) { group in
                for testCase in testCases {
                    group.addTask {
                        try await Task { try runTestCase(testCase: testCase) }.value
                    }
                }

                var results = [Result]()
                for try await testCaseResults in group {
                    results.append(contentsOf: testCaseResults)
                }

                return results
            }
        } else {
            results = try testCases.flatMap { try runTestCase(testCase: $0) }
        }

        let passingCount = results.filter { if case .passed = $0 { return true } else { return false } }.count
        let skippedCount = results.filter { if case .skipped = $0 { return true } else { return false } }.count
        let failedCount = results.filter { if case .failed = $0 { return true } else { return false } }.count

        print(
            """
            \(passingCount)/\(results.count) (\(
                percentage(passingCount, results.count)
            ) passing, \(
                percentage(skippedCount, results.count)
            ) skipped, \(
                percentage(failedCount, results.count)
            ) failed)
            """
        )

        // Exit with non-zero status when there is any failure
        if failedCount > 0 {
            throw ArgumentParser.ExitCode(1)
        }
    }

    private func percentage(_ numerator: Int, _ denominator: Int) -> String {
        "\(Int(Double(numerator) / Double(denominator) * 100))%"
    }
}

struct ParseWat: ParsableCommand {
    @Argument
    var path: String

    @Option
    var output: String?

    func run() throws {
        let allFiles: [URL]
        if isDirectory(FilePath(path)) {
            allFiles = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil)
        } else {
            allFiles = [URL(fileURLWithPath: path)]
        }
        let exclude = [
            "annotations.wast"
        ]

        var failureCount = 0
        var allParseCount = 0
        for filePath in allFiles {
            guard filePath.pathExtension == "wast" else {
                continue
            }
            guard !exclude.contains(filePath.lastPathComponent) else { continue }
            guard !filePath.lastPathComponent.starts(with: "simd_") else { continue }
            print("Parsing \(filePath.path)...")
            let source = try String(contentsOf: filePath)
            do {
                allParseCount += 1
                var wast = try parseWAST(source)
                var moduleIndex = 0
                while let directive = try wast.nextDirective() {
                    guard case let .module(moduleDirective) = directive,
                       case var .text(wat) = moduleDirective.source else {
                        continue
                    }
                    if let output {
                        let bytes = try wat.encode()
                        let outputFileName = filePath.deletingPathExtension().lastPathComponent + ".\(moduleIndex).wasm"
                        let outputPath = URL(fileURLWithPath: output).appendingPathComponent(outputFileName)
                        try Data(bytes).write(to: outputPath)
                    }
                    moduleIndex += 1
                }
            } catch {
                failureCount += 1
                print("Failed to parse \(filePath.path):\(error)")
            }
        }

        if failureCount > 0 {
            print("Failed to parse \(failureCount) / \(allParseCount) files")
        } else {
            print("Passed")
        }
    }
}
