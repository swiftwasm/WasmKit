import Commander
import Foundation
import LEB
import Parser
import Rainbow
import WAKit

struct TestCase: Decodable {
    struct Command: Decodable {
        enum CommandType: String, Decodable {
            case module
            case action
            case register
            case assertReturn = "assert_return"
            case assertInvalid = "assert_invalid"
            case assertTrap = "assert_trap"
            case assertMalformed = "assert_malformed"
            case assertExhaustion = "assert_exhaustion"
            case assertUnlinkable = "assert_unlinkable"
            case assertUninstantiable = "assert_uninstantiable"
            case assertReturnCanonicalNan = "assert_return_canonical_nan"
            case assertReturnArithmeticNan = "assert_return_arithmetic_nan"
        }

        enum ModuleType: String, Decodable {
            case binary
            case text
        }

        let type: CommandType
        let line: Int
        let filename: String?
        let text: String?
        let moduleType: ModuleType?
    }

    let sourceFilename: String
    let commands: [Command]

    static func load(specs: [String], in path: String) throws -> [TestCase] {
        let specs = specs.map { name in name.hasSuffix(".json") ? name : name + ".json" }

        let fileManager = FileManager.default
        let filePaths = try fileManager.contentsOfDirectory(atPath: path).filter { $0.hasSuffix("json") }
        guard !filePaths.isEmpty else {
            return []
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        var testCases: [TestCase] = []
        for filePath in filePaths where specs.isEmpty || specs.contains(filePath) {
            print("loading \(filePath)")
            guard let data = fileManager.contents(atPath: path + "/" + filePath) else {
                assertionFailure("failed to load \(filePath)")
                continue
            }

            let spec = try jsonDecoder.decode(TestCase.self, from: data)
            testCases.append(spec)
        }

        return testCases
    }
}

enum Result {
    case passed
    case failed(String)
    case skipped(String)
    case timeout
    case `internal`(Swift.Error)

    var banner: String {
        switch self {
        case .passed: return "[PASSED]".green
        case .failed: return "[FAILED]".red
        case .skipped: return "[SKIPPED]".blue
        case .timeout: return "[TIMEOUT]".yellow
        case .internal: return "[INTERNAL]".white.onRed
        }
    }
}

extension TestCase {
    func run(rootPath: String, handler: @escaping (TestCase, TestCase.Command, Result) -> Void) {
        for command in commands {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                command.run(rootPath: rootPath) { command, result in
                    handler(self, command, result)
                    semaphore.signal()
                }
            }
            if semaphore.wait(timeout: .now() + 5) == .timedOut {
                handler(self, command, .timeout)
            }
        }
    }
}

extension TestCase.Command {
    func run(rootPath: String, handler: (TestCase.Command, Result) -> Void) {
        guard moduleType != .text else {
            return handler(self, .skipped("module type is text"))
        }

        guard let filename = filename else {
            return handler(self, .skipped("no filename"))
        }

        let url = URL(fileURLWithPath: rootPath).appendingPathComponent(filename)
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: url)
        } catch {
            handler(self, .internal(error))
            return
        }
        defer { fileHandle.closeFile() }

        let stream = FileHandleStream(fileHandle: fileHandle)

        var module: Module?
        var error: Swift.Error?

        do {
            module = try WASMParser.parse(stream: stream)
        } catch let e {
            error = e
        }

        switch type {
        case .module:
            guard module != nil else {
                if let error = error {
                    return handler(self, .failed("module could not be parsed: \(error)"))
                } else {
                    return handler(self, .failed("module could not be parsed: unknown error"))
                }
            }
            return handler(self, .passed)
        case .assertMalformed:
            guard let error = error else {
                return handler(self, .failed("module should not be parsed: expected \"\(text ?? "null")\""))
            }
            guard error.text == text else {
                return handler(self, .failed("unexpected error: expected \"\(text ?? "null")\" but got \(error)"))
            }
            return handler(self, .passed)
        default:
            return handler(self, .failed("nothing to test found"))
        }
    }
}

extension Swift.Error {
    var text: String {
        if let error = self as? Parser.Error<UInt8> {
            switch error {
            case .unexpectedEnd(expected: _):
                return "unexpected end"
            default: break
            }
        }

        if let error = self as? WASMParserError {
            switch error {
            case .invalidMagicNumber:
                return "magic header not detected"
            case .unknownVersion:
                return "unknown binary version"
            case .zeroExpected:
                return "zero flag expected"
            case .inconsistentFunctionAndCodeLength:
                return "function and code section have inconsistent lengths"
            default: break
            }
        }

        if let error = self as? LEBError {
            switch error {
            case .overflow:
                return "integer too large"
            default: break
            }
        }

        return "unknown error"
    }
}
