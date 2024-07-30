import Foundation
import SystemPackage
import WAT
import WasmKit
import WasmParser

struct TestCase {
    enum Error: Swift.Error {
        case invalidPath
    }

    let content: Wast
    let path: String

    static func load(include: [String], exclude: [String], in path: [String], log: ((String) -> Void)? = nil) throws -> [TestCase] {
        let fileManager = FileManager.default
        var filePaths: [URL] = []
        for path in path {
            let dirPath: String
            let filePath = FilePath(path)
            if isDirectory(filePath) {
                dirPath = path
                filePaths += try self.computeTestSources(inDirectory: filePath, fileManager: fileManager).map {
                    URL(fileURLWithPath: dirPath).appendingPathComponent($0)
                }
            } else if fileManager.isReadableFile(atPath: path) {
                let url = URL(fileURLWithPath: path)
                dirPath = url.deletingLastPathComponent().path
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

            let toCheck = fileName.hasSuffix(".wast") ? String(fileName.dropLast(".wast".count)) : fileName
            guard !exclude.contains(toCheck) else { return false }
            guard !include.isEmpty else { return true }
            return include.contains(toCheck)
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

extension TestCase {
    func run(spectestModule: Module, handler: @escaping (TestCase, Location, Result) -> Void) throws {
        let runtime = Runtime()
        let hostModuleInstance = try runtime.instantiate(module: spectestModule)

        try runtime.store.register(hostModuleInstance, as: "spectest")

        var currentModuleInstance: ModuleInstance?
        let rootPath = FilePath(path).removingLastComponent().string
        var content = content
        do {
            while let (directive, location) = try content.nextDirective() {
                directive.run(
                    runtime: runtime,
                    module: &currentModuleInstance,
                    rootPath: rootPath
                ) { command, result in
                    handler(self, location, result)
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

extension WastDirective {
    func run(
        runtime: Runtime,
        module currentModuleInstance: inout ModuleInstance?,
        rootPath: String,
        handler: (WastDirective, Result) -> Void
    ) {

        func deriveModuleInstance(from execute: WastExecute) throws -> ModuleInstance? {
            switch execute {
            case .invoke(let invoke):
                if let module = invoke.module {
                    return runtime.store.namedModuleInstances[module]
                } else {
                    return currentModuleInstance
                }
            case .wat(var wat):
                let module = try parseModule(rootPath: rootPath, moduleSource: .binary(wat.encode()))
                let instance = try runtime.instantiate(module: module)
                return instance
            case .get(let module, _):
                if let module {
                    return runtime.store.namedModuleInstances[module]
                } else {
                    return currentModuleInstance
                }
            }
        }

        switch self {
        case .module(let moduleDirective):
            currentModuleInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: moduleDirective.source)
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                currentModuleInstance = try runtime.instantiate(module: module, name: moduleDirective.id)
            } catch {
                return handler(self, .failed("module could not be instantiated: \(error)"))
            }

            return handler(self, .passed)

        case .register(let name, let moduleId):
            let module: ModuleInstance
            if let moduleId {
                guard let found = runtime.store.namedModuleInstances[moduleId] else {
                    return handler(self, .failed("module \(moduleId) not found"))
                }
                module = found
            } else {
                guard let currentModuleInstance else {
                    return handler(self, .failed("no current module to register"))
                }
                module = currentModuleInstance
            }

            do {
                try runtime.store.register(module, as: name)
            } catch {
                return handler(self, .failed("module could not be registered: \(error)"))
            }

        case .assertMalformed(let module, let message):
            currentModuleInstance = nil
            guard case .binary = module.source else {
                return handler(self, .skipped("assert_malformed is only supported for binary modules for now"))
            }

            do {
                var module = try parseModule(rootPath: rootPath, moduleSource: module.source)
                // Materialize all functions to see all errors in the module
                try module.materializeAll()
            } catch {
                return handler(self, .passed)
            }
            return handler(self, .failed("module should not be parsed: expected \"\(message)\""))

        case .assertTrap(execute: .wat(var wat), let message):
            currentModuleInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: .binary(wat.encode()))
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                _ = try runtime.instantiate(module: module)
            } catch let error as InstantiationError {
                guard error.assertionText.contains(message) else {
                    return handler(self, .failed("assertion mismatch: expected: \(message), actual: \(error.assertionText)"))
                }
            } catch let error as Trap {
                guard error.assertionText.contains(message) else {
                    return handler(self, .failed("assertion mismatch: expected: \(message), actual: \(error.assertionText)"))
                }
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        case .assertReturn(let execute, let results):
            let moduleInstance: ModuleInstance?
            do {
                moduleInstance = try deriveModuleInstance(from: execute)
            } catch {
                return handler(self, .failed("failed to derive module instance: \(error)"))
            }
            guard let moduleInstance else {
                return handler(self, .failed("no module to execute"))
            }

            let expected = parseValues(args: results)

            switch execute {
            case .invoke(let invoke):
                let result: [WasmKit.Value]
                do {
                    result = try runtime.invoke(moduleInstance, function: invoke.name, with: invoke.args)
                } catch {
                    return handler(self, .failed("\(error)"))
                }
                guard result.isTestEquivalent(to: expected) else {
                    return handler(self, .failed("invoke result mismatch: expected: \(expected), actual: \(result)"))
                }
                return handler(self, .passed)

            case .get(_, let globalName):
                let result: WasmKit.Value
                do {
                    result = try runtime.getGlobal(moduleInstance, globalName: globalName)
                } catch {
                    return handler(self, .failed("\(error)"))
                }
                guard result.isTestEquivalent(to: expected[0]) else {
                    return handler(self, .failed("get result mismatch: expected: \(expected), actual: \(result)"))
                }
                return handler(self, .passed)
            case .wat: break
            }

        case .assertTrap(let execute, let message):
            let moduleInstance: ModuleInstance?
            do {
                moduleInstance = try deriveModuleInstance(from: execute)
            } catch {
                return handler(self, .failed("failed to derive module instance: \(error)"))
            }
            guard let moduleInstance else {
                return handler(self, .failed("no module to execute"))
            }

            switch execute {
            case .invoke(let invoke):
                do {
                    _ = try runtime.invoke(moduleInstance, function: invoke.name, with: invoke.args)
                    // XXX: This is wrong but just keep it as is
                    // return handler(self, .failed("trap expected: \(message)"))
                    return handler(self, .passed)
                } catch let trap as Trap {
                    guard trap.assertionText.contains(message) else {
                        return handler(self, .failed("assertion mismatch: expected: \(message), actual: \(trap.assertionText)"))
                    }
                    return handler(self, .passed)
                } catch {
                    return handler(self, .failed("\(error)"))
                }
            default:
                return handler(self, .failed("assert_trap is not implemented non-invoke actions"))
            }
        case .assertExhaustion(let call, let message):
            let moduleInstance: ModuleInstance?
            do {
                moduleInstance = try deriveModuleInstance(from: .invoke(call))
            } catch {
                return handler(self, .failed("failed to derive module instance: \(error)"))
            }
            guard let moduleInstance else {
                return handler(self, .failed("no module to execute"))
            }

            do {
                _ = try runtime.invoke(moduleInstance, function: call.name, with: call.args)
                return handler(self, .failed("trap expected: \(message)"))
            } catch let trap as Trap {
                guard trap.assertionText.contains(message) else {
                    return handler(self, .failed("assertion mismatch: expected: \(message), actual: \(trap.assertionText)"))
                }
                return handler(self, .passed)
            } catch {
                return handler(self, .failed("\(error)"))
            }
        case .assertUnlinkable(let wat, let message):
            currentModuleInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: .text(wat))
            } catch {
                return handler(self, .failed("module could not be parsed: \(error)"))
            }

            do {
                _ = try runtime.instantiate(module: module)
            } catch let error as ImportError {
                guard error.assertionText.contains(message) else {
                    return handler(self, .failed("assertion mismatch: expected: \(message), actual: \(error.assertionText)"))
                }
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)

        case .assertInvalid:
            return handler(self, .skipped("validation is no implemented yet"))

        case .invoke(let invoke):
            let moduleInstance: ModuleInstance?
            do {
                moduleInstance = try deriveModuleInstance(from: .invoke(invoke))
            } catch {
                return handler(self, .failed("failed to derive module instance: \(error)"))
            }
            guard let moduleInstance else {
                return handler(self, .failed("no module to execute"))
            }

            do {
                _ = try runtime.invoke(moduleInstance, function: invoke.name, with: invoke.args)
            } catch {
                return handler(self, .failed("\(error)"))
            }
            return handler(self, .passed)
        }
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
