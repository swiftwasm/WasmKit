import ArgumentParser
import Foundation
import SystemPackage

struct Spectest: ParsableCommand {
    @Argument
    var path: String

    @Option
    var include: String?

    @Option
    var exclude: String?

    @Flag
    var verbose = false

    func run() throws {
        let include = self.include.flatMap { $0.split(separator: ",").map(String.init) } ?? []
        let exclude = self.exclude.flatMap { $0.split(separator: ",").map(String.init) } ?? []

        let testCases: [TestCase]
        do {
            testCases = try TestCase.load(include: include, exclude: exclude, in: path)
        } catch {
            fatalError("failed to load test: \(error)")
        }

        let rootPath: String
        let filePath = FilePath(path)
        if (try? FileDescriptor.open(filePath, FileDescriptor.AccessMode.readOnly, options: .directory)) != nil {
            rootPath = path
        } else {
            rootPath = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }

        var results = [Result]()
        for testCase in testCases {
            testCase.run(rootPath: rootPath) { testCase, command, result in
                switch result {
                case let .failed(reason):
                    print("\(testCase.sourceFilename):\(command.line):", result.banner, reason)
                case let .skipped(reason):
                    if verbose { print("\(testCase.sourceFilename):\(command.line):", result.banner, reason) }
                default:
                    print("\(testCase.sourceFilename):\(command.line):", result.banner)
                }
                results.append(result)
            }
        }

        let passingCount = results.filter { if case .passed = $0 { return true } else { return false} }.count
        print("\(passingCount)/\(results.count) \(Int(Double(passingCount)/Double(results.count) * 100))% passing")
    }
}
