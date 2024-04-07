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
/// <https://webassembly.github.io/spec/core/binary/conventions.html#vectors>
extension ByteStream {
    fileprivate func parseVector<Content>(content parser: () throws -> Content) throws -> [Content] {
        var contents = [Content]()
        let count: UInt32 = try parseUnsigned()
        for _ in 0..<count {
            try contents.append(parser())
        }
        return contents
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#integers>
extension ByteStream {
    fileprivate func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws -> T {
        return try T(LEB: { try? self.consumeAny() })
    }

    fileprivate func parseSigned<T: FixedWidthInteger & SignedInteger>() throws -> T {
        return try T(LEB: { try? self.consumeAny() })
    }

    fileprivate func parseInteger<T: RawUnsignedInteger>() throws -> T {
        let signed: T.Signed = try parseSigned()
        return signed.unsigned
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#names>
extension ByteStream {
    fileprivate func parseName() throws -> String {
        let bytes = try parseVector { () -> UInt8 in
            try consumeAny()
        }

        var name = ""

        var iterator = bytes.makeIterator()
        var decoder = UTF8()
        Decode: while true {
            switch decoder.decode(&iterator) {
            case let .scalarValue(scalar): name.append(Character(scalar))
            case .emptyInput: break Decode
            case .error: throw LegacyWasmParserError.invalidUTF8(bytes)
            }
        }

        return name
    }
}

extension LegacyWasmParser {
    func parseVector<Content>(content parser: () throws -> Content) throws -> [Content] {
        try stream.parseVector(content: parser)
    }

    func parseUnsigned<T: RawUnsignedInteger>(_: T.Type = T.self) throws -> T {
        try stream.parseUnsigned(T.self)
    }

    func parseSigned<T: FixedWidthInteger & SignedInteger>() throws -> T {
        try stream.parseSigned()
    }

    func parseInteger<T: RawUnsignedInteger>() throws -> T {
        try stream.parseInteger()
    }

    func parseName() throws -> String {
        try stream.parseName()
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#floating-point>
extension LegacyWasmParser {
    func parseFloat() throws -> UInt32 {
        let consumedLittleEndian = try stream.consume(count: 4).reversed()
        let bitPattern = consumedLittleEndian.reduce(UInt32(0)) { acc, byte in
            acc << 8 + UInt32(byte)
        }
        return bitPattern
    }

    func parseDouble() throws -> UInt64 {
        let consumedLittleEndian = try stream.consume(count: 8).reversed()
        let bitPattern = consumedLittleEndian.reduce(UInt64(0)) { acc, byte in
            acc << 8 + UInt64(byte)
        }
        return bitPattern
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/types.html#types>
extension LegacyWasmParser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#value-types>
    func parseValueType() throws -> ValueType {
        let b = try stream.consumeAny()

        switch b {
        case 0x7F:
            return .i32
        case 0x7E:
            return .i64
        case 0x7D:
            return .f32
        case 0x7C:
            return .f64
        case 0x70:
            return .reference(.funcRef)
        case 0x6F:
            return .reference(.externRef)
        default:
            throw StreamError<Stream.Element>.unexpected(b, index: currentIndex, expected: Set(0x7C...0x7F))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#result-types>
    func parseResultType() throws -> ResultType {
        let nextByte = try stream.peek()!
        switch nextByte {
        case 0x40:
            _ = try stream.consumeAny()
            return .empty
        case 0x7C...0x7F, 0x70, 0x6F:
            return try .single(parseValueType())
        default:
            return try .multi(typeIndex: stream.consumeAny())
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#function-types>
    func parseFunctionType() throws -> FunctionType {
        let opcode = try stream.consumeAny()

        // XXX: spectest expects the first byte should be parsed as a LEB128 with 1 byte limit
        // but the spec itself doesn't require it, so just check the continue bit of LEB128 here.
        guard opcode & 0b10000000 == 0 else {
            throw LegacyWasmParserError.integerRepresentationTooLong
        }
        guard opcode == 0x60 else {
            throw LegacyWasmParserError.malformedFunctionType(opcode)
        }

        let parameters = try parseVector { try parseValueType() }
        let results = try parseVector { try parseValueType() }
        return FunctionType(parameters: parameters, results: results)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#limits>
    func parseLimits() throws -> Limits {
        let b = try stream.consumeAny()

        switch b {
        case 0x00:
            return try Limits(min: UInt64(parseUnsigned(UInt32.self)), max: nil)
        case 0x01:
            return try Limits(min: UInt64(parseUnsigned(UInt32.self)), max: UInt64(parseUnsigned(UInt32.self)))
        case 0x04 where features.contains(.memory64):
            return try Limits(min: parseUnsigned(UInt64.self), max: nil, isMemory64: true)
        case 0x05 where features.contains(.memory64):
            return try Limits(min: parseUnsigned(UInt64.self), max: parseUnsigned(UInt64.self), isMemory64: true)
        default:
            throw LegacyWasmParserError.malformedLimit(b)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#memory-types>
    func parseMemoryType() throws -> MemoryType {
        return try parseLimits()
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#table-types>
    func parseTableType() throws -> TableType {
        let elementType: ReferenceType
        let b = try stream.consumeAny()

        switch b {
        case 0x70:
            elementType = .funcRef
        case 0x6F:
            elementType = .externRef
        default:
            throw StreamError.unexpected(b, index: currentIndex, expected: [0x6F, 0x70])
        }

        let limits = try parseLimits()
        return TableType(elementType: elementType, limits: limits)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#global-types>
    func parseGlobalType() throws -> GlobalType {
        let valueType = try parseValueType()
        let mutability = try parseMutability()
        return GlobalType(mutability: mutability, valueType: valueType)
    }

    func parseMutability() throws -> Mutability {
        let b = try stream.consumeAny()
        switch b {
        case 0x00:
            return .constant
        case 0x01:
            return .variable
        default:
            throw LegacyWasmParserError.malformedMutability(b)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/instructions.html#memory-instructions>
    func parseMemarg() throws -> Instruction.Memarg {
        let align: UInt32 = try parseUnsigned()
        let offset: UInt64 = try features.contains(.memory64) ? parseUnsigned(UInt64.self) : UInt64(parseUnsigned(UInt32.self))
        return Instruction.Memarg(offset: offset, align: align)
    }

    func parseVectorBytes() throws -> ArraySlice<UInt8> {
        let count: UInt32 = try parseUnsigned()
        return try stream.consume(count: Int(count))
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html>
extension LegacyWasmParser {

    enum ParseInstructionResult {
        /// The instruction is not fully parsed yet but need expression to continue
        case requestExpression(resume: ([Instruction], PseudoInstruction) throws -> ParseInstructionResult)
        case `value`(Instruction)
        case multiValue([Instruction])
    }

    func parseInstruction(typeSection: [FunctionType]?) throws -> ParseInstructionResult {
        let rawCode = try stream.consumeAny()
        guard let code = InstructionCode(rawValue: rawCode) else {
            throw LegacyWasmParserError.illegalOpcode(rawCode)
        }

        switch code {
        case .unreachable:
            return .value(.control(.unreachable))
        case .nop:
            return .value(.control(.nop))
        case .block, .loop:
            fatalError("no longer supported")
        case .if:
            fatalError("no longer supported")
        case .else:
            fatalError("no longer supported")
        case .end:
            return .value(.end)
        case .br, .br_if, .br_table: fatalError("no longer supported")
        case .return:
            return .value(.control(.return))
        case .call:
            let index: UInt32 = try parseUnsigned()
            return .value(.control(.call(functionIndex: index)))
        case .call_indirect:
            let typeIndex: TypeIndex = try parseUnsigned()
            if try !features.contains(.referenceTypes) && stream.peek() != 0 {
                // Check that reserved byte is zero when reference-types is disabled
                throw LegacyWasmParserError.malformedIndirectCall
            }
            let tableIndex: TableIndex = try parseUnsigned()
            return .value(.control(.callIndirect(tableIndex: tableIndex, typeIndex: typeIndex)))

        case .drop:
            return .value(.parametric(.drop))
        case .select:
            return .value(.parametric(.select))
        case .typed_select:
            // Just discard since our executor doesn't use it
            _ = try parseVector { try parseValueType() }
            return .value(.parametric(.select))

        case .local_get:
            let index: UInt32 = try parseUnsigned()
            return .value(.variable(.localGet(index: index)))
        case .local_set:
            let index: UInt32 = try parseUnsigned()
            return .value(.variable(.localSet(index: index)))
        case .local_tee:
            let index: UInt32 = try parseUnsigned()
            return .value(.variable(.localTee(index: index)))
        case .global_get:
            let index: UInt32 = try parseUnsigned()
            return .value(.variable(.globalGet(index: index)))
        case .global_set:
            let index: UInt32 = try parseUnsigned()
            return .value(.variable(.globalSet(index: index)))

        case .i32_load:
            return .value(try .i32Load(memarg: parseMemarg()))
        case .i64_load:
            return .value(try .i64Load(memarg: parseMemarg()))
        case .f32_load:
            return .value(try .f32Load(memarg: parseMemarg()))
        case .f64_load:
            return .value(try .f64Load(memarg: parseMemarg()))
        case .i32_load8_s:
            return .value(try .i32Load8S(memarg: parseMemarg()))
        case .i32_load8_u:
            return .value(try .i32Load8U(memarg: parseMemarg()))
        case .i32_load16_s:
            return .value(try .i32Load16S(memarg: parseMemarg()))
        case .i32_load16_u:
            return .value(try .i32Load16U(memarg: parseMemarg()))
        case .i64_load8_s:
            return .value(try .i64Load8S(memarg: parseMemarg()))
        case .i64_load8_u:
            return .value(try .i64Load8U(memarg: parseMemarg()))
        case .i64_load16_s:
            return .value(try .i64Load16S(memarg: parseMemarg()))
        case .i64_load16_u:
            return .value(try .i64Load16U(memarg: parseMemarg()))
        case .i64_load32_s:
            return .value(try .i64Load32S(memarg: parseMemarg()))
        case .i64_load32_u:
            return .value(try .i64Load32U(memarg: parseMemarg()))
        case .i32_store:
            return .value(try .i32Store(memarg: parseMemarg()))
        case .i64_store:
            return .value(try .i64Store(memarg: parseMemarg()))
        case .f32_store:
            return .value(try .f32Store(memarg: parseMemarg()))
        case .f64_store:
            return .value(try .f64Store(memarg: parseMemarg()))
        case .i32_store8:
            return .value(try .i32Store8(memarg: parseMemarg()))
        case .i32_store16:
            return .value(try .i32Store16(memarg: parseMemarg()))
        case .i64_store8:
            return .value(try .i64Store8(memarg: parseMemarg()))
        case .i64_store16:
            return .value(try .i64Store16(memarg: parseMemarg()))
        case .i64_store32:
            return .value(try .i64Store32(memarg: parseMemarg()))
        case .memory_size:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw LegacyWasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return .value(.memorySize)
        case .memory_grow:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw LegacyWasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return .value(.memoryGrow)

        case .i32_const:
            let n: UInt32 = try parseInteger()
            return .value(.numericConst((.i32(n))))
        case .i64_const:
            let n: UInt64 = try parseInteger()
            return .value(.numericConst((.i64(n))))
        case .f32_const:
            let n = try parseFloat()
            return .value(.numericConst((.f32(n))))
        case .f64_const:
            let n = try parseDouble()
            return .value(.numericConst((.f64(n))))

        case .i32_eqz:
            return .value(.i32Eqz)
        case .i32_eq:
            return .value(.i32Eq)
        case .i32_ne:
            return .value(.i32Ne)
        case .i32_lt_s:
            return .value(.i32LtS)
        case .i32_lt_u:
            return .value(.i32LtU)
        case .i32_gt_s:
            return .value(.i32GtS)
        case .i32_gt_u:
            return .value(.i32GtU)
        case .i32_le_s:
            return .value(.i32LeS)
        case .i32_le_u:
            return .value(.i32LeU)
        case .i32_ge_s:
            return .value(.i32GeS)
        case .i32_ge_u:
            return .value(.i32GeU)

        case .i64_eqz:
            return .value(.i64Eqz)
        case .i64_eq:
            return .value(.i64Eq)
        case .i64_ne:
            return .value(.i64Ne)
        case .i64_lt_s:
            return .value(.i64LtS)
        case .i64_lt_u:
            return .value(.i64LtU)
        case .i64_gt_s:
            return .value(.i64GtS)
        case .i64_gt_u:
            return .value(.i64GtU)
        case .i64_le_s:
            return .value(.i64LeS)
        case .i64_le_u:
            return .value(.i64LeU)
        case .i64_ge_s:
            return .value(.i64GeS)
        case .i64_ge_u:
            return .value(.i64GeU)

        case .f32_eq:
            return .value(.f32Eq)
        case .f32_ne:
            return .value(.f32Ne)
        case .f32_lt:
            return .value(.numericFloatBinary((.lt(.f32))))
        case .f32_gt:
            return .value(.numericFloatBinary((.gt(.f32))))
        case .f32_le:
            return .value(.numericFloatBinary((.le(.f32))))
        case .f32_ge:
            return .value(.numericFloatBinary((.ge(.f32))))

        case .f64_eq:
            return .value(.f64Eq)
        case .f64_ne:
            return .value(.f64Ne)
        case .f64_lt:
            return .value(.numericFloatBinary((.lt(.f64))))
        case .f64_gt:
            return .value(.numericFloatBinary((.gt(.f64))))
        case .f64_le:
            return .value(.numericFloatBinary((.le(.f64))))
        case .f64_ge:
            return .value(.numericFloatBinary((.ge(.f64))))

        case .i32_clz:
            return .value(.i32Clz)
        case .i32_ctz:
            return .value(.i32Ctz)
        case .i32_popcnt:
            return .value(.i32Popcnt)
        case .i32_add:
            return .value(.i32Add)
        case .i32_sub:
            return .value(.i32Sub)
        case .i32_mul:
            return .value(.i32Mul)
        case .i32_div_s:
            return .value(.numericIntBinary((.divS(.i32))))
        case .i32_div_u:
            return .value(.numericIntBinary((.divU(.i32))))
        case .i32_rem_s:
            return .value(.numericIntBinary((.remS(.i32))))
        case .i32_rem_u:
            return .value(.numericIntBinary((.remU(.i32))))
        case .i32_and:
            return .value(.numericIntBinary((.and(.i32))))
        case .i32_or:
            return .value(.numericIntBinary((.or(.i32))))
        case .i32_xor:
            return .value(.numericIntBinary((.xor(.i32))))
        case .i32_shl:
            return .value(.numericIntBinary((.shl(.i32))))
        case .i32_shr_s:
            return .value(.numericIntBinary((.shrS(.i32))))
        case .i32_shr_u:
            return .value(.numericIntBinary((.shrU(.i32))))
        case .i32_rotl:
            return .value(.numericIntBinary((.rotl(.i32))))
        case .i32_rotr:
            return .value(.numericIntBinary((.rotr(.i32))))

        case .i64_clz:
            return .value(.i64Clz)
        case .i64_ctz:
            return .value(.i64Ctz)
        case .i64_popcnt:
            return .value(.i64Popcnt)
        case .i64_add:
            return .value(.i64Add)
        case .i64_sub:
            return .value(.i64Sub)
        case .i64_mul:
            return .value(.i64Mul)
        case .i64_div_s:
            return .value(.numericIntBinary((.divS(.i64))))
        case .i64_div_u:
            return .value(.numericIntBinary((.divU(.i64))))
        case .i64_rem_s:
            return .value(.numericIntBinary((.remS(.i64))))
        case .i64_rem_u:
            return .value(.numericIntBinary((.remU(.i64))))
        case .i64_and:
            return .value(.numericIntBinary((.and(.i64))))
        case .i64_or:
            return .value(.numericIntBinary((.or(.i64))))
        case .i64_xor:
            return .value(.numericIntBinary((.xor(.i64))))
        case .i64_shl:
            return .value(.numericIntBinary((.shl(.i64))))
        case .i64_shr_s:
            return .value(.numericIntBinary((.shrS(.i64))))
        case .i64_shr_u:
            return .value(.numericIntBinary((.shrU(.i64))))
        case .i64_rotl:
            return .value(.numericIntBinary((.rotl(.i64))))
        case .i64_rotr:
            return .value(.numericIntBinary((.rotr(.i64))))

        case .f32_abs:
            return .value(.numericFloatUnary((.abs(.f32))))
        case .f32_neg:
            return .value(.numericFloatUnary((.neg(.f32))))
        case .f32_ceil:
            return .value(.numericFloatUnary((.ceil(.f32))))
        case .f32_floor:
            return .value(.numericFloatUnary((.floor(.f32))))
        case .f32_trunc:
            return .value(.numericFloatUnary((.trunc(.f32))))
        case .f32_nearest:
            return .value(.numericFloatUnary((.nearest(.f32))))
        case .f32_sqrt:
            return .value(.numericFloatUnary((.sqrt(.f32))))

        case .f32_add:
            return .value(.f32Add)
        case .f32_sub:
            return .value(.f32Sub)
        case .f32_mul:
            return .value(.f32Mul)
        case .f32_div:
            return .value(.numericFloatBinary((.div(.f32))))
        case .f32_min:
            return .value(.numericFloatBinary((.min(.f32))))
        case .f32_max:
            return .value(.numericFloatBinary((.max(.f32))))
        case .f32_copysign:
            return .value(.numericFloatBinary((.copysign(.f32))))

        case .f64_abs:
            return .value(.numericFloatUnary((.abs(.f64))))
        case .f64_neg:
            return .value(.numericFloatUnary((.neg(.f64))))
        case .f64_ceil:
            return .value(.numericFloatUnary((.ceil(.f64))))
        case .f64_floor:
            return .value(.numericFloatUnary((.floor(.f64))))
        case .f64_trunc:
            return .value(.numericFloatUnary((.trunc(.f64))))
        case .f64_nearest:
            return .value(.numericFloatUnary((.nearest(.f64))))
        case .f64_sqrt:
            return .value(.numericFloatUnary((.sqrt(.f64))))

        case .f64_add:
            return .value(.f64Add)
        case .f64_sub:
            return .value(.f64Sub)
        case .f64_mul:
            return .value(.f64Mul)
        case .f64_div:
            return .value(.numericFloatBinary((.div(.f64))))
        case .f64_min:
            return .value(.numericFloatBinary((.min(.f64))))
        case .f64_max:
            return .value(.numericFloatBinary((.max(.f64))))
        case .f64_copysign:
            return .value(.numericFloatBinary((.copysign(.f64))))

        case .i32_wrap_i64:
            return .value(.numericConversion((.wrap)))
        case .i32_trunc_f32_s:
            return .value(.numericConversion((.truncSigned(.i32, .f32))))
        case .i32_trunc_f32_u:
            return .value(.numericConversion((.truncUnsigned(.i32, .f32))))
        case .i32_trunc_f64_s:
            return .value(.numericConversion((.truncSigned(.i32, .f64))))
        case .i32_trunc_f64_u:
            return .value(.numericConversion((.truncUnsigned(.i32, .f64))))
        case .i64_extend_i32_s:
            return .value(.numericConversion((.extendSigned)))
        case .i64_extend_i32_u:
            return .value(.numericConversion((.extendUnsigned)))
        case .i64_trunc_f32_s:
            return .value(.numericConversion((.truncSigned(.i64, .f32))))
        case .i64_trunc_f32_u:
            return .value(.numericConversion((.truncUnsigned(.i64, .f32))))
        case .i64_trunc_f64_s:
            return .value(.numericConversion((.truncSigned(.i64, .f64))))
        case .i64_trunc_f64_u:
            return .value(.numericConversion((.truncUnsigned(.i64, .f64))))
        case .f32_convert_i32_s:
            return .value(.numericConversion((.convertSigned(.f32, .i32))))
        case .f32_convert_i32_u:
            return .value(.numericConversion((.convertUnsigned(.f32, .i32))))
        case .f32_convert_i64_s:
            return .value(.numericConversion((.convertSigned(.f32, .i64))))
        case .f32_convert_i64_u:
            return .value(.numericConversion((.convertUnsigned(.f32, .i64))))
        case .f32_demote_f64:
            return .value(.numericConversion((.demote)))
        case .f64_convert_i32_s:
            return .value(.numericConversion((.convertSigned(.f64, .i32))))
        case .f64_convert_i32_u:
            return .value(.numericConversion((.convertUnsigned(.f64, .i32))))
        case .f64_convert_i64_s:
            return .value(.numericConversion((.convertSigned(.f64, .i64))))
        case .f64_convert_i64_u:
            return .value(.numericConversion((.convertUnsigned(.f64, .i64))))
        case .f64_promote_f32:
            return .value(.numericConversion((.promote)))
        case .i32_reinterpret_f32:
            return .value(.numericConversion((.reinterpret(.int(.i32), .float(.f32)))))
        case .i64_reinterpret_f64:
            return .value(.numericConversion((.reinterpret(.int(.i64), .float(.f64)))))
        case .f32_reinterpret_i32:
            return .value(.numericConversion((.reinterpret(.float(.f32), .int(.i32)))))
        case .f64_reinterpret_i64:
            return .value(.numericConversion((.reinterpret(.float(.f64), .int(.i64)))))

        case .i32_extend8_s:
            return .value(.numericConversion((.extend8Signed(.i32))))
        case .i32_extend16_s:
            return .value(.numericConversion((.extend16Signed(.i32))))
        case .i64_extend8_s:
            return .value(.numericConversion((.extend8Signed(.i64))))
        case .i64_extend16_s:
            return .value(.numericConversion((.extend16Signed(.i64))))
        case .i64_extend32_s:
            return .value(.numericConversion((.extend32Signed)))

        case .ref_null:
            let type = try parseValueType()

            guard case let .reference(refType) = type else {
                throw LegacyWasmParserError.expectedRefType(actual: type)
            }

            return .value(.reference(.refNull(refType)))

        case .ref_is_null:
            return .value(.reference(.refIsNull))

        case .ref_func:
            return .value(try .reference(.refFunc(parseUnsigned())))

        case .table_get:
            return .value(try .tableGet(parseUnsigned()))

        case .table_set:
            return .value(try .tableSet(parseUnsigned()))

        case .wasm2InstructionPrefix:
            let codeSuffix: UInt32 = try parseUnsigned()
            switch codeSuffix {
            case 0:
                return .value(.numericConversion((.truncSaturatingSigned(.i32, .f32))))
            case 1:
                return .value(.numericConversion((.truncSaturatingUnsigned(.i32, .f32))))
            case 2:
                return .value(.numericConversion((.truncSaturatingSigned(.i32, .f64))))
            case 3:
                return .value(.numericConversion((.truncSaturatingUnsigned(.i32, .f64))))
            case 4:
                return .value(.numericConversion((.truncSaturatingSigned(.i64, .f32))))
            case 5:
                return .value(.numericConversion((.truncSaturatingUnsigned(.i64, .f32))))
            case 6:
                return .value(.numericConversion((.truncSaturatingSigned(.i64, .f64))))
            case 7:
                return .value(.numericConversion((.truncSaturatingUnsigned(.i64, .f64))))
            case 8:
                let result = try Instruction.memoryInit(parseUnsigned())
                // memory.init requires data count section
                // https://webassembly.github.io/spec/core/binary/modules.html#data-count-section
                guard hasDataCount else {
                    throw LegacyWasmParserError.dataCountSectionRequired
                }

                let zero = try stream.consumeAny()
                guard zero == 0x00 else {
                    throw LegacyWasmParserError.zeroExpected(actual: zero, index: currentIndex)
                }

                return .value(result)

            case 9:
                // memory.drop requires data count section
                // https://webassembly.github.io/spec/core/binary/modules.html#data-count-section
                guard hasDataCount else {
                    throw LegacyWasmParserError.dataCountSectionRequired
                }
                return .value(try .memoryDataDrop(parseUnsigned()))

            case 10:
                let (zero1, zero2) = try (stream.consumeAny(), stream.consumeAny())
                guard zero1 == 0x00 && zero2 == 0x00 else {
                    throw LegacyWasmParserError.zeroExpected(actual: zero2, index: currentIndex)
                }
                return .value(.memoryCopy)

            case 11:
                let zero = try stream.consumeAny()
                guard zero == 0x00 else {
                    throw LegacyWasmParserError.zeroExpected(actual: zero, index: currentIndex)
                }

                return .value(.memoryFill)

            case 12:
                let elementIndex: ElementIndex = try parseUnsigned()
                let tableIndex: TableIndex = try parseUnsigned()
                return .value(.tableInit(tableIndex, elementIndex))

            case 13:
                return .value(try .tableElementDrop(parseUnsigned()))

            case 14:
                let sourceTableIndex: TableIndex = try parseUnsigned()
                let destinationTableIndex: TableIndex = try parseUnsigned()
                return .value(.tableCopy(dest: sourceTableIndex, src: destinationTableIndex))

            case 15:
                return .value(try .tableGrow(parseUnsigned()))

            case 16:
                return .value(try .tableSize(parseUnsigned()))

            case 17:
                return .value(try .tableFill(parseUnsigned()))

            default:
                throw LegacyWasmParserError.unimplementedInstruction(rawCode, suffix: codeSuffix)
            }
        }
    }

    func parseExpression(typeSection: [FunctionType]? = nil) throws -> Expression {
        let constExpr = try WasmParser.parseConstExpression(
            stream: self.stream,
            features: features,
            hasDataCount: hasDataCount
        )
        return constExpr.instructions
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension LegacyWasmParser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#custom-section>
    func parseCustomSection(size: UInt32) throws -> CustomSection {
        let preNameIndex = stream.currentIndex
        let name = try parseName()
        let nameSize = stream.currentIndex - preNameIndex
        let contentSize = Int(size) - nameSize

        guard contentSize >= 0 else {
            throw LegacyWasmParserError.invalidSectionSize(size)
        }

        let bytes = try stream.consume(count: contentSize)

        return CustomSection(name: name, bytes: bytes)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#type-section>
    func parseTypeSection() throws -> [FunctionType] {
        return try parseVector { try parseFunctionType() }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#import-section>
    func parseImportSection() throws -> [Import] {
        return try parseVector {
            let module = try parseName()
            let name = try parseName()
            let descriptor = try parseImportDescriptor()
            return Import(module: module, name: name, descriptor: descriptor)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-importdesc>
    func parseImportDescriptor() throws -> ImportDescriptor {
        let b = try stream.consume(Set(0x00...0x03))
        switch b {
        case 0x00:
            return try .function(parseUnsigned())
        case 0x01:
            return try .table(parseTableType())
        case 0x02:
            return try .memory(parseMemoryType())
        case 0x03:
            return try .global(parseGlobalType())
        default:
            preconditionFailure("should never reach here")
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#function-section>
    func parseFunctionSection() throws -> [TypeIndex] {
        return try parseVector { try parseUnsigned() }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#table-section>
    func parseTableSection() throws -> [Table] {
        return try parseVector { try Table(type: parseTableType()) }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#memory-section>
    func parseMemorySection() throws -> [Memory] {
        return try parseVector { try Memory(type: parseLimits()) }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#global-section>
    func parseGlobalSection() throws -> [Global] {
        return try parseVector {
            let type = try parseGlobalType()
            let expression = try parseExpression()
            return Global(type: type, initializer: expression)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#export-section>
    func parseExportSection() throws -> [Export] {
        return try parseVector {
            let name = try parseName()
            let descriptor = try parseExportDescriptor()
            return Export(name: name, descriptor: descriptor)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-exportdesc>
    func parseExportDescriptor() throws -> ExportDescriptor {
        let b = try stream.consume(Set(0x00...0x03))
        switch b {
        case 0x00:
            return try .function(parseUnsigned())
        case 0x01:
            return try .table(parseUnsigned())
        case 0x02:
            return try .memory(parseUnsigned())
        case 0x03:
            return try .global(parseUnsigned())
        default:
            preconditionFailure("should never reach here")
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#start-section>
    func parseStartSection() throws -> FunctionIndex {
        return try parseUnsigned()
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#element-section>
    func parseElementSection() throws -> [ElementSegment] {
        return try parseVector {
            let flag = try ElementSegment.Flag(rawValue: parseUnsigned())

            let type: ReferenceType
            let initializer: [Expression]
            let mode: ElementSegment.Mode

            if flag.contains(.isPassiveOrDeclarative) {
                if flag.contains(.isDeclarative) {
                    mode = .declarative
                } else {
                    mode = .passive
                }
            } else {
                let table: TableIndex

                if flag.contains(.hasTableIndex) {
                    table = try parseUnsigned()
                } else {
                    table = 0
                }

                let offset = try parseExpression()
                mode = .active(table: table, offset: offset)
            }

            if flag.segmentHasRefType {
                let valueType = try parseValueType()

                guard case let .reference(refType) = valueType else {
                    throw LegacyWasmParserError.expectedRefType(actual: valueType)
                }

                type = refType
            } else {
                type = .funcRef
            }

            if flag.segmentHasElemKind {
                // `elemkind` parsing as defined in the spec
                let elemKind = try parseUnsigned() as UInt32
                guard elemKind == 0x00 else {
                    throw LegacyWasmParserError.unexpectedElementKind(expected: 0x00, actual: elemKind)
                }
            }

            if flag.contains(.usesExpressions) {
                initializer = try parseVector { try parseExpression() }
            } else {
                initializer = try parseVector {
                    try [.refFunc(functionIndex: parseUnsigned() as UInt32)]
                }
            }

            return ElementSegment(type: type, initializer: initializer, mode: mode)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#code-section>
    func parseCodeSection() throws -> [Code] {
        return try parseVector {
            let size = try parseUnsigned() as UInt32
            let bodyStart = stream.currentIndex
            let localTypes = try parseVector { () -> (n: UInt32, type: ValueType) in
                let n: UInt32 = try parseUnsigned()
                let t = try parseValueType()
                return (n, t)
            }
            let totalLocals = localTypes.reduce(UInt64(0)) { $0 + UInt64($1.n) }
            guard totalLocals < UInt32.max else {
                throw LegacyWasmParserError.tooManyLocals
            }

            let locals = localTypes.map { (n: UInt32, type: ValueType) in
                return (0..<n).map { _ in type }
            }
            let expressionBytes = try stream.consume(
                count: Int(size) - (stream.currentIndex - bodyStart)
            )
            return Code(locals: locals.flatMap { $0 }, expression: expressionBytes)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-section>
    func parseDataSection() throws -> [DataSegment] {
        return try parseVector {
            let kind: UInt32 = try parseUnsigned()
            switch kind {
            case 0:
                let offset = try parseExpression()
                let initializer = try parseVectorBytes()
                return .active(.init(index: 0, offset: offset, initializer: initializer))

            case 1:
                return try .passive(parseVector { try stream.consumeAny() })

            case 2:
                let index: UInt32 = try parseUnsigned()
                let offset = try parseExpression()
                let initializer = try parseVectorBytes()
                return .active(.init(index: index, offset: offset, initializer: initializer))
            default:
                fatalError("unimplemented data segment kind")
            }
        }
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
