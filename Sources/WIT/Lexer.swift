typealias TextRange = Range<String.UnicodeScalarView.Index>

struct Lexer {
    struct Cursor {
        let input: String.UnicodeScalarView
        var nextIndex: String.UnicodeScalarView.Index

        init(input: String) {
            self.input = input.unicodeScalars
            self.nextIndex = self.input.startIndex
        }

        func peek(at offset: Int = 0) -> Unicode.Scalar? {
            precondition(offset >= 0)
            guard self.input.index(self.nextIndex, offsetBy: offset) < self.input.endIndex else {
                return nil
            }
            let index = self.input.index(self.nextIndex, offsetBy: offset)
            return self.input[index]
        }

        mutating func next() -> Unicode.Scalar? {
            guard self.nextIndex < self.input.endIndex else { return nil }
            defer { self.nextIndex = self.input.index(after: self.nextIndex) }
            return self.input[self.nextIndex]
        }

        mutating func eat(_ expected: UnicodeScalar) -> Bool {
            if peek() == expected {
                _ = next()
                return true
            }
            return false
        }
    }

    struct Lexeme: Equatable {
        var kind: TokenKind
        var textRange: TextRange
    }

    struct Diagnostic: CustomStringConvertible {
        let description: String
    }

    var cursor: Cursor

    init(cursor: Cursor) {
        self.cursor = cursor
    }

    mutating func advanceToEndOfBlockComment() -> Diagnostic? {
        var depth = 1
        while true {
            switch self.cursor.next() {
            case "*":
                // Check end of block comment
                if cursor.eat("/") {
                    depth -= 1
                    if depth == 0 {
                        break
                    }
                }
            case "/":
                // Check nested "/*"
                if cursor.eat("*") {
                    depth += 1
                }
            case nil:
                return Diagnostic(description: "unterminated block comment")
            case .some:
                continue
            }
        }
    }

    struct LexKindResult {
        var kind: TokenKind
        var diagnostic: Diagnostic?
    }

    mutating func lexKind() -> LexKindResult? {

        func isKeyLikeStart(_ ch: UnicodeScalar) -> Bool {
            // This check allows invalid identifier but we'll diagnose
            // that after we've lexed the full string.
            return ch.properties.isXIDStart || ch == "_" || ch == "-"
        }
        func isKeyLikeContinue(_ ch: UnicodeScalar) -> Bool {
            // XID continue includes '_'
            return ch.properties.isXIDContinue || ch == "-"
        }
        func isASCIIDigit(_ ch: UnicodeScalar) -> Bool {
            return "0" <= ch && ch <= "9"
        }

        let startIndex = cursor.nextIndex
        while let nextChar = cursor.next() {
            switch nextChar {
            case "\n", "\t", " ":
                while cursor.eat("\n") || cursor.eat("\t") || cursor.eat(" ") {}
                return LexKindResult(kind: .whitespace)
            case "/":
                // Eat a line comment if it starts with "//"
                if cursor.eat("/") {
                    while let commentChar = cursor.next(), commentChar != "\n" {}
                    return LexKindResult(kind: .comment)
                }
                // Eat a block comment if it starts with "/*"
                if cursor.eat("*") {
                    let diag = advanceToEndOfBlockComment()
                    return LexKindResult(kind: .comment, diagnostic: diag)
                }
                return LexKindResult(kind: .slash)
            case "=": return LexKindResult(kind: .equals)
            case ",": return LexKindResult(kind: .comma)
            case ":": return LexKindResult(kind: .colon)
            case ".": return LexKindResult(kind: .period)
            case ";": return LexKindResult(kind: .semicolon)
            case "(": return LexKindResult(kind: .leftParen)
            case ")": return LexKindResult(kind: .rightParen)
            case "{": return LexKindResult(kind: .leftBrace)
            case "}": return LexKindResult(kind: .rightBrace)
            case "<": return LexKindResult(kind: .lessThan)
            case ">": return LexKindResult(kind: .greaterThan)
            case "*": return LexKindResult(kind: .star)
            case "@": return LexKindResult(kind: .at)
            case "-":
                if cursor.eat(">") {
                    return LexKindResult(kind: .rArrow)
                } else {
                    return LexKindResult(kind: .minus)
                }
            case "+": return LexKindResult(kind: .plus)
            case "%":
                var tmp = self.cursor
                if let ch = tmp.next(), isKeyLikeStart(ch) {
                    self.cursor = tmp
                    while let ch = tmp.next() {
                        if !isKeyLikeContinue(ch) {
                            break
                        }
                        self.cursor = tmp
                    }
                }
                return LexKindResult(kind: .explicitId)
            case let ch where isKeyLikeStart(ch):
                var tmp = self.cursor
                while let ch = tmp.next() {
                    if !isKeyLikeContinue(ch) {
                        break
                    }
                    self.cursor = tmp
                }

                let text = String(self.cursor.input[startIndex..<self.cursor.nextIndex])
                return LexKindResult(kind: WITKeyword(rawValue: text).map(TokenKind.keyword) ?? .id)
            case let ch where isASCIIDigit(ch):
                var tmp = self.cursor
                while let ch = tmp.next() {
                    if !isASCIIDigit(ch) {
                        break
                    }
                    self.cursor = tmp
                }
                return LexKindResult(kind: .integer)
            default:
                return nil
            }
        }
        return nil
    }

    mutating func rawLex() -> Lexeme? {
        let start = self.cursor.nextIndex
        guard let kind = self.lexKind() else {
            return nil
        }
        let end = self.cursor.nextIndex
        return Lexeme(kind: kind.kind, textRange: start..<end)
    }

    mutating func lex() -> Lexeme? {
        while let token = self.rawLex() {
            switch token.kind {
            case .comment, .whitespace: continue
            default: return token
            }
        }
        return nil
    }

    func peek() -> Lexeme? {
        var copy = self
        return copy.lex()
    }

    @discardableResult
    mutating func expect(_ expected: TokenKind) throws -> Lexer.Lexeme {
        guard let actual = self.lex() else {
            throw ParseError(description: "\(expected) expected but got nothing")
        }
        guard actual.kind == expected else {
            throw ParseError(description: "\(expected) expected but got \(actual.kind)")
        }
        return actual
    }

    @discardableResult
    mutating func expectIdentifier(_ expected: String) throws -> Lexer.Lexeme {
        let lexme = try self.expect(.id)
        let actualText = self.parseText(in: lexme.textRange)
        guard actualText == expected else {
            throw ParseError(description: "\(expected) expected but got \(actualText)")
        }
        return lexme
    }

    @discardableResult
    mutating func eat(_ expected: TokenKind) -> Bool {
        var other = self
        guard let token = other.lex(), token.kind == expected else {
            return false
        }
        self = other
        return true
    }

    var isEOF: Bool { self.peek() == nil }

    func parseText(in range: TextRange) -> String {
        String(self.cursor.input[range])
    }

    func parseExplicitIdentifier(in range: TextRange) -> String {
        let firstIndex = range.lowerBound
        let nextIndex = self.cursor.input.index(after: firstIndex)
        assert(self.cursor.input[firstIndex] == "%")
        return String(self.cursor.input[nextIndex..<range.upperBound])
    }
}

extension Lexer: IteratorProtocol, Sequence {
    mutating func next() -> Lexeme? {
        return self.lex()
    }
}

enum TokenKind: Equatable {
    case whitespace
    case comment

    case equals
    case comma
    case colon
    case period
    case semicolon
    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case lessThan
    case greaterThan
    case rArrow
    case star
    case at
    case slash
    case plus
    case minus

    case keyword(WITKeyword)

    case id
    case explicitId

    case integer
}

enum WITKeyword: String, CaseIterable {
    case use, type, `func`
    case u8, u16, u32, u64, s8, s16, s32, s64
    case f32, f64
    case char, resource, own, borrow, record, flags, variant, `enum`, union
    case bool, string, option, result, future, stream, list
    case underscore = "_"
    case `as`, from, `static`, async, interface, tuple, world, `import`, export, package, constructor, include, with
}

extension TokenKind: CustomStringConvertible {
    var description: String {
        switch self {
        case .keyword(let keyword): return keyword.rawValue
        case .whitespace: return "whitespace"
        case .comment: return "comment"
        case .equals: return "equals"
        case .comma: return "comma"
        case .colon: return "colon"
        case .period: return "period"
        case .semicolon: return "semicolon"
        case .leftParen: return "leftParen"
        case .rightParen: return "rightParen"
        case .leftBrace: return "leftBrace"
        case .rightBrace: return "rightBrace"
        case .lessThan: return "lessThan"
        case .greaterThan: return "greaterThan"
        case .rArrow: return "rArrow"
        case .star: return "star"
        case .at: return "at"
        case .slash: return "slash"
        case .plus: return "plus"
        case .minus: return "minus"
        case .id: return "id"
        case .explicitId: return "explicitId"
        case .integer: return "integer"
        }
    }
}
