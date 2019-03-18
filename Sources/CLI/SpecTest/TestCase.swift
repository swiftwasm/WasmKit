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

        enum ValueType: String, Decodable {
            case i32
            case i64
            case f32
            case f64
        }

        struct Value: Decodable {
            let type: ValueType
            let value: String
        }

        struct Expectation: Decodable {
            let type: ValueType
            let value: String?
        }

        struct Action: Decodable {
            enum ActionType: String, Decodable {
                case invoke
                case get
            }

            let type: ActionType
            let field: String
            let args: [Value]?
        }

        let type: CommandType
        let line: Int
        let filename: String?
        let text: String?
        let moduleType: ModuleType?
        let action: Action?
        let expected: [Expectation]?
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
    case `internal`(Swift.Error)

    var banner: String {
        switch self {
        case .passed: return "[PASSED]".green
        case .failed: return "[FAILED]".red
        case .skipped: return "[SKIPPED]".blue
        case .internal: return "[INTERNAL]".white.onRed
        }
    }
}

extension TestCase {
    func run(rootPath: String, handler: @escaping (TestCase, TestCase.Command, Result) -> Void) {
        let runtime = Runtime()
        var currentModuleInstance: ModuleInstance?
        let queue = DispatchQueue(label: "sh.aky.WAKit.spectest")
        let semaphore = DispatchSemaphore(value: 0)
        for command in commands {
            queue.async {
                command.run(runtime: runtime, module: &currentModuleInstance, rootPath: rootPath) { command, result in
                    handler(self, command, result)
                    semaphore.signal()
                }
            }

            guard semaphore.wait(timeout: .now() + 5) != .timedOut else {
                semaphore.resume()
                return handler(self, command, .failed("timed out"))
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
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                currentModuleInstance = try runtime.instantiate(module: module, externalValues: [])
            } catch {
                return handler(self, .failed("module could not be instantiated: \(error)"))
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
                let args = parseValues(args: action.args!)
                let expected = parseValues(args: self.expected ?? [])
                let result: [WAKit.Value]
                do {
                    result = try runtime.invoke(moduleInstance, function: action.field, with: args)
                } catch {
                    return handler(self, .failed("\(error)"))
                }
                guard result == expected else {
                    return handler(self, .failed("result mismatch: expected: \(expected), actual: \(result)"))
                }
                handler(self, .passed)
            default:
                handler(self, .failed("action type \(action.type) has been not implemented"))
            }
        default:
            handler(self, .failed("type \(type) has been not implemented"))
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

    private func parseValues(args: [TestCase.Command.Expectation]) -> [WAKit.Value] {
        return args.compactMap {
            switch $0.type {
            case .i32: return I32(UInt32($0.value!)!)
            case .i64: return I64(UInt64($0.value!)!)
            case .f32: return F32(Float32($0.value!)!)
            case .f64: return F64(Float64($0.value!)!)
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
