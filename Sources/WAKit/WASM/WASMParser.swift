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
}

extension WASMParser {
    func parseUnsigned32() throws -> UInt32 {
        return UInt32(try parseUnsigned(bits: 32))
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
        case 0x0B:
            return PseudoInstruction.end
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

        return module
    }
}
