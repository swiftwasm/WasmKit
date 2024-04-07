import Foundation

public struct Parser<Stream: ByteStream> {
    let stream: Stream
    private var hasDataCount: Bool = false
    private let features: WasmFeatureSet

    enum NextParseTarget {
        case header
        case section
    }
    private var nextParseTarget: NextParseTarget

    var currentIndex: Int {
        return stream.currentIndex
    }

    public init(stream: Stream, features: WasmFeatureSet = .default, hasDataCount: Bool = false) {
        self.stream = stream
        self.features = features
        self.hasDataCount = hasDataCount
        self.nextParseTarget = .header
    }
}

public func parseExpression<V: InstructionVisitor, Stream: ByteStream>(
    stream: Stream,
    features: WasmFeatureSet = .default,
    hasDataCount: Bool = false,
    visitor: inout V
) throws {
    let parser = Parser(stream: stream, features: features, hasDataCount: hasDataCount)
    var lastCode: InstructionCode?
    while try !parser.stream.hasReachedEnd() {
        (lastCode, _) = try parser.parseInstruction(visitor: &visitor)
    }
    guard lastCode == .end else {
        throw WasmParserError.endOpcodeExpected
    }
}
public func parseExpression<V: InstructionVisitor>(bytes: [UInt8], features: WasmFeatureSet = .default, hasDataCount: Bool = false, visitor: inout V) throws {
    try parseExpression(
        stream: StaticByteStream(bytes: bytes), features: features,
        hasDataCount: hasDataCount, visitor: &visitor
    )
}

/// Flags for enabling/disabling WebAssembly features
public struct WasmFeatureSet: OptionSet {
    /// The raw value of the feature set
    public let rawValue: Int

    /// Initialize a new feature set with the given raw value
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The WebAssembly memory64 proposal
    public static let memory64 = WasmFeatureSet(rawValue: 1 << 0)
    /// The WebAssembly reference types proposal
    public static let referenceTypes = WasmFeatureSet(rawValue: 1 << 1)

    /// The default feature set
    public static let `default`: WasmFeatureSet = [.referenceTypes]
    /// The feature set with all features enabled
    public static let all: WasmFeatureSet = [.memory64, .referenceTypes]
}

public enum WasmParserError: Swift.Error {
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
    case raw(String)

    init(_ message: String) {
        self = .raw(message)
    }
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
            case .error: throw WasmParserError.invalidUTF8(bytes)
            }
        }

        return name
    }
}

extension Parser {
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
extension Parser {
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
extension Parser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#value-types>
    func parseValueType() throws -> ValueType {
        let b = try stream.consumeAny()

        switch b {
        case 0x7F: return .i32
        case 0x7E: return .i64
        case 0x7D: return .f32
        case 0x7C: return .f64
        case 0x70: return .ref(.funcRef)
        case 0x6F: return .ref(.externRef)
        default:
            throw StreamError<Stream.Element>.unexpected(b, index: currentIndex, expected: Set(0x7C...0x7F))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#result-types>
    func parseResultType() throws -> BlockType {
        let nextByte = try stream.peek()!
        switch nextByte {
        case 0x40:
            _ = try stream.consumeAny()
            return .empty
        case 0x7C...0x7F, 0x70, 0x6F:
            return try .type(parseValueType())
        default:
            return try .funcType(TypeIndex(stream.consumeAny()))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#function-types>
    func parseFunctionType() throws -> FunctionType {
        let opcode = try stream.consumeAny()

        // XXX: spectest expects the first byte should be parsed as a LEB128 with 1 byte limit
        // but the spec itself doesn't require it, so just check the continue bit of LEB128 here.
        guard opcode & 0b10000000 == 0 else {
            throw WasmParserError.integerRepresentationTooLong
        }
        guard opcode == 0x60 else {
            throw WasmParserError.malformedFunctionType(opcode)
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
            throw WasmParserError.malformedLimit(b)
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
            throw WasmParserError.malformedMutability(b)
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/instructions.html#memory-instructions>
    func parseMemarg() throws -> MemArg {
        let align: UInt32 = try parseUnsigned()
        let offset: UInt64 = try features.contains(.memory64) ? parseUnsigned(UInt64.self) : UInt64(parseUnsigned(UInt32.self))
        return MemArg(offset: offset, align: align)
    }

    func parseVectorBytes() throws -> ArraySlice<UInt8> {
        let count: UInt32 = try parseUnsigned()
        return try stream.consume(count: Int(count))
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html>
extension Parser {
    func parseInstruction<V: InstructionVisitor>(visitor v: inout V) throws -> (InstructionCode, V.Output) {
        let rawCode = try stream.consumeAny()
        guard let code = InstructionCode(rawValue: rawCode) else {
            throw WasmParserError.illegalOpcode(rawCode)
        }
        return (code, try doParseInstruction(code: code, visitor: &v))
    }

    func doParseInstruction<V: InstructionVisitor>(code: InstructionCode, visitor v: inout V) throws -> V.Output {
        switch code {
        case .unreachable: return try v.visitUnreachable()
        case .nop: return try v.visitNop()
        case .block: return try v.visitBlock(blockType: try parseResultType())
        case .loop: return try v.visitLoop(blockType: try parseResultType())
        case .if: return try v.visitIf(blockType: try parseResultType())
        case .else: return try v.visitElse()
        case .end: return try v.visitEnd()
        case .br:
            let label: UInt32 = try parseUnsigned()
            return try v.visitBr(relativeDepth: label)
        case .br_if:
            let label: UInt32 = try parseUnsigned()
            return try v.visitBrIf(relativeDepth: label)
        case .br_table:
            let labelIndices: [UInt32] = try parseVector { try parseUnsigned() }
            let labelIndex: UInt32 = try parseUnsigned()
            return try v.visitBrTable(targets: BrTable(labelIndices: labelIndices, defaultIndex: labelIndex))
        case .return:
            return try v.visitReturn()
        case .call:
            let index: UInt32 = try parseUnsigned()
            return try v.visitCall(functionIndex: index)
        case .call_indirect:
            let typeIndex: TypeIndex = try parseUnsigned()
            if try !features.contains(.referenceTypes) && stream.peek() != 0 {
                // Check that reserved byte is zero when reference-types is disabled
                throw WasmParserError.malformedIndirectCall
            }
            let tableIndex: TableIndex = try parseUnsigned()
            return try v.visitCallIndirect(typeIndex: typeIndex, tableIndex: tableIndex)
        case .drop: return try v.visitDrop()
        case .select: return try v.visitSelect()
        case .typed_select:
            let results = try parseVector { try parseValueType() }
            guard results.count == 1 else {
                throw WasmParserError("Only single result type is allowed but got \(results)")
            }
            return try v.visitTypedSelect(type: results[0])

        case .local_get:
            let index: UInt32 = try parseUnsigned()
            return try v.visitLocalGet(localIndex: index)
        case .local_set:
            let index: UInt32 = try parseUnsigned()
            return try v.visitLocalSet(localIndex: index)
        case .local_tee:
            let index: UInt32 = try parseUnsigned()
            return try v.visitLocalTee(localIndex: index)
        case .global_get:
            let index: UInt32 = try parseUnsigned()
            return try v.visitGlobalGet(globalIndex: index)
        case .global_set:
            let index: UInt32 = try parseUnsigned()
            return try v.visitGlobalSet(globalIndex: index)

        case .i32_load:     return try v.visitI32Load(memarg: try parseMemarg())
        case .i64_load:     return try v.visitI64Load(memarg: try parseMemarg())
        case .f32_load:     return try v.visitF32Load(memarg: try parseMemarg())
        case .f64_load:     return try v.visitF64Load(memarg: try parseMemarg())
        case .i32_load8_s:  return try v.visitI32Load8S(memarg: try parseMemarg())
        case .i32_load8_u:  return try v.visitI32Load8U(memarg: try parseMemarg())
        case .i32_load16_s: return try v.visitI32Load16S(memarg: try parseMemarg())
        case .i32_load16_u: return try v.visitI32Load16U(memarg: try parseMemarg())
        case .i64_load8_s:  return try v.visitI64Load8S(memarg: try parseMemarg())
        case .i64_load8_u:  return try v.visitI64Load8U(memarg: try parseMemarg())
        case .i64_load16_s: return try v.visitI64Load16S(memarg: try parseMemarg())
        case .i64_load16_u: return try v.visitI64Load16U(memarg: try parseMemarg())
        case .i64_load32_s: return try v.visitI64Load32S(memarg: try parseMemarg())
        case .i64_load32_u: return try v.visitI64Load32U(memarg: try parseMemarg())
        case .i32_store:    return try v.visitI32Store(memarg: try parseMemarg())
        case .i64_store:    return try v.visitI64Store(memarg: try parseMemarg())
        case .f32_store:    return try v.visitF32Store(memarg: try parseMemarg())
        case .f64_store:    return try v.visitF64Store(memarg: try parseMemarg())
        case .i32_store8:   return try v.visitI32Store8(memarg: try parseMemarg())
        case .i32_store16:  return try v.visitI32Store16(memarg: try parseMemarg())
        case .i64_store8:   return try v.visitI64Store8(memarg: try parseMemarg())
        case .i64_store16:  return try v.visitI64Store16(memarg: try parseMemarg())
        case .i64_store32:  return try v.visitI64Store32(memarg: try parseMemarg())
        case .memory_size:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return try v.visitMemorySize(memory: UInt32(zero))
        case .memory_grow:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return try v.visitMemoryGrow(memory: UInt32(zero))

        case .i32_const:
            let n: UInt32 = try parseInteger()
            return try v.visitI32Const(value: Int32(bitPattern: n))
        case .i64_const:
            let n: UInt64 = try parseInteger()
            return try v.visitI64Const(value: Int64(bitPattern: n))
        case .f32_const:
            let n = try parseFloat()
            return try v.visitF32Const(value: IEEE754.Float32(bitPattern: n))
        case .f64_const:
            let n = try parseDouble()
            return try v.visitF64Const(value: IEEE754.Float64(bitPattern: n))

        case .i32_eqz:  return try v.visitI32Eqz()
        case .i32_eq:   return try v.visitI32Eq()
        case .i32_ne:   return try v.visitI32Ne()
        case .i32_lt_s: return try v.visitI32LtS()
        case .i32_lt_u: return try v.visitI32LtU()
        case .i32_gt_s: return try v.visitI32GtS()
        case .i32_gt_u: return try v.visitI32GtU()
        case .i32_le_s: return try v.visitI32LeS()
        case .i32_le_u: return try v.visitI32LeU()
        case .i32_ge_s: return try v.visitI32GeS()
        case .i32_ge_u: return try v.visitI32GeU()

        case .i64_eqz:  return try v.visitI64Eqz()
        case .i64_eq:   return try v.visitI64Eq()
        case .i64_ne:   return try v.visitI64Ne()
        case .i64_lt_s: return try v.visitI64LtS()
        case .i64_lt_u: return try v.visitI64LtU()
        case .i64_gt_s: return try v.visitI64GtS()
        case .i64_gt_u: return try v.visitI64GtU()
        case .i64_le_s: return try v.visitI64LeS()
        case .i64_le_u: return try v.visitI64LeU()
        case .i64_ge_s: return try v.visitI64GeS()
        case .i64_ge_u: return try v.visitI64GeU()

        case .f32_eq: return try v.visitF32Eq()
        case .f32_ne: return try v.visitF32Ne()
        case .f32_lt: return try v.visitF32Lt()
        case .f32_gt: return try v.visitF32Gt()
        case .f32_le: return try v.visitF32Le()
        case .f32_ge: return try v.visitF32Ge()

        case .f64_eq: return try v.visitF64Eq()
        case .f64_ne: return try v.visitF64Ne()
        case .f64_lt: return try v.visitF64Lt()
        case .f64_gt: return try v.visitF64Gt()
        case .f64_le: return try v.visitF64Le()
        case .f64_ge: return try v.visitF64Ge()

        case .i32_clz:    return try v.visitI32Clz()
        case .i32_ctz:    return try v.visitI32Ctz()
        case .i32_popcnt: return try v.visitI32Popcnt()
        case .i32_add:    return try v.visitI32Add()
        case .i32_sub:    return try v.visitI32Sub()
        case .i32_mul:    return try v.visitI32Mul()
        case .i32_div_s:  return try v.visitI32DivS()
        case .i32_div_u:  return try v.visitI32DivU()
        case .i32_rem_s:  return try v.visitI32RemS()
        case .i32_rem_u:  return try v.visitI32RemU()
        case .i32_and:    return try v.visitI32And()
        case .i32_or:     return try v.visitI32Or()
        case .i32_xor:    return try v.visitI32Xor()
        case .i32_shl:    return try v.visitI32Shl()
        case .i32_shr_s:  return try v.visitI32ShrS()
        case .i32_shr_u:  return try v.visitI32ShrU()
        case .i32_rotl:   return try v.visitI32Rotl()
        case .i32_rotr:   return try v.visitI32Rotr()

        case .i64_clz:    return try v.visitI64Clz()
        case .i64_ctz:    return try v.visitI64Ctz()
        case .i64_popcnt: return try v.visitI64Popcnt()
        case .i64_add:    return try v.visitI64Add()
        case .i64_sub:    return try v.visitI64Sub()
        case .i64_mul:    return try v.visitI64Mul()
        case .i64_div_s:  return try v.visitI64DivS()
        case .i64_div_u:  return try v.visitI64DivU()
        case .i64_rem_s:  return try v.visitI64RemS()
        case .i64_rem_u:  return try v.visitI64RemU()
        case .i64_and:    return try v.visitI64And()
        case .i64_or:     return try v.visitI64Or()
        case .i64_xor:    return try v.visitI64Xor()
        case .i64_shl:    return try v.visitI64Shl()
        case .i64_shr_s:  return try v.visitI64ShrS()
        case .i64_shr_u:  return try v.visitI64ShrU()
        case .i64_rotl:   return try v.visitI64Rotl()
        case .i64_rotr:   return try v.visitI64Rotr()

        case .f32_abs:     return try v.visitF32Abs()
        case .f32_neg:     return try v.visitF32Neg()
        case .f32_ceil:    return try v.visitF32Ceil()
        case .f32_floor:   return try v.visitF32Floor()
        case .f32_trunc:   return try v.visitF32Trunc()
        case .f32_nearest: return try v.visitF32Nearest()
        case .f32_sqrt:    return try v.visitF32Sqrt()

        case .f32_add: return try v.visitF32Add()
        case .f32_sub: return try v.visitF32Sub()
        case .f32_mul: return try v.visitF32Mul()
        case .f32_div: return try v.visitF32Div()
        case .f32_min: return try v.visitF32Min()
        case .f32_max: return try v.visitF32Max()
        case .f32_copysign: return try v.visitF32Copysign()

        case .f64_abs: return try v.visitF64Abs()
        case .f64_neg: return try v.visitF64Neg()
        case .f64_ceil: return try v.visitF64Ceil()
        case .f64_floor: return try v.visitF64Floor()
        case .f64_trunc: return try v.visitF64Trunc()
        case .f64_nearest: return try v.visitF64Nearest()
        case .f64_sqrt: return try v.visitF64Sqrt()

        case .f64_add: return try v.visitF64Add()
        case .f64_sub: return try v.visitF64Sub()
        case .f64_mul: return try v.visitF64Mul()
        case .f64_div: return try v.visitF64Div()
        case .f64_min: return try v.visitF64Min()
        case .f64_max: return try v.visitF64Max()
        case .f64_copysign: return try v.visitF64Copysign()

        case .i32_wrap_i64:        return try v.visitI32WrapI64()
        case .i32_trunc_f32_s:     return try v.visitI32TruncF32S()
        case .i32_trunc_f32_u:     return try v.visitI32TruncF32U()
        case .i32_trunc_f64_s:     return try v.visitI32TruncF64S()
        case .i32_trunc_f64_u:     return try v.visitI32TruncF64U()
        case .i64_extend_i32_s:    return try v.visitI64ExtendI32S()
        case .i64_extend_i32_u:    return try v.visitI64ExtendI32U()
        case .i64_trunc_f32_s:     return try v.visitI64TruncF32S()
        case .i64_trunc_f32_u:     return try v.visitI64TruncF32U()
        case .i64_trunc_f64_s:     return try v.visitI64TruncF64S()
        case .i64_trunc_f64_u:     return try v.visitI64TruncF64U()
        case .f32_convert_i32_s:   return try v.visitF32ConvertI32S()
        case .f32_convert_i32_u:   return try v.visitF32ConvertI32U()
        case .f32_convert_i64_s:   return try v.visitF32ConvertI64S()
        case .f32_convert_i64_u:   return try v.visitF32ConvertI64U()
        case .f32_demote_f64:      return try v.visitF32DemoteF64()
        case .f64_convert_i32_s:   return try v.visitF64ConvertI32S()
        case .f64_convert_i32_u:   return try v.visitF64ConvertI32U()
        case .f64_convert_i64_s:   return try v.visitF64ConvertI64S()
        case .f64_convert_i64_u:   return try v.visitF64ConvertI64U()
        case .f64_promote_f32:     return try v.visitF64PromoteF32()
        case .i32_reinterpret_f32: return try v.visitI32ReinterpretF32()
        case .i64_reinterpret_f64: return try v.visitI64ReinterpretF64()
        case .f32_reinterpret_i32: return try v.visitF32ReinterpretI32()
        case .f64_reinterpret_i64: return try v.visitF64ReinterpretI64()
        case .i32_extend8_s:       return try v.visitI32Extend8S()
        case .i32_extend16_s:      return try v.visitI32Extend16S()
        case .i64_extend8_s:       return try v.visitI64Extend8S()
        case .i64_extend16_s:      return try v.visitI64Extend16S()
        case .i64_extend32_s:      return try v.visitI64Extend32S()

        case .ref_null:
            let type = try parseValueType()

            guard case let .ref(refType) = type else {
                throw WasmParserError.expectedRefType(actual: type)
            }

            return try v.visitRefNull(type: refType)

        case .ref_is_null: return try v.visitRefIsNull()

        case .ref_func: return try v.visitRefFunc(functionIndex: try parseUnsigned())

        case .table_get: return try v.visitTableGet(table: try parseUnsigned())

        case .table_set: return try v.visitTableSet(table: try parseUnsigned())

        case .wasm2InstructionPrefix:
            let codeSuffix: UInt32 = try parseUnsigned()
            switch codeSuffix {
            case 0: return try v.visitI32TruncSatF32S()
            case 1: return try v.visitI32TruncSatF32U()
            case 2: return try v.visitI32TruncSatF64S()
            case 3: return try v.visitI32TruncSatF64U()
            case 4: return try v.visitI64TruncSatF32S()
            case 5: return try v.visitI64TruncSatF32U()
            case 6: return try v.visitI64TruncSatF64S()
            case 7: return try v.visitI64TruncSatF64U()
            case 8:
                let dataIndex: DataIndex = try parseUnsigned()
                // memory.init requires data count section
                // https://webassembly.github.io/spec/core/binary/modules.html#data-count-section
                guard hasDataCount else {
                    throw WasmParserError.dataCountSectionRequired
                }

                let zero = try stream.consumeAny()
                guard zero == 0x00 else {
                    throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
                }

                return try v.visitMemoryInit(dataIndex: dataIndex)
            case 9:
                // memory.drop requires data count section
                // https://webassembly.github.io/spec/core/binary/modules.html#data-count-section
                guard hasDataCount else {
                    throw WasmParserError.dataCountSectionRequired
                }
                return try v.visitDataDrop(dataIndex: try parseUnsigned())
            case 10:
                let (zero1, zero2) = try (stream.consumeAny(), stream.consumeAny())
                guard zero1 == 0x00 && zero2 == 0x00 else {
                    throw WasmParserError.zeroExpected(actual: zero2, index: currentIndex)
                }
                return try v.visitMemoryCopy(dstMem: 0, srcMem: 0)
            case 11:
                let zero = try stream.consumeAny()
                guard zero == 0x00 else {
                    throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
                }

                return try v.visitMemoryFill(memory: 0)
            case 12:
                let elementIndex: ElementIndex = try parseUnsigned()
                let tableIndex: TableIndex = try parseUnsigned()
                return try v.visitTableInit(elemIndex: elementIndex, table: tableIndex)
            case 13: return try v.visitElemDrop(elemIndex: try parseUnsigned())
            case 14:
                let destinationTableIndex: TableIndex = try parseUnsigned()
                let sourceTableIndex: TableIndex = try parseUnsigned()
                return try v.visitTableCopy(dstTable: destinationTableIndex, srcTable: sourceTableIndex)
            case 15: return try v.visitTableGrow(table: try parseUnsigned())
            case 16: return try v.visitTableSize(table: try parseUnsigned())
            case 17: return try v.visitTableFill(table: try parseUnsigned())
            default:
                throw WasmParserError.unimplementedInstruction(code.rawValue, suffix: codeSuffix)
            }
        }
    }

    func parseConstExpression() throws -> ConstExpression {
        var factory = InstructionFactory()
        var insts: [Instruction] = []
        var inst: Instruction
        repeat {
            (_, inst) = try self.parseInstruction(visitor: &factory)
            insts.append(inst)
        } while inst != .end
        return insts
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension Parser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#custom-section>
    func parseCustomSection(size: UInt32) throws -> CustomSection {
        let preNameIndex = stream.currentIndex
        let name = try parseName()
        let nameSize = stream.currentIndex - preNameIndex
        let contentSize = Int(size) - nameSize

        guard contentSize >= 0 else {
            throw WasmParserError.invalidSectionSize(size)
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
        case 0x00: return try .function(parseUnsigned())
        case 0x01: return try .table(parseTableType())
        case 0x02: return try .memory(parseMemoryType())
        case 0x03: return try .global(parseGlobalType())
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
            let expression = try parseConstExpression()
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
        case 0x00: return try .function(parseUnsigned())
        case 0x01: return try .table(parseUnsigned())
        case 0x02: return try .memory(parseUnsigned())
        case 0x03: return try .global(parseUnsigned())
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
            let initializer: [ConstExpression]
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

                let offset = try parseConstExpression()
                mode = .active(table: table, offset: offset)
            }

            if flag.segmentHasRefType {
                let valueType = try parseValueType()

                guard case let .ref(refType) = valueType else {
                    throw WasmParserError.expectedRefType(actual: valueType)
                }

                type = refType
            } else {
                type = .funcRef
            }

            if flag.segmentHasElemKind {
                // `elemkind` parsing as defined in the spec
                let elemKind = try parseUnsigned() as UInt32
                guard elemKind == 0x00 else {
                    throw WasmParserError.unexpectedElementKind(expected: 0x00, actual: elemKind)
                }
            }

            if flag.contains(.usesExpressions) {
                initializer = try parseVector { try parseConstExpression() }
            } else {
                initializer = try parseVector {
                    try [Instruction.refFunc(functionIndex: parseUnsigned() as UInt32)]
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
                throw WasmParserError.tooManyLocals
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
                let offset = try parseConstExpression()
                let initializer = try parseVectorBytes()
                return .active(.init(index: 0, offset: offset, initializer: initializer))

            case 1:
                return try .passive(parseVector { try stream.consumeAny() })

            case 2:
                let index: UInt32 = try parseUnsigned()
                let offset = try parseConstExpression()
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
extension Parser {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-magic>
    func parseMagicNumber() throws {
        let magicNumber = try stream.consume(count: 4)
        guard magicNumber == [0x00, 0x61, 0x73, 0x6D] else {
            throw WasmParserError.invalidMagicNumber(.init(magicNumber))
        }
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-version>
    func parseVersion() throws -> [UInt8] {
        let version = try Array(stream.consume(count: 4))
        guard version == [0x01, 0x00, 0x00, 0x00] else {
            throw WasmParserError.unknownVersion(.init(version))
        }
        return version
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

    public enum Payload {
        case header(version: [UInt8])
        case customSection(CustomSection)
        case typeSection([FunctionType])
        case importSection([Import])
        case functionSection([TypeIndex])
        case tableSection([Table])
        case memorySection([Memory])
        case globalSection([Global])
        case exportSection([Export])
        case startSection(FunctionIndex)
        case elementSection([ElementSegment])
        case codeSection([Code])
        case dataSection([DataSegment])
        case dataCount(UInt32)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
    public mutating func parseNext() throws -> Payload? {
        switch nextParseTarget {
        case .header:
            try parseMagicNumber()
            let version = try parseVersion()
            self.nextParseTarget = .section
            return .header(version: version)
        case .section:
            guard try !stream.hasReachedEnd() else {
                return nil
            }
            let sectionID = try stream.consumeAny()
            let sectionSize: UInt32 = try parseUnsigned()
            let sectionStart = stream.currentIndex

            let payload: Payload
            switch sectionID {
            case 0:  payload = .customSection(try parseCustomSection(size: sectionSize))
            case 1:  payload = .typeSection(try parseTypeSection())
            case 2:  payload = .importSection(try parseImportSection())
            case 3:  payload = .functionSection(try parseFunctionSection())
            case 4:  payload = .tableSection(try parseTableSection())
            case 5:  payload = .memorySection(try parseMemorySection())
            case 6:  payload = .globalSection(try parseGlobalSection())
            case 7:  payload = .exportSection(try parseExportSection())
            case 8:  payload = .startSection(try parseStartSection())
            case 9:  payload = .elementSection(try parseElementSection())
            case 10: payload = .codeSection(try parseCodeSection())
            case 11: payload = .dataSection(try parseDataSection())
            case 12:
                hasDataCount = true
                payload = .dataCount(try parseDataCountSection())
            default:
                throw WasmParserError.malformedSectionID(sectionID)
            }
            let expectedSectionEnd = sectionStart + Int(sectionSize)
            guard expectedSectionEnd == stream.currentIndex else {
                throw WasmParserError.sectionSizeMismatch(
                    expected: expectedSectionEnd, actual: stream.currentIndex
                )
            }
            return payload
        }
    }
}

/// > Note: <https://webassembly.github.io/spec/core/appendix/custom.html#name-section>
public struct NameSectionParser<Stream: ByteStream> {
    let stream: Stream

    public typealias NameMap = [UInt32: String]
    public enum ParsedNames {
        case functions(NameMap)
    }

    public init(stream: Stream) {
        self.stream = stream
    }

    public func parseAll() throws -> [ParsedNames] {
        var results: [ParsedNames] = []
        while try !stream.hasReachedEnd() {
            let id = try stream.consumeAny()
            guard let result = try parseNameSubsection(type: id) else {
                continue
            }
            results.append(result)
        }
        return results
    }

    func parseNameSubsection(type: UInt8) throws -> ParsedNames? {
        let size = try stream.parseUnsigned(UInt32.self)
        switch type {
        case 1:  // function names
            return .functions(try parseNameMap())
        case 0, 2:  // local names
            fallthrough
        default:
            // Just skip other sections for now
            _ = try stream.consume(count: Int(size))
            return nil
        }
    }

    func parseNameMap() throws -> NameMap {
        var nameMap: NameMap = [:]
        _ = try stream.parseVector {
            let index = try stream.parseUnsigned(UInt32.self)
            let name = try stream.parseName()
            nameMap[index] = name
        }
        return nameMap
    }
}
