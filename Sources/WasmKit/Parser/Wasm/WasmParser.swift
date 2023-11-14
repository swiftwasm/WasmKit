import Foundation
import SystemPackage

final class WasmParser<Stream: ByteStream> {
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

public struct WasmFeatureSet: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let memory64 = WasmFeatureSet(rawValue: 1 << 0)
    public static let referenceTypes = WasmFeatureSet(rawValue: 1 << 1)

    public static let `default`: WasmFeatureSet = [.referenceTypes]
    public static let all: WasmFeatureSet = [.memory64, .referenceTypes]
}

/// Parse a given file as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(filePath: FilePath, features: WasmFeatureSet = .default) throws -> Module {
    let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath.string))
    defer { try? fileHandle.close() }
    let stream = try FileHandleStream(fileHandle: fileHandle)
    let parser = WasmParser(stream: stream, features: features)
    let module = try parser.parseModule()
    return module
}

/// Parse a given byte array as a WebAssembly binary format file
/// > Note: <https://webassembly.github.io/spec/core/binary/index.html>
public func parseWasm(bytes: [UInt8], features: WasmFeatureSet = .default) throws -> Module {
    let stream = StaticByteStream(bytes: bytes)
    let parser = WasmParser(stream: stream, features: features)
    let module = try parser.parseModule()
    return module
}

public enum WasmParserError: Swift.Error {
    case invalidMagicNumber([UInt8])
    case unknownVersion([UInt8])
    case invalidUTF8([UInt8])
    case invalidSectionSize(UInt32)
    case malformedSectionID(UInt8)
    case zeroExpected(actual: UInt8, index: Int)
    case inconsistentFunctionAndCodeLength(functionCount: Int, codeCount: Int)
    case inconsistentDataCountAndDataSectionLength(dataCount: UInt32, dataSection: Int)
    case tooManyLocals
    case expectedRefType(actual: ValueType)
    case unimplementedInstruction(UInt8, suffix: UInt32? = nil)
    case unexpectedElementKind(expected: UInt32, actual: UInt32)
    case integerRepresentationTooLong
    case endOpcodeExpected
    case unexpectedEnd
    case unexpectedContent
    case sectionSizeMismatch(expected: Int, actual: Int)
    case illegalOpcode(UInt8)
    case malformedMutability(UInt8)
    case malformedFunctionType(UInt8)
    case sectionOutOfOrder
    case dataCountSectionRequired
    case malformedLimit(UInt8)
    case malformedIndirectCall
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

extension WasmParser {
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
extension WasmParser {
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
extension WasmParser {
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
    func parseMemarg() throws -> MemoryInstruction.Memarg {
        let align: UInt32 = try parseUnsigned()
        let offset: UInt64 = try features.contains(.memory64) ? parseUnsigned(UInt64.self) : UInt64(parseUnsigned(UInt32.self))
        return MemoryInstruction.Memarg(offset: offset, align: align)
    }

    func parseVectorBytes() throws -> ArraySlice<UInt8> {
        let count: UInt32 = try parseUnsigned()
        return try stream.consume(count: Int(count))
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html>
extension WasmParser {

    enum ParseInstructionResult {
        /// The instruction is not fully parsed yet but need expression to continue
        case requestExpression(resume: (Expression, PseudoInstruction) throws -> ParseInstructionResult)
        case `value`(Instruction)
    }

    func parseInstruction() throws -> ParseInstructionResult {
        let rawCode = try stream.consumeAny()
        guard let code = InstructionCode(rawValue: rawCode) else {
            throw WasmParserError.illegalOpcode(rawCode)
        }

        switch code {
        case .unreachable:
            return .value(.control(.unreachable))
        case .nop:
            return .value(.control(.nop))
        case .block:
            let type = try parseResultType()
            return .requestExpression { expr, _ in
                return .value(.control(.block(expression: expr, type: type)))
            }
        case .loop:
            let type = try parseResultType()
            return .requestExpression { expr, _ in
                return .value(.control(.loop(expression: expr, type: type)))
            }
        case .if:
            let type = try parseResultType()
            return .requestExpression { then, end in
                switch end {
                case .else:
                    return .requestExpression { `else`, _ in
                        return .value(.control(.if(then: then, else: `else`, type: type)))
                    }
                case .end:
                    let `else` = Expression(instructions: [])
                    return .value(.control(.if(then: then, else: `else`, type: type)))
                }
            }
        case .else:
            return .value(.pseudo(.else))
        case .end:
            return .value(.pseudo(.end))
        case .br:
            let label: UInt32 = try parseUnsigned()
            return .value(.control(.br(label)))
        case .br_if:
            let label: UInt32 = try parseUnsigned()
            return .value(.control(.brIf(label)))
        case .br_table:
            let labelIndices: [UInt32] = try parseVector { try parseUnsigned() }
            let labelIndex: UInt32 = try parseUnsigned()
            return .value(.control(.brTable(labelIndices, default: labelIndex)))
        case .return:
            return .value(.control(.return))
        case .call:
            let index: UInt32 = try parseUnsigned()
            return .value(.control(.call(functionIndex: index)))
        case .call_indirect:
            let typeIndex: TypeIndex = try parseUnsigned()
            if try !features.contains(.referenceTypes) && stream.peek() != 0 {
                // Check that reserved byte is zero when reference-types is disabled
                throw WasmParserError.malformedIndirectCall
            }
            let tableIndex: TableIndex = try parseUnsigned()
            return .value(.control(.callIndirect(tableIndex: tableIndex, typeIndex: typeIndex)))

        case .drop:
            return .value(.parametric(.drop))
        case .select:
            return .value(.parametric(.select))
        case .typed_select:
            return .value(try .parametric(.typedSelect(parseVector { try parseValueType() })))

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
            return .value(try .memory(.load(parseMemarg(), bitWidth: 32, .i32)))
        case .i64_load:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 64, .i64)))
        case .f32_load:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 32, .f32)))
        case .f64_load:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 64, .f64)))
        case .i32_load8_s:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 8, .i32, isSigned: true)))
        case .i32_load8_u:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 8, .i32, isSigned: false)))
        case .i32_load16_s:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 16, .i32, isSigned: true)))
        case .i32_load16_u:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 16, .i32, isSigned: false)))
        case .i64_load8_s:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 8, .i64, isSigned: true)))
        case .i64_load8_u:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 8, .i64, isSigned: false)))
        case .i64_load16_s:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 16, .i64, isSigned: true)))
        case .i64_load16_u:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 16, .i64, isSigned: false)))
        case .i64_load32_s:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 32, .i64, isSigned: true)))
        case .i64_load32_u:
            return .value(try .memory(.load(parseMemarg(), bitWidth: 32, .i64, isSigned: false)))
        case .i32_store:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 32, .i32)))
        case .i64_store:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 64, .i64)))
        case .f32_store:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 32, .i32)))
        case .f64_store:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 64, .i64)))
        case .i32_store8:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 8, .i32)))
        case .i32_store16:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 16, .i32)))
        case .i64_store8:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 8, .i64)))
        case .i64_store16:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 16, .i64)))
        case .i64_store32:
            return .value(try .memory(.store(parseMemarg(), bitWidth: 32, .i64)))
        case .memory_size:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return .value(.memory(.size))
        case .memory_grow:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return .value(.memory(.grow))

        case .i32_const:
            let n: UInt32 = try parseInteger()
            return .value(.numeric(.const(.i32(n))))
        case .i64_const:
            let n: UInt64 = try parseInteger()
            return .value(.numeric(.const(.i64(n))))
        case .f32_const:
            let n = try parseFloat()
            return .value(.numeric(.const(.f32(n))))
        case .f64_const:
            let n = try parseDouble()
            return .value(.numeric(.const(.f64(n))))

        case .i32_eqz:
            return .value(.numeric(.intUnary(.eqz(.i32))))
        case .i32_eq:
            return .value(.numeric(.binary(.eq(.int(.i32)))))
        case .i32_ne:
            return .value(.numeric(.binary(.ne(.int(.i32)))))
        case .i32_lt_s:
            return .value(.numeric(.intBinary(.ltS(.i32))))
        case .i32_lt_u:
            return .value(.numeric(.intBinary(.ltU(.i32))))
        case .i32_gt_s:
            return .value(.numeric(.intBinary(.gtS(.i32))))
        case .i32_gt_u:
            return .value(.numeric(.intBinary(.gtU(.i32))))
        case .i32_le_s:
            return .value(.numeric(.intBinary(.leS(.i32))))
        case .i32_le_u:
            return .value(.numeric(.intBinary(.leU(.i32))))
        case .i32_ge_s:
            return .value(.numeric(.intBinary(.geS(.i32))))
        case .i32_ge_u:
            return .value(.numeric(.intBinary(.geU(.i32))))

        case .i64_eqz:
            return .value(.numeric(.intUnary(.eqz(.i64))))
        case .i64_eq:
            return .value(.numeric(.binary(.eq(.int(.i64)))))
        case .i64_ne:
            return .value(.numeric(.binary(.ne(.int(.i64)))))
        case .i64_lt_s:
            return .value(.numeric(.intBinary(.ltS(.i64))))
        case .i64_lt_u:
            return .value(.numeric(.intBinary(.ltU(.i64))))
        case .i64_gt_s:
            return .value(.numeric(.intBinary(.gtS(.i64))))
        case .i64_gt_u:
            return .value(.numeric(.intBinary(.gtU(.i64))))
        case .i64_le_s:
            return .value(.numeric(.intBinary(.leS(.i64))))
        case .i64_le_u:
            return .value(.numeric(.intBinary(.leU(.i64))))
        case .i64_ge_s:
            return .value(.numeric(.intBinary(.geS(.i64))))
        case .i64_ge_u:
            return .value(.numeric(.intBinary(.geU(.i64))))

        case .f32_eq:
            return .value(.numeric(.binary(.eq(.float(.f32)))))
        case .f32_ne:
            return .value(.numeric(.binary(.ne(.float(.f32)))))
        case .f32_lt:
            return .value(.numeric(.floatBinary(.lt(.f32))))
        case .f32_gt:
            return .value(.numeric(.floatBinary(.gt(.f32))))
        case .f32_le:
            return .value(.numeric(.floatBinary(.le(.f32))))
        case .f32_ge:
            return .value(.numeric(.floatBinary(.ge(.f32))))

        case .f64_eq:
            return .value(.numeric(.binary(.eq(.float(.f64)))))
        case .f64_ne:
            return .value(.numeric(.binary(.ne(.float(.f64)))))
        case .f64_lt:
            return .value(.numeric(.floatBinary(.lt(.f64))))
        case .f64_gt:
            return .value(.numeric(.floatBinary(.gt(.f64))))
        case .f64_le:
            return .value(.numeric(.floatBinary(.le(.f64))))
        case .f64_ge:
            return .value(.numeric(.floatBinary(.ge(.f64))))

        case .i32_clz:
            return .value(.numeric(.intUnary(.clz(.i32))))
        case .i32_ctz:
            return .value(.numeric(.intUnary(.ctz(.i32))))
        case .i32_popcnt:
            return .value(.numeric(.intUnary(.popcnt(.i32))))
        case .i32_add:
            return .value(.numeric(.binary(.add(.int(.i32)))))
        case .i32_sub:
            return .value(.numeric(.binary(.sub(.int(.i32)))))
        case .i32_mul:
            return .value(.numeric(.binary(.mul(.int(.i32)))))
        case .i32_div_s:
            return .value(.numeric(.intBinary(.divS(.i32))))
        case .i32_div_u:
            return .value(.numeric(.intBinary(.divU(.i32))))
        case .i32_rem_s:
            return .value(.numeric(.intBinary(.remS(.i32))))
        case .i32_rem_u:
            return .value(.numeric(.intBinary(.remU(.i32))))
        case .i32_and:
            return .value(.numeric(.intBinary(.and(.i32))))
        case .i32_or:
            return .value(.numeric(.intBinary(.or(.i32))))
        case .i32_xor:
            return .value(.numeric(.intBinary(.xor(.i32))))
        case .i32_shl:
            return .value(.numeric(.intBinary(.shl(.i32))))
        case .i32_shr_s:
            return .value(.numeric(.intBinary(.shrS(.i32))))
        case .i32_shr_u:
            return .value(.numeric(.intBinary(.shrU(.i32))))
        case .i32_rotl:
            return .value(.numeric(.intBinary(.rotl(.i32))))
        case .i32_rotr:
            return .value(.numeric(.intBinary(.rotr(.i32))))

        case .i64_clz:
            return .value(.numeric(.intUnary(.clz(.i64))))
        case .i64_ctz:
            return .value(.numeric(.intUnary(.ctz(.i64))))
        case .i64_popcnt:
            return .value(.numeric(.intUnary(.popcnt(.i64))))
        case .i64_add:
            return .value(.numeric(.binary(.add(.int(.i64)))))
        case .i64_sub:
            return .value(.numeric(.binary(.sub(.int(.i64)))))
        case .i64_mul:
            return .value(.numeric(.binary(.mul(.int(.i64)))))
        case .i64_div_s:
            return .value(.numeric(.intBinary(.divS(.i64))))
        case .i64_div_u:
            return .value(.numeric(.intBinary(.divU(.i64))))
        case .i64_rem_s:
            return .value(.numeric(.intBinary(.remS(.i64))))
        case .i64_rem_u:
            return .value(.numeric(.intBinary(.remU(.i64))))
        case .i64_and:
            return .value(.numeric(.intBinary(.and(.i64))))
        case .i64_or:
            return .value(.numeric(.intBinary(.or(.i64))))
        case .i64_xor:
            return .value(.numeric(.intBinary(.xor(.i64))))
        case .i64_shl:
            return .value(.numeric(.intBinary(.shl(.i64))))
        case .i64_shr_s:
            return .value(.numeric(.intBinary(.shrS(.i64))))
        case .i64_shr_u:
            return .value(.numeric(.intBinary(.shrU(.i64))))
        case .i64_rotl:
            return .value(.numeric(.intBinary(.rotl(.i64))))
        case .i64_rotr:
            return .value(.numeric(.intBinary(.rotr(.i64))))

        case .f32_abs:
            return .value(.numeric(.floatUnary(.abs(.f32))))
        case .f32_neg:
            return .value(.numeric(.floatUnary(.neg(.f32))))
        case .f32_ceil:
            return .value(.numeric(.floatUnary(.ceil(.f32))))
        case .f32_floor:
            return .value(.numeric(.floatUnary(.floor(.f32))))
        case .f32_trunc:
            return .value(.numeric(.floatUnary(.trunc(.f32))))
        case .f32_nearest:
            return .value(.numeric(.floatUnary(.nearest(.f32))))
        case .f32_sqrt:
            return .value(.numeric(.floatUnary(.sqrt(.f32))))

        case .f32_add:
            return .value(.numeric(.binary(.add(.float(.f32)))))
        case .f32_sub:
            return .value(.numeric(.binary(.sub(.float(.f32)))))
        case .f32_mul:
            return .value(.numeric(.binary(.mul(.float(.f32)))))
        case .f32_div:
            return .value(.numeric(.floatBinary(.div(.f32))))
        case .f32_min:
            return .value(.numeric(.floatBinary(.min(.f32))))
        case .f32_max:
            return .value(.numeric(.floatBinary(.max(.f32))))
        case .f32_copysign:
            return .value(.numeric(.floatBinary(.copysign(.f32))))

        case .f64_abs:
            return .value(.numeric(.floatUnary(.abs(.f64))))
        case .f64_neg:
            return .value(.numeric(.floatUnary(.neg(.f64))))
        case .f64_ceil:
            return .value(.numeric(.floatUnary(.ceil(.f64))))
        case .f64_floor:
            return .value(.numeric(.floatUnary(.floor(.f64))))
        case .f64_trunc:
            return .value(.numeric(.floatUnary(.trunc(.f64))))
        case .f64_nearest:
            return .value(.numeric(.floatUnary(.nearest(.f64))))
        case .f64_sqrt:
            return .value(.numeric(.floatUnary(.sqrt(.f64))))

        case .f64_add:
            return .value(.numeric(.binary(.add(.float(.f64)))))
        case .f64_sub:
            return .value(.numeric(.binary(.sub(.float(.f64)))))
        case .f64_mul:
            return .value(.numeric(.binary(.mul(.float(.f64)))))
        case .f64_div:
            return .value(.numeric(.floatBinary(.div(.f64))))
        case .f64_min:
            return .value(.numeric(.floatBinary(.min(.f64))))
        case .f64_max:
            return .value(.numeric(.floatBinary(.max(.f64))))
        case .f64_copysign:
            return .value(.numeric(.floatBinary(.copysign(.f64))))

        case .i32_wrap_i64:
            return .value(.numeric(.conversion(.wrap)))
        case .i32_trunc_f32_s:
            return .value(.numeric(.conversion(.truncSigned(.i32, .f32))))
        case .i32_trunc_f32_u:
            return .value(.numeric(.conversion(.truncUnsigned(.i32, .f32))))
        case .i32_trunc_f64_s:
            return .value(.numeric(.conversion(.truncSigned(.i32, .f64))))
        case .i32_trunc_f64_u:
            return .value(.numeric(.conversion(.truncUnsigned(.i32, .f64))))
        case .i64_extend_i32_s:
            return .value(.numeric(.conversion(.extendSigned)))
        case .i64_extend_i32_u:
            return .value(.numeric(.conversion(.extendUnsigned)))
        case .i64_trunc_f32_s:
            return .value(.numeric(.conversion(.truncSigned(.i64, .f32))))
        case .i64_trunc_f32_u:
            return .value(.numeric(.conversion(.truncUnsigned(.i64, .f32))))
        case .i64_trunc_f64_s:
            return .value(.numeric(.conversion(.truncSigned(.i64, .f64))))
        case .i64_trunc_f64_u:
            return .value(.numeric(.conversion(.truncUnsigned(.i64, .f64))))
        case .f32_convert_i32_s:
            return .value(.numeric(.conversion(.convertSigned(.f32, .i32))))
        case .f32_convert_i32_u:
            return .value(.numeric(.conversion(.convertUnsigned(.f32, .i32))))
        case .f32_convert_i64_s:
            return .value(.numeric(.conversion(.convertSigned(.f32, .i64))))
        case .f32_convert_i64_u:
            return .value(.numeric(.conversion(.convertUnsigned(.f32, .i64))))
        case .f32_demote_f64:
            return .value(.numeric(.conversion(.demote)))
        case .f64_convert_i32_s:
            return .value(.numeric(.conversion(.convertSigned(.f64, .i32))))
        case .f64_convert_i32_u:
            return .value(.numeric(.conversion(.convertUnsigned(.f64, .i32))))
        case .f64_convert_i64_s:
            return .value(.numeric(.conversion(.convertSigned(.f64, .i64))))
        case .f64_convert_i64_u:
            return .value(.numeric(.conversion(.convertUnsigned(.f64, .i64))))
        case .f64_promote_f32:
            return .value(.numeric(.conversion(.promote)))
        case .i32_reinterpret_f32:
            return .value(.numeric(.conversion(.reinterpret(.int(.i32), .float(.f32)))))
        case .i64_reinterpret_f64:
            return .value(.numeric(.conversion(.reinterpret(.int(.i64), .float(.f64)))))
        case .f32_reinterpret_i32:
            return .value(.numeric(.conversion(.reinterpret(.float(.f32), .int(.i32)))))
        case .f64_reinterpret_i64:
            return .value(.numeric(.conversion(.reinterpret(.float(.f64), .int(.i64)))))

        case .i32_extend8_s:
            return .value(.numeric(.conversion(.extend8Signed(.i32))))
        case .i32_extend16_s:
            return .value(.numeric(.conversion(.extend16Signed(.i32))))
        case .i64_extend8_s:
            return .value(.numeric(.conversion(.extend8Signed(.i64))))
        case .i64_extend16_s:
            return .value(.numeric(.conversion(.extend16Signed(.i64))))
        case .i64_extend32_s:
            return .value(.numeric(.conversion(.extend32Signed)))

        case .ref_null:
            let type = try parseValueType()

            guard case let .reference(refType) = type else {
                throw WasmParserError.expectedRefType(actual: type)
            }

            return .value(.reference(.refNull(refType)))

        case .ref_is_null:
            return .value(.reference(.refIsNull))

        case .ref_func:
            return .value(try .reference(.refFunc(parseUnsigned())))

        case .table_get:
            return .value(try .table(.get(parseUnsigned())))

        case .table_set:
            return .value(try .table(.set(parseUnsigned())))

        case .wasm2InstructionPrefix:
            let codeSuffix: UInt32 = try parseUnsigned()
            switch codeSuffix {
            case 0:
                return .value(.numeric(.conversion(.truncSaturatingSigned(.i32, .f32))))
            case 1:
                return .value(.numeric(.conversion(.truncSaturatingUnsigned(.i32, .f32))))
            case 2:
                return .value(.numeric(.conversion(.truncSaturatingSigned(.i32, .f64))))
            case 3:
                return .value(.numeric(.conversion(.truncSaturatingUnsigned(.i32, .f64))))
            case 4:
                return .value(.numeric(.conversion(.truncSaturatingSigned(.i64, .f32))))
            case 5:
                return .value(.numeric(.conversion(.truncSaturatingUnsigned(.i64, .f32))))
            case 6:
                return .value(.numeric(.conversion(.truncSaturatingSigned(.i64, .f64))))
            case 7:
                return .value(.numeric(.conversion(.truncSaturatingUnsigned(.i64, .f64))))
            case 8:
                let result = try Instruction.memory(.`init`(parseUnsigned()))
                // memory.init requires data count section
                // https://webassembly.github.io/spec/core/binary/modules.html#data-count-section
                guard hasDataCount else {
                    throw WasmParserError.dataCountSectionRequired
                }

                let zero = try stream.consumeAny()
                guard zero == 0x00 else {
                    throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
                }

                return .value(result)

            case 9:
                // memory.drop requires data count section
                // https://webassembly.github.io/spec/core/binary/modules.html#data-count-section
                guard hasDataCount else {
                    throw WasmParserError.dataCountSectionRequired
                }
                return .value(try .memory(.dataDrop(parseUnsigned())))

            case 10:
                let (zero1, zero2) = try (stream.consumeAny(), stream.consumeAny())
                guard zero1 == 0x00 && zero2 == 0x00 else {
                    throw WasmParserError.zeroExpected(actual: zero2, index: currentIndex)
                }
                return .value(.memory(.copy))

            case 11:
                let zero = try stream.consumeAny()
                guard zero == 0x00 else {
                    throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
                }

                return .value(.memory(.fill))

            case 12:
                let elementIndex: ElementIndex = try parseUnsigned()
                let tableIndex: TableIndex = try parseUnsigned()
                return .value(.table(.`init`(tableIndex, elementIndex)))

            case 13:
                return .value(try .table(.elementDrop(parseUnsigned())))

            case 14:
                let sourceTableIndex: TableIndex = try parseUnsigned()
                let destinationTableIndex: TableIndex = try parseUnsigned()
                return .value(.table(.copy(sourceTableIndex, destinationTableIndex)))

            case 15:
                return .value(try .table(.grow(parseUnsigned())))

            case 16:
                return .value(try .table(.size(parseUnsigned())))

            case 17:
                return .value(try .table(.fill(parseUnsigned())))

            default:
                throw WasmParserError.unimplementedInstruction(rawCode, suffix: codeSuffix)
            }
        }
    }

    func parseExpression() throws -> (result: Expression, end: PseudoInstruction) {
        typealias PendingWork = (
            instructions: [Instruction],
            resume: (Expression, PseudoInstruction) throws -> ParseInstructionResult
        )
        var pendingWorks: [PendingWork] = []
        var instructions: [Instruction] = []

        var nextResult = try parseInstruction()

        while true {
            switch nextResult {
            case .value(.pseudo(let end)):
                let expr = Expression(instructions: instructions)
                if let nextWork = pendingWorks.popLast() {
                    // If there is a pending parse, then restore the parsing
                    // state and resume the rest of the work
                    instructions = nextWork.instructions
                    nextResult = try nextWork.resume(expr, end)
                } else {
                    // If no more pending expression, the expression is top-level
                    return (expr, end)
                }
            case let .value(nextInstruction):
                instructions.append(nextInstruction)
                nextResult = try parseInstruction()
            case let .requestExpression(resume):
                // If nested expression is requested, stop parsing the current expression
                // and start parsing the nested one
                pendingWorks.append((instructions, resume))
                instructions = []
                nextResult = try parseInstruction()
            }
        }
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension WasmParser {
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
            let (expression, _) = try parseExpression()
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

                let (offset, _) = try parseExpression()
                mode = .active(table: table, offset: offset)
            }

            if flag.segmentHasRefType {
                let valueType = try parseValueType()

                guard case let .reference(refType) = valueType else {
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
                initializer = try parseVector { try parseExpression().result }
            } else {
                initializer = try parseVector {
                    try Expression(
                        instructions: [.reference(.refFunc(parseUnsigned() as UInt32))]
                    )
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
                let (offset, _) = try parseExpression()
                let initializer = try parseVectorBytes()
                return .active(.init(index: 0, offset: offset, initializer: initializer))

            case 1:
                return try .passive(parseVector { try stream.consumeAny() })

            case 2:
                let index: UInt32 = try parseUnsigned()
                let (offset, _) = try parseExpression()
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
extension WasmParser {
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
    func parseVersion() throws {
        let version = try stream.consume(count: 4)
        guard version == [0x01, 0x00, 0x00, 0x00] else {
            throw WasmParserError.unknownVersion(.init(version))
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
                throw WasmParserError.sectionOutOfOrder
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
                throw WasmParserError.malformedSectionID(sectionID)
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
                throw WasmParserError.sectionSizeMismatch(
                    expected: expectedSectionEnd, actual: stream.currentIndex
                )
            }
        }

        guard typeIndices.count == codes.count else {
            throw WasmParserError.inconsistentFunctionAndCodeLength(
                functionCount: typeIndices.count,
                codeCount: codes.count
            )
        }

        if let dataCount = module.dataCount, dataCount != UInt32(module.data.count) {
            throw WasmParserError.inconsistentDataCountAndDataSectionLength(
                dataCount: dataCount,
                dataSection: module.data.count
            )
        }

        let functions = codes.enumerated().map { [hasDataCount, features] index, code in
            GuestFunction(
                type: typeIndices[index], locals: code.locals,
                body: {
                    let stream = StaticByteStream(bytes: Array(code.expression))
                    let parser = WasmParser<StaticByteStream>(stream: stream, features: features, hasDataCount: hasDataCount)
                    let (result, end) = try parser.parseExpression()
                    guard end == .end else {
                        throw WasmParserError.endOpcodeExpected
                    }
                    return result
                })
        }
        module.functions = functions

        return module
    }
}

/// > Note: <https://webassembly.github.io/spec/core/appendix/custom.html#name-section>
struct NameSectionParser<Stream: ByteStream> {
    let stream: Stream

    typealias NameMap = [UInt32: String]
    enum ParsedNames {
        case functions(NameMap)
    }

    func parseAll() throws -> [ParsedNames] {
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
