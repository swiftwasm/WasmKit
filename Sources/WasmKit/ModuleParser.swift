import SystemPackage
import WasmParser

#if os(Windows)
    import ucrt
#endif

/// Parse a given file as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(filePath: FilePath, features: WasmFeatureSet = .default) throws -> Module {
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
    let module = try parseModule(stream: stream, features: features)
    return module
}

/// Parse a given byte array as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: [UInt8], features: WasmFeatureSet = .default) throws -> Module {
    let stream = StaticByteStream(bytes: bytes)
    let module = try parseModule(stream: stream, features: features)
    return module
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
func parseModule<Stream: ByteStream>(stream: Stream, features: WasmFeatureSet = .default) throws -> Module {
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
            tables = tableSection.map(\.type)
        case .memorySection(let memorySection):
            memories = memorySection.map(\.type)
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

    guard typeIndices.count == codes.count else {
        throw WasmParserError.inconsistentFunctionAndCodeLength(
            functionCount: typeIndices.count,
            codeCount: codes.count
        )
    }

    if let dataCount = dataCount, dataCount != UInt32(data.count) {
        throw WasmParserError.inconsistentDataCountAndDataSectionLength(
            dataCount: dataCount,
            dataSection: data.count
        )
    }

    let allocator = ISeqAllocator()
    let functions = try codes.enumerated().map { index, code in
        // SAFETY: The number of typeIndices is guaranteed to be the same as the number of codes
        let funcTypeIndex = typeIndices[index]
        let funcType = try Module.resolveType(funcTypeIndex, typeSection: types)
        return GuestFunction(
            type: funcType,
            code: code
        )
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
        allocator: allocator,
        features: features,
        hasDataCount: dataCount != nil
    )
}
