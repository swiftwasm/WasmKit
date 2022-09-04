import Foundation
import LEB
import Rainbow
import SystemPackage
import WAKit

struct TestCase: Decodable {
    enum Error: Swift.Error {
        case invalidPath
    }
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
            case externref
            case funcref
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

    static func load(include: [String], exclude: [String], in path: String) throws -> [TestCase] {
        let fileManager = FileManager.default
        let filePath = FilePath(path)
        let dirPath: String
        let filePaths: [String]
        if (try? FileDescriptor.open(filePath, FileDescriptor.AccessMode.readOnly, options: .directory)) != nil {
            dirPath = path
            filePaths = try fileManager.contentsOfDirectory(atPath: path).filter { $0.hasSuffix("json") }.sorted()
        } else if fileManager.isReadableFile(atPath: path) {
            let url = URL(fileURLWithPath: path)
            dirPath = url.deletingLastPathComponent().path
            filePaths = [url.lastPathComponent]
        } else {
            throw Error.invalidPath
        }

        guard !filePaths.isEmpty else {
            return []
        }

        let matchesPattern: (String) throws -> Bool = { filePath in
            let filePath = filePath.hasSuffix(".json") ? String(filePath.dropLast(".json".count)) : filePath
            guard !exclude.contains(filePath) else { return false }
            guard !include.isEmpty else { return true }
            return include.contains(filePath)
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        var testCases: [TestCase] = []
        for filePath in filePaths where try matchesPattern(filePath) {
            print("loading \(filePath)")
            guard let data = fileManager.contents(atPath: dirPath + "/" + filePath) else {
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
            currentModuleInstance = nil

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
            currentModuleInstance = nil

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
            guard case .invoke = action.type else {
                return handler(self, .failed("action type \(action.type) has been not implemented for \(type.rawValue)"))
            }

            let args = parseValues(args: action.args!)
            let expected = parseValues(args: self.expected ?? [])
            let result: [WAKit.Value]
            do {
                result = try runtime.invoke(moduleInstance, function: action.field, with: args)
            } catch {
                return handler(self, .failed("\(error)"))
            }
            guard result.isTestEquivalent(to: expected) else {
                return handler(self, .failed("result mismatch: expected: \(expected), actual: \(result)"))
            }
            return handler(self, .passed)

        case .assertTrap:
            guard let action = action else {
                return handler(self, .failed("type is \(type), but no action specified"))
            }
            guard let moduleInstance = currentModuleInstance else {
                return handler(self, .failed("type is \(type), but no current module"))
            }
            guard case .invoke = action.type else {
                return handler(self, .failed("action type \(action.type) has been not implemented for \(type.rawValue)"))
            }

            let args = parseValues(args: action.args!)
            do {
                _ = try runtime.invoke(moduleInstance, function: action.field, with: args)
            } catch let trap as Trap {
                guard trap.assertionText == text else {
                    return handler(self, .failed("assertion mismatch: expected: \(text!), actual: \(trap.assertionText)"))
                }
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        default:
            return handler(self, .failed("type \(type) has been not implemented"))
        }
    }

    private func parseModule(rootPath: String, filename: String) throws -> Module {
        let url = URL(fileURLWithPath: rootPath).appendingPathComponent(filename)
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { fileHandle.closeFile() }

        let stream = FileHandleStream(fileHandle: fileHandle)

        let module = try WasmParser.parse(stream: stream)
        return module
    }

    private func parseValues(args: [TestCase.Command.Value]) -> [WAKit.Value] {
        return args.map {
            switch $0.type {
            case .i32: return .i32(UInt32($0.value)!)
            case .i64: return .i64(UInt64($0.value)!)
            case .f32 where $0.value.starts(with: "nan:"): return .f32(Float32.nan)
            case .f32: return .f32(Float32(bitPattern: UInt32($0.value)!))
            case .f64 where $0.value.starts(with: "nan:"): return .f64(Float64.nan)
            case .f64: return .f64(Float64(bitPattern: UInt64($0.value)!))
            case .externref:
                fatalError("externref is not currently supported")
            case .funcref:
                fatalError("funcref is not currently supported")
            }
        }
    }

    private func parseValues(args: [TestCase.Command.Expectation]) -> [WAKit.Value] {
        return args.compactMap {
            switch $0.type {
            case .i32: return .i32(UInt32($0.value!)!)
            case .i64: return .i64(UInt64($0.value!)!)
            case .f32 where $0.value!.starts(with: "nan:"): return .f32(Float32.nan)
            case .f32: return .f32(Float32(bitPattern: UInt32($0.value!)!))
            case .f64 where $0.value!.starts(with: "nan:"): return .f64(Float64.nan)
            case .f64: return .f64(Float64(bitPattern: UInt64($0.value!)!))
            case .externref:
                fatalError("externref is not currently supported")
            case .funcref:
                fatalError("funcref is not currently supported")
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

        if let error = self as? WasmParserError {
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
