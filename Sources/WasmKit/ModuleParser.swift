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
    var module = Module()

    var orderTracking = OrderTracking()
    var typeIndices = [TypeIndex]()
    var codes = [Code]()
    var parser = WasmParser.Parser<Stream>(
        stream: stream, features: features
    )
    var dataCount: UInt32?

    while let payload = try parser.parseNext() {
        switch payload {
        case .header: break
        case .customSection(let customSection):
            module.customSections.append(customSection)
        case .typeSection(let types):
            try orderTracking.track(order: .type)
            module.types = types
        case .importSection(let importSection):
            try orderTracking.track(order: ._import)
            module.imports = importSection
        case .functionSection(let types):
            try orderTracking.track(order: .function)
            typeIndices = types
        case .tableSection(let tableSection):
            try orderTracking.track(order: .table)
            module.tables = tableSection
        case .memorySection(let memorySection):
            try orderTracking.track(order: .memory)
            module.memories = memorySection
        case .globalSection(let globalSection):
            try orderTracking.track(order: .global)
            module.globals = globalSection
        case .exportSection(let exportSection):
            try orderTracking.track(order: .export)
            module.exports = exportSection
        case .startSection(let functionIndex):
            try orderTracking.track(order: .start)
            module.start = functionIndex
        case .elementSection(let elementSection):
            try orderTracking.track(order: .element)
            module.elements = elementSection
        case .codeSection(let codeSection):
            try orderTracking.track(order: .code)
            codes = codeSection
        case .dataSection(let dataSection):
            try orderTracking.track(order: .data)
            module.data = dataSection
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

    if let dataCount = dataCount, dataCount != UInt32(module.data.count) {
        throw WasmParserError.inconsistentDataCountAndDataSectionLength(
            dataCount: dataCount,
            dataSection: module.data.count
        )
    }

    let translatorContext = InstructionTranslator.Module(
        typeSection: module.types,
        importSection: module.imports,
        functionSection: typeIndices,
        globalTypes: module.globals.map { $0.type },
        memoryTypes: module.memories.map { $0.type },
        tables: module.tables
    )
    let allocator = module.allocator
    let functions = codes.enumerated().map { [hasDataCount = parser.hasDataCount, features] index, code in
        let funcTypeIndex = typeIndices[index]
        let funcType = module.types[Int(funcTypeIndex)]
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
                return translator.finalize()
            })
    }
    module.functions = functions

    return module
}
