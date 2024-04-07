import Foundation
import SystemPackage
import WasmParser

final class LegacyWasmParser<Stream: ByteStream> {
    let stream: Stream
    private var hasDataCount: Bool = false
    private let features: WasmFeatureSet

    var currentIndex: Int {
        return stream.currentIndex
    }

    init(stream: Stream, features: WasmFeatureSet = .default, hasDataCount: Bool = false) {
        self.stream = stream
        self.features = features
        self.hasDataCount = hasDataCount
    }
}

/// Parse a given file as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(filePath: FilePath, features: WasmFeatureSet = .default) throws -> Module {
    let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath.string))
    defer { try? fileHandle.close() }
    let stream = try FileHandleStream(fileHandle: fileHandle)
    let parser = LegacyWasmParser(stream: stream, features: features)
    let module = try parser.parseModule()
    return module
}

/// Parse a given byte array as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: [UInt8], features: WasmFeatureSet = .default) throws -> Module {
    let stream = LegacyStaticByteStream(bytes: bytes)
    let parser = LegacyWasmParser(stream: stream, features: features)
    let module = try parser.parseModule()
    return module
}

public enum LegacyWasmParserError: Swift.Error {
    /// The magic number is not found or invalid
    case invalidMagicNumber([UInt8])
    /// The version is not recognized
    case unknownVersion([UInt8])
    /// The bytes are not valid UTF-8
    case invalidUTF8([UInt8])
    /// The section has an invalid size
    case invalidSectionSize(UInt32)
    /// The section ID is malformed
    case malformedSectionID(UInt8)
    /// The byte is expected to be zero, but it's not
    case zeroExpected(actual: UInt8, index: Int)
    /// The function and code length are inconsistent
    case inconsistentFunctionAndCodeLength(functionCount: Int, codeCount: Int)
    /// The data count and data section length are inconsistent
    case inconsistentDataCountAndDataSectionLength(dataCount: UInt32, dataSection: Int)
    /// The local count is too large
    case tooManyLocals
    /// The type is expected to be a reference type, but it's not
    case expectedRefType(actual: ValueType)
    /// The instruction is not implemented
    case unimplementedInstruction(UInt8, suffix: UInt32? = nil)
    /// The element kind is unexpected
    case unexpectedElementKind(expected: UInt32, actual: UInt32)
    /// The element kind is not recognized
    case integerRepresentationTooLong
    /// `end` opcode is expected but not found
    case endOpcodeExpected
    /// Unexpected end of the stream
    case unexpectedEnd
    /// The byte is not expected
    case sectionSizeMismatch(expected: Int, actual: Int)
    /// Illegal opcode is found
    case illegalOpcode(UInt8)
    /// Malformed mutability byte
    case malformedMutability(UInt8)
    /// Malformed function type byte
    case malformedFunctionType(UInt8)
    /// Sections in the module are out of order
    case sectionOutOfOrder
    /// The data count section is required but not found
    case dataCountSectionRequired
    /// Malformed limit byte
    case malformedLimit(UInt8)
    /// Malformed indirect call
    case malformedIndirectCall
    /// Invalid reference to a type section entry
    case invalidTypeSectionReference
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
extension LegacyWasmParser {
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
                throw LegacyWasmParserError.sectionOutOfOrder
            }
            last = order
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
    func parseModule() throws -> Module {
        var module = Module()

        var orderTracking = OrderTracking()
        var typeIndices = [TypeIndex]()
        var codes = [Code]()
        var parser = WasmParser.Parser<Stream>(
            stream: self.stream, features: features, hasDataCount: hasDataCount
        )

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
            case .dataCount(let dataCount):
                try orderTracking.track(order: .dataCount)
                module.dataCount = dataCount
                hasDataCount = true
            }
        }

        guard typeIndices.count == codes.count else {
            throw LegacyWasmParserError.inconsistentFunctionAndCodeLength(
                functionCount: typeIndices.count,
                codeCount: codes.count
            )
        }

        if let dataCount = module.dataCount, dataCount != UInt32(module.data.count) {
            throw LegacyWasmParserError.inconsistentDataCountAndDataSectionLength(
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
        let enableAssertDefault = _slowPath(getenv("WASMKIT_ENABLE_ASSERT") != nil)
        let functions = codes.enumerated().map { [hasDataCount, features] index, code in
            let funcTypeIndex = typeIndices[index]
            let funcType = module.types[Int(funcTypeIndex)]
            return GuestFunction(
                type: typeIndices[index], locals: code.locals,
                body: {
                    var enableAssert = enableAssertDefault
                    #if ASSERT
                    enableAssert = true
                    #endif
                    
                    var translator = InstructionTranslator(
                        allocator: module.allocator,
                        module: translatorContext,
                        type: funcType, locals: code.locals
                    )

                    if enableAssert && !_isFastAssertConfiguration() {
                        let globalFuncIndex = module.imports.count + index
                        print("🚀 Starting Translation for code[\(globalFuncIndex)] (\(funcType))")
                        var tracing = InstructionTracingVisitor(trace: {
                            print("🍵 code[\(globalFuncIndex)] Translating \($0)")
                        }, visitor: translator)
                        try WasmParser.parseExpression(
                            bytes: Array(code.expression),
                            features: features, hasDataCount: hasDataCount,
                            visitor: &tracing
                        )
                        let newISeq = InstructionSequence(instructions: tracing.visitor.finalize())
                        return newISeq
                    }
                    try WasmParser.parseExpression(
                        bytes: Array(code.expression),
                        features: features, hasDataCount: hasDataCount,
                        visitor: &translator
                    )
                    return InstructionSequence(instructions: translator.finalize())
                })
        }
        module.functions = functions

        return module
    }
}
