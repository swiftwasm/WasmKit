import LEB
import Parser

public final class WASMParser<Stream: ByteStream> {
    public let stream: Stream

    public var currentIndex: Int {
        return stream.currentIndex
    }

    public init(stream: Stream) {
        self.stream = stream
    }
}

extension WASMParser {
    public static func parse(stream: Stream) throws -> Module {
        let parser = WASMParser(stream: stream)
        let module = try parser.parseModule()
        return module
    }
}

public enum WASMParserError: Swift.Error {
    case invalidMagicNumber([UInt8])
    case unknownVersion([UInt8])
    case invalidUnicode([UInt8])
    case invalidSectionSize(UInt32)
    case zeroExpected(actual: UInt8, index: Int)
    case inconsistentFunctionAndCodeLength(functionCount: Int, codeCount: Int)
}

extension WASMParser {
    typealias StreamError = Parser.Error<Stream.Element>
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/conventions.html#vectors>
extension WASMParser {
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
extension WASMParser {
    func parseUnsigned<T: FixedWidthInteger & UnsignedInteger>() throws -> T {
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

    func parseInteger<T: FixedWidthInteger & SignedInteger>() throws -> T {
        // FIXME:
        return try parseSigned()
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/values.html#floating-point>
extension WASMParser {
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
extension WASMParser {
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
            case .error: throw WASMParserError.invalidUnicode(bytes)
            }
        }

        return name
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/types.html#types>
extension WASMParser {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/types.html#value-types>
    func parseValueType() throws -> ValueType {
        let b = try stream.consume(Set(0x7C ... 0x7F))

        switch b {
        case 0x7F:
            return Value.Int32.self
        case 0x7E:
            return Value.Int64.self
        case 0x7D:
            return Value.Float32.self
        case 0x7C:
            return Value.Float64.self
        default:
            throw StreamError.unexpected(b, index: currentIndex, expected: Set(0x7C ... 0x7F))
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
extension WASMParser {
    func parseInstruction() throws -> Instruction {
        let code = try stream.consumeAny()
        switch code {
        case 0x00:
            return ControlInstruction.unreachable
        case 0x01:
            return ControlInstruction.nop
        case 0x02:
            let type = try parseResultType()
            let expression = try parseExpression()
            return ControlInstruction.block(type, expression)
        case 0x03:
            let type = try parseResultType()
            let expression = try parseExpression()
            return ControlInstruction.loop(type, expression)
        case 0x04:
            let type = try parseResultType()
            let ifExpression = try parseExpression()
            guard (try? stream.consume(0x05)) == nil else {
                return ControlInstruction.if(type, ifExpression, Expression())
            }
            let elseExpression = try parseExpression()
            return ControlInstruction.if(type, ifExpression, elseExpression)
        case 0x0B:
            return PseudoInstruction.end
        case 0x0C:
            let label: UInt32 = try parseUnsigned()
            return ControlInstruction.br(label)
        case 0x0D:
            let label: UInt32 = try parseUnsigned()
            return ControlInstruction.brIf(label)
        case 0x0E:
            let labels: [UInt32] = try parseVector { try parseUnsigned() }
            return ControlInstruction.brTable(labels)
        case 0x0F:
            return ControlInstruction.return
        case 0x10:
            let index: UInt32 = try parseUnsigned()
            return ControlInstruction.call(index)
        case 0x11:
            let index: UInt32 = try parseUnsigned()
            return ControlInstruction.callIndirect(index)

        case 0x1A:
            return ParametricInstruction.drop
        case 0x1B:
            return ParametricInstruction.select

        case 0x20:
            let index: UInt32 = try parseUnsigned()
            return VariableInstruction.getLocal(index)
        case 0x21:
            let index: UInt32 = try parseUnsigned()
            return VariableInstruction.setLocal(index)
        case 0x22:
            let index: UInt32 = try parseUnsigned()
            return VariableInstruction.teeLocal(index)
        case 0x23:
            let index: UInt32 = try parseUnsigned()
            return VariableInstruction.getGlobal(index)
        case 0x24:
            let index: UInt32 = try parseUnsigned()
            return VariableInstruction.setGlobal(index)

        case 0x28:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load(Value.Int32.self, .init(min: align, max: offset))
        case 0x29:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load(Value.Int64.self, .init(min: align, max: offset))
        case 0x2A:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load(Value.Float32.self, .init(min: align, max: offset))
        case 0x2B:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load(Value.Float64.self, .init(min: align, max: offset))
        case 0x2C:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load8s(Value.Int32.self, .init(min: align, max: offset))
        case 0x2D:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load8u(Value.Int64.self, .init(min: align, max: offset))
        case 0x2E:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load16s(Value.Int32.self, .init(min: align, max: offset))
        case 0x2F:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load16u(Value.Int32.self, .init(min: align, max: offset))
        case 0x30:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load8s(Value.Int64.self, .init(min: align, max: offset))
        case 0x31:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load8u(Value.Int64.self, .init(min: align, max: offset))
        case 0x32:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load16s(Value.Int64.self, .init(min: align, max: offset))
        case 0x33:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load16u(Value.Int64.self, .init(min: align, max: offset))
        case 0x34:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load32s(Value.Int64.self, .init(min: align, max: offset))
        case 0x35:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.load32u(Value.Int64.self, .init(min: align, max: offset))
        case 0x36:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store(Value.Int32.self, .init(min: align, max: offset))
        case 0x37:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store(Value.Int64.self, .init(min: align, max: offset))
        case 0x38:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store(Value.Float32.self, .init(min: align, max: offset))
        case 0x39:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store(Value.Float64.self, .init(min: align, max: offset))
        case 0x3A:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store8(Value.Int32.self, .init(min: align, max: offset))
        case 0x3B:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store16(Value.Int32.self, .init(min: align, max: offset))
        case 0x3C:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store8(Value.Int64.self, .init(min: align, max: offset))
        case 0x3D:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store16(Value.Int64.self, .init(min: align, max: offset))
        case 0x3E:
            let align: UInt32 = try parseUnsigned()
            let offset: UInt32 = try parseUnsigned()
            return MemoryInstruction.store32(Value.Int64.self, .init(min: align, max: offset))
        case 0x3F:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WASMParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return MemoryInstruction.currentMemory
        case 0x40:
            let zero = try stream.consumeAny()
            guard zero == 0x00 else {
                throw WASMParserError.zeroExpected(actual: zero, index: currentIndex)
            }
            return MemoryInstruction.growMemory

        case 0x41:
            let n: Int32 = try parseInteger()
            return NumericInstruction.Constant.const(Value.Int32(n))
        case 0x42:
            let n: Int64 = try parseInteger()
            return NumericInstruction.Constant.const(Value.Int64(n))
        case 0x43:
            let n = try parseFloat()
            return NumericInstruction.Constant.const(Value.Float32(n))
        case 0x44:
            let n = try parseDouble()
            return NumericInstruction.Constant.const(Value.Float64(n))

        case 0x45:
            return NumericInstruction.Test.eqz(Value.Int32.self)
        case 0x46:
            return NumericInstruction.Comparison.eq(Value.Int32.self)
        case 0x47:
            return NumericInstruction.Comparison.ne(Value.Int32.self)
        case 0x48:
            return NumericInstruction.Comparison.ltS(Value.Int32.self)
        case 0x49:
            return NumericInstruction.Comparison.ltU(Value.Int32.self)
        case 0x4A:
            return NumericInstruction.Comparison.gtS(Value.Int32.self)
        case 0x4B:
            return NumericInstruction.Comparison.gtU(Value.Int32.self)
        case 0x4C:
            return NumericInstruction.Comparison.leS(Value.Int32.self)
        case 0x4D:
            return NumericInstruction.Comparison.leU(Value.Int32.self)
        case 0x4E:
            return NumericInstruction.Comparison.geS(Value.Int32.self)
        case 0x4F:
            return NumericInstruction.Comparison.geU(Value.Int32.self)

        case 0x50:
            return NumericInstruction.Test.eqz(Value.Int64.self)
        case 0x51:
            return NumericInstruction.Comparison.eq(Value.Int64.self)
        case 0x52:
            return NumericInstruction.Comparison.ne(Value.Int64.self)
        case 0x53:
            return NumericInstruction.Comparison.ltS(Value.Int64.self)
        case 0x54:
            return NumericInstruction.Comparison.ltU(Value.Int64.self)
        case 0x55:
            return NumericInstruction.Comparison.gtS(Value.Int64.self)
        case 0x56:
            return NumericInstruction.Comparison.gtU(Value.Int64.self)
        case 0x57:
            return NumericInstruction.Comparison.leS(Value.Int64.self)
        case 0x58:
            return NumericInstruction.Comparison.leU(Value.Int64.self)
        case 0x59:
            return NumericInstruction.Comparison.geS(Value.Int64.self)
        case 0x5A:
            return NumericInstruction.Comparison.geU(Value.Int64.self)

        case 0x5B:
            return NumericInstruction.Comparison.eq(Value.Float32.self)
        case 0x5C:
            return NumericInstruction.Comparison.ne(Value.Float32.self)
        case 0x5D:
            return NumericInstruction.Comparison.lt(Value.Float32.self)
        case 0x5E:
            return NumericInstruction.Comparison.gt(Value.Float32.self)
        case 0x5F:
            return NumericInstruction.Comparison.le(Value.Float32.self)
        case 0x60:
            return NumericInstruction.Comparison.ge(Value.Float32.self)

        case 0x61:
            return NumericInstruction.Comparison.eq(Value.Float64.self)
        case 0x62:
            return NumericInstruction.Comparison.ne(Value.Float64.self)
        case 0x63:
            return NumericInstruction.Comparison.lt(Value.Float64.self)
        case 0x64:
            return NumericInstruction.Comparison.gt(Value.Float64.self)
        case 0x65:
            return NumericInstruction.Comparison.le(Value.Float64.self)
        case 0x66:
            return NumericInstruction.Comparison.ge(Value.Float64.self)

        case 0x67:
            return NumericInstruction.Unary.clz(Value.Int32.self)
        case 0x68:
            return NumericInstruction.Unary.ctz(Value.Int32.self)
        case 0x69:
            return NumericInstruction.Unary.popcnt(Value.Int32.self)
        case 0x6A:
            return NumericInstruction.Binary.add(Value.Int32.self)
        case 0x6B:
            return NumericInstruction.Binary.sub(Value.Int32.self)
        case 0x6C:
            return NumericInstruction.Binary.mul(Value.Int32.self)
        case 0x6D:
            return NumericInstruction.Binary.divS(Value.Int32.self)
        case 0x6E:
            return NumericInstruction.Binary.divU(Value.Int32.self)
        case 0x6F:
            return NumericInstruction.Binary.remS(Value.Int32.self)
        case 0x70:
            return NumericInstruction.Binary.remU(Value.Int32.self)
        case 0x71:
            return NumericInstruction.Binary.add(Value.Int32.self)
        case 0x72:
            return NumericInstruction.Binary.or(Value.Int32.self)
        case 0x73:
            return NumericInstruction.Binary.xor(Value.Int32.self)
        case 0x74:
            return NumericInstruction.Binary.shl(Value.Int32.self)
        case 0x75:
            return NumericInstruction.Binary.shrS(Value.Int32.self)
        case 0x76:
            return NumericInstruction.Binary.shrU(Value.Int32.self)
        case 0x77:
            return NumericInstruction.Binary.rotl(Value.Int32.self)
        case 0x78:
            return NumericInstruction.Binary.rotr(Value.Int32.self)

        case 0x79:
            return NumericInstruction.Unary.clz(Value.Int64.self)
        case 0x7A:
            return NumericInstruction.Unary.ctz(Value.Int64.self)
        case 0x7B:
            return NumericInstruction.Unary.popcnt(Value.Int64.self)
        case 0x7C:
            return NumericInstruction.Binary.add(Value.Int64.self)
        case 0x7D:
            return NumericInstruction.Binary.sub(Value.Int64.self)
        case 0x7E:
            return NumericInstruction.Binary.mul(Value.Int64.self)
        case 0x7F:
            return NumericInstruction.Binary.divS(Value.Int64.self)
        case 0x80:
            return NumericInstruction.Binary.divU(Value.Int64.self)
        case 0x81:
            return NumericInstruction.Binary.remS(Value.Int64.self)
        case 0x82:
            return NumericInstruction.Binary.remU(Value.Int64.self)
        case 0x83:
            return NumericInstruction.Binary.add(Value.Int64.self)
        case 0x84:
            return NumericInstruction.Binary.or(Value.Int64.self)
        case 0x85:
            return NumericInstruction.Binary.xor(Value.Int64.self)
        case 0x86:
            return NumericInstruction.Binary.shl(Value.Int64.self)
        case 0x87:
            return NumericInstruction.Binary.shrS(Value.Int64.self)
        case 0x88:
            return NumericInstruction.Binary.shrU(Value.Int64.self)
        case 0x89:
            return NumericInstruction.Binary.rotl(Value.Int64.self)
        case 0x8A:
            return NumericInstruction.Binary.rotr(Value.Int64.self)

        case 0x8B:
            return NumericInstruction.Unary.abs(Value.Float32.self)
        case 0x8C:
            return NumericInstruction.Unary.neg(Value.Float32.self)
        case 0x8D:
            return NumericInstruction.Unary.ceil(Value.Float32.self)
        case 0x8E:
            return NumericInstruction.Unary.floor(Value.Float32.self)
        case 0x8F:
            return NumericInstruction.Unary.trunc(Value.Float32.self)
        case 0x90:
            return NumericInstruction.Unary.nearest(Value.Float32.self)
        case 0x91:
            return NumericInstruction.Unary.sqrt(Value.Float32.self)
        case 0x92:
            return NumericInstruction.Binary.add(Value.Float32.self)
        case 0x93:
            return NumericInstruction.Binary.sub(Value.Float32.self)
        case 0x94:
            return NumericInstruction.Binary.mul(Value.Float32.self)
        case 0x95:
            return NumericInstruction.Binary.div(Value.Float32.self)
        case 0x96:
            return NumericInstruction.Binary.min(Value.Float32.self)
        case 0x97:
            return NumericInstruction.Binary.max(Value.Float32.self)
        case 0x98:
            return NumericInstruction.Binary.copysign(Value.Float32.self)

        case 0x99:
            return NumericInstruction.Unary.abs(Value.Float64.self)
        case 0x9A:
            return NumericInstruction.Unary.neg(Value.Float64.self)
        case 0x9B:
            return NumericInstruction.Unary.ceil(Value.Float64.self)
        case 0x9C:
            return NumericInstruction.Unary.floor(Value.Float64.self)
        case 0x9D:
            return NumericInstruction.Unary.trunc(Value.Float64.self)
        case 0x9E:
            return NumericInstruction.Unary.nearest(Value.Float64.self)
        case 0x9F:
            return NumericInstruction.Unary.sqrt(Value.Float64.self)
        case 0xA0:
            return NumericInstruction.Binary.add(Value.Float64.self)
        case 0xA1:
            return NumericInstruction.Binary.sub(Value.Float64.self)
        case 0xA2:
            return NumericInstruction.Binary.mul(Value.Float64.self)
        case 0xA3:
            return NumericInstruction.Binary.div(Value.Float64.self)
        case 0xA4:
            return NumericInstruction.Binary.min(Value.Float64.self)
        case 0xA5:
            return NumericInstruction.Binary.max(Value.Float64.self)
        case 0xA6:
            return NumericInstruction.Binary.copysign(Value.Float64.self)

        case 0xA7:
            return NumericInstruction.Conversion.wrap(Value.Int32.self, Value.Int64.self)
        case 0xA8:
            return NumericInstruction.Conversion.truncS(Value.Int32.self, Value.Float32.self)
        case 0xA9:
            return NumericInstruction.Conversion.truncU(Value.Int32.self, Value.Float32.self)
        case 0xAA:
            return NumericInstruction.Conversion.truncS(Value.Int32.self, Value.Float64.self)
        case 0xAB:
            return NumericInstruction.Conversion.truncU(Value.Int32.self, Value.Float64.self)
        case 0xAC:
            return NumericInstruction.Conversion.extendS(Value.Int64.self, Value.Int32.self)
        case 0xAD:
            return NumericInstruction.Conversion.extendU(Value.Int64.self, Value.Int32.self)
        case 0xAE:
            return NumericInstruction.Conversion.truncS(Value.Int64.self, Value.Float32.self)
        case 0xAF:
            return NumericInstruction.Conversion.truncU(Value.Int64.self, Value.Float32.self)
        case 0xB0:
            return NumericInstruction.Conversion.truncS(Value.Int64.self, Value.Float64.self)
        case 0xB1:
            return NumericInstruction.Conversion.truncU(Value.Int64.self, Value.Float64.self)
        case 0xB2:
            return NumericInstruction.Conversion.convertS(Value.Float32.self, Value.Int32.self)
        case 0xB3:
            return NumericInstruction.Conversion.convertU(Value.Float32.self, Value.Int32.self)
        case 0xB4:
            return NumericInstruction.Conversion.convertS(Value.Float32.self, Value.Int64.self)
        case 0xB5:
            return NumericInstruction.Conversion.convertU(Value.Float32.self, Value.Int64.self)
        case 0xB6:
            return NumericInstruction.Conversion.demote(Value.Float32.self, Value.Float64.self)
        case 0xB7:
            return NumericInstruction.Conversion.convertS(Value.Float64.self, Value.Int32.self)
        case 0xB8:
            return NumericInstruction.Conversion.convertU(Value.Float64.self, Value.Int32.self)
        case 0xB9:
            return NumericInstruction.Conversion.convertS(Value.Float64.self, Value.Int64.self)
        case 0xBA:
            return NumericInstruction.Conversion.convertU(Value.Float64.self, Value.Int64.self)
        case 0xBB:
            return NumericInstruction.Conversion.promote(Value.Float64.self, Value.Float32.self)
        case 0xBC:
            return NumericInstruction.Conversion.reinterpret(Value.Int32.self, Value.Float32.self)
        case 0xBD:
            return NumericInstruction.Conversion.reinterpret(Value.Int64.self, Value.Float64.self)
        case 0xBE:
            return NumericInstruction.Conversion.reinterpret(Value.Float32.self, Value.Int32.self)
        case 0xBF:
            return NumericInstruction.Conversion.reinterpret(Value.Float64.self, Value.Int64.self)
        default:
            throw StreamError.unexpected(code, index: currentIndex, expected: nil)
        }
    }

    func parseExpression() throws -> Expression {
        var instructions = [Instruction]()
        var instruction: Instruction

        repeat {
            instruction = try parseInstruction()
            instructions.append(instruction)
        } while !instruction.isEqual(to: PseudoInstruction.end)

        return Expression(instructions: instructions)
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#sections>
extension WASMParser {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#custom-section>
    func parseCustomSection() throws -> Section {
        _ = try stream.consume(0)
        let size: UInt32 = try parseUnsigned()

        let name = try parseName()
        guard size > name.utf8.count else {
            throw WASMParserError.invalidSectionSize(size)
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
            let expression = try parseExpression()
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
            let table: UInt32 = try parseUnsigned()
            let expression = try parseExpression()
            let initializer: [UInt32] = try parseVector { try parseUnsigned() }
            return Element(table: table, offset: expression, initializer: initializer)
        })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#code-section>
    func parseCodeSection() throws -> Section {
        _ = try stream.consume(10)
        /* size */ _ = try parseUnsigned() as UInt32

        return .code(try parseVector {
            /* size */ _ = try parseUnsigned() as UInt32
            let locals = try parseVector { () -> [ValueType] in
                let n: UInt32 = try parseUnsigned()
                let t = try parseValueType()
                return (0 ..< n).map { _ in t }
            }
            let expression = try parseExpression()
            return Code(locals: locals.flatMap { $0 }, expression: expression)
        })
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#data-section>
    func parseDataSection() throws -> Section {
        _ = try stream.consume(11)
        /* size */ _ = try parseUnsigned() as UInt32

        return .data(try parseVector {
            let data: UInt32 = try parseUnsigned()
            let offset = try parseExpression()
            let initializer = try parseVector { try stream.consumeAny() }
            return Data(data: data, offset: offset, initializer: initializer)
        })
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/binary/modules.html#binary-module>
extension WASMParser {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-magic>
    func parseMagicNumber() throws {
        let magicNumber = try stream.consume(count: 4)
        guard magicNumber == [0x00, 0x61, 0x73, 0x6D] else {
            throw WASMParserError.invalidMagicNumber(magicNumber)
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/binary/modules.html#binary-version>
    func parseVersion() throws {
        let version = try stream.consume(count: 4)
        guard version == [0x01, 0x00, 0x00, 0x00] else {
            throw WASMParserError.unknownVersion(version)
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
            throw WASMParserError.inconsistentFunctionAndCodeLength(
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
