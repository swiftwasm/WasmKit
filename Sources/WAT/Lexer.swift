import WasmParser

enum TokenKind: Equatable {
    case leftParen
    case rightParen
    case lineComment
    case blockComment
    case id
    case keyword
    case string([UInt8])
    case integer(FloatingPointSign?, IntegerToken)
    case float(FloatingPointSign?, FloatToken)
    case unknown

    var isMeaningful: Bool {
        switch self {
        case .lineComment, .blockComment:
            return false
        default:
            return true
        }
    }
}

enum FloatToken: Equatable {
    case inf
    case nan(hexPattern: String?)
    case hexPattern(String)
    case decimalPattern(String)
}

enum IntegerToken: Equatable {
    case hexPattern(String)
    case decimalPattern(String)
}

struct Token {
    let range: Range<Lexer.Index>
    let kind: TokenKind

    func text(from lexer: Lexer) -> String {
        String(lexer.cursor.input[range])
    }

    func location(in lexer: Lexer) -> Location {
        Location(at: range.lowerBound, in: lexer.cursor.input)
    }
}

struct Lexer {
    typealias Index = String.UnicodeScalarView.Index
    fileprivate struct Cursor {
        let input: String.UnicodeScalarView
        var nextIndex: Index

        var isEOF: Bool {
            return nextIndex == input.endIndex
        }

        init(input: String) {
            self.init(input: input.unicodeScalars)
        }

        init(input: String.UnicodeScalarView) {
            self.input = input
            self.nextIndex = self.input.startIndex
        }

        /// Seek to the given offset
        /// - Parameter offset: The offset to seek
        mutating func seek(at offset: Index) {
            self.nextIndex = offset
        }

        func peek(at offset: Int = 0) throws -> Unicode.Scalar? {
            precondition(offset >= 0)
            guard self.input.index(self.nextIndex, offsetBy: offset) < self.input.endIndex else {
                return nil
            }
            let index = self.input.index(self.nextIndex, offsetBy: offset)
            return self.input[index]
        }

        mutating func next() throws -> Unicode.Scalar? {
            guard self.nextIndex < self.input.endIndex else { return nil }
            defer { self.nextIndex = self.input.index(after: self.nextIndex) }
            return self.input[self.nextIndex]
        }

        mutating func eat(_ expected: Unicode.Scalar) throws -> Bool {
            if try peek() == expected {
                _ = try next()
                return true
            }
            return false
        }

        mutating func eat(_ expected: String) throws -> Bool {
            var index = self.nextIndex
            for char in expected.unicodeScalars {
                guard index < self.input.endIndex, self.input[index] == char else {
                    return false
                }
                index = self.input.index(after: index)
            }
            self.nextIndex = index
            return true
        }

        mutating func eatOneOf(_ expectedSet: [Unicode.Scalar]) throws -> Unicode.Scalar? {
            guard let ch = try peek() else { return nil }
            for expected in expectedSet {
                if ch == expected {
                    _ = try next()
                    return ch
                }
            }
            return nil
        }

        /// Check if the next characters match the expected string without consuming them
        /// - Parameters:
        ///   - expected: The expected string
        ///   - eof: Whether if EOF is expected after the string
        /// - Returns: `true` if the next characters match the expected string
        func match(_ expected: String, eof: Bool = false) throws -> Bool {
            var index = self.nextIndex
            for char in expected.unicodeScalars {
                guard index < self.input.endIndex, self.input[index] == char else {
                    return false
                }
                index = self.input.index(after: index)
            }
            if eof {
                return index == self.input.endIndex
            }
            return true
        }

        /// Returns the current location in line-column style. Line is 1-indexed and column is 0-indexed.
        func currentSourceLocation() -> Location {
            return Location(at: nextIndex, in: self.input)
        }

        func createError(_ description: String) -> WatParserError {
            return WatParserError(description, location: currentSourceLocation())
        }

        func unexpectedEof() -> WatParserError {
            createError("Unexpected end-of-file")
        }
    }

    fileprivate var cursor: Cursor

    init(input: String) {
        self.cursor = Cursor(input: input)
    }

    /// Seek to the given offset
    /// - Parameter offset: The offset to seek
    mutating func seek(at offset: Index) {
        cursor.seek(at: offset)
    }

    /// Lex the next meaningful token
    /// - Returns: The next meaningful token or `nil` if EOF
    mutating func lex() throws -> Token? {
        while true {
            guard let token = try rawLex() else { return nil }
            guard token.kind.isMeaningful else { continue }
            return token
        }
    }

    /// Lex the next token without skipping comments
    mutating func rawLex() throws -> Token? {
        guard let (start, initialChar) = try peekNonWhitespaceChar() else {
            return nil
        }
        guard let kind = try classifyToken(initialChar) else { return nil }
        let end = cursor.nextIndex
        return Token(range: start..<end, kind: kind)
    }

    func location() -> Location {
        return cursor.currentSourceLocation()
    }

    private mutating func classifyToken(_ initialChar: Unicode.Scalar) throws -> TokenKind? {
        switch initialChar {
        case "(":
            _ = try cursor.next()
            switch try cursor.peek() {
            case ";":
                _ = try cursor.next()
                return try lexBlockComment()
            default: return .leftParen
            }
        case ")":
            _ = try cursor.next()
            return .rightParen
        case ";":
            _ = try cursor.next()
            // Lex ";; ..." line comment
            guard try cursor.eat(";") else {
                throw cursor.createError("Expected ';' after ';' line comment")
            }
            while let char = try cursor.next() {
                switch char {
                case "\r":
                    if try cursor.peek() == "\n" {
                        _ = try cursor.next()
                    }
                    return .lineComment
                case "\n":
                    return .lineComment
                default: break
                }
            }
            // source file ends with line comment
            return .lineComment
        case "\"",
            _ where isIdChar(initialChar):
            let (kind, text) = try lexReservedChars(initial: initialChar)
            switch kind {
            case .idChars:
                if initialChar == "$" {
                    return .id
                }
                do {
                    // Try to parse as integer or float
                    var numberSource = Cursor(input: String.UnicodeScalarView(text))
                    var sign: FloatingPointSign? = nil
                    if let maybeSign = try numberSource.peek(),
                        let (found, _) = [(FloatingPointSign.plus, "+"), (FloatingPointSign.minus, "-")].first(where: { $1 == maybeSign })
                    {
                        sign = found
                        _ = try numberSource.next()
                    }
                    if try numberSource.match("inf", eof: true) {
                        return .float(sign, .inf)
                    }
                    if try numberSource.match("nan", eof: true) {
                        return .float(sign, .nan(hexPattern: nil))
                    }
                    if try numberSource.eat("nan:0x") {
                        return .float(sign, .nan(hexPattern: try numberSource.parseHexNumber()))
                    }
                    var pattern: String
                    let parseFraction: () throws -> String
                    let makeFloatToken: (String) -> FloatToken
                    if try numberSource.eat("0x") {
                        pattern = try numberSource.parseHexNumber()
                        if numberSource.isEOF {
                            return .integer(sign, .hexPattern(pattern))
                        }
                        parseFraction = { try numberSource.parseHexNumber() }
                        makeFloatToken = { FloatToken.hexPattern($0) }
                    } else {
                        pattern = try numberSource.parseDecimalNumber()
                        parseFraction = { try numberSource.parseDecimalNumber() }
                        makeFloatToken = { FloatToken.decimalPattern($0) }
                    }
                    if !pattern.isEmpty {
                        // The token has at least single digit
                        if numberSource.isEOF {
                            // No more characters
                            return .integer(sign, .decimalPattern(pattern))
                        }
                        // Still might be a float
                        if try numberSource.eat(".") {
                            let fraction = try parseFraction()
                            pattern += "." + fraction
                        }
                        if let expCh = try numberSource.eatOneOf(["e", "E", "p", "P"]) {
                            pattern += String(expCh)
                            if try numberSource.eat("+") {
                                pattern += "+"
                            } else if try numberSource.eat("-") {
                                pattern += "-"
                            }
                            let exponent = try numberSource.parseDecimalNumber()
                            guard !exponent.isEmpty else { return .unknown }
                            pattern += exponent
                        }
                        guard numberSource.isEOF else { return .unknown }
                        return .float(sign, makeFloatToken(pattern))
                    }
                }
                if ("a"..."z").contains(initialChar) {
                    return .keyword
                }
                return .unknown
            case .string(let string):
                return .string(string)
            case .unknown:
                return .unknown
            }
        default:
            _ = try cursor.next()
            return .unknown
        }
    }

    private mutating func lexBlockComment() throws -> TokenKind {
        var level = 1
        while true {
            switch try cursor.next() {
            case "(":
                if try cursor.peek() == ";" {
                    // Nested comment block
                    level += 1
                }
            case ";":
                if try cursor.peek() == ")" {
                    level -= 1
                    _ = try cursor.next()
                    if level == 0 {
                        return .blockComment
                    }
                }
            default: break
            }
        }
    }

    private mutating func peekNonWhitespaceChar() throws -> (index: Lexer.Index, byte: Unicode.Scalar)? {
        guard var char = try cursor.peek() else { return nil }
        var start: Lexer.Index = cursor.nextIndex
        // https://webassembly.github.io/spec/core/text/lexical.html#white-space
        let whitespaces: [Unicode.Scalar] = [" ", "\n", "\t", "\r"]
        while whitespaces.contains(char) {
            _ = try cursor.next()
            start = cursor.nextIndex
            guard let newChar = try cursor.peek() else { return nil }
            char = newChar
        }
        return (start, char)
    }

    // https://webassembly.github.io/spec/core/text/values.html#text-idchar
    private func isIdChar(_ char: Unicode.Scalar) -> Bool {
        // NOTE: Intentionally not using Range here to keep fast enough even in debug mode
        return ("0" <= char && char <= "9")
            || ("A" <= char && char <= "Z")
            || ("a" <= char && char <= "z")
            || "!" == char || "#" == char || "$" == char || "%" == char
            || "&" == char || "'" == char || "*" == char || "+" == char
            || "-" == char || "." == char || "/" == char || ":" == char
            || "<" == char || "=" == char || ">" == char || "?" == char
            || "@" == char || "\\" == char || "^" == char || "_" == char
            || "`" == char || "|" == char || "~" == char
    }

    private enum ReservedKind {
        case string([UInt8])
        case idChars
        case unknown
    }

    private mutating func lexReservedChars(initial: Unicode.Scalar) throws -> (ReservedKind, String.UnicodeScalarView.SubSequence) {
        let start = cursor.nextIndex
        var numberOfIdChars: Int = 0
        var strings: [[UInt8]] = []
        var char = initial

        while true {
            if isIdChar(char) {
                _ = try cursor.next()
                numberOfIdChars += 1
            } else if char == "\"" {
                _ = try cursor.next()
                strings.append(try readString())
            } else {
                break
            }
            guard let new = try cursor.peek() else { break }
            char = new
        }
        let text = cursor.input[start..<cursor.nextIndex]
        if numberOfIdChars > 0, strings.count == 0 {
            return (.idChars, text)
        } else if numberOfIdChars == 0, strings.count == 1 {
            return (.string(strings[0]), text)
        } else if numberOfIdChars == 1, strings.count == 1, initial == "$" {
            return (.idChars, text)
        }
        return (.unknown, text)
    }

    private mutating func readString() throws -> [UInt8] {
        var copyingBuffer: [UInt8] = []
        func append(_ char: Unicode.Scalar) {
            copyingBuffer.append(contentsOf: String(char).utf8)
        }

        while let char = try cursor.next() {
            if char == "\"" {
                break
            }
            if char == "\\" {
                guard let nextChar = try cursor.next() else {
                    throw cursor.unexpectedEof()
                }
                switch nextChar {
                case "\"", "'", "\\":
                    append(nextChar)
                case "t": append("\t")
                case "n": append("\n")
                case "r": append("\r")
                case "u":
                    // Unicode escape sequence \u{XXXX}
                    guard try cursor.eat("{") else {
                        throw cursor.createError("Expected '{' after \\u unicode escape sequence")
                    }
                    let codePointString = try cursor.parseHexNumber()
                    guard let codePoint = UInt32(codePointString, radix: 16) else {
                        throw cursor.createError("Cannot parse code point in \\u unicode escape sequence as 32-bit unsigned hex integer")
                    }
                    guard try cursor.eat("}") else {
                        throw cursor.createError("No closing '}' after \\u unicode escape sequence")
                    }
                    // Allocate copying buffer if not already allocated
                    guard let scalar = Unicode.Scalar(codePoint) else {
                        throw cursor.createError("Invalid code point in \\u unicode escape sequence")
                    }
                    append(scalar)
                case let nChar where nChar.properties.isASCIIHexDigit:
                    guard let mChar = try cursor.next() else {
                        throw cursor.unexpectedEof()
                    }
                    guard mChar.properties.isASCIIHexDigit else {
                        throw cursor.createError("Invalid escape sequence: \(mChar)")
                    }
                    let n = try parseHexDigit(nChar)!
                    let m = try parseHexDigit(mChar)!
                    let digit = n * 16 + m
                    copyingBuffer.append(digit)
                case let other:
                    throw cursor.createError("Invalid escape sequence: \(other)")
                }
            } else {
                append(char)
            }
        }
        return copyingBuffer
    }
}

func parseHexDigit(_ char: Unicode.Scalar) throws -> UInt8? {
    let base: Unicode.Scalar
    let addend: UInt8
    if ("0"..."9").contains(char) {
        base = "0"
        addend = 0
    } else if ("a"..."f").contains(char) {
        base = "a"
        addend = 10
    } else if ("A"..."F").contains(char) {
        base = "A"
        addend = 10
    } else {
        return nil
    }
    return UInt8(char.value - base.value + UInt32(addend))
}

extension Lexer.Cursor {
    mutating func parseHexNumber() throws -> String {
        return try parseUnderscoredChars(continueParsing: \.properties.isASCIIHexDigit)
    }

    mutating func parseDecimalNumber() throws -> String {
        return try parseUnderscoredChars(continueParsing: { "0"..."9" ~= $0 })
    }

    /// Parse underscore-separated characters
    /// - Parameter continueParsing: A closure that returns `true` if the parsing should continue
    /// - Returns: The parsed string without underscores
    mutating func parseUnderscoredChars(continueParsing: (Unicode.Scalar) -> Bool) throws -> String {
        var value = String.UnicodeScalarView()
        var lastParsedChar: Unicode.Scalar?
        while let char = try peek() {
            if char == "_" {
                guard let lastChar = lastParsedChar else {
                    throw createError("Invalid hex number, leading underscore")
                }
                guard lastChar != "_" else {
                    throw createError("Invalid hex number, consecutive underscores")
                }
                lastParsedChar = char
                _ = try next()
                continue
            }
            guard continueParsing(char) else { break }
            lastParsedChar = char
            value.append(char)
            _ = try next()
        }
        if lastParsedChar == "_" {
            throw createError("Invalid hex number, trailing underscore")
        }
        return String(value)
    }
}
