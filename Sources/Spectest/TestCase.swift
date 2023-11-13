import Foundation
import SystemPackage
import WasmKit

struct TestCase {
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
            let module: String?
            let field: String
            let args: [Value]?
        }

        let type: CommandType
        let line: Int
        let `as`: String?
        let name: String?
        let filename: String?
        let text: String?
        let moduleType: ModuleType?
        let action: Action?
        let expected: [Expectation]?
    }

    struct Content: Decodable {
        let sourceFilename: String
        let commands: [Command]
    }

    let content: Content
    let path: String

    private static func isDirectory(_ path: FilePath) -> Bool {
        let fd = try? FileDescriptor.open(path, FileDescriptor.AccessMode.readOnly, options: .directory)
        let isDirectory = fd != nil
        try? fd?.close()
        return isDirectory
    }

    static func load(include: [String], exclude: [String], in path: String, log: ((String) -> Void)? = nil) throws -> [TestCase] {
        let fileManager = FileManager.default
        let filePath = FilePath(path)
        let dirPath: String
        let filePaths: [String]
        if isDirectory(filePath) {
            dirPath = path
            filePaths = try self.computeTestSources(inDirectory: filePath, fileManager: fileManager)
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
            // FIXME: Skip names.wast until we have .wat/.wast parser
            // "names.wast" contains BOM in some test cases and they are parsed
            // as empty string in JSONDecoder because there is no way to express
            // it in UTF-8.
            guard filePath != "names.json" else { return false }
            // FIXME: Skip SIMD proposal tests for now
            guard !filePath.starts(with: "simd_") else { return false }

            let filePath = filePath.hasSuffix(".json") ? String(filePath.dropLast(".json".count)) : filePath
            guard !exclude.contains(filePath) else { return false }
            guard !include.isEmpty else { return true }
            return include.contains(filePath)
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

        var testCases: [TestCase] = []
        for filePath in filePaths where try matchesPattern(filePath) {
            log?("loading \(filePath)")
            let path = dirPath + "/" + filePath
            guard let data = fileManager.contents(atPath: path) else {
                assertionFailure("failed to load \(filePath)")
                continue
            }

            let content = try jsonDecoder.decode(TestCase.Content.self, from: data)
            let spec = TestCase(content: content, path: path)
            testCases.append(spec)
        }

        return testCases
    }

    /// Returns list of `.json` paths recursively found under `rootPath`. They are relative to `rootPath`.
    static func computeTestSources(inDirectory rootPath: FilePath, fileManager: FileManager) throws -> [String] {
        var queue: [String] = [rootPath.string]
        var contents: [String] = []

        while let dirPath = queue.popLast() {
            let dirContents = try fileManager.contentsOfDirectory(atPath: dirPath)
            contents += dirContents.filter { $0.hasSuffix(".json") }.map { dirPath + "/" + $0 }
            queue += dirContents.filter { isDirectory(FilePath(dirPath + "/" + $0)) }.map { dirPath + "/" + $0 }
        }

        return contents.map { String($0.dropFirst(rootPath.string.count + 1)) }
    }
}

enum Result {
    case passed
    case failed(String)
    case skipped(String)
    case `internal`(Swift.Error)

    var banner: String {
        switch self {
        case .passed:
            return "[PASSED]"
        case .failed:
            return "[FAILED]"
        case .skipped:
            return "[SKIPPED]"
        case .internal:
            return "[INTERNAL]"
        }
    }
}

extension TestCase {
    func run(spectestModule: Module, handler: @escaping (TestCase, TestCase.Command, Result) -> Void) throws {
        let runtime = Runtime()
        let hostModuleInstance = try runtime.instantiate(module: spectestModule)

        try runtime.store.register(hostModuleInstance, as: "spectest")

        var currentModuleInstance: ModuleInstance?
        let rootPath = FilePath(path).removingLastComponent().string
        for command in content.commands {
            command.run(
                runtime: runtime,
                module: &currentModuleInstance,
                rootPath: rootPath
            ) { command, result in
                handler(self, command, result)
            }
        }
    }
}

extension TestCase.Command {
    func run(
        runtime: Runtime,
        module currentModuleInstance: inout ModuleInstance?,
        rootPath: String,
        handler: (TestCase.Command, Result) -> Void
    ) {
        guard moduleType != .text else {
            return handler(self, .skipped("module type is text"))
        }

        switch type {
        case .module:
            currentModuleInstance = nil

            guard let filename else {
                return handler(self, .skipped("type is \(type), but no filename specified"))
            }

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, filename: filename)
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                currentModuleInstance = try runtime.instantiate(module: module, name: name)
            } catch {
                return handler(self, .failed("module could not be instantiated: \(error)"))
            }

            return handler(self, .passed)

        case .register:
            guard let name = `as`, let currentModuleInstance else {
                fatalError("`register` command without a module name")
            }

            do {
                try runtime.store.register(currentModuleInstance, as: name)
            } catch {
                return handler(self, .failed("module could not be registered: \(error)"))
            }

        case .assertMalformed:
            currentModuleInstance = nil

            guard let filename else {
                return handler(self, .skipped("type is \(type), but no filename specified"))
            }

            do {
                var module = try parseModule(rootPath: rootPath, filename: filename)
                // Materialize all functions to see all errors in the module
                try module.materializeAll()
            } catch {
                return handler(self, .passed)
            }
            return handler(self, .failed("module should not be parsed: expected \"\(text ?? "null")\""))

        case .assertUninstantiable:
            currentModuleInstance = nil

            guard let filename else {
                return handler(self, .skipped("type is \(type), but no filename specified"))
            }

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, filename: filename)
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                _ = try runtime.instantiate(module: module)
            } catch let error as InstantiationError {
                guard error.assertionText == text else {
                    return handler(self, .failed("assertion mismatch: expected: \(text!), actual: \(error.assertionText)"))
                }
            } catch let error as Trap {
                guard error.assertionText == text else {
                    return handler(self, .failed("assertion mismatch: expected: \(text!), actual: \(error.assertionText)"))
                }
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        case .assertReturn:
            guard let action else {
                return handler(self, .failed("type is \(type), but no action specified"))
            }

            let moduleInstance: ModuleInstance?
            if let name = action.module {
                moduleInstance = runtime.store.namedModuleInstances[name]
            } else {
                moduleInstance = currentModuleInstance
            }

            guard let moduleInstance else {
                return handler(self, .failed("type is \(type), but no current module"))
            }

            let expected = parseValues(args: self.expected ?? [])

            switch action.type {
            case .invoke:
                let args = parseValues(args: action.args!)
                let result: [WasmKit.Value]
                do {
                    result = try runtime.invoke(moduleInstance, function: action.field, with: args)
                } catch {
                    return handler(self, .failed("\(error)"))
                }
                guard result.isTestEquivalent(to: expected) else {
                    return handler(self, .failed("invoke result mismatch: expected: \(expected), actual: \(result)"))
                }
                return handler(self, .passed)

            case .get:
                let result: WasmKit.Value
                do {
                    result = try runtime.getGlobal(moduleInstance, globalName: action.field)
                } catch {
                    return handler(self, .failed("\(error)"))
                }
                guard result.isTestEquivalent(to: expected[0]) else {
                    return handler(self, .failed("get result mismatch: expected: \(expected), actual: \(result)"))
                }
                return handler(self, .passed)
            }

        case .assertTrap, .assertExhaustion:
            guard let action else {
                return handler(self, .failed("type is \(type), but no action specified"))
            }
            let moduleInstance: ModuleInstance?
            if let name = action.module {
                moduleInstance = runtime.store.namedModuleInstances[name]
            } else {
                moduleInstance = currentModuleInstance
            }

            guard let moduleInstance else {
                return handler(self, .failed("type is \(type), but no current module"))
            }
            guard case .invoke = action.type else {
                return handler(self, .failed("action type \(action.type) has been not implemented for \(type.rawValue)"))
            }

            let args = parseValues(args: action.args!)
            do {
                _ = try runtime.invoke(moduleInstance, function: action.field, with: args)
            } catch let trap as Trap {
                if let text {
                    guard trap.assertionText.contains(text) else {
                        return handler(self, .failed("assertion mismatch: expected: \(text), actual: \(trap.assertionText)"))
                    }
                }
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        case .assertUnlinkable:
            currentModuleInstance = nil

            guard let filename else {
                return handler(self, .skipped("type is \(type), but no filename specified"))
            }

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, filename: filename)
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                _ = try runtime.instantiate(module: module)
            } catch let error as ImportError {
                guard error.assertionText == text else {
                    return handler(self, .failed("assertion mismatch: expected: \(text!), actual: \(error.assertionText)"))
                }
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        case .assertInvalid:
            return handler(self, .skipped("validation is no implemented yet"))

        case .action:
            guard let action else {
                return handler(self, .failed("type is \(type), but no action specified"))
            }

            guard let currentModuleInstance else {
                return handler(self, .failed("type is \(type), but no current module"))
            }

            guard case .invoke = action.type else {
                return handler(self, .failed("action type \(action.type) is not implemented for \(type.rawValue)"))
            }

            let args = parseValues(args: action.args!)

            do {
                _ = try runtime.invoke(currentModuleInstance, function: action.field, with: args)
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        default:
            return handler(self, .failed("type \(type) is not implemented yet"))
        }
    }

    private func deriveFeatureSet(rootPath: String) -> WasmFeatureSet {
        var features = WasmFeatureSet.default
        if rootPath.hasSuffix("/proposals/memory64") {
            features.insert(.memory64)
            // memory64 doesn't expect reference-types proposal
            // and it depends on the fact reference-types is disabled
            features.remove(.referenceTypes)
        }
        return features
    }

    private func parseModule(rootPath: String, filename: String) throws -> Module {
        let url = URL(fileURLWithPath: rootPath).appendingPathComponent(filename)

        let module = try parseWasm(filePath: FilePath(url.path), features: deriveFeatureSet(rootPath: rootPath))
        return module
    }

    private func parseValues(args: [TestCase.Command.Value]) -> [WasmKit.Value] {
        return args.map {
            switch $0.type {
            case .i32: return .i32(UInt32($0.value)!)
            case .i64: return .i64(UInt64($0.value)!)
            case .f32 where $0.value.starts(with: "nan:"): return .f32(Float32.nan.bitPattern)
            case .f32: return .f32(UInt32($0.value)!)
            case .f64 where $0.value.starts(with: "nan:"): return .f64(Float64.nan.bitPattern)
            case .f64: return .f64(UInt64($0.value)!)
            case .externref:
                return .ref(.extern(ExternAddress($0.value)))
            case .funcref:
                return .ref(.function(FunctionAddress($0.value)))
            }
        }
    }

    private func parseValues(args: [TestCase.Command.Expectation]) -> [WasmKit.Value] {
        return args.compactMap {
            switch $0.type {
            case .i32: return .i32(UInt32($0.value!)!)
            case .i64: return .i64(UInt64($0.value!)!)
            case .f32 where $0.value!.starts(with: "nan:"): return .f32(Float32.nan.bitPattern)
            case .f32: return .f32(UInt32($0.value!)!)
            case .f64 where $0.value!.starts(with: "nan:"): return .f64(Float64.nan.bitPattern)
            case .f64: return .f64(UInt64($0.value!)!)
            case .externref:
                return .ref(.extern(ExternAddress($0.value!)))
            case .funcref:
                return .ref(.function(FunctionAddress($0.value!)))
            }
        }
    }
}

extension Value {
    func isTestEquivalent(to value: Self) -> Bool {
        switch (self, value) {
        case let (.i32(lhs), .i32(rhs)):
            return lhs == rhs
        case let (.i64(lhs), .i64(rhs)):
            return lhs == rhs
        case let (.f32(lhs), .f32(rhs)):
            let lhs = Float32(bitPattern: lhs)
            let rhs = Float32(bitPattern: rhs)
            return lhs.isNaN && rhs.isNaN || lhs == rhs
        case let (.f64(lhs), .f64(rhs)):
            let lhs = Float64(bitPattern: lhs)
            let rhs = Float64(bitPattern: rhs)
            return lhs.isNaN && rhs.isNaN || lhs == rhs
        case let (.ref(.extern(lhs)), .ref(.extern(rhs))):
            return lhs == rhs
        case let (.ref(.function(lhs)), .ref(.function(rhs))):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Array where Element == Value {
    func isTestEquivalent(to arrayOfValues: Self) -> Bool {
        guard count == arrayOfValues.count else {
            return false
        }

        for (i, value) in enumerated() {
            if !value.isTestEquivalent(to: arrayOfValues[i]) {
                return false
            }
        }

        return true
    }
}

extension Swift.Error {
    var text: String {
        if let error = self as? WasmParserError {
            switch error {
            case .invalidMagicNumber:
                return "magic header not detected"
            case .unknownVersion:
                return "unknown binary version"
            case .invalidUTF8:
                return "malformed UTF-8 encoding"
            case .zeroExpected:
                return "zero byte expected"
            case .inconsistentFunctionAndCodeLength:
                return "function and code section have inconsistent lengths"
            case .tooManyLocals:
                return "too many locals"
            case .invalidSectionSize:
                // XXX: trailing "unexpected end" is just for making spectest happy
                // The reference interpreter raises EOF error when the custom content
                // size is negative[^1], and custom.wast contains a test case that depends
                // on the behavior[^2].
                // [^1]: https://github.com/WebAssembly/spec/blob/653938a88c6f40eb886d5980ca315136eb861d03/interpreter/binary/decode.ml#L20
                // [^2]: https://github.com/WebAssembly/spec/blob/653938a88c6f40eb886d5980ca315136eb861d03/test/core/custom.wast#L76-L82
                return "invalid section size, unexpected end"
            case .malformedSectionID:
                return "malformed section id"
            case .endOpcodeExpected:
                return "END opcode expected"
            case .unexpectedEnd:
                return "unexpected end of section or function"
            case .inconsistentDataCountAndDataSectionLength:
                return "data count and data section have inconsistent lengths"
            case .expectedRefType:
                return "malformed reference type"
            case .unexpectedContent:
                return "unexpected content after last section"
            case .sectionSizeMismatch:
                return "section size mismatch"
            case .illegalOpcode:
                return "illegal opcode"
            case .malformedMutability:
                return "malformed mutability"
            case .integerRepresentationTooLong:
                return "integer representation too long"
            default:
                return String(describing: error)
            }
        }

        return "unknown error: \(self)"
    }
}
