import WasmParser

/// Parse a given byte sequence as a WebAssembly binary format file
///
/// Registers the module's types in `engine`. The module can only be instantiated in a ``Store`` of `engine`.
///
/// - Throws: `WasmKitError` if the binary is malformed, if a type refers to a type defined in a later recursion
///   group or declares an invalid supertype, or if `engine` would hold more than
///   ``EngineConfiguration/maxTypeCount`` types.
///
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: some Sequence<UInt8>, engine: Engine, features: WasmFeatureSet = .default) throws(WasmKitError) -> Module {
    let parser = Parser(bytes: ArraySlice(bytes), features: features)
    let module = try parseModule(parser: parser, engine: engine, features: features)
    return module
}

@available(*, unavailable, renamed: "parseWasm(bytes:engine:features:)")
public func parseWasm(bytes: some Sequence<UInt8>, features: WasmFeatureSet = .default) throws(WasmKitError) -> Module {
    fatalError()
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
func parseModule<Source: ByteStreamSource>(
    parser: consuming WasmParser.Parser<Source>, engine: Engine, features: WasmFeatureSet = .default
) throws(WasmKitError) -> Module {
    var types = TypeSection([])
    var typeIndices: [TypeIndex] = []
    var codes: [Code] = []
    var tables: [WasmParser.Table] = []
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
            types = TypeSection(typeSection)
        case .importSection(let importSection):
            imports = importSection
        case .functionSection(let types):
            typeIndices = types
        case .tableSection(let tableSection):
            tables = tableSection
        case .memorySection(let memorySection):
            memories = memorySection.map { $0.type }
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
        let funcType = try types.functionType(at: funcTypeIndex)
        return GuestFunction(
            typeIndex: funcTypeIndex,
            type: funcType,
            code: code
        )
    }

    let typeCanonicalizer = try TypeCanonicalizer(typeSection: types, registry: engine.typeRegistry)
    let canonicalImports = try imports.map { (entry) throws(WasmKitError) in try typeCanonicalizer.canonicalize(entry) }

    return Module(
        engine: engine,
        typeCanonicalizer: typeCanonicalizer,
        types: types,
        functions: functions,
        elements: elements,
        data: data,
        start: start,
        imports: canonicalImports,
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
