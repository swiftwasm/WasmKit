import SwiftCLI

final class SpecTestCommand: Command {
    let name = "spectest"

    let path = Parameter()
    let specs = VariadicKey<String>("--specs")

    func execute() throws {
        let testCases: [TestCase]
        do {
            testCases = try TestCase.load(specs: specs.values, in: path.value)
        } catch {
            fatalError("failed to load test: \(error)")
        }

        for testCase in testCases {
            testCase.run(rootPath: path.value) { testCase, command, result in
                print("\(testCase.sourceFilename):\(command.line):", result.banner)
                if case let .failed(reason) = result {
                    print(reason)
                }
            }
        }
    }
}
