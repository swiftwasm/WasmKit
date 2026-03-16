import WasmParser

enum TokenKind: Equatable {
    case leftParen
    case rightParen
    case lineComment
    case blockComment
    /// A recognized annotation like `(@name`. The associated value is the annotation id (e.g. "name").
    /// The lexer returns this token after consuming `(@id` but before consuming the body or closing `)`.
    case annotation(String)
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
    /// For quoted identifiers ($"..."), the decoded string bytes (not including the `$` prefix).
    let quotedIdBytes: [UInt8]?

    init(range: Range<Lexer.Index>, kind: TokenKind, quotedIdBytes: [UInt8]? = nil) {
        self.range = range
        self.kind = kind
        self.quotedIdBytes = quotedIdBytes
    }

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

        mutating func eat(_ expected: Unicode.Scalar) -> Bool {
            if peek() == expected {
                _ = next()
                return true
            }
            return false
        }

        mutating func eat(_ expected: String) -> Bool {
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

        mutating func eatOneOf(_ expectedSet: [Unicode.Scalar]) -> Unicode.Scalar? {
            guard let ch = peek() else { return nil }
            for expected in expectedSet {
                if ch == expected {
                    _ = next()
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
        func match(_ expected: String, eof: Bool = false) -> Bool {
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
    mutating func lex() throws(WatParserError) -> Token? {
        while true {
            guard let token = try rawLex() else { return nil }
            guard token.kind.isMeaningful else { continue }
            return token
        }
    }

    /// Temporarily stores decoded bytes from the most recently lexed quoted identifier ($"...").
    /// Set by classifyToken, consumed by rawLex.
    private var pendingQuotedIdBytes: [UInt8]? = nil

    /// Lex the next token without skipping comments
    mutating func rawLex() throws(WatParserError) -> Token? {
        guard let (start, initialChar) = peekNonWhitespaceChar() else {
            return nil
        }
        pendingQuotedIdBytes = nil
        guard let kind = try classifyToken(initialChar) else { return nil }
        let end = cursor.nextIndex
        let quotedIdBytes = pendingQuotedIdBytes
        pendingQuotedIdBytes = nil
        return Token(range: start..<end, kind: kind, quotedIdBytes: quotedIdBytes)
    }

    func location() -> Location {
        return cursor.currentSourceLocation()
    }

    private mutating func classifyToken(_ initialChar: Unicode.Scalar) throws(WatParserError) -> TokenKind? {
        switch initialChar {
        case "(":
            _ = cursor.next()
            switch cursor.peek() {
            case ";":
                _ = cursor.next()
                return try lexBlockComment()
            case "@":
                _ = cursor.next()
                return try lexAnnotation()
            default: return .leftParen
            }
        case ")":
            _ = cursor.next()
            return .rightParen
        case ";":
            _ = cursor.next()
            guard cursor.eat(";") else {
                throw cursor.createError("Expected ';' after ';' line comment")
            }
            skipLineComment()
            return .lineComment
        case "\"",
            _ where isIdChar(initialChar):
            let (kind, text) = try lexReservedChars(initial: initialChar)
            switch kind {
            case .quotedId(let bytes):
                // $"..." quoted identifier form
                guard !bytes.isEmpty else {
                    throw cursor.createError("empty identifier")
                }
                guard String(validating: bytes, as: UTF8.self) != nil else {
                    throw cursor.createError("malformed UTF-8 encoding")
                }
                pendingQuotedIdBytes = bytes
                return .id
            case .idChars:
                if initialChar == "$" {
                    // id ::= '$' idchar+ — must have at least one char after '$'
                    guard text.count > 1 else {
                        throw cursor.createError("empty identifier")
                    }
                    return .id
                }
                do {
                    // Try to parse as integer or float
                    var numberSource = Cursor(input: String.UnicodeScalarView(text))
                    var sign: FloatingPointSign? = nil
                    if let maybeSign = numberSource.peek(),
                        let (found, _) = [(FloatingPointSign.plus, "+"), (FloatingPointSign.minus, "-")].first(where: { $1 == maybeSign })
                    {
                        sign = found
                        _ = numberSource.next()
                    }
                    if numberSource.match("inf", eof: true) {
                        return .float(sign, .inf)
                    }
                    if numberSource.match("nan", eof: true) {
                        return .float(sign, .nan(hexPattern: nil))
                    }
                    if numberSource.eat("nan:0x") {
                        return .float(sign, .nan(hexPattern: try numberSource.parseHexNumber()))
                    }
                    var pattern: String
                    let parseFraction: () throws(WatParserError) -> String
                    let makeFloatToken: (String) -> FloatToken
                    if numberSource.eat("0x") {
                        pattern = try numberSource.parseHexNumber()
                        if numberSource.isEOF {
                            return .integer(sign, .hexPattern(pattern))
                        }
                        parseFraction = { () throws(WatParserError) in try numberSource.parseHexNumber() }
                        makeFloatToken = { FloatToken.hexPattern($0) }
                    } else {
                        pattern = try numberSource.parseDecimalNumber()
                        parseFraction = { () throws(WatParserError) in try numberSource.parseDecimalNumber() }
                        makeFloatToken = { FloatToken.decimalPattern($0) }
                    }
                    if !pattern.isEmpty {
                        // The token has at least single digit
                        if numberSource.isEOF {
                            // No more characters
                            return .integer(sign, .decimalPattern(pattern))
                        }
                        // Still might be a float
                        if numberSource.eat(".") {
                            let fraction = try parseFraction()
                            pattern += "." + fraction
                        }
                        if let expCh = numberSource.eatOneOf(["e", "E", "p", "P"]) {
                            pattern += String(expCh)
                            if numberSource.eat("+") {
                                pattern += "+"
                            } else if numberSource.eat("-") {
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
            _ = cursor.next()
            return .unknown
        }
    }

    /// Skip a line comment body. The leading `;;` has already been consumed.
    /// Consumes through the end of line (or EOF).
    private mutating func skipLineComment() {
        while let char = cursor.next() {
            switch char {
            case "\r":
                if cursor.peek() == "\n" {
                    _ = cursor.next()
                }
                return
            case "\n":
                return
            default: break
            }
        }
    }

    private mutating func lexBlockComment() throws(WatParserError) -> TokenKind {
        var level = 1
        while true {
            guard let char = cursor.next() else {
                throw cursor.unexpectedEof()
            }
            switch char {
            case "(":
                if cursor.peek() == ";" {
                    // Nested comment block
                    level += 1
                }
            case ";":
                if cursor.peek() == ")" {
                    level -= 1
                    _ = cursor.next()
                    if level == 0 {
                        return .blockComment
                    }
                }
            default: break
            }
        }
    }

    /// Recognized annotation IDs that the parser needs to handle.
    private static let recognizedAnnotations: Set<String> = ["name", "custom"]

    /// Read an annotation ID after `(@` has been consumed.
    /// Handles both idchar-form (`@id`) and string-form (`@"id"`).
    private mutating func readAnnotationId() throws(WatParserError) -> String {
        if let ch = cursor.peek(), ch == "\"" {
            // String-form: (@"id" ...)
            _ = cursor.next()
            let str = try readString()
            guard !str.isEmpty else {
                throw cursor.createError("empty annotation id")
            }
            guard let id = String(validating: str, as: UTF8.self) else {
                throw cursor.createError("malformed UTF-8 encoding")
            }
            return id
        } else if let ch = cursor.peek(), isIdChar(ch) {
            // idchar-form: (@id ...)
            let idStart = cursor.nextIndex
            _ = cursor.next()
            while let next = cursor.peek(), isIdChar(next) {
                _ = cursor.next()
            }
            return String(cursor.input[idStart..<cursor.nextIndex])
        } else {
            throw cursor.createError("empty annotation id")
        }
    }

    /// Lex an annotation `(@id ...)`. The leading `(@` has already been consumed.
    /// For recognized annotations (e.g. `@name`), returns `.annotation(id)` without
    /// consuming the body — the parser reads the body and closing `)`.
    /// For unknown annotations, consumes the entire body and returns `.blockComment`.
    private mutating func lexAnnotation() throws(WatParserError) -> TokenKind {
        let annotationId = try readAnnotationId()

        if Self.recognizedAnnotations.contains(annotationId) {
            return .annotation(annotationId)
        }

        try skipAnnotationBody()
        return .blockComment
    }

    /// Skip the body of an unrecognized annotation, tracking paren depth.
    /// Called after the annotation ID has been consumed.
    ///
    /// This method has its own token dispatch rather than delegating to
    /// `classifyToken` because annotation bodies differ from top-level WAT
    /// in three ways:
    /// - A lone `;` is legal body content (not the start of a line comment).
    /// - Non-ASCII and control characters must be rejected (`classifyToken`
    ///   returns `.unknown` instead).
    /// - `(@)` is a valid parenthesized group (not a malformed annotation),
    ///   so `(@` must peek ahead before consuming the annotation ID.
    private mutating func skipAnnotationBody() throws(WatParserError) {
        var depth = 1
        while true {
            guard let char = cursor.peek() else {
                throw cursor.createError("unclosed annotation")
            }
            switch char {
            case "(":
                _ = cursor.next()
                if cursor.peek() == ";" {
                    // Block comment: (; ... ;) — fully consumed, no depth change
                    _ = cursor.next()
                    _ = try lexBlockComment()
                } else {
                    // Regular paren group or nested annotation
                    if cursor.peek() == "@" {
                        // Consume the annotation ID so body-skipping doesn't misparse it.
                        let charAfterAt = cursor.peek(at: 1)
                        if let c = charAfterAt, isIdChar(c) || c == "\"" {
                            _ = cursor.next()  // consume @
                            _ = try readAnnotationId()
                        }
                    }
                    depth += 1
                }
            case ")":
                _ = cursor.next()
                depth -= 1
                if depth == 0 {
                    return
                }
            case "\"":
                // String inside annotation body
                _ = cursor.next()
                _ = try readString()
            case ";":
                _ = cursor.next()
                if cursor.eat(";") {
                    skipLineComment()
                }
            // A lone `;` is just a regular character in annotation body
            default:
                if isIllegalWATChar(char) {
                    throw cursor.createError("illegal character")
                }
                _ = cursor.next()
            }
        }
    }

    private mutating func peekNonWhitespaceChar() -> (index: Lexer.Index, byte: Unicode.Scalar)? {
        guard var char = cursor.peek() else { return nil }
        var start: Lexer.Index = cursor.nextIndex
        // https://webassembly.github.io/spec/core/text/lexical.html#white-space
        let whitespaces: [Unicode.Scalar] = [" ", "\n", "\t", "\r"]
        while whitespaces.contains(char) {
            _ = cursor.next()
            start = cursor.nextIndex
            guard let newChar = cursor.peek() else { return nil }
            char = newChar
        }
        return (start, char)
    }

    /// Returns true if the scalar is not a legal WAT character outside of strings.
    /// Legal: U+09 (tab), U+0A (LF), U+0D (CR), U+20..U+7E (printable ASCII).
    private func isIllegalWATChar(_ char: Unicode.Scalar) -> Bool {
        let value = char.value
        return value <= 0x08
            || (value >= 0x0B && value <= 0x0C)
            || (value >= 0x0E && value <= 0x1F)
            || value == 0x7F
            || value >= 0x80
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
        /// A quoted identifier: `$"..."` form with decoded string bytes
        case quotedId([UInt8])
        case unknown
    }

    private mutating func lexReservedChars(initial: Unicode.Scalar) throws(WatParserError) -> (ReservedKind, String.UnicodeScalarView.SubSequence) {
        let start = cursor.nextIndex
        var numberOfIdChars: Int = 0
        var strings: [[UInt8]] = []
        var char = initial

        while true {
            if isIdChar(char) {
                _ = cursor.next()
                numberOfIdChars += 1
            } else if char == "\"" {
                _ = cursor.next()
                strings.append(try readString())
            } else {
                break
            }
            guard let new = cursor.peek() else { break }
            char = new
        }
        let text = cursor.input[start..<cursor.nextIndex]
        if numberOfIdChars > 0, strings.count == 0 {
            return (.idChars, text)
        } else if numberOfIdChars == 0, strings.count == 1 {
            return (.string(strings[0]), text)
        } else if numberOfIdChars == 1, strings.count == 1, initial == "$" {
            return (.quotedId(strings[0]), text)
        }
        return (.unknown, text)
    }

    private mutating func readString() throws(WatParserError) -> [UInt8] {
        var copyingBuffer: [UInt8] = []
        func append(_ char: Unicode.Scalar) {
            copyingBuffer.append(contentsOf: String(char).utf8)
        }

        while let char = cursor.next() {
            if char == "\"" {
                break
            }
            if char == "\\" {
                guard let nextChar = cursor.next() else {
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
                    guard cursor.eat("{") else {
                        throw cursor.createError("Expected '{' after \\u unicode escape sequence")
                    }
                    let codePointString = try cursor.parseHexNumber()
                    guard let codePoint = UInt32(codePointString, radix: 16) else {
                        throw cursor.createError("Cannot parse code point in \\u unicode escape sequence as 32-bit unsigned hex integer")
                    }
                    guard cursor.eat("}") else {
                        throw cursor.createError("No closing '}' after \\u unicode escape sequence")
                    }
                    // Allocate copying buffer if not already allocated
                    guard let scalar = Unicode.Scalar(codePoint) else {
                        throw cursor.createError("Invalid code point in \\u unicode escape sequence")
                    }
                    append(scalar)
                case let nChar where nChar.properties.isASCIIHexDigit:
                    guard let mChar = cursor.next() else {
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
                // Validate: char must be a valid stringchar (not a control character)
                // WAT spec: char ::= U+20 | ... | U+7E | <non-control Unicode chars>
                let value = char.value
                if value < 0x20 || value == 0x7F {
                    throw cursor.createError("illegal character in string")
                }
                append(char)
            }
        }
        return copyingBuffer
    }
}

func parseHexDigit(_ char: Unicode.Scalar) throws(WatParserError) -> UInt8? {
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
    mutating func parseHexNumber() throws(WatParserError) -> String {
        return try parseUnderscoredChars(continueParsing: \.properties.isASCIIHexDigit)
    }

    mutating func parseDecimalNumber() throws(WatParserError) -> String {
        return try parseUnderscoredChars(continueParsing: { "0"..."9" ~= $0 })
    }

    /// Parse underscore-separated characters
    /// - Parameter continueParsing: A closure that returns `true` if the parsing should continue
    /// - Returns: The parsed string without underscores
    mutating func parseUnderscoredChars(continueParsing: (Unicode.Scalar) -> Bool) throws(WatParserError) -> String {
        var value = String.UnicodeScalarView()
        var lastParsedChar: Unicode.Scalar?
        while let char = peek() {
            if char == "_" {
                guard let lastChar = lastParsedChar else {
                    throw createError("Invalid hex number, leading underscore")
                }
                guard lastChar != "_" else {
                    throw createError("Invalid hex number, consecutive underscores")
                }
                lastParsedChar = char
                _ = next()
                continue
            }
            guard continueParsing(char) else { break }
            lastParsedChar = char
            value.append(char)
            _ = next()
        }
        if lastParsedChar == "_" {
            throw createError("Invalid hex number, trailing underscore")
        }
        return String(value)
    }
}
