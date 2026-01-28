import WasmParser

/// Error type for module parsing in embedded environments
public enum ModuleParseError: Error {
    case parserError(WasmParserError)
    case validationError(ValidationError)
    case translationError(TranslationError)
}

/// Parse a given byte array as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm<MemorySpace: GuestMemory>(bytes: [UInt8], features: WasmFeatureSet = .default) throws(ModuleParseError) -> Module<MemorySpace> {
    let stream = StaticByteStream(bytes: bytes)
    return try parseModule(stream: stream, features: features)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
func parseModule<Stream: ByteStream, MemorySpace: GuestMemory>(stream: Stream, features: WasmFeatureSet = .default) throws(ModuleParseError) -> Module<MemorySpace> {
    var types: [FunctionType] = []
    var typeIndices: [TypeIndex] = []
    var codes: [Code] = []
    var tables: [TableType] = []
    var memories: [MemoryType] = []
    var globals: [WasmParser.Global] = []
    var elements: [ElementSegment] = []
    var data: [DataSegment] = []
    var start: FunctionIndex?
    var imports: [Import] = []
    var exports: [Export] = []
    var customSections: [CustomSection] = []
    var dataCount: UInt32?

    var parser = WasmParser.Parser<Stream>(
        stream: stream, features: features
    )

    do {
        while let payload = try parser.parseNext() {
            switch payload {
            case .header: break
            case .customSection(let customSection):
                customSections.append(customSection)
            case .typeSection(let typeSection):
                types = typeSection
            case .importSection(let importSection):
                imports = importSection
            case .functionSection(let types):
                typeIndices = types
            case .tableSection(let tableSection):
                tables = tableSection.map { $0.type }
            case .memorySection(let memorySection):
                memories = memorySection.map { $0.type }
            case .globalSection(let globalSection):
                globals = globalSection
            case .exportSection(let exportSection):
                exports = exportSection
            case .startSection(let functionIndex):
                start = functionIndex
            case .elementSection(let elementSection):
                elements = elementSection
            case .codeSection(let codeSection):
                codes = codeSection
            case .dataSection(let dataSection):
                data = dataSection
            case .dataCount(let count):
                dataCount = count
            }
        }
    } catch {
        throw ModuleParseError.parserError(error)
    }

    guard typeIndices.count == codes.count else {
        throw ModuleParseError.validationError(ValidationError(
            .inconsistentFunctionAndCodeLength(
                functionCount: typeIndices.count,
                codeCount: codes.count
            )))
    }

    if let dataCount = dataCount, dataCount != UInt32(data.count) {
        throw ModuleParseError.validationError(ValidationError(
            .inconsistentDataCountAndDataSectionLength(
                dataCount: dataCount,
                dataSection: data.count
            )))
    }

    var functions: [GuestFunction] = []
    for (index, code) in codes.enumerated() {
        // SAFETY: The number of typeIndices is guaranteed to be the same as the number of codes
        let funcTypeIndex = typeIndices[index]
        do {
            let funcType = try Module<MemorySpace>.resolveType(funcTypeIndex, typeSection: types)
            functions.append(GuestFunction(
                type: funcType,
                code: code
            ))
        } catch {
            throw ModuleParseError.translationError(error)
        }
    }

    return Module(
        types: types,
        functions: functions,
        elements: elements,
        data: data,
        start: start,
        imports: imports,
        exports: exports,
        globals: globals,
        memories: memories,
        tables: tables,
        customSections: customSections,
        features: features,
        dataCount: dataCount
    )
}

#if !$Embedded
import SystemPackage

#if os(Windows)
    import ucrt
#endif

/// Parse a given file as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm<MemorySpace: GuestMemory>(filePath: FilePath, features: WasmFeatureSet = .default) throws -> Module<MemorySpace> {
    #if os(Windows)
        // TODO: Upstream `O_BINARY` to `SystemPackage
        let accessMode = FileDescriptor.AccessMode(
            rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
        )
    #else
        let accessMode: FileDescriptor.AccessMode = .readOnly
    #endif
    let fileHandle = try FileDescriptor.open(filePath, accessMode)
    defer { try? fileHandle.close() }
    let stream = try FileHandleStream(fileHandle: fileHandle)
    do {
        return try parseModule(stream: stream, features: features)
    } catch let error as ModuleParseError {
        throw error
    }
}
#endif
