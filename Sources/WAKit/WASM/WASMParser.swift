import Parser

public final class WASMParser<Stream: ByteStream> {
    public let stream: Stream

    public var currentIndex: Stream.Index {
        return stream.currentIndex
    }

    init(stream: Stream) {
        self.stream = stream
    }
}

public enum WASMParserError: Swift.Error {
    case invalidUnicode([UInt8])
    case invalidSectionSize(UInt32)
}

extension WASMParser {
    typealias StreamError = Parser.Error<Stream.Element>
}

// https://webassembly.github.io/spec/core/binary/conventions.html#vectors
extension WASMParser {
    func parseVector<Content>(content parser: () throws -> Content) throws -> [Content] {
        var contents = [Content]()
        let count = try parseUnsigned(bits: 32)
        for _ in 0 ..< count {
            contents.append(try parser())
        }
        return contents
    }
}

// https://webassembly.github.io/spec/core/binary/values.html#integers
extension WASMParser {

    private func p2<I: BinaryInteger>(_ n: I) -> I { return 1 << n }

    func parseUnsigned(bits: Int) throws -> UInt {
        let first = try stream.peek()

        switch UInt(first) {
        case let n where n < p2(7) && n < p2(bits):
            try stream.consumeAny()
            return UInt(first)
        case let n where n >= p2(7) && bits > 7:
            try stream.consumeAny()
            let m = try parseUnsigned(bits: bits - 7)
            let result = p2(7) * m + (n - p2(7))
            return result
        default:
            throw StreamError.unexpected(first, expected: nil)
        }
    }

    func parseSigned(bits: Int) throws -> Int {
        let first = try stream.peek()

        switch Int(first) {
        case let n where n < p2(6) && n < p2(bits - 1):
            try stream.consumeAny()
            return n
        case let n where p2(6) <= n && n < p2(7) && n >= (p2(7) - p2(bits - 1)):
            try stream.consumeAny()
            return n - p2(7)
        case let n where n >= p2(7) && bits > 7:
            try stream.consumeAny()
            let m = try parseSigned(bits: bits - 7)
            let result = m << 7 + (n - p2(7))
            return result
        default:
            throw StreamError.unexpected(first, expected: nil)
        }
    }

    func parseInteger(bits: Int) throws -> Int {
        let i = try parseSigned(bits: bits)
        switch i {
        case ..<p2(bits - 1): return i
        default: return i - p2(bits)
        }
    }
}

extension WASMParser {
    func parseUnsigned32() throws -> UInt32 {
        return UInt32(try parseUnsigned(bits: 32))
    }
}

// http://webassembly.github.io/spec/core/binary/values.html#floating-point
extension WASMParser {
    func parseFloatingPoint(bits: Int) throws -> Double {
        assert(bits == 32 || bits == 64)
        let bytes = try (0 ..< (bits / 8))
            .map { _ in try UInt64(stream.consumeAny()) }
            .reduce(0) { acc, byte in acc << 8 + byte }
        return Double(bitPattern: bytes)
    }
}

extension WASMParser {
    func parseFloat() throws -> Float {
        let bytes = try (0 ..< 4)
            .map { _ in try UInt32(stream.consumeAny()) }
            .reduce(0) { acc, byte in acc << 8 + byte }
        return Float(bitPattern: bytes)
    }

    func parseDouble() throws -> Double {
        let bytes = try (0 ..< 8)
            .map { _ in try UInt64(stream.consumeAny()) }
            .reduce(0) { acc, byte in acc << 8 + byte }
        return Double(bitPattern: bytes)
    }
}

// https://webassembly.github.io/spec/core/binary/values.html#names
extension WASMParser {
    func parseName() throws -> String {
        let bytes = try parseVector { () -> UInt8 in
            return try stream.consumeAny()
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

// https://webassembly.github.io/spec/core/binary/types.html#types
extension WASMParser {

    // https://webassembly.github.io/spec/core/binary/types.html#value-types
    func parseValueType() throws -> Value.Type {
        let b = try stream.consume(Set(0x7C ... 0x7F))

        switch b {
        case 0x7F:
            return Int32.self
        case 0x7E:
            return Int64.self
        case 0x7D:
            return Float32.self
        case 0x7C:
            return Float64.self
        default:
            throw StreamError.unexpected(b, expected: Set(0x7C ... 0x7F))
        }
    }

    // https://webassembly.github.io/spec/core/binary/types.html#result-types
    func parseResultType() throws -> ResultType {
        let b = try stream.peek()

        switch b {
        case 0x40:
            try stream.consumeAny()
            return []
        default:
            return [try parseValueType()]
        }
    }

    // https://webassembly.github.io/spec/core/binary/types.html#function-types
    func parseFunctionType() throws -> FunctionType {
        try stream.consume(0x60)

        let parameters = try parseVector { try parseValueType() }
        let results = try parseVector { try parseValueType() }
        return FunctionType(parameters: parameters, results: results)
    }

    // https://webassembly.github.io/spec/core/binary/types.html#limits
    func parseLimits() throws -> Limits {
        let b = try stream.peek()
        switch b {
        case 0x00:
            try stream.consumeAny()
            return try Limits(min: parseUnsigned32(), max: nil)
        case 0x01:
            try stream.consumeAny()
            return try Limits(min: parseUnsigned32(), max: parseUnsigned32())
        default:
            throw StreamError.unexpected(b, expected: [0x00, 0x01])
        }
    }

    // https://webassembly.github.io/spec/core/binary/types.html#memory-types
    func parseMemoryType() throws -> MemoryType {
        return try parseLimits()
    }

    // https://webassembly.github.io/spec/core/binary/types.html#table-types
    func parseTableType() throws -> TableType {
        let elementType: FunctionType
        let b = try stream.peek()
        switch b {
        case 0x70:
            try stream.consumeAny()
            elementType = .any
        default:
            throw StreamError.unexpected(b, expected: [0x70])
        }
        let limits = try parseLimits()
        return TableType(elementType: elementType, limits: limits)
    }

    // https://webassembly.github.io/spec/core/binary/types.html#global-types
    func parseGlobalType() throws -> GlobalType {
        let valueType = try parseValueType()
        let mutability = try parseMutability()
        return GlobalType(mutability: mutability, valueType: valueType)
    }

    func parseMutability() throws -> Mutability {
        let b = try stream.peek()
        switch b {
        case 0x00:
            try stream.consumeAny()
            return .constant
        case 0x01:
            try stream.consumeAny()
            return .variable
        default:
            throw StreamError.unexpected(b, expected: [0x00, 0x01])
        }
    }
}

// https://webassembly.github.io/spec/core/binary/instructions.html
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
            return ControlInstruction.block(type, expression.instructions)
        case 0x03:
            let type = try parseResultType()
            let expression = try parseExpression()
            return ControlInstruction.loop(type, expression.instructions)
        case 0x04:
            let type = try parseResultType()
            let ifExpression = try parseExpression()
            guard (try? stream.consume(0x05)) == nil else {
                return ControlInstruction.if(type, ifExpression.instructions, [])
            }
            let elseExpression = try parseExpression()
            return ControlInstruction.if(type, ifExpression.instructions, elseExpression.instructions)
        case 0x0B:
            return PseudoInstruction.end
        case 0x0C:
            let label = try parseUnsigned32()
            return ControlInstruction.br(label)
        case 0x0D:
            let label = try parseUnsigned32()
            return ControlInstruction.brIf(label)
        case 0x0E:
            let labels = try parseVector { try parseUnsigned32() }
            return ControlInstruction.brTable(labels)
        case 0x0F:
            return ControlInstruction.return
        case 0x10:
            let index = try parseUnsigned32()
            return ControlInstruction.call(index)
        case 0x11:
            let index = try parseUnsigned32()
            return ControlInstruction.callIndirect(index)

        case 0x1A:
            return ParametricInstruction.drop
        case 0x1B:
            return ParametricInstruction.select

        case 0x20:
            let index = try parseUnsigned32()
            return VariableInstruction.getLocal(index)
        case 0x21:
            let index = try parseUnsigned32()
            return VariableInstruction.setLocal(index)
        case 0x22:
            let index = try parseUnsigned32()
            return VariableInstruction.teeLocal(index)
        case 0x23:
            let index = try parseUnsigned32()
            return VariableInstruction.getGlobal(index)
        case 0x24:
            let index = try parseUnsigned32()
            return VariableInstruction.setGlobal(index)

        case 0x28:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.load((align, offset))
        case 0x29:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load((align, offset))
        case 0x2A:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.f32.load((align, offset))
        case 0x2B:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.f64.load((align, offset))
        case 0x2C:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.load8s((align, offset))
        case 0x2D:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load8u((align, offset))
        case 0x2E:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.load16s((align, offset))
        case 0x2F:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.load16u((align, offset))
        case 0x30:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load8s((align, offset))
        case 0x31:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load8u((align, offset))
        case 0x32:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load16s((align, offset))
        case 0x33:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load16u((align, offset))
        case 0x34:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load32s((align, offset))
        case 0x35:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.load32u((align, offset))
        case 0x36:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.store((align, offset))
        case 0x37:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.store((align, offset))
        case 0x38:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.f32.store((align, offset))
        case 0x39:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.f64.store((align, offset))
        case 0x3A:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.store8((align, offset))
        case 0x3B:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i32.store16((align, offset))
        case 0x3C:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.store8((align, offset))
        case 0x3D:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.store16((align, offset))
        case 0x3E:
            let align = try parseUnsigned32()
            let offset = try parseUnsigned32()
            return MemoryInstruction.i64.store32((align, offset))
        case 0x3F:
            try stream.consume(0x00)
            return MemoryInstruction.currentMemory
        case 0x40:
            try stream.consume(0x00)
            return MemoryInstruction.growMemory

        case 0x41:
            let n = try parseInteger(bits: 32)
            return NumericInstruction.i32.const(Int32(n))
        case 0x42:
            let n = try parseInteger(bits: 64)
            return NumericInstruction.i64.const(Int64(n))
        case 0x43:
            let n = try parseFloat()
            return NumericInstruction.f32.const(n)
        case 0x44:
            let n = try parseDouble()
            return NumericInstruction.f64.const(n)

        case 0x45:
            return NumericInstruction.i32.eqz
        case 0x46:
            return NumericInstruction.i32.eq
        case 0x47:
            return NumericInstruction.i32.ne
        case 0x48:
            return NumericInstruction.i32.ltS
        case 0x49:
            return NumericInstruction.i32.ltU
        case 0x4A:
            return NumericInstruction.i32.gtS
        case 0x4B:
            return NumericInstruction.i32.gtU
        case 0x4C:
            return NumericInstruction.i32.leS
        case 0x4D:
            return NumericInstruction.i32.leU
        case 0x4E:
            return NumericInstruction.i32.geS
        case 0x4F:
            return NumericInstruction.i32.geU

        case 0x50:
            return NumericInstruction.i64.eqz
        case 0x51:
            return NumericInstruction.i64.eq
        case 0x52:
            return NumericInstruction.i64.ne
        case 0x53:
            return NumericInstruction.i64.ltS
        case 0x54:
            return NumericInstruction.i64.ltU
        case 0x55:
            return NumericInstruction.i64.gtS
        case 0x56:
            return NumericInstruction.i64.gtU
        case 0x57:
            return NumericInstruction.i64.leS
        case 0x58:
            return NumericInstruction.i64.leU
        case 0x59:
            return NumericInstruction.i64.geS
        case 0x5A:
            return NumericInstruction.i64.geU

        case 0x5B:
            return NumericInstruction.f32.eq
        case 0x5C:
            return NumericInstruction.f32.ne
        case 0x5D:
            return NumericInstruction.f32.lt
        case 0x5E:
            return NumericInstruction.f32.gt
        case 0x5F:
            return NumericInstruction.f32.le
        case 0x60:
            return NumericInstruction.f32.ge

        case 0x61:
            return NumericInstruction.f64.eq
        case 0x62:
            return NumericInstruction.f64.ne
        case 0x63:
            return NumericInstruction.f64.lt
        case 0x64:
            return NumericInstruction.f64.gt
        case 0x65:
            return NumericInstruction.f64.le
        case 0x66:
            return NumericInstruction.f64.ge

        case 0x67:
            return NumericInstruction.i32.clz
        case 0x68:
            return NumericInstruction.i32.ctz
        case 0x69:
            return NumericInstruction.i32.popcnt
        case 0x6A:
            return NumericInstruction.i32.add
        case 0x6B:
            return NumericInstruction.i32.sub
        case 0x6C:
            return NumericInstruction.i32.mul
        case 0x6D:
            return NumericInstruction.i32.divS
        case 0x6E:
            return NumericInstruction.i32.divU
        case 0x6F:
            return NumericInstruction.i32.remS
        case 0x70:
            return NumericInstruction.i32.remU
        case 0x71:
            return NumericInstruction.i32.add
        case 0x72:
            return NumericInstruction.i32.or
        case 0x73:
            return NumericInstruction.i32.xor
        case 0x74:
            return NumericInstruction.i32.shl
        case 0x75:
            return NumericInstruction.i32.shrS
        case 0x76:
            return NumericInstruction.i32.shrU
        case 0x77:
            return NumericInstruction.i32.rotl
        case 0x78:
            return NumericInstruction.i32.rotr

        case 0x79:
            return NumericInstruction.i64.clz
        case 0x7A:
            return NumericInstruction.i64.ctz
        case 0x7B:
            return NumericInstruction.i64.popcnt
        case 0x7C:
            return NumericInstruction.i64.add
        case 0x7D:
            return NumericInstruction.i64.sub
        case 0x7E:
            return NumericInstruction.i64.mul
        case 0x7F:
            return NumericInstruction.i64.divS
        case 0x80:
            return NumericInstruction.i64.divU
        case 0x81:
            return NumericInstruction.i64.remS
        case 0x82:
            return NumericInstruction.i64.remU
        case 0x83:
            return NumericInstruction.i64.add
        case 0x84:
            return NumericInstruction.i64.or
        case 0x85:
            return NumericInstruction.i64.xor
        case 0x86:
            return NumericInstruction.i64.shl
        case 0x87:
            return NumericInstruction.i64.shrS
        case 0x88:
            return NumericInstruction.i64.shrU
        case 0x89:
            return NumericInstruction.i64.rotl
        case 0x8A:
            return NumericInstruction.i64.rotr

        case 0x8B:
            return NumericInstruction.f32.abs
        case 0x8C:
            return NumericInstruction.f32.neg
        case 0x8D:
            return NumericInstruction.f32.ceil
        case 0x8E:
            return NumericInstruction.f32.floor
        case 0x8F:
            return NumericInstruction.f32.trunc
        case 0x90:
            return NumericInstruction.f32.nearest
        case 0x91:
            return NumericInstruction.f32.sqrt
        case 0x92:
            return NumericInstruction.f32.add
        case 0x93:
            return NumericInstruction.f32.sub
        case 0x94:
            return NumericInstruction.f32.mul
        case 0x95:
            return NumericInstruction.f32.div
        case 0x96:
            return NumericInstruction.f32.min
        case 0x97:
            return NumericInstruction.f32.max
        case 0x98:
            return NumericInstruction.f32.copysign

        case 0x99:
            return NumericInstruction.f64.abs
        case 0x9A:
            return NumericInstruction.f64.neg
        case 0x9B:
            return NumericInstruction.f64.ceil
        case 0x9C:
            return NumericInstruction.f64.floor
        case 0x9D:
            return NumericInstruction.f64.trunc
        case 0x9E:
            return NumericInstruction.f64.nearest
        case 0x9F:
            return NumericInstruction.f64.sqrt
        case 0xA0:
            return NumericInstruction.f64.add
        case 0xA1:
            return NumericInstruction.f64.sub
        case 0xA2:
            return NumericInstruction.f64.mul
        case 0xA3:
            return NumericInstruction.f64.div
        case 0xA4:
            return NumericInstruction.f64.min
        case 0xA5:
            return NumericInstruction.f64.max
        case 0xA6:
            return NumericInstruction.f64.copysign

        case 0xA7:
            return NumericInstruction.i32.wrapI64
        case 0xA8:
            return NumericInstruction.i32.truncSF32
        case 0xA9:
            return NumericInstruction.i32.truncUF32
        case 0xAA:
            return NumericInstruction.i32.truncSF64
        case 0xAB:
            return NumericInstruction.i32.truncUF64
        case 0xAC:
            return NumericInstruction.i64.extendSI32
        case 0xAD:
            return NumericInstruction.i64.extendUI32
        case 0xAE:
            return NumericInstruction.i64.truncSF32
        case 0xAF:
            return NumericInstruction.i64.truncUF32
        case 0xB0:
            return NumericInstruction.i64.truncSF64
        case 0xB1:
            return NumericInstruction.i64.truncUF64
        case 0xB2:
            return NumericInstruction.f32.convertSI32
        case 0xB3:
            return NumericInstruction.f32.convertUI32
        case 0xB4:
            return NumericInstruction.f32.convertSI64
        case 0xB5:
            return NumericInstruction.f32.convertUI64
        case 0xB6:
            return NumericInstruction.f32.demoteF64
        case 0xB7:
            return NumericInstruction.f64.convertSI32
        case 0xB8:
            return NumericInstruction.f64.convertUI32
        case 0xB9:
            return NumericInstruction.f64.convertSI64
        case 0xBA:
            return NumericInstruction.f64.convertUI64
        case 0xBB:
            return NumericInstruction.f64.promoteF32
        case 0xBC:
            return NumericInstruction.i32.reinterpretF32
        case 0xBD:
            return NumericInstruction.i64.reinterpretF64
        case 0xBE:
            return NumericInstruction.f32.reinterpretI32
        case 0xBF:
            return NumericInstruction.f64.reinterpretI64
        default:
            throw StreamError.unexpected(code, expected: nil)
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

// https://webassembly.github.io/spec/core/binary/modules.html#sections
extension WASMParser {

    // https://webassembly.github.io/spec/core/binary/modules.html#custom-section
    func parseCustomSection() throws -> Section {
        try stream.consume(0)
        let size = try parseUnsigned32()

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

    // https://webassembly.github.io/spec/core/binary/modules.html#type-section
    func parseTypeSection() throws -> Section {
        try stream.consume(1)
        /* size */ _ = try parseUnsigned32()
        return .type(try parseVector { try parseFunctionType() })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#import-section
    func parseImportSection() throws -> Section {
        try stream.consume(2)
        /* size */ _ = try parseUnsigned32()

        let imports: [Import] = try parseVector {
            let module = try parseName()
            let name = try parseName()
            let descriptor = try parseImportDescriptor()
            return Import(module: module, name: name, descripter: descriptor)
        }
        return .import(imports)
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#binary-importdesc
    func parseImportDescriptor() throws -> ImportDescriptor {
        let b = try stream.peek()
        switch b {
        case 0x00:
            try stream.consumeAny()
            return try .function(parseUnsigned32())
        case 0x01:
            try stream.consumeAny()
            return try .table(parseTableType())
        case 0x02:
            try stream.consumeAny()
            return try .memory(parseMemoryType())
        case 0x03:
            try stream.consumeAny()
            return try .global(parseGlobalType())
        default:
            throw StreamError.unexpected(b, expected: Set(0x00 ... 0x03))
        }
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#function-section
    func parseFunctionSection() throws -> Section {
        try stream.consume(3)
        /* size */ _ = try parseUnsigned32()
        return .function(try parseVector { try parseUnsigned32() })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#table-section
    func parseTableSection() throws -> Section {
        try stream.consume(4)
        /* size */ _ = try parseUnsigned32()

        return .table(try parseVector { Table(type: try parseTableType()) })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#memory-section
    func parseMemorySection() throws -> Section {
        try stream.consume(5)
        /* size */ _ = try parseUnsigned32()

        return .memory(try parseVector { Memory(type: try parseLimits()) })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#global-section
    func parseGlobalSection() throws -> Section {
        try stream.consume(6)
        /* size */ _ = try parseUnsigned32()

        return .global(try parseVector {
            let type = try parseGlobalType()
            let expression = try parseExpression()
            return Global(type: type, initializer: expression)
        })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#export-section
    func parseExportSection() throws -> Section {
        try stream.consume(7)
        /* size */ _ = try parseUnsigned32()

        return .export(try parseVector {
            let name = try parseName()
            let descriptor = try parseExportDescriptor()
            return Export(name: name, descriptor: descriptor)
        })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#binary-exportdesc
    func parseExportDescriptor() throws -> ExportDescriptor {
        let b = try stream.peek()
        switch b {
        case 0x00:
            try stream.consumeAny()
            return try .function(parseUnsigned32())
        case 0x01:
            try stream.consumeAny()
            return try .table(parseUnsigned32())
        case 0x02:
            try stream.consumeAny()
            return try .memory(parseUnsigned32())
        case 0x03:
            try stream.consumeAny()
            return try .global(parseUnsigned32())
        default:
            throw StreamError.unexpected(b, expected: Set(0x00 ... 0x03))
        }
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#start-section
    func parseStartSection() throws -> Section {
        try stream.consume(8)
        /* size */ _ = try parseUnsigned32()

        return .start(try parseUnsigned32())
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#element-section
    func parseElementSection() throws -> Section {
        try stream.consume(9)
        /* size */ _ = try parseUnsigned32()

        return .element(try parseVector {
            let table = try parseUnsigned32()
            let expression = try parseExpression()
            let initializer = try parseVector { try parseUnsigned32() }
            return Element(table: table, offset: expression, initializer: initializer)
        })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#code-section
    func parseCodeSection() throws -> Section {
        try stream.consume(10)
        /* size */ _ = try parseUnsigned32()

        return .code(try parseVector {
            /* size */ _ = try parseUnsigned32()
            let locals = try parseVector { () -> [Value.Type] in
                let n = try parseUnsigned32()
                let t = try parseValueType()
                return (0 ..< n).map { _ in t }
            }
            let expression = try parseExpression()
            return Code(locals: locals.flatMap { $0 }, expression: expression)
        })
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#data-section
    func parseDataSection() throws -> Section {
        try stream.consume(11)
        /* size */ _ = try parseUnsigned32()

        return .data(try parseVector {
            let data = try parseUnsigned32()
            let offset = try parseExpression()
            let initializer = try parseVector { try stream.consumeAny() }
            return Data(data: data, offset: offset, initializer: initializer)
        })
    }
}

// https://webassembly.github.io/spec/core/binary/modules.html#binary-module
extension WASMParser {
    // https://webassembly.github.io/spec/core/binary/modules.html#binary-magic
    func parseMagicNumbers() throws {
        try stream.consume([0x00, 0x61, 0x73, 0x6D])
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#binary-version
    func parseVersion() throws {
        try stream.consume([0x01, 0x00, 0x00, 0x00])
    }

    // https://webassembly.github.io/spec/core/binary/modules.html#binary-module
    func parseModule() throws -> Module {
        try parseMagicNumbers()
        try parseVersion()

        var module = Module()

        var typeIndices = [TypeIndex]()
        var codes = [Code]()

        for i in 0 ... 11 {
            guard let id = try? stream.peek() else {
                break
            }

            switch id {
            case 0:
                _ = try? parseCustomSection()
            case 1 where id == i:
                if case let .type(types) = try parseTypeSection() {
                    module.types = types
                }
            case 2 where id == i:
                if case let .import(imports) = try parseImportSection() {
                    module.imports = imports
                }
            case 3 where id == i:
                if case let .function(_typeIndices) = try parseFunctionSection() {
                    typeIndices = _typeIndices
                }
            case 4 where id == i:
                if case let .table(tables) = try parseTableSection() {
                    module.tables = tables
                }
            case 5 where id == i:
                if case let .memory(memory) = try parseMemorySection() {
                    module.memories = memory
                }
            case 6 where id == i:
                if case let .global(globals) = try parseGlobalSection() {
                    module.globals = globals
                }
            case 7 where id == i:
                if case let .export(exports) = try parseExportSection() {
                    module.exports = exports
                }
            case 8 where id == i:
                if case let .start(start) = try parseStartSection() {
                    module.start = start
                }
            case 9 where id == i:
                if case let .element(elements) = try parseElementSection() {
                    module.elements = elements
                }
            case 10 where id == i:
                if case let .code(_codes) = try parseCodeSection() {
                    codes = _codes
                }
            case 11 where id == i:
                if case let .data(data) = try parseDataSection() {
                    module.data = data
                }
            default:
                continue
            }
        }

        let functions = codes.enumerated().map { index, code in
            Function(type: typeIndices[index], locals: code.locals, body: code.expression)
        }
        module.functions = functions

        return module
    }
}
