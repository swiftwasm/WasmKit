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

private struct OrderTracking {
    enum Order: UInt8 {
        case initial = 0
        case type
        case _import
        case function
        case table
        case memory
        case tag
        case global
        case export
        case start
        case element
        case dataCount
        case code
        case data
    }

    private var last: Order = .initial
    mutating func track(order: Order) throws {
        guard last.rawValue < order.rawValue else {
            throw WasmParserError.sectionOutOfOrder
        }
        last = order
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
func parseModule<Stream: ByteStream>(stream: Stream, features: WasmFeatureSet = .default) throws -> Module {
    var orderTracking = OrderTracking()
    var types: [FunctionType] = []
    var typeIndices: [TypeIndex] = []
    var codes: [Code] = []
    var tables: [Table] = []
    var memories: [Memory] = []
    var globals: [Global] = []
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
            try orderTracking.track(order: .type)
            types = typeSection
        case .importSection(let importSection):
            try orderTracking.track(order: ._import)
            imports = importSection
        case .functionSection(let types):
            try orderTracking.track(order: .function)
            typeIndices = types
        case .tableSection(let tableSection):
            try orderTracking.track(order: .table)
            tables = tableSection
        case .memorySection(let memorySection):
            try orderTracking.track(order: .memory)
            memories = memorySection
        case .globalSection(let globalSection):
            try orderTracking.track(order: .global)
            globals = globalSection
        case .exportSection(let exportSection):
            try orderTracking.track(order: .export)
            exports = exportSection
        case .startSection(let functionIndex):
            try orderTracking.track(order: .start)
            start = functionIndex
        case .elementSection(let elementSection):
            try orderTracking.track(order: .element)
            elements = elementSection
        case .codeSection(let codeSection):
            try orderTracking.track(order: .code)
            codes = codeSection
        case .dataSection(let dataSection):
            try orderTracking.track(order: .data)
            data = dataSection
        case .dataCount(let count):
            try orderTracking.track(order: .dataCount)
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

    let translatorContext = TranslatorContext(
        typeSection: types,
        importSection: imports,
        functionSection: typeIndices,
        globals: globals,
        memories: memories,
        tables: tables
    )
    let allocator = ISeqAllocator()
    let functions = try codes.enumerated().map { [hasDataCount = parser.hasDataCount, features] index, code in
        // SAFETY: The number of typeIndices is guaranteed to be the same as the number of codes
        let funcTypeIndex = typeIndices[index]
        let funcType = try translatorContext.resolveType(funcTypeIndex)
        return GuestFunction(
            type: typeIndices[index], locals: code.locals, allocator: allocator,
            body: {
                var translator = InstructionTranslator(
                    allocator: allocator,
                    module: translatorContext,
                    type: funcType, locals: code.locals
                )

                try WasmParser.parseExpression(
                    bytes: Array(code.expression),
                    features: features, hasDataCount: hasDataCount,
                    visitor: &translator
                )
                return try translator.finalize()
            })
    }

    return Module(
        functions: functions,
        elements: elements,
        data: data,
        start: start,
        imports: imports,
        exports: exports,
        customSections: customSections,
        translatorContext: translatorContext,
        allocator: allocator
    )
}
