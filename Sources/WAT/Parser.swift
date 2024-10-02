import WasmParser

internal struct Parser {
    var lexer: Lexer

    init(_ input: String) {
        self.lexer = Lexer(input: input)
    }

    init(_ lexer: Lexer) {
        self.lexer = lexer
    }

    func peek(_ kind: TokenKind? = nil) throws -> Token? {
        var lexer = lexer
        guard let token = try lexer.lex() else { return nil }
        if let kind {
            guard token.kind == kind else { return nil }
        }
        return token
    }

    func peekKeyword() throws -> String? {
        guard let token = try peek(.keyword) else {
            return nil
        }
        return token.text(from: lexer)
    }

    mutating func take(_ kind: TokenKind) throws -> Bool {
        guard try peek(kind) != nil else { return false }
        try consume()
        return true
    }

    mutating func takeKeyword(_ keyword: String) throws -> Bool {
        guard let token = try peek(.keyword), token.text(from: lexer) == keyword else {
            return false
        }
        try consume()
        return true
    }

    /// Consume a `(keyword` sequence, returning whether the tokens were consumed.
    mutating func takeParenBlockStart(_ keyword: String) throws -> Bool {
        let original = lexer
        guard try take(.leftParen), try takeKeyword(keyword) else {
            lexer = original
            return false
        }
        return true
    }

    mutating func takeUnsignedInt<IntegerType: UnsignedInteger & FixedWidthInteger>(_: IntegerType.Type = IntegerType.self) throws -> IntegerType? {
        guard let token = try peek() else { return nil }
        guard case let .integer(nil, pattern) = token.kind else {
            return nil
        }
        try consume()
        switch pattern {
        case .hexPattern(let pattern):
            guard let index = IntegerType(pattern, radix: 16) else {
                throw WatParserError("invalid index \(pattern)", location: token.location(in: lexer))
            }
            return index
        case .decimalPattern(let pattern):
            guard let index = IntegerType(pattern) else {
                throw WatParserError("invalid index \(pattern)", location: token.location(in: lexer))
            }
            return index
        }
    }

    mutating func takeSignedInt<IntegerType: FixedWidthInteger, UnsignedType: FixedWidthInteger & UnsignedInteger>(
        fromBitPattern: (UnsignedType) -> IntegerType
    ) throws -> IntegerType? {
        guard let token = try peek() else { return nil }
        guard case let .integer(sign, pattern) = token.kind else {
            return nil
        }
        try consume()
        let value: UnsignedType
        switch pattern {
        case .hexPattern(let pattern):
            guard let index = UnsignedType(pattern, radix: 16) else {
                throw WatParserError("invalid index \(pattern)", location: token.location(in: lexer))
            }
            value = index
        case .decimalPattern(let pattern):
            guard let index = UnsignedType(pattern) else {
                throw WatParserError("invalid index \(pattern)", location: token.location(in: lexer))
            }
            value = index
        }
        switch sign {
        case .plus, nil: return fromBitPattern(value)
        case .minus: return fromBitPattern(~value &+ 1)
        }
    }

    mutating func takeStringBytes() throws -> [UInt8]? {
        guard let token = try peek(), case .string(let bytes) = token.kind else { return nil }
        try consume()
        return bytes
    }

    mutating func takeString() throws -> String? {
        guard let bytes = try takeStringBytes() else { return nil }
        return String(decoding: bytes, as: UTF8.self)
    }

    mutating func takeIndexOrId() throws -> IndexOrId? {
        let location = lexer.location()
        if let index: UInt32 = try takeUnsignedInt() {
            return .index(index, location)
        } else if let id = try takeId() {
            return .id(id, location)
        }
        return nil
    }

    @discardableResult
    mutating func expect(_ kind: TokenKind) throws -> Token {
        guard let token = try lexer.lex() else {
            throw WatParserError("expected \(kind)", location: lexer.location())
        }
        guard token.kind == kind else {
            throw WatParserError("expected \(kind)", location: token.location(in: lexer))
        }
        return token
    }

    @discardableResult
    mutating func expectKeyword(_ keyword: String? = nil) throws -> String {
        let token = try expect(.keyword)
        let text = token.text(from: lexer)
        if let keyword {
            guard text == keyword else {
                throw WatParserError("expected \(keyword)", location: token.location(in: lexer))
            }
        }
        return text
    }

    mutating func expectStringBytes() throws -> [UInt8] {
        guard let token = try lexer.lex() else {
            throw WatParserError("expected string", location: lexer.location())
        }
        guard case .string(let text) = token.kind else {
            throw WatParserError("expected string but got \(token.kind)", location: token.location(in: lexer))
        }
        return text
    }
    mutating func expectString() throws -> String {
        String(decoding: try expectStringBytes(), as: UTF8.self)
    }

    mutating func expectStringList() throws -> [UInt8] {
        var data: [UInt8] = []
        while try !take(.rightParen) {
            data += try expectStringBytes()
        }
        return data
    }

    mutating func expectUnsignedInt<IntegerType: UnsignedInteger & FixedWidthInteger>(_: IntegerType.Type = IntegerType.self) throws -> IntegerType {
        guard let value: IntegerType = try takeUnsignedInt() else {
            throw WatParserError("expected decimal index without sign", location: lexer.location())
        }
        return value
    }

    mutating func expectSignedInt<IntegerType: FixedWidthInteger, UnsignedType: FixedWidthInteger & UnsignedInteger>(
        fromBitPattern: (UnsignedType) -> IntegerType
    ) throws -> IntegerType {
        guard let value: IntegerType = try takeSignedInt(fromBitPattern: fromBitPattern) else {
            throw WatParserError("expected decimal index with sign", location: lexer.location())
        }
        return value
    }

    mutating func expectFloatingPoint<F: BinaryFloatingPoint & LosslessStringConvertible, BitPattern: FixedWidthInteger>(
        _: F.Type, toBitPattern: (F) -> BitPattern,
        buildBitPattern: (
            _ sign: FloatingPointSign,
            _ exponentBitPattern: UInt,
            _ significandBitPattern: UInt
        ) -> BitPattern
    ) throws -> BitPattern {
        let token = try consume()

        var infinityExponent: UInt {
            return 1 &<< UInt(F.exponentBitCount) - 1
        }

        switch token.kind {
        case let .float(sign, pattern):
            let float: F
            switch pattern {
            case .decimalPattern(let pattern):
                guard let value = F(pattern) else {
                    throw WatParserError("invalid float \(pattern)", location: token.location(in: lexer))
                }
                float = value
            case .hexPattern(let pattern):
                guard let value = F("0x" + pattern) else {
                    throw WatParserError("invalid float \(pattern)", location: token.location(in: lexer))
                }
                float = value
            case .inf:
                float = .infinity
            case .nan(hexPattern: nil):
                float = .nan
            case .nan(let hexPattern?):
                guard let bitPattern = BitPattern(hexPattern, radix: 16) else {
                    throw WatParserError("invalid float \(hexPattern)", location: token.location(in: lexer))
                }
                return buildBitPattern(sign ?? .plus, infinityExponent, UInt(bitPattern))
            }
            return toBitPattern(sign == .minus ? -float : float)
        case let .integer(sign, pattern):
            let float: F
            switch pattern {
            case .hexPattern(let pattern):
                guard let value = F("0x" + pattern) else {
                    throw WatParserError("invalid float \(pattern)", location: token.location(in: lexer))
                }
                float = value
            case .decimalPattern(let pattern):
                guard let value = F(pattern) else {
                    throw WatParserError("invalid float \(pattern)", location: token.location(in: lexer))
                }
                float = value
            }
            return toBitPattern(sign == .minus ? -float : float)
        default:
            throw WatParserError("expected float but got \(token.kind)", location: token.location(in: lexer))
        }
    }

    mutating func expectFloat32() throws -> IEEE754.Float32 {
        let bitPattern = try expectFloatingPoint(
            Float32.self, toBitPattern: \.bitPattern,
            buildBitPattern: {
                UInt32(
                    ($0 == .minus ? 1 : 0) << (Float32.exponentBitCount + Float32.significandBitCount)
                        + ($1 << Float32.significandBitCount) + $2
                )
            }
        )
        return IEEE754.Float32(bitPattern: bitPattern)
    }

    mutating func expectFloat64() throws -> IEEE754.Float64 {
        let bitPattern = try expectFloatingPoint(
            Float64.self, toBitPattern: \.bitPattern,
            buildBitPattern: {
                UInt64(
                    ($0 == .minus ? 1 : 0) << (Float64.exponentBitCount + Float64.significandBitCount)
                        + ($1 << Float64.significandBitCount) + $2
                )
            }
        )
        return IEEE754.Float64(bitPattern: bitPattern)
    }

    mutating func expectIndex() throws -> UInt32 { try expectUnsignedInt(UInt32.self) }

    mutating func expectParenBlockStart(_ keyword: String) throws {
        guard try takeParenBlockStart(keyword) else {
            throw WatParserError("expected \(keyword)", location: lexer.location())
        }
    }

    enum IndexOrId {
        case index(UInt32, Location)
        case id(Name, Location)
        var location: Location {
            switch self {
            case .index(_, let location), .id(_, let location):
                return location
            }
        }
    }

    mutating func expectIndexOrId() throws -> IndexOrId {
        guard let indexOrId = try takeIndexOrId() else {
            throw WatParserError("expected index or id", location: lexer.location())
        }
        return indexOrId
    }

    func isEndOfParen() throws -> Bool {
        guard let token = try peek() else { return true }
        return token.kind == .rightParen
    }

    @discardableResult
    mutating func consume() throws -> Token {
        guard let token = try lexer.lex() else {
            throw WatParserError("unexpected EOF", location: lexer.location())
        }
        return token
    }

    mutating func takeId() throws -> Name? {
        guard let token = try peek(.id) else { return nil }
        try consume()
        return Name(value: token.text(from: lexer), location: token.location(in: lexer))
    }

    mutating func skipParenBlock() throws {
        var depth = 1
        while depth > 0 {
            let token = try consume()
            switch token.kind {
            case .leftParen:
                depth += 1
            case .rightParen:
                depth -= 1
            default:
                break
            }
        }
    }
}

public struct WatParserError: Error, CustomStringConvertible {
    public let message: String
    public let location: Location?

    public var description: String {
        if let location {
            let (line, column) = location.computeLineAndColumn()
            return "\(line):\(column): \(message)"
        } else {
            return message
        }
    }

    init(_ message: String, location: Location?) {
        self.message = message
        self.location = location
    }
}
