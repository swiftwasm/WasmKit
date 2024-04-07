import Foundation
import SystemPackage
@_spi(Migration) import WasmParser

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
/// <https://webassembly.github.io/spec/core/binary/values.html#integers>
extension ByteStream {
    fileprivate func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws -> T {
        return try T(LEB: { try? self.consumeAny() })
    }
}

extension LegacyWasmParser {
    func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws -> T {
        try stream.parseUnsigned(T.self)
    }
}


/// > Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html>
extension LegacyWasmParser {
    func parseExpression(typeSection: [FunctionType]? = nil) throws -> Expression {
        return try WasmParser.parseConstExpression(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension LegacyWasmParser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#custom-section>
    func parseCustomSection(size: UInt32) throws -> CustomSection {
        return try WasmParser.parseCustomSection(
            stream: self.stream, size: size,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#type-section>
    func parseTypeSection() throws -> [FunctionType] {
        return try WasmParser.parseTypeSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#import-section>
    func parseImportSection() throws -> [Import] {
        return try WasmParser.parseImportSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#function-section>
    func parseFunctionSection() throws -> [TypeIndex] {
        return try WasmParser.parseFunctionSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#table-section>
    func parseTableSection() throws -> [Table] {
        return try WasmParser.parseTableSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#memory-section>
    func parseMemorySection() throws -> [Memory] {
        return try WasmParser.parseMemorySection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#global-section>
    func parseGlobalSection() throws -> [Global] {
        return try WasmParser.parseGlobalSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#export-section>
    func parseExportSection() throws -> [Export] {
        return try WasmParser.parseExportSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#start-section>
    func parseStartSection() throws -> FunctionIndex {
        return try parseUnsigned()
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#element-section>
    func parseElementSection() throws -> [ElementSegment] {
        return try WasmParser.parseElementSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#code-section>
    func parseCodeSection() throws -> [Code] {
        return try WasmParser.parseCodeSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-section>
    func parseDataSection() throws -> [DataSegment] {
        return try WasmParser.parseDataSection(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-count-section>
    func parseDataCountSection() throws -> UInt32 {
        return try parseUnsigned()
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
extension LegacyWasmParser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-magic>
    func parseMagicNumber() throws {
        let magicNumber = try stream.consume(count: 4)
        guard magicNumber == [0x00, 0x61, 0x73, 0x6D] else {
            throw LegacyWasmParserError.invalidMagicNumber(.init(magicNumber))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-version>
    func parseVersion() throws {
        let version = try stream.consume(count: 4)
        guard version == [0x01, 0x00, 0x00, 0x00] else {
            throw LegacyWasmParserError.unknownVersion(.init(version))
        }
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
                throw LegacyWasmParserError.sectionOutOfOrder
            }
            last = order
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
    func parseModule() throws -> Module {
        try parseMagicNumber()
        try parseVersion()

        var module = Module()

        var typeIndices = [TypeIndex]()
        var codes = [Code]()
        var orderTracking = OrderTracking()

        let ids: ClosedRange<UInt8> = 0...12
        while try !stream.hasReachedEnd() {
            let sectionID = try stream.consumeAny()

            guard ids.contains(sectionID) else {
                throw LegacyWasmParserError.malformedSectionID(sectionID)
            }

            let sectionSize: UInt32 = try parseUnsigned()
            let sectionStart = stream.currentIndex

            switch sectionID {
            case 0:
                try module.customSections.append(parseCustomSection(size: sectionSize))
            case 1:
                try orderTracking.track(order: .type)
                module.types = try parseTypeSection()
            case 2:
                try orderTracking.track(order: ._import)
                module.imports = try parseImportSection()
            case 3:
                try orderTracking.track(order: .function)
                typeIndices = try parseFunctionSection()
            case 4:
                try orderTracking.track(order: .table)
                module.tables = try parseTableSection()
            case 5:
                try orderTracking.track(order: .memory)
                module.memories = try parseMemorySection()
            case 6:
                try orderTracking.track(order: .global)
                module.globals = try parseGlobalSection()
            case 7:
                try orderTracking.track(order: .export)
                module.exports = try parseExportSection()
            case 8:
                try orderTracking.track(order: .start)
                module.start = try parseStartSection()
            case 9:
                try orderTracking.track(order: .element)
                module.elements = try parseElementSection()
            case 10:
                try orderTracking.track(order: .code)
                codes = try parseCodeSection()
            case 11:
                try orderTracking.track(order: .data)
                module.data = try parseDataSection()
            case 12:
                try orderTracking.track(order: .dataCount)
                module.dataCount = try parseDataCountSection()
                hasDataCount = true
            default:
                break
            }
            let expectedSectionEnd = sectionStart + Int(sectionSize)
            guard expectedSectionEnd == stream.currentIndex else {
                throw LegacyWasmParserError.sectionSizeMismatch(
                    expected: expectedSectionEnd, actual: stream.currentIndex
                )
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
