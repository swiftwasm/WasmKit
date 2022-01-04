import SwiftCLI

final class SpecTestCommand: Command {
    let name = "spectest"

    let path = Parameter()
    let include = Key<String>("--include")
    let exclude = Key<String>("--exclude")
    let isVerbose = Flag("-v", "--verbose")

    func execute() throws {
        let isVerbose = self.isVerbose.value
        let include = self.include.value.flatMap { $0.split(separator: ",").map(String.init) } ?? []
        let exclude = self.exclude.value.flatMap { $0.split(separator: ",").map(String.init) } ?? []

        let testCases: [TestCase]
        do {
            testCases = try TestCase.load(include: include, exclude: exclude, in: path.value)
        } catch {
            fatalError("failed to load test: \(error)")
        }

        for testCase in testCases {
            testCase.run(rootPath: path.value) { testCase, command, result in
                switch result {
                case let .failed(reason):
                    print("\(testCase.sourceFilename):\(command.line):", result.banner, reason)
                case let .skipped(reason):
                    if isVerbose { print("\(testCase.sourceFilename):\(command.line):", result.banner, reason) }
                default:
                    print("\(testCase.sourceFilename):\(command.line):", result.banner)
                }
            }
        }
    }
}
