import LEB

public final class WasmParser<Stream: ByteStream> {
    public let stream: Stream

    public var currentIndex: Int {
        return stream.currentIndex
    }

    public init(stream: Stream) {
        self.stream = stream
    }
}

extension WasmParser {
    public static func parse(stream: Stream) throws -> Module {
        let parser = WasmParser(stream: stream)
        let module = try parser.parseModule()
        return module
    }
}

public enum WasmParserError: Swift.Error {
    case invalidMagicNumber([UInt8])
    case unknownVersion([UInt8])
    case invalidUTF8([UInt8])
    case invalidSectionSize(UInt32)
    case zeroExpected(actual: UInt8, index: Int)
    case inconsistentFunctionAndCodeLength(functionCount: Int, codeCount: Int)
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/conventions.html#vectors>
extension WasmParser {
    func parseVector<Content>(content parser: () throws -> Content) throws -> [Content] {
        var contents = [Content]()
        let count: UInt32 = try parseUnsigned()
        for _ in 0 ..< count {
            contents.append(try parser())
        }
        return contents
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#integers>
extension WasmParser {
    func parseUnsigned<T: RawUnsignedInteger>() throws -> T {
        let sequence = AnySequence { [stream] in
            AnyIterator {
                try? stream.consumeAny()
            }
        }
        return try T(LEB: sequence)
    }

    func parseSigned<T: FixedWidthInteger & SignedInteger>() throws -> T {
        let sequence = AnySequence { [stream] in
            AnyIterator {
                try? stream.consumeAny()
            }
        }
        return try T(LEB: sequence)
    }

    func parseInteger<T: RawUnsignedInteger>() throws -> T {
        let signed: T.Signed = try parseSigned()
        return signed.unsigned
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#floating-point>
extension WasmParser {
    func parseFloat() throws -> Float {
        let bytes = try stream.consume(count: 4).reduce(UInt32(0)) { acc, byte in acc << 8 + UInt32(byte) }
        return Float(bitPattern: bytes)
    }

    func parseDouble() throws -> Double {
        let bytes = try stream.consume(count: 8).reduce(UInt64(0)) { acc, byte in acc << 8 + UInt64(byte) }
        return Double(bitPattern: bytes)
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#names>
extension WasmParser {
    func parseName() throws -> String {
        let bytes = try parseVector { () -> UInt8 in
            try stream.consumeAny()
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

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/types.html#types>
extension WasmParser {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#value-types>
    func parseValueType() throws -> ValueType {
        let b = try stream.consume(Set(0x7C ... 0x7F))

        switch b {
        case 0x7F:
            return I32.self
        case 0x7E:
            return I64.self
        case 0x7D:
            return F32.self
        case 0x7C:
            return F64.self
        default:
            throw StreamError<Stream.Element>.unexpected(b, index: currentIndex, expected: Set(0x7C ... 0x7F))
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#result-types>
    func parseResultType() throws -> ResultType {
        switch stream.peek() {
        case 0x40?:
            _ = try stream.consumeAny()
            return []
        default:
            return [try parseValueType()]
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#function-types>
    func parseFunctionType() throws -> FunctionType {
        _ = try stream.consume(0x60)

        let parameters = try parseVector { try parseValueType() }
        let results = try parseVector { try parseValueType() }
        return FunctionType.some(parameters: parameters, results: results)
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#limits>
    func parseLimits() throws -> Limits {
        let b = try stream.consume([0x00, 0x01])

        switch b {
        case 0x00:
            return try Limits(min: parseUnsigned(), max: nil)
        case 0x01:
            return try Limits(min: parseUnsigned(), max: parseUnsigned())
        default:
            preconditionFailure("should never reach here")
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#memory-types>
    func parseMemoryType() throws -> MemoryType {
        return try parseLimits()
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#table-types>
    func parseTableType() throws -> TableType {
        let elementType: FunctionType
        let b = try stream.consume(0x70)

        switch b {
        case 0x70:
            elementType = .any
        default:
            preconditionFailure("should never reach here")
        }

        let limits = try parseLimits()
        return TableType(elementType: elementType, limits: limits)
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#global-types>
    func parseGlobalType() throws -> GlobalType {
        let valueType = try parseValueType()
        let mutability = try parseMutability()
        return GlobalType(mutability: mutability, valueType: valueType)
    }

    func parseMutability() throws -> Mutability {
        let b = try stream.consume([0x00, 0x01])
        switch b {
        case 0x00:
            return .constant
        case 0x01:
            return .variable
        default:
            preconditionFailure("should never reach here")
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html>
extension WasmParser {
    func parseInstruction() throws -> [Instruction] {
        let rawCode = try stream.consumeAny()
        guard let code = InstructionCode(rawValue: rawCode) else {
            throw StreamError.unexpected(rawCode, index: currentIndex, expected: [])
        }

        let factory = InstructionFactory(code: code)

        switch code {
        case .unreachable:
            return [factory.unreachable]
        case .nop:
            return [factory.nop]
        case .block:
            let type = try parseResultType()
            let (expression, _) = try parseExpression()
            return factory.block(type: type, expression: expression)
        case .loop:
            let type = try parseResultType()
            let (expression, _) = try parseExpression()
            return factory.loop(type: type, expression: expression)
        case .if:
            let type = try parseResultType()
            let (then, lastInstruction) = try parseExpression()
            let `else`: Expression
            switch lastInstruction.code {
            case .else:
                (`else`, _) = try parseExpression()
            case .end:
                `else` = Expression()
            default: preconditionFailure("should never reach here")
            }
            return factory.if(type: type, then: then, else: `else`)

        case .else:
            return [factory.else]

        case .end:
            return [factory.end]
        case .br:
            let label: UInt32 = try parseUnsigned()
            return [factory.br(label)]
        case .br_if:
            let label: UInt32 = try parseUnsigned()
            return [factory.brIf(label)]
        case .br_table:
            let labelIndices: [UInt32] = try parseVector { try parseUnsigned() }
            let labelIndex: UInt32 = try parseUnsigned()
            return [factory.brTable(labelIndices, default: labelIndex)]
        case .return:
            return [factory.return]
        case .call:
            let index: UInt32 = try parseUnsigned()
            return [factory.call(index)]
        case .call_indirect:
            let index: UInt32 = try parseUnsigned()
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return [factory.callIndirect(index)]

        case .drop:
            return [factory.drop]
        case .select:
            return [factory.select]

        case .local_get:
            let index: UInt32 = try parseUnsigned()
            return [factory.localGet(index)]
        case .local_set:
            let index: UInt32 = try parseUnsigned()
            return [factory.localSet(index)]
        case .local_tee:
            let index: UInt32 = try parseUnsigned()
            return [factory.localTee(index)]
        case .global_get:
            let index: UInt32 = try parseUnsigned()
            return [factory.globalGet(index)]
        case .global_set:
            let index: UInt32 = try parseUnsigned()
            return [factory.globalSet(index)]

        case .i32_load:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .f32_load:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .f64_load:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i32_load8_s:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i32_load8_u:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i32_load16_s:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i32_load16_u:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load8_s:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load8_u:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load16_s:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load16_u:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load32_s:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i64_load32_u:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.load(I32.self, offset)]
        case .i32_store:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .i64_store:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .f32_store:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .f64_store:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .i32_store8:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .i32_store16:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .i64_store8:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .i64_store16:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .i64_store32:
            let _: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return [factory.store(I32.self, offset)]
        case .memory_size:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return [factory.memorySize]
        case .memory_grow:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WasmParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return [factory.memoryGrow]

        case .i32_const:
            let n: UInt32 = try parseInteger()
            return [factory.const(I32(n))]
        case .i64_const:
            let n: UInt64 = try parseInteger()
            return [factory.const(I64(n))]
        case .f32_const:
            let n = try parseFloat()
            return [factory.const(F32(n))]
        case .f64_const:
            let n = try parseDouble()
            return [factory.const(F64(n))]

        case .i32_eqz:
            return [factory.numeric(unary: .eqz(I32.self))]
        case .i32_eq:
            return [factory.numeric(binary: .eq(I32.self))]
        case .i32_ne:
            return [factory.numeric(binary: .ne(I32.self))]
        case .i32_lt_s:
            return [factory.numeric(binary: .ltS(I32.self))]
        case .i32_lt_u:
            return [factory.numeric(binary: .ltU(I32.self))]
        case .i32_gt_s:
            return [factory.numeric(binary: .gtS(I32.self))]
        case .i32_gt_u:
            return [factory.numeric(binary: .gtU(I32.self))]
        case .i32_le_s:
            return [factory.numeric(binary: .leS(I32.self))]
        case .i32_le_u:
            return [factory.numeric(binary: .leU(I32.self))]
        case .i32_ge_s:
            return [factory.numeric(binary: .geS(I32.self))]
        case .i32_ge_u:
            return [factory.numeric(binary: .geU(I32.self))]

        case .i64_eqz:
            return [factory.numeric(unary: .eqz(I64.self))]
        case .i64_eq:
            return [factory.numeric(binary: .eq(I64.self))]
        case .i64_ne:
            return [factory.numeric(binary: .ne(I64.self))]
        case .i64_lt_s:
            return [factory.numeric(binary: .ltS(I64.self))]
        case .i64_lt_u:
            return [factory.numeric(binary: .ltU(I64.self))]
        case .i64_gt_s:
            return [factory.numeric(binary: .gtS(I64.self))]
        case .i64_gt_u:
            return [factory.numeric(binary: .gtU(I64.self))]
        case .i64_le_s:
            return [factory.numeric(binary: .leS(I64.self))]
        case .i64_le_u:
            return [factory.numeric(binary: .leU(I64.self))]
        case .i64_ge_s:
            return [factory.numeric(binary: .geS(I64.self))]
        case .i64_ge_u:
            return [factory.numeric(binary: .geU(I64.self))]

        case .f32_eq:
            return [factory.numeric(binary: .eq(F32.self))]
        case .f32_ne:
            return [factory.numeric(binary: .ne(F32.self))]
        case .f32_lt:
            return [factory.numeric(binary: .lt(F32.self))]
        case .f32_gt:
            return [factory.numeric(binary: .gt(F32.self))]
        case .f32_le:
            return [factory.numeric(binary: .le(F32.self))]
        case .f32_ge:
            return [factory.numeric(binary: .ge(F32.self))]

        case .f64_eq:
            return [factory.numeric(binary: .eq(F64.self))]
        case .f64_ne:
            return [factory.numeric(binary: .ne(F64.self))]
        case .f64_lt:
            return [factory.numeric(binary: .lt(F64.self))]
        case .f64_gt:
            return [factory.numeric(binary: .gt(F64.self))]
        case .f64_le:
            return [factory.numeric(binary: .le(F64.self))]
        case .f64_ge:
            return [factory.numeric(binary: .ge(F64.self))]

        case .i32_clz:
            return [factory.numeric(unary: .clz(I32.self))]
        case .i32_ctz:
            return [factory.numeric(unary: .ctz(I32.self))]
        case .i32_popcnt:
            return [factory.numeric(unary: .popcnt(I32.self))]
        case .i32_add:
            return [factory.numeric(binary: .add(I32.self))]
        case .i32_sub:
            return [factory.numeric(binary: .sub(I32.self))]
        case .i32_mul:
            return [factory.numeric(binary: .mul(I32.self))]
        case .i32_div_s:
            return [factory.numeric(binary: .divS(I32.self))]
        case .i32_div_u:
            return [factory.numeric(binary: .divU(I32.self))]
        case .i32_rem_s:
            return [factory.numeric(binary: .remS(I32.self))]
        case .i32_rem_u:
            return [factory.numeric(binary: .remU(I32.self))]
        case .i32_and:
            return [factory.numeric(binary: .and(I32.self))]
        case .i32_or:
            return [factory.numeric(binary: .or(I32.self))]
        case .i32_xor:
            return [factory.numeric(binary: .xor(I32.self))]
        case .i32_shl:
            return [factory.numeric(binary: .shl(I32.self))]
        case .i32_shr_s:
            return [factory.numeric(binary: .shrS(I32.self))]
        case .i32_shr_u:
            return [factory.numeric(binary: .shrU(I32.self))]
        case .i32_rotl:
            return [factory.numeric(binary: .rotl(I32.self))]
        case .i32_rotr:
            return [factory.numeric(binary: .rotr(I32.self))]

        case .i64_clz:
            return [factory.numeric(unary: .clz(I64.self))]
        case .i64_ctz:
            return [factory.numeric(unary: .ctz(I64.self))]
        case .i64_popcnt:
            return [factory.numeric(unary: .popcnt(I64.self))]
        case .i64_add:
            return [factory.numeric(binary: .add(I64.self))]
        case .i64_sub:
            return [factory.numeric(binary: .sub(I64.self))]
        case .i64_mul:
            return [factory.numeric(binary: .mul(I64.self))]
        case .i64_div_s:
            return [factory.numeric(binary: .divS(I64.self))]
        case .i64_div_u:
            return [factory.numeric(binary: .divU(I64.self))]
        case .i64_rem_s:
            return [factory.numeric(binary: .remS(I64.self))]
        case .i64_rem_u:
            return [factory.numeric(binary: .remU(I64.self))]
        case .i64_and:
            return [factory.numeric(binary: .and(I64.self))]
        case .i64_or:
            return [factory.numeric(binary: .or(I64.self))]
        case .i64_xor:
            return [factory.numeric(binary: .xor(I64.self))]
        case .i64_shl:
            return [factory.numeric(binary: .shl(I64.self))]
        case .i64_shr_s:
            return [factory.numeric(binary: .shrS(I64.self))]
        case .i64_shr_u:
            return [factory.numeric(binary: .shrU(I64.self))]
        case .i64_rotl:
            return [factory.numeric(binary: .rotl(I64.self))]
        case .i64_rotr:
            return [factory.numeric(binary: .rotr(I64.self))]

        case .f32_abs:
            return [factory.numeric(unary: .abs(F32.self))]
        case .f32_neg:
            return [factory.numeric(unary: .neg(F32.self))]
        case .f32_ceil:
            return [factory.numeric(unary: .ceil(F32.self))]
        case .f32_floor:
            return [factory.numeric(unary: .floor(F32.self))]
        case .f32_trunc:
            return [factory.numeric(unary: .trunc(F32.self))]
        case .f32_nearest:
            return [factory.numeric(unary: .nearest(F32.self))]
        case .f32_sqrt:
            return [factory.numeric(unary: .sqrt(F32.self))]

        case .f32_add:
            return [factory.numeric(binary: .add(F32.self))]
        case .f32_sub:
            return [factory.numeric(binary: .sub(F32.self))]
        case .f32_mul:
            return [factory.numeric(binary: .mul(F32.self))]
        case .f32_div:
            return [factory.numeric(binary: .div(F32.self))]
        case .f32_min:
            return [factory.numeric(binary: .min(F32.self))]
        case .f32_max:
            return [factory.numeric(binary: .max(F32.self))]
        case .f32_copysign:
            return [factory.numeric(binary: .copysign(F32.self))]

        case .f64_abs:
            return [factory.numeric(unary: .abs(F64.self))]
        case .f64_neg:
            return [factory.numeric(unary: .neg(F64.self))]
        case .f64_ceil:
            return [factory.numeric(unary: .ceil(F64.self))]
        case .f64_floor:
            return [factory.numeric(unary: .floor(F64.self))]
        case .f64_trunc:
            return [factory.numeric(unary: .trunc(F64.self))]
        case .f64_nearest:
            return [factory.numeric(unary: .nearest(F64.self))]
        case .f64_sqrt:
            return [factory.numeric(unary: .sqrt(F64.self))]

        case .f64_add:
            return [factory.numeric(binary: .add(F64.self))]
        case .f64_sub:
            return [factory.numeric(binary: .sub(F64.self))]
        case .f64_mul:
            return [factory.numeric(binary: .mul(F64.self))]
        case .f64_div:
            return [factory.numeric(binary: .div(F64.self))]
        case .f64_min:
            return [factory.numeric(binary: .min(F64.self))]
        case .f64_max:
            return [factory.numeric(binary: .max(F64.self))]
        case .f64_copysign:
            return [factory.numeric(binary: .copysign(F64.self))]

        case .i32_wrap_i64:
            return [factory.numeric(conversion: .wrap(I32.self, I64.self))]
        case .i32_trunc_f32_s:
            return [factory.numeric(conversion: .truncS(I32.self, F32.self))]
        case .i32_trunc_f32_u:
            return [factory.numeric(conversion: .truncU(I32.self, F32.self))]
        case .i32_trunc_f64_s:
            return [factory.numeric(conversion: .truncS(I32.self, F64.self))]
        case .i32_trunc_f64_u:
            return [factory.numeric(conversion: .truncU(I32.self, F64.self))]
        case .i64_extend_i32_s:
            return [factory.numeric(conversion: .extendS(I64.self, I32.self))]
        case .i64_extend_i32_u:
            return [factory.numeric(conversion: .extendU(I64.self, I32.self))]
        case .i64_trunc_f32_s:
            return [factory.numeric(conversion: .truncS(I64.self, F32.self))]
        case .i64_trunc_f32_u:
            return [factory.numeric(conversion: .truncU(I64.self, F32.self))]
        case .i64_trunc_f64_s:
            return [factory.numeric(conversion: .truncS(I64.self, F64.self))]
        case .i64_trunc_f64_u:
            return [factory.numeric(conversion: .truncU(I64.self, F64.self))]
        case .f32_convert_i32_s:
            return [factory.numeric(conversion: .convertS(F32.self, I32.self))]
        case .f32_convert_i32_u:
            return [factory.numeric(conversion: .convertU(F32.self, I32.self))]
        case .f32_convert_i64_s:
            return [factory.numeric(conversion: .convertS(F32.self, I64.self))]
        case .f32_convert_i64_u:
            return [factory.numeric(conversion: .convertU(F32.self, I64.self))]
        case .f32_demote_f64:
            return [factory.numeric(conversion: .demote(F32.self, F64.self))]
        case .f64_convert_i32_s:
            return [factory.numeric(conversion: .convertS(F64.self, I32.self))]
        case .f64_convert_i32_u:
            return [factory.numeric(conversion: .convertU(F64.self, I32.self))]
        case .f64_convert_i64_s:
            return [factory.numeric(conversion: .convertS(F64.self, I64.self))]
        case .f64_convert_i64_u:
            return [factory.numeric(conversion: .convertU(F64.self, I64.self))]
        case .f64_promote_f32:
            return [factory.numeric(conversion: .promote(F64.self, F32.self))]
        case .i32_reinterpret_f32:
            return [factory.numeric(conversion: .reinterpret(I32.self, F32.self))]
        case .i64_reinterpret_f64:
            return [factory.numeric(conversion: .reinterpret(I64.self, F64.self))]
        case .f32_reinterpret_i32:
            return [factory.numeric(conversion: .reinterpret(F32.self, I32.self))]
        case .f64_reinterpret_i64:
            return [factory.numeric(conversion: .reinterpret(F64.self, I64.self))]
        }
    }

    func parseExpression() throws -> (expression: Expression, lastInstruction: Instruction) {
        var instructions: [Instruction] = []

        repeat {
            instructions.append(contentsOf: try parseInstruction())
        } while instructions.last?.isPseudo != true
        let last = instructions.removeLast()

        return (Expression(instructions: instructions), last)
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension WasmParser {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#custom-section>
    func parseCustomSection() throws -> Section {
        _ = try stream.consume(0)
        let size: UInt32 = try parseUnsigned()

        let name = try parseName()
        guard size > name.utf8.count else {
            throw WasmParserError.invalidSectionSize(size)
        }
        let contentSize = Int(size) - name.utf8.count

        var bytes = [UInt8]()
        for _ in 0 ..< contentSize {
            bytes.append(try stream.consumeAny())
        }

        return .custom(name: name, bytes: bytes)
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#type-section>
    func parseTypeSection() throws -> Section {
        _ = try stream.consume(1)
        /* size */ _ = try parseUnsigned() as UInt32
        return .type(try parseVector { try parseFunctionType() })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#import-section>
    func parseImportSection() throws -> Section {
        _ = try stream.consume(2)
        /* size */ _ = try parseUnsigned() as UInt32

        let imports: [Import] = try parseVector {
            let module = try parseName()
            let name = try parseName()
            let descriptor = try parseImportDescriptor()
            return Import(module: module, name: name, descripter: descriptor)
        }
        return .import(imports)
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-importdesc>
    func parseImportDescriptor() throws -> ImportDescriptor {
        let b = try stream.consume(Set(0x00 ... 0x03))
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

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#function-section>
    func parseFunctionSection() throws -> Section {
        _ = try stream.consume(3)
        /* size */ _ = try parseUnsigned() as UInt32
        return .function(try parseVector { try parseUnsigned() })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#table-section>
    func parseTableSection() throws -> Section {
        _ = try stream.consume(4)
        /* size */ _ = try parseUnsigned() as UInt32

        return .table(try parseVector { Table(type: try parseTableType()) })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#memory-section>
    func parseMemorySection() throws -> Section {
        _ = try stream.consume(5)
        /* size */ _ = try parseUnsigned() as UInt32

        return .memory(try parseVector { Memory(type: try parseLimits()) })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#global-section>
    func parseGlobalSection() throws -> Section {
        _ = try stream.consume(6)
        /* size */ _ = try parseUnsigned() as UInt32

        return .global(try parseVector {
            let type = try parseGlobalType()
            let (expression, _) = try parseExpression()
            return Global(type: type, initializer: expression)
        })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#export-section>
    func parseExportSection() throws -> Section {
        _ = try stream.consume(7)
        /* size */ _ = try parseUnsigned() as UInt32

        return .export(try parseVector {
            let name = try parseName()
            let descriptor = try parseExportDescriptor()
            return Export(name: name, descriptor: descriptor)
        })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-exportdesc>
    func parseExportDescriptor() throws -> ExportDescriptor {
        let b = try stream.consume(Set(0x00 ... 0x03))
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

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#start-section>
    func parseStartSection() throws -> Section {
        _ = try stream.consume(8)
        /* size */ _ = try parseUnsigned() as UInt32

        return .start(try parseUnsigned())
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#element-section>
    func parseElementSection() throws -> Section {
        _ = try stream.consume(9)
        /* size */ _ = try parseUnsigned() as UInt32

        return .element(try parseVector {
            let index: UInt32 = try parseUnsigned()
            let (expression, _) = try parseExpression()
            let initializer: [UInt32] = try parseVector { try parseUnsigned() }
            return Element(index: index, offset: expression, initializer: initializer)
        })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#code-section>
    func parseCodeSection() throws -> Section {
        _ = try stream.consume(10)
        /* size */ _ = try parseUnsigned() as UInt32

        return .code(try parseVector {
            _ = try parseUnsigned() as UInt32
            let locals = try parseVector { () -> [ValueType] in
                let n: UInt32 = try parseUnsigned()
                let t = try parseValueType()
                return (0 ..< n).map { _ in t }
            }
            let (expression, _) = try parseExpression()
            return Code(locals: locals.flatMap { $0 }, expression: expression)
        })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-section>
    func parseDataSection() throws -> Section {
        _ = try stream.consume(11)
        /* size */ _ = try parseUnsigned() as UInt32

        return .data(try parseVector {
            let index: UInt32 = try parseUnsigned()
            let (offset, _) = try parseExpression()
            let initializer = try parseVector { try stream.consumeAny() }
            return Data(index: index, offset: offset, initializer: initializer)
        })
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
extension WasmParser {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-magic>
    func parseMagicNumber() throws {
        let magicNumber = try stream.consume(count: 4)
        guard magicNumber == [0x00, 0x61, 0x73, 0x6D] else {
            throw WasmParserError.invalidMagicNumber(magicNumber)
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-version>
    func parseVersion() throws {
        let version = try stream.consume(count: 4)
        guard version == [0x01, 0x00, 0x00, 0x00] else {
            throw WasmParserError.unknownVersion(version)
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
    func parseModule() throws -> Module {
        try parseMagicNumber()
        try parseVersion()

        var module = Module()

        var typeIndices = [TypeIndex]()
        var codes = [Code]()

        let ids: ClosedRange<UInt8> = 0 ... 11
        for i in ids {
            guard let sectionID = stream.peek(), ids.contains(sectionID) else {
                break
            }

            switch sectionID {
            case 0:
                _ = try? parseCustomSection()
            case 1 where sectionID == i:
                if case let .type(types) = try parseTypeSection() {
                    module.types = types
                }
            case 2 where sectionID == i:
                if case let .import(imports) = try parseImportSection() {
                    module.imports = imports
                }
            case 3 where sectionID == i:
                if case let .function(_typeIndices) = try parseFunctionSection() {
                    typeIndices = _typeIndices
                }
            case 4 where sectionID == i:
                if case let .table(tables) = try parseTableSection() {
                    module.tables = tables
                }
            case 5 where sectionID == i:
                if case let .memory(memory) = try parseMemorySection() {
                    module.memories = memory
                }
            case 6 where sectionID == i:
                if case let .global(globals) = try parseGlobalSection() {
                    module.globals = globals
                }
            case 7 where sectionID == i:
                if case let .export(exports) = try parseExportSection() {
                    module.exports = exports
                }
            case 8 where sectionID == i:
                if case let .start(start) = try parseStartSection() {
                    module.start = start
                }
            case 9 where sectionID == i:
                if case let .element(elements) = try parseElementSection() {
                    module.elements = elements
                }
            case 10 where sectionID == i:
                if case let .code(_codes) = try parseCodeSection() {
                    codes = _codes
                }
            case 11 where sectionID == i:
                if case let .data(data) = try parseDataSection() {
                    module.data = data
                }
            default:
                continue
            }
        }

        guard typeIndices.count == codes.count else {
            throw WasmParserError.inconsistentFunctionAndCodeLength(
                functionCount: typeIndices.count,
                codeCount: codes.count
            )
        }

        let functions = codes.enumerated().map { index, code in
            Function(type: typeIndices[index], locals: code.locals, body: code.expression)
        }
        module.functions = functions

        return module
    }
}
