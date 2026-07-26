import WasmParser

/// Parse a given byte array as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: [UInt8], features: WasmFeatureSet = .default) throws(WasmKitError) -> Module {
    let parser = Parser(bytes: bytes, features: features)
    let module = try parseModule(parser: parser, features: features)
    return module
}

/// Parse a given byte slice as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: ArraySlice<UInt8>, features: WasmFeatureSet = .default) throws -> Module {
    let parser = Parser(bytes: bytes, features: features)
    let module = try parseModule(parser: parser, features: features)
    return module
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
func parseModule<Source: ByteStreamSource>(parser: consuming WasmParser.Parser<Source>, features: WasmFeatureSet = .default) throws(WasmKitError) -> Module {
    var types: [FunctionType] = []
    var typeIndices: [TypeIndex] = []
    var codes: [Code] = []
    var tables: [TableType] = []
    var memories: [MemoryType] = []
    var globals: [WasmParser.Global] = []
    var tags: [WasmParser.Tag] = []
    var elements: [ElementSegment] = []
    var data: [DataSegment] = []
    var start: FunctionIndex?
    var imports: [Import] = []
    var exports: [Export] = []
    var customSections: [CustomSection] = []
    var dataCount: UInt32?

    while let payload = try WasmKitError.wrap({ () throws(WasmParserError) in try parser.parseNext() }) {
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
        case .tagSection(let tagSection):
            tags = tagSection
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
        throw
            WasmKitError(
                message: .inconsistentFunctionAndCodeLength(
                    functionCount: typeIndices.count,
                    codeCount: codes.count
                ),
                offset: parser.offset
            )
    }

    if let dataCount = dataCount, dataCount != UInt32(data.count) {
        throw
            WasmKitError(
                message: .inconsistentDataCountAndDataSectionLength(
                    dataCount: dataCount,
                    dataSection: data.count
                ),
                offset: parser.offset
            )
    }

    let functions = try codes.enumerated().map { index, code throws(WasmKitError) in
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
        tags: tags,
        customSections: customSections,
        features: features,
        dataCount: dataCount
    )
}
