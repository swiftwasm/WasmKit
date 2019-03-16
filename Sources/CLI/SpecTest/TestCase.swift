import Foundation
import LEB
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

        struct Value: Decodable {
            enum ValueType: String, Decodable {
                case i32
                case i64
                case f32
                case f64
            }
            let type: ValueType
            let value: String
        }

        struct Action: Decodable {
            enum ActionType: String, Decodable {
                case invoke
            }

            let type: ActionType
            let field: String
            let args: [Value]
        }

        let type: CommandType
        let line: Int
        let filename: String?
        let text: String?
        let moduleType: ModuleType?
        let action: Action?
        let expected: [Value]?
    }

    let sourceFilename: String
    let commands: [Command]

    static func load(specs specFilter: [String], in path: String) throws -> [TestCase] {
        let specFilter = specFilter.map { name in name.hasSuffix(".json") ? name : name + ".json" }

        let fileManager = FileManager.default
        let filePaths = try fileManager.contentsOfDirectory(atPath: path).filter { $0.hasSuffix("json") }.sorted()
        guard !filePaths.isEmpty else {
            return []
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        var testCases: [TestCase] = []
        for filePath in filePaths where specFilter.isEmpty || specFilter.contains(filePath) {
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
        let runtime = Runtime()
        var currentModuleInstance: ModuleInstance?
        for command in commands {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                command.run(runtime: runtime, module: &currentModuleInstance, rootPath: rootPath) { command, result in
                    handler(self, command, result)
                    semaphore.signal()
                }
            }
            if semaphore.wait(timeout: .distantFuture /*.now() + 5*/) == .timedOut {
                handler(self, command, .timeout)
            }
        }
    }
}

extension TestCase.Command {
    func run(runtime: Runtime, module currentModuleInstance: inout ModuleInstance?, rootPath: String, handler: (TestCase.Command, Result) -> Void) {
        guard moduleType != .text else {
            return handler(self, .skipped("module type is text"))
        }

        switch type {
        case .module:
            guard let filename = filename else {
                return handler(self, .skipped("type is \(type), but no filename specified"))
            }

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, filename: filename)
            } catch let error {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                currentModuleInstance = try runtime.instantiate(module: module, externalValues: [])
            } catch let error {
                return handler(self, .failed("module could not be instanciated: \(error)"))
            }

            return handler(self, .passed)
        case .assertMalformed:
            guard let filename = filename else {
                return handler(self, .skipped("type is \(type), but no filename specified"))
            }

            var error: Error?
            do {
                _ = try parseModule(rootPath: rootPath, filename: filename)
            } catch let e {
                error = e
            }

            guard let e = error, e.text == text else {
                return handler(self, .failed("module should not be parsed: expected \"\(text ?? "null")\""))
            }
            return handler(self, .passed)
        case .assertReturn:
            guard let action = action else {
                return handler(self, .failed("type is \(type), but no action specified"))
            }
            guard let moduleInstance = currentModuleInstance else {
                return handler(self, .failed("type is \(type), but no current module"))
            }
            switch action.type {
            case .invoke:
                let args = parseValues(args: action.args)
                let expected = parseValues(args: self.expected ?? [])
                let result: [WAKit.Value]
                do {
                    result = try runtime.invoke(moduleInstance, function: action.field, with: args)
                } catch let error {
                    return handler(self, .failed("\(error)"))
                }
                guard result == expected else {
                    return handler(self, .failed("result mismatch: expected: \(expected), actual: \(result)"))
                }
                handler(self, .passed)
            }
        default:
            return handler(self, .failed("nothing to test found"))
        }
    }

    private func parseModule(rootPath: String, filename: String) throws -> Module {
        let url = URL(fileURLWithPath: rootPath).appendingPathComponent(filename)
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { fileHandle.closeFile() }

        let stream = FileHandleStream(fileHandle: fileHandle)

        let module = try WASMParser.parse(stream: stream)
        return module
    }

    private func parseValues(args: [TestCase.Command.Value]) -> [WAKit.Value] {
        return args.map {
            switch $0.type {
            case .i32: return I32(UInt32($0.value)!)
            case .i64: return I64(UInt64($0.value)!)
            case .f32: return F32(Float32($0.value)!)
            case .f64: return F64(Float64($0.value)!)
            }
        }
    }
}

extension Swift.Error {
    var text: String {
        if let error = self as? StreamError<UInt8> {
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
            case .invalidUTF8:
                return "invalid UTF-8 encoding"
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
