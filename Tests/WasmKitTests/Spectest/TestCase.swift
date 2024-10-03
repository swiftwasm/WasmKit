import Foundation
import SystemPackage
import WAT
@testable import WasmKit
import WasmParser

struct TestCase {
    enum Error: Swift.Error {
        case invalidPath
    }

    let content: Wast
    let path: String
    var relativePath: String {
        // Relative path from the current working directory
        let currentDirectory = FileManager.default.currentDirectoryPath
        if path.hasPrefix(currentDirectory) {
            return String(path.dropFirst(currentDirectory.count + 1))
        }
        return path
    }

    static func load(include: [String], exclude: [String], in path: [String], log: ((String) -> Void)? = nil) throws -> [TestCase] {
        let fileManager = FileManager.default
        var filePaths: [URL] = []
        for path in path {
            let filePath = FilePath(path)
            if isDirectory(filePath) {
                filePaths += try self.computeTestSources(inDirectory: filePath, fileManager: fileManager).map {
                    URL(fileURLWithPath: path).appendingPathComponent($0)
                }
            } else if fileManager.isReadableFile(atPath: path) {
                let url = URL(fileURLWithPath: path)
                filePaths += [url]
            } else {
                throw Error.invalidPath
            }
        }

        guard !filePaths.isEmpty else {
            return []
        }

        let matchesPattern: (URL) throws -> Bool = { filePath in
            let fileName = filePath.lastPathComponent
            // FIXME: Skip names.wast until we have .wat/.wast parser
            // "names.wast" contains BOM in some test cases and they are parsed
            // as empty string in JSONDecoder because there is no way to express
            // it in UTF-8.
            guard fileName != "names.wast" else { return false }
            // FIXME: Skip SIMD proposal tests for now
            guard !fileName.starts(with: "simd_") else { return false }

            let patternPredicate = { pattern in filePath.path.hasSuffix(pattern) }
            if !include.isEmpty {
                return include.contains(where: patternPredicate)
            }
            guard !exclude.contains(where: patternPredicate) else { return false }
            return true
        }

        var testCases: [TestCase] = []
        for filePath in filePaths where try matchesPattern(filePath) {
            guard let data = fileManager.contents(atPath: filePath.path) else {
                assertionFailure("failed to load \(filePath)")
                continue
            }

            let wast = try parseWAST(String(data: data, encoding: .utf8)!)
            let spec = TestCase(content: wast, path: filePath.path)
            testCases.append(spec)
        }

        return testCases
    }

    /// Returns list of `.json` paths recursively found under `rootPath`. They are relative to `rootPath`.
    static func computeTestSources(inDirectory rootPath: FilePath, fileManager: FileManager) throws -> [String] {
        return try fileManager.contentsOfDirectory(atPath: rootPath.string).filter {
            $0.hasSuffix(".wast")
        }
    }
}

enum Result {
    case passed
    case failed(String)
    case skipped(String)
//    case `internal`(Swift.Error)

    var banner: String {
        switch self {
        case .passed:
            return "[PASSED]"
        case .failed:
            return "[FAILED]"
        case .skipped:
            return "[SKIPPED]"
//        case .internal:
//            return "[INTERNAL]"
        }
    }
}

struct SpectestError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}

class WastRunContext {
    let store: Store
    var engine: Engine { store.engine }
    let rootPath: String
    private var namedModuleInstances: [String: Instance] = [:]
    var currentInstance: Instance?
    var importsSpace = Imports()

    init(store: Store, rootPath: String) {
        self.store = store
        self.rootPath = rootPath
    }

    func lookupInstance(_ name: String) -> Instance? {
        return namedModuleInstances[name]
    }
    func register(_ name: String, instance: Instance) {
        self.namedModuleInstances[name] = instance
    }
}

extension TestCase {
    func run(spectestModule: Module, configuration: EngineConfiguration, handler: @escaping (TestCase, Location, Result) -> Void) throws {
        let engine = Engine(configuration: configuration)
        let store = Store(engine: engine)
        let spectestInstance = try spectestModule.instantiate(store: store)

        let rootPath = FilePath(path).removingLastComponent().string
        var content = content
        let context = WastRunContext(store: store, rootPath: rootPath)
        context.importsSpace.define(module: "spectest", spectestInstance.exports)
        do {
            while let (directive, location) = try content.nextDirective() {
                do {
                    if let result = try context.run(directive: directive) {
                        handler(self, location, result)
                    }
                } catch let error as SpectestError {
                    handler(self, location, .failed(error.description))
                }
            }
        } catch let parseError as WatParserError {
            if let location = parseError.location {
                handler(self, location, .failed(parseError.message))
            } else {
                throw parseError
            }
        }
    }
}

extension WastRunContext {
    func instantiate(module: Module, name: String? = nil) throws -> Instance {
        let instance = try module.instantiate(store: store, imports: importsSpace)
        if let name {
            register(name, instance: instance)
        }
        return instance
    }
    func deriveInstance(by name: String?) throws -> Instance {
        let instance: Instance?
        if let name {
            instance = lookupInstance(name)
        } else {
            instance = currentInstance
        }
        guard let instance else {
            throw SpectestError("no module to execute")
        }
        return instance
    }
    func deriveInstance(from execute: WastExecute) throws -> Instance? {
        switch execute {
        case .invoke(let invoke):
            if let module = invoke.module {
                return lookupInstance(module)
            } else {
                return currentInstance
            }
        case .wat(var wat):
            let module = try parseModule(rootPath: rootPath, moduleSource: .binary(wat.encode()))
            let instance = try instantiate(module: module)
            return instance
        case .get(let module, _):
            if let module {
                return lookupInstance(module)
            } else {
                return currentInstance
            }
        }
    }

    func run(directive: WastDirective) throws -> Result? {
        switch directive {
        case .module(let moduleDirective):
            currentInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: moduleDirective.source)
            } catch {
                return .failed("module could not be parsed: \(error)")
            }

            do {
                currentInstance = try instantiate(module: module, name: moduleDirective.id)
            } catch {
                return .failed("module could not be instantiated: \(error)")
            }

            return .passed

        case .register(let name, let moduleId):
            let instance: Instance
            if let moduleId {
                guard let found = self.lookupInstance(moduleId) else {
                    return .failed("module \(moduleId) not found")
                }
                instance = found
            } else {
                guard let currentInstance else {
                    return .failed("no current module to register")
                }
                instance = currentInstance
            }
            importsSpace.define(module: name, instance.exports)
            return nil

        case .assertMalformed(let module, let message):
            currentInstance = nil
            do {
                let module = try parseModule(rootPath: rootPath, moduleSource: module.source)
                let instance = try instantiate(module: module)
                // Materialize all functions to see all errors in the module
                try instance.handle.withValue { try $0.compileAllFunctions(store: store) }
            } catch {
                return .passed
            }
            return .failed("module should not be parsed: expected \"\(message)\"")

        case .assertTrap(execute: .wat(var wat), let message):
            currentInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: .binary(wat.encode()))
            } catch {
                return .failed("module could not be parsed: \(error)")
            }

            do {
                _ = try instantiate(module: module)
            } catch let error as InstantiationError {
                guard error.assertionText.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(error.assertionText)")
                }
            } catch let error as Trap {
                guard error.assertionText.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(error.assertionText)")
                }
            } catch {
                return .failed("\(error)")
            }
            return .passed

        case .assertReturn(let execute, let results):
            let expected = parseValues(args: results)
            let actual = try wastExecute(execute: execute)
            guard actual.isTestEquivalent(to: expected) else {
                return .failed("invoke result mismatch: expected: \(expected), actual: \(actual)")
            }
            return .passed
        case .assertTrap(let execute, let message):
            switch execute {
            case .invoke(let invoke):
                do {
                    _ = try wastInvoke(call: invoke)
                    return .failed("trap expected: \(message)")
                } catch let trap as Trap {
                    guard trap.assertionText.contains(message) else {
                        return .failed("assertion mismatch: expected: \(message), actual: \(trap.assertionText)")
                    }
                    return .passed
                } catch {
                    return .failed("\(error)")
                }
            default:
                return .failed("assert_trap is not implemented non-invoke actions")
            }
        case .assertExhaustion(let call, let message):
            do {
                _ = try wastInvoke(call: call)
                return .failed("trap expected: \(message)")
            } catch let trap as Trap {
                guard trap.assertionText.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(trap.assertionText)")
                }
                return .passed
            }
        case .assertUnlinkable(let wat, let message):
            currentInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: .text(wat))
            } catch {
                return .failed("module could not be parsed: \(error)")
            }

            do {
                _ = try instantiate(module: module)
            } catch let error as ImportError {
                guard error.assertionText.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(error.assertionText)")
                }
            } catch {
                return .failed("\(error)")
            }
            return .passed

        case .assertInvalid:
            return .skipped("validation is no implemented yet")

        case .invoke(let invoke):
            do {
                _ = try wastInvoke(call: invoke)
            } catch {
                return .failed("\(error)")
            }
            return .passed
        }
    }

    private func wastExecute(execute: WastExecute) throws -> [Value] {
        switch execute {
        case .invoke(let invoke):
            return try wastInvoke(call: invoke)
        case .get(let module, let globalName):
            let instance = try deriveInstance(by: module)
            let result: WasmKit.Value
            guard case let .global(global) = instance.export(globalName) else {
                throw SpectestError("no global export with name \(globalName) in a module instance \(instance)")
            }
            return [global.value]
        case .wat(var wat):
            let module = try parseModule(rootPath: rootPath, moduleSource: .binary(wat.encode()))
            _ = try instantiate(module: module)
            return []
        }
    }

    private func wastInvoke(call: WastInvoke) throws -> [Value] {
        let instance = try deriveInstance(by: call.module)
        guard let function = instance.exportedFunction(name: call.name) else {
            throw SpectestError("function \(call.name) not exported")
        }
        return try function.invoke(call.args)
    }

    private func deriveFeatureSet(rootPath: FilePath) -> WasmFeatureSet {
        var features = WasmFeatureSet.default
        if rootPath.ends(with: "proposals/memory64") {
            features.insert(.memory64)
        }
        return features
    }

    private func parseModule(rootPath: String, filename: String) throws -> Module {
        let rootPath = FilePath(rootPath)
        let path = rootPath.appending(filename)

        let module = try parseWasm(filePath: path, features: deriveFeatureSet(rootPath: rootPath))
        return module
    }

    private func parseModule(rootPath: String, moduleSource: ModuleSource) throws -> Module {
        let rootPath = FilePath(rootPath)
        let binary: [UInt8]
        switch moduleSource {
        case .text(var watModule):
            binary = try watModule.encode()
        case .quote(let text):
            binary = try wat2wasm(String(decoding: text, as: UTF8.self))
        case .binary(let bytes):
            binary = bytes
        }

        let module = try parseWasm(bytes: binary, features: deriveFeatureSet(rootPath: rootPath))
        return module
    }

    private func parseValues(args: [WastExpectValue]) -> [WasmKit.Value] {
        return args.compactMap {
            switch $0 {
            case .value(let value): return value
            case .f32CanonicalNaN, .f32ArithmeticNaN: return .f32(Float.nan.bitPattern)
            case .f64CanonicalNaN, .f64ArithmeticNaN: return .f64(Double.nan.bitPattern)
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

#if os(Windows)
    import WinSDK
#endif
internal func isDirectory(_ path: FilePath) -> Bool {
    #if os(Windows)
        return path.withPlatformString {
            let result = GetFileAttributesW($0)
            return result != INVALID_FILE_ATTRIBUTES && result & DWORD(FILE_ATTRIBUTE_DIRECTORY) != 0
        }
    #else
        let fd = try? FileDescriptor.open(path, FileDescriptor.AccessMode.readOnly, options: .directory)
        let isDirectory = fd != nil
        try? fd?.close()
        return isDirectory
    #endif
}
