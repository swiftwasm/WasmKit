import Foundation
import SystemPackage
import WAT
import WasmKit
import WasmParser

package struct TestCase: CustomStringConvertible {
    package enum Error: Swift.Error {
        case invalidPath
    }

    package let path: String
    package var relativePath: String {
        // Relative path from the current working directory
        let currentDirectory = FileManager.default.currentDirectoryPath
        if path.hasPrefix(currentDirectory) {
            return String(path.dropFirst(currentDirectory.count + 1))
        }
        return path
    }

    package var description: String {
        return relativePath
    }

    package static func load(include: [String], exclude: [String], in path: [String]) throws -> [TestCase] {
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

            let patternPredicate = { pattern in filePath.path.hasSuffix(pattern) }
            if !include.isEmpty {
                return include.contains(where: patternPredicate)
            }
            guard !exclude.contains(where: patternPredicate) else { return false }
            return true
        }

        var testCases: [TestCase] = []
        for filePath in filePaths where try matchesPattern(filePath) {
            let spec = TestCase(path: filePath.path)
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

package enum Result {
    case passed
    case failed(String)
    case skipped(String)

    package var banner: String {
        switch self {
        case .passed:
            return "[PASSED]"
        case .failed:
            return "[FAILED]"
        case .skipped:
            return "[SKIPPED]"
        }
    }
}

package struct SpectestError: Error, CustomStringConvertible {
    package let description: String
    package init(_ description: String) {
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
        guard let data = FileManager.default.contents(atPath: path) else {
            assertionFailure("failed to load \(path)")
            return
        }
        var configuration = configuration
        let rootPath = FilePath(path).removingLastComponent()
        let features = WastRunContext.deriveFeatureSet(rootPath: rootPath)
        configuration.features = features

        let engine = Engine(configuration: configuration)
        let store = Store(engine: engine)
        let spectestInstance = try spectestModule.instantiate(store: store)

        var content = try parseWAST(String(data: data, encoding: .utf8)!, features: features)
        let context = WastRunContext(store: store, rootPath: rootPath.string)
        context.importsSpace.define(module: "spectest", spectestInstance.exports)

        // Add shared_memory export for threads proposal tests
        if configuration.features.contains(.threads) {
            let sharedMemoryType = MemoryType(min: 1, max: 2, shared: true)
            let sharedMemory = try Memory(store: store, type: sharedMemoryType)
            context.importsSpace.define(module: "spectest", name: "shared_memory", sharedMemory)
        }
        do {
            while let (directive, location) = try content.nextDirective() {
                do {
                    if let result = try context.run(directive: directive) {
                        handler(self, location, result)
                    }
                } catch let error {
                    handler(self, location, .failed("\(error)"))
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
        case .wat(let wat):
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

        case .assertMalformed(let module, let message), .assertInvalid(let module, let message):
            currentInstance = nil
            do {
                let module = try parseModule(rootPath: rootPath, moduleSource: module.source)
                let instance = try instantiate(module: module)
                // Materialize all functions to see all errors in the module
                try instance.handle.withValue { try $0.compileAllFunctions(store: store) }
            } catch {
                return .passed
            }
            return .failed("module should not be parsed nor valid: expected \"\(message)\"")

        case .assertTrap(execute: .wat(let wat), let message):
            currentInstance = nil

            let module: Module
            do {
                module = try parseModule(rootPath: rootPath, moduleSource: .binary(wat.encode()))
            } catch {
                return .failed("module could not be parsed: \(error)")
            }

            do {
                _ = try instantiate(module: module)
            } catch let error as Trap {
                guard error.reason.description.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(error.reason.description)")
                }
            } catch {
                return .failed("\(error)")
            }
            return .passed

        case .assertReturn(let execute, let expected):
            let actual = try wastExecute(execute: execute)
            guard actual.isTestEquivalent(to: expected) else {
                return .failed("invoke result mismatch: expected: \(expected), actual: \(actual)")
            }
            return .passed
        case .assertTrap(let execute, let message):
            do {
                _ = try wastExecute(execute: execute)
                return .failed("trap expected: \(message)")
            } catch let trap as Trap {
                guard trap.reason.description.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(trap.reason.description)")
                }
                return .passed
            } catch {
                return .failed("\(error)")
            }
        case .assertExhaustion(let call, let message):
            do {
                _ = try wastInvoke(call: call)
                return .failed("trap expected: \(message)")
            } catch let trap as Trap {
                guard trap.reason.description.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(trap.reason.description)")
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
                guard error.message.text.contains(message) else {
                    return .failed("assertion mismatch: expected: \(message), actual: \(error.message.text)")
                }
            } catch {
                return .failed("\(error)")
            }
            return .passed

        case .invoke(let invoke):
            _ = try wastInvoke(call: invoke)
            return .passed
        }
    }

    private func wastExecute(execute: WastExecute) throws -> [Value] {
        switch execute {
        case .invoke(let invoke):
            return try wastInvoke(call: invoke)
        case .get(let module, let globalName):
            let instance = try deriveInstance(by: module)
            guard case .global(let global) = instance.export(globalName) else {
                throw SpectestError("no global export with name \(globalName) in a module instance \(instance)")
            }
            return [global.value]
        case .wat(let wat):
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
        let args = try call.args.map { arg -> Value in
            switch arg {
            case .i32(let value): return .i32(value)
            case .i64(let value): return .i64(value)
            case .f32(let value): return .f32(value)
            case .f64(let value): return .f64(value)
            case .v128(let value): return .v128(value)
            case .refNull(let heapType):
                switch heapType {
                case .abstract(.funcRef): return .ref(.function(nil))
                case .abstract(.externRef): return .ref(.extern(nil))
                case .concrete:
                    throw SpectestError("concrete ref.null is not supported yet")
                }
            case .refExtern(let value): return .ref(.extern(Int(value)))
            case .refFunc(let value): return .ref(.function(Int(value)))
            }
        }
        return try function.invoke(args)
    }

    static func deriveFeatureSet(rootPath: FilePath) -> WasmFeatureSet {
        var features = WasmFeatureSet.default
        if rootPath.ends(with: "proposals/memory64") {
            features.insert(.memory64)
        }
        features.insert(.simd)
        if rootPath.ends(with: "proposals/threads") {
            // Threads proposal tests should not enable reference types by default
            // as they test core WebAssembly features without reference types
            features.remove(.referenceTypes)
            features.insert(.threads)
        }
        return features
    }

    private func parseModule(rootPath: String, filename: String) throws -> Module {
        let rootPath = FilePath(rootPath)
        let path = rootPath.appending(filename)

        let module = try parseWasm(filePath: path, features: Self.deriveFeatureSet(rootPath: rootPath))
        return module
    }

    private func parseModule(rootPath: String, moduleSource: ModuleSource) throws -> Module {
        let rootPath = FilePath(rootPath)
        let binary: [UInt8]
        switch moduleSource {
        case .text(let watModule):
            binary = try watModule.encode()
        case .quote(let text):
            binary = try wat2wasm(String(decoding: text, as: UTF8.self))
        case .binary(let bytes):
            binary = bytes
        }

        let module = try parseWasm(bytes: binary, features: Self.deriveFeatureSet(rootPath: rootPath))
        return module
    }
}

extension Value {
    func isTestEquivalent(to value: WastExpectValue) -> Bool {
        switch (self, value) {
        case (.i32(let lhs), .i32(let rhs)):
            return lhs == rhs
        case (.i64(let lhs), .i64(let rhs)):
            return lhs == rhs
        case (.f32(let lhs), .f32(let rhs)):
            let lhs = Float32(bitPattern: lhs)
            let rhs = Float32(bitPattern: rhs)
            return lhs.isNaN && rhs.isNaN || lhs == rhs
        case (.f64(let lhs), .f64(let rhs)):
            let lhs = Float64(bitPattern: lhs)
            let rhs = Float64(bitPattern: rhs)
            return lhs.isNaN && rhs.isNaN || lhs == rhs
        case (.v128(let lhs), .v128(let rhs)):
            return lhs == rhs
        case (.v128(let actual), .v128Pattern(let expected)):
            let actualBytes = actual.bytes
            let expectedBytes = expected.bytes
            guard actualBytes.count == 16, expectedBytes.count == 16 else { return false }
            guard let shape = expected.shape else { return actualBytes == expectedBytes }

            func u32LE(_ offset: Int, _ bytes: [UInt8]) -> UInt32 {
                UInt32(bytes[offset])
                    | (UInt32(bytes[offset + 1]) << 8)
                    | (UInt32(bytes[offset + 2]) << 16)
                    | (UInt32(bytes[offset + 3]) << 24)
            }
            func u64LE(_ offset: Int, _ bytes: [UInt8]) -> UInt64 {
                var value: UInt64 = 0
                for i in 0..<8 {
                    value |= UInt64(bytes[offset + i]) << (UInt64(i) * 8)
                }
                return value
            }

            switch shape {
            case .f32x4:
                for i in 0..<4 {
                    let a = u32LE(i * 4, actualBytes)
                    let e = u32LE(i * 4, expectedBytes)
                    if expected.nanLaneMask & (1 << UInt8(i)) != 0 {
                        guard Float32(bitPattern: a).isNaN else { return false }
                    } else if a != e {
                        return false
                    }
                }
                return true
            case .f64x2:
                for i in 0..<2 {
                    let a = u64LE(i * 8, actualBytes)
                    let e = u64LE(i * 8, expectedBytes)
                    if expected.nanLaneMask & (1 << UInt8(i)) != 0 {
                        guard Float64(bitPattern: a).isNaN else { return false }
                    } else if a != e {
                        return false
                    }
                }
                return true
            }
        case (.f64(let lhs), .f64ArithmeticNaN),
            (.f64(let lhs), .f64CanonicalNaN):
            return Float64(bitPattern: lhs).isNaN
        case (.f32(let lhs), .f32ArithmeticNaN),
            (.f32(let lhs), .f32CanonicalNaN):
            return Float32(bitPattern: lhs).isNaN
        case (.ref(.extern(let lhs?)), .refExtern(let rhs)):
            return rhs.map { lhs == $0 } ?? true
        case (.ref(.function(let lhs?)), .refFunc(let rhs)):
            return rhs.map { lhs == $0 } ?? true
        case (.ref(.extern(nil)), .refNull(.abstract(.externRef))),
            (.ref(.function(nil)), .refNull(.abstract(.funcRef))):
            return true
        default:
            return false
        }
    }
}

extension Array where Element == Value {
    func isTestEquivalent(to arrayOfValues: [WastExpectValue]) -> Bool {
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
            return error.description
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
