import SwiftCLI

final class SpecTestCommand: Command {
    let name = "spectest"

    let path = Parameter()
    let specs = VariadicKey<String>("--specs")
    let isVerbose = Flag("-v", "--verbose")

    func execute() throws {
        let isVerbose = self.isVerbose.value

        let testCases: [TestCase]
        do {
            testCases = try TestCase.load(specs: specs.values, in: path.value)
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
