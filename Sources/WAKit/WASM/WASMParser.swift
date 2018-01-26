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
    case invalidSectionSize(UInt)
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
        let b = try stream.peek()

        switch b {
        case 0x7F:
            try stream.consumeAny()
            return Int32.self
        case 0x7E:
            try stream.consumeAny()
            return Int64.self
        case 0x7D:
            try stream.consumeAny()
            return Float32.self
        case 0x7C:
            try stream.consumeAny()
            return Float64.self
        default:
            throw StreamError.unexpected(b, expected: Set(0x7C ... 0x7F))
        }
    }
}

// https://webassembly.github.io/spec/core/binary/modules.html#sections
extension WASMParser {
    func parseSection() throws -> Section {
        let id = try stream.peek()

        switch id {
        case 0:
            return try parseCustomSection()
        default:
            throw StreamError.unexpected(id, expected: Set(0 ... 11))
        }
    }

    func parseCustomSection() throws -> CustomSection {
        try stream.consume(0)

        let size = try parseUnsigned(bits: 32)
        let name = try parseName()
        guard size > name.utf8.count else {
            throw WASMParserError.invalidSectionSize(size)
        }
        let contentSize = Int(size) - name.utf8.count

        var content = [UInt8]()
        for _ in 0 ..< contentSize {
            content.append(try stream.consumeAny())
        }

        return CustomSection(name: name, content: content)
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

        let module = Module()
        while try stream.hasReachedEnd() == false {
            _ = try parseSection()
        }
        return module
    }
}
