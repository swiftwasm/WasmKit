/// WAVE (WebAssembly Value Encoding) Lexer
/// Tokenizes WAVE format input for component model values.

/// Source span for error reporting (byte offsets)
public struct SourceSpan: Equatable, Sendable {
    public let start: Int
    public let end: Int

    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

/// WAVE token types
public enum WAVEToken: Equatable, Sendable {
    // Literals
    case number(String, SourceSpan)
    case char(Unicode.Scalar, SourceSpan)
    case string(String, SourceSpan)

    // Keywords
    case `true`(SourceSpan)
    case `false`(SourceSpan)
    case nan(SourceSpan)
    case inf(SourceSpan)
    case negInf(SourceSpan)  // -inf as single token
    case some(SourceSpan)
    case none(SourceSpan)
    case ok(SourceSpan)
    case err(SourceSpan)

    // Labels (kebab-case identifiers)
    case label(String, SourceSpan)
    case escapedLabel(String, SourceSpan)  // %label

    // Delimiters
    case leftParen(SourceSpan)
    case rightParen(SourceSpan)
    case leftBracket(SourceSpan)
    case rightBracket(SourceSpan)
    case leftBrace(SourceSpan)
    case rightBrace(SourceSpan)
    case colon(SourceSpan)
    case comma(SourceSpan)
    case semicolon(SourceSpan)
    case arrow(SourceSpan)  // ->

    case eof(SourceSpan)

    public var span: SourceSpan {
        switch self {
        case .number(_, let s), .char(_, let s), .string(_, let s): return s
        case .true(let s), .false(let s), .nan(let s), .inf(let s), .negInf(let s): return s
        case .some(let s), .none(let s), .ok(let s), .err(let s): return s
        case .label(_, let s), .escapedLabel(_, let s): return s
        case .leftParen(let s), .rightParen(let s): return s
        case .leftBracket(let s), .rightBracket(let s): return s
        case .leftBrace(let s), .rightBrace(let s): return s
        case .colon(let s), .comma(let s), .semicolon(let s), .arrow(let s): return s
        case .eof(let s): return s
        }
    }
}

/// Cursor for traversing unicode scalar input
struct TextCursor {
    let input: String.UnicodeScalarView
    let originalString: String
    var nextIndex: String.UnicodeScalarView.Index
    private let startIndex: String.UnicodeScalarView.Index

    var isEOF: Bool {
        nextIndex >= input.endIndex
    }

    /// Byte offset from start of input
    var byteOffset: Int {
        originalString.utf8.distance(from: originalString.utf8.startIndex, to: nextIndex)
    }

    init(input: String) {
        self.originalString = input
        self.input = input.unicodeScalars
        self.nextIndex = self.input.startIndex
        self.startIndex = self.input.startIndex
    }

    func peek(at offset: Int = 0) -> Unicode.Scalar? {
        guard let index = input.index(nextIndex, offsetBy: offset, limitedBy: input.endIndex),
              index < input.endIndex else {
            return nil
        }
        return input[index]
    }

    mutating func next() -> Unicode.Scalar? {
        guard nextIndex < input.endIndex else { return nil }
        defer { nextIndex = input.index(after: nextIndex) }
        return input[nextIndex]
    }

    mutating func eat(_ expected: Unicode.Scalar) -> Bool {
        if peek() == expected {
            _ = next()
            return true
        }
        return false
    }

    mutating func eat(_ expected: String) -> Bool {
        var index = nextIndex
        for char in expected.unicodeScalars {
            guard index < input.endIndex, input[index] == char else {
                return false
            }
            index = input.index(after: index)
        }
        nextIndex = index
        return true
    }
}

/// WAVE Lexer
public struct WAVELexer: ~Copyable {
    private var cursor: TextCursor
    private var peeked: WAVEToken?

    public init(_ input: String) {
        self.cursor = TextCursor(input: input)
    }

    /// Extract leading comments from the input, returning them as a string.
    /// This consumes any leading whitespace and comments up to the first non-comment token.
    public mutating func extractLeadingComments() -> String {
        var comments = ""
        while true {
            // Skip whitespace
            while let ch = cursor.peek(), ch.isWhitespace {
                _ = cursor.next()
            }
            // Check for line comment
            if cursor.peek() == "/" && cursor.peek(at: 1) == "/" {
                let commentStart = cursor.nextIndex
                _ = cursor.next()  // first /
                _ = cursor.next()  // second /
                while let ch = cursor.peek(), ch != "\n" {
                    _ = cursor.next()
                }
                // Include the newline in the comment
                if cursor.peek() == "\n" {
                    _ = cursor.next()
                }
                let commentEnd = cursor.nextIndex
                comments += String(cursor.input[commentStart..<commentEnd])
            } else {
                break
            }
        }
        return comments
    }

    /// Current byte offset in the input
    public var currentByteOffset: Int {
        cursor.byteOffset
    }

    /// Scan for matching close paren without tokenizing content.
    /// This avoids triggering lexer errors for invalid escapes inside strings/chars.
    /// Call this after consuming the opening paren.
    /// Returns the byte offset of the closing paren.
    public mutating func scanToCloseParen() throws(WAVEParserError) -> Int {
        var depth = 1

        while depth > 0 {
            guard let ch = cursor.peek() else {
                throw WAVEParserError(
                    "unexpected end of input",
                    span: SourceSpan(start: cursor.byteOffset, end: cursor.byteOffset)
                )
            }

            switch ch {
            case "(", "[", "{":
                depth += 1
                _ = cursor.next()
            case ")":
                depth -= 1
                if depth == 0 {
                    return cursor.byteOffset
                }
                _ = cursor.next()
            case "]", "}":
                depth -= 1
                _ = cursor.next()
            case "\"":
                skipStringLiteral()
            case "'":
                skipCharLiteral()
            case "/":
                if cursor.peek(at: 1) == "/" {
                    // Line comment - skip to end of line
                    while let c = cursor.peek(), c != "\n" {
                        _ = cursor.next()
                    }
                    if cursor.peek() == "\n" {
                        _ = cursor.next()
                    }
                } else {
                    _ = cursor.next()
                }
            default:
                _ = cursor.next()
            }
        }

        return cursor.byteOffset
    }

    /// Skip over a string literal without validating escapes
    private mutating func skipStringLiteral() {
        _ = cursor.next()  // opening "

        // Check for multiline string """
        if cursor.peek() == "\"" && cursor.peek(at: 1) == "\"" {
            _ = cursor.next()  // second "
            _ = cursor.next()  // third "

            // Multiline - skip until we find closing """
            while !cursor.isEOF {
                if cursor.peek() == "\"" && cursor.peek(at: 1) == "\"" && cursor.peek(at: 2) == "\"" {
                    _ = cursor.next()
                    _ = cursor.next()
                    _ = cursor.next()
                    return
                }
                _ = cursor.next()
            }
        } else {
            // Regular string - skip until closing "
            while let ch = cursor.peek() {
                if ch == "\"" {
                    _ = cursor.next()
                    return
                } else if ch == "\\" {
                    _ = cursor.next()  // backslash
                    _ = cursor.next()  // escaped char (don't validate)
                } else if ch == "\n" {
                    // Invalid but don't throw - let argument parsing handle it
                    return
                } else {
                    _ = cursor.next()
                }
            }
        }
    }

    /// Skip over a char literal without validating content
    private mutating func skipCharLiteral() {
        _ = cursor.next()  // opening '

        while let ch = cursor.peek() {
            if ch == "'" {
                _ = cursor.next()
                return
            } else if ch == "\\" {
                _ = cursor.next()  // backslash
                _ = cursor.next()  // escaped char
            } else if ch == "\n" {
                // Invalid but don't throw
                return
            } else {
                _ = cursor.next()
            }
        }
    }

    /// Peek at the next token without consuming it
    public mutating func peek() throws(WAVEParserError) -> WAVEToken {
        if let token = peeked {
            return token
        }
        let token = try nextToken()
        peeked = token
        return token
    }

    /// Consume and return the next token
    public mutating func next() throws(WAVEParserError) -> WAVEToken {
        if let token = peeked {
            peeked = nil
            return token
        }
        return try nextToken()
    }

    private mutating func nextToken() throws(WAVEParserError) -> WAVEToken {
        skipWhitespaceAndComments()

        let start = cursor.byteOffset
        guard let ch = cursor.peek() else {
            return .eof(SourceSpan(start: start, end: start))
        }

        switch ch {
        case "(":
            _ = cursor.next()
            return .leftParen(SourceSpan(start: start, end: cursor.byteOffset))
        case ")":
            _ = cursor.next()
            return .rightParen(SourceSpan(start: start, end: cursor.byteOffset))
        case "[":
            _ = cursor.next()
            return .leftBracket(SourceSpan(start: start, end: cursor.byteOffset))
        case "]":
            _ = cursor.next()
            return .rightBracket(SourceSpan(start: start, end: cursor.byteOffset))
        case "{":
            _ = cursor.next()
            return .leftBrace(SourceSpan(start: start, end: cursor.byteOffset))
        case "}":
            _ = cursor.next()
            return .rightBrace(SourceSpan(start: start, end: cursor.byteOffset))
        case ":":
            _ = cursor.next()
            return .colon(SourceSpan(start: start, end: cursor.byteOffset))
        case ",":
            _ = cursor.next()
            return .comma(SourceSpan(start: start, end: cursor.byteOffset))
        case ";":
            _ = cursor.next()
            return .semicolon(SourceSpan(start: start, end: cursor.byteOffset))
        case "-":
            return try readNegativeOrArrow(start: start)
        case "'":
            return try readChar(start: start)
        case "\"":
            return try readString(start: start)
        case "%":
            return try readEscapedLabel(start: start)
        case _ where ch.isASCIIDigit:
            return try readNumber(start: start)
        case _ where ch.isASCIILetter:
            return try readLabelOrKeyword(start: start)
        default:
            _ = cursor.next()
            throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
        }
    }

    private mutating func skipWhitespaceAndComments() {
        while true {
            // Skip whitespace
            while let ch = cursor.peek(), ch.isWhitespace {
                _ = cursor.next()
            }
            // Skip line comments
            if cursor.eat("//") {
                while let ch = cursor.peek(), ch != "\n" {
                    _ = cursor.next()
                }
                continue
            }
            break
        }
    }

    // MARK: - Number Parsing

    private mutating func readNegativeOrArrow(start: Int) throws(WAVEParserError) -> WAVEToken {
        _ = cursor.next()  // consume '-'

        // Check for -> (arrow)
        if cursor.eat(">") {
            return .arrow(SourceSpan(start: start, end: cursor.byteOffset))
        }

        // Check for -inf
        if cursor.eat("inf") {
            // Make sure it's not part of a longer identifier
            if let next = cursor.peek(), next.isASCIILetter || next.isASCIIDigit || next == "-" {
                throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
            }
            return .negInf(SourceSpan(start: start, end: cursor.byteOffset))
        }

        // Must be negative number
        guard let ch = cursor.peek(), ch.isASCIIDigit else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
        }

        return try readNumberAfterSign(start: start, negative: true)
    }

    private mutating func readNumber(start: Int) throws(WAVEParserError) -> WAVEToken {
        return try readNumberAfterSign(start: start, negative: false)
    }

    private mutating func readNumberAfterSign(start: Int, negative: Bool) throws(WAVEParserError) -> WAVEToken {
        var numberStr = negative ? "-" : ""

        // Integer part
        if cursor.eat("0") {
            numberStr.append("0")
        } else {
            // Must start with 1-9
            guard let first = cursor.peek(), first >= "1" && first <= "9" else {
                throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
            }
            numberStr.append(Character(cursor.next()!))
            while let ch = cursor.peek(), ch.isASCIIDigit {
                numberStr.append(Character(cursor.next()!))
            }
        }

        // Fractional part
        if cursor.peek() == "." {
            numberStr.append(Character(cursor.next()!))
            guard let ch = cursor.peek(), ch.isASCIIDigit else {
                throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
            }
            while let ch = cursor.peek(), ch.isASCIIDigit {
                numberStr.append(Character(cursor.next()!))
            }
        }

        // Exponent part
        if let ch = cursor.peek(), ch == "e" || ch == "E" {
            numberStr.append(Character(cursor.next()!))
            if let sign = cursor.peek(), sign == "+" || sign == "-" {
                numberStr.append(Character(cursor.next()!))
            }
            guard let ch = cursor.peek(), ch.isASCIIDigit else {
                throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
            }
            while let ch = cursor.peek(), ch.isASCIIDigit {
                numberStr.append(Character(cursor.next()!))
            }
        }

        return .number(numberStr, SourceSpan(start: start, end: cursor.byteOffset))
    }

    // MARK: - Char Parsing

    private mutating func readChar(start: Int) throws(WAVEParserError) -> WAVEToken {
        _ = cursor.next()  // consume opening '

        let scalar: Unicode.Scalar
        if cursor.peek() == "\\" {
            let escapeStart = cursor.byteOffset
            _ = cursor.next()  // consume backslash
            scalar = try readEscape(escapeStart: escapeStart, tokenStart: start)
        } else if let ch = cursor.next() {
            if ch == "\n" {
                throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
            }
            scalar = ch
        } else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
        }

        guard cursor.eat("'") else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
        }

        return .char(scalar, SourceSpan(start: start, end: cursor.byteOffset))
    }

    // MARK: - String Parsing

    private mutating func readString(start: Int) throws(WAVEParserError) -> WAVEToken {
        _ = cursor.next()  // consume first "

        // Check for multiline string """
        if cursor.peek() == "\"" && cursor.peek(at: 1) == "\"" {
            _ = cursor.next()  // second "
            _ = cursor.next()  // third "
            return try readMultilineString(start: start)
        }

        // Regular single-line string
        var result = ""
        while let ch = cursor.peek() {
            if ch == "\"" {
                _ = cursor.next()
                return .string(result, SourceSpan(start: start, end: cursor.byteOffset))
            } else if ch == "\n" {
                throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
            } else if ch == "\\" {
                let escapeStart = cursor.byteOffset  // capture position of \
                _ = cursor.next()
                result.append(Character(try readEscape(escapeStart: escapeStart, tokenStart: start)))
            } else {
                result.append(Character(cursor.next()!))
            }
        }

        throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
    }

    private mutating func readMultilineString(start: Int) throws(WAVEParserError) -> WAVEToken {
        // Must be followed immediately by newline
        if cursor.eat("\r\n") || cursor.eat("\n") {
            // OK
        } else {
            let msgStart = cursor.byteOffset
            throw WAVEParserError(
                "invalid multiline string: opening \"\"\" must be followed immediately by newline",
                span: SourceSpan(start: msgStart, end: msgStart + 1)
            )
        }

        var lines: [String] = []
        var currentLine = ""

        while !cursor.isEOF {
            // Check for closing delimiter (spaces + """)
            if let closingIndent = checkMultilineClosing() {
                // Dedent all lines
                let result = dedentMultilineString(lines: lines, indent: closingIndent, start: start)
                return .string(result, SourceSpan(start: start, end: cursor.byteOffset))
            }

            guard let ch = cursor.peek() else { break }

            if ch == "\\" {
                let escapeStart = cursor.byteOffset
                _ = cursor.next()
                currentLine.append(Character(try readEscape(escapeStart: escapeStart, tokenStart: start)))
            } else if ch == "\r" && cursor.peek(at: 1) == "\n" {
                // CRLF line ending
                _ = cursor.next()  // \r
                _ = cursor.next()  // \n
                lines.append(currentLine)
                currentLine = ""
            } else if ch == "\n" {
                _ = cursor.next()
                lines.append(currentLine)
                currentLine = ""
            } else {
                currentLine.append(Character(cursor.next()!))
            }
        }

        throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
    }

    /// Check if we're at a closing delimiter (optional spaces + """)
    /// Returns the number of spaces before """ if found, nil otherwise
    private mutating func checkMultilineClosing() -> Int? {
        let savedIndex = cursor.nextIndex
        var spaces = 0

        // Count leading spaces on this line
        while cursor.peek() == " " {
            _ = cursor.next()
            spaces += 1
        }

        // Check for """
        if cursor.eat("\"\"\"") {
            return spaces
        }

        // Not a closing delimiter, restore position
        cursor.nextIndex = savedIndex
        return nil
    }

    private func dedentMultilineString(lines: [String], indent: Int, start: Int) -> String {
        var result: [String] = []

        for line in lines {
            if line.isEmpty {
                result.append("")
            } else {
                // Remove up to `indent` spaces from the beginning
                var lineScalars = line.unicodeScalars
                var removed = 0
                while removed < indent, let first = lineScalars.first, first == " " {
                    lineScalars.removeFirst()
                    removed += 1
                }
                result.append(String(lineScalars))
            }
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Escape Parsing

    private mutating func readEscape(escapeStart: Int, tokenStart: Int) throws(WAVEParserError) -> Unicode.Scalar {
        guard let ch = cursor.next() else {
            throw WAVEParserError("invalid character escape", span: SourceSpan(start: escapeStart, end: escapeStart + 1))
        }

        switch ch {
        case "\"": return "\""
        case "'": return "'"
        case "\\": return "\\"
        case "t": return "\t"
        case "n": return "\n"
        case "r": return "\r"
        case "u":
            return try readUnicodeEscape(escapeStart: escapeStart, tokenStart: tokenStart)
        default:
            throw WAVEParserError("invalid character escape", span: SourceSpan(start: escapeStart, end: escapeStart + 1))
        }
    }

    private mutating func readUnicodeEscape(escapeStart: Int, tokenStart: Int) throws(WAVEParserError) -> Unicode.Scalar {
        guard cursor.eat("{") else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: tokenStart, end: cursor.byteOffset))
        }

        var hex = ""
        while let ch = cursor.peek(), ch != "}" {
            guard ch.isASCIIHexDigit else {
                // Syntax error - non-hex digit in unicode escape
                throw WAVEParserError("invalid token", span: SourceSpan(start: tokenStart, end: cursor.byteOffset))
            }
            hex.append(Character(cursor.next()!))
        }

        guard cursor.eat("}") else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: tokenStart, end: cursor.byteOffset))
        }

        guard let value = UInt32(hex, radix: 16) else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: tokenStart, end: cursor.byteOffset))
        }

        // Reject surrogates (U+D800..U+DFFF) - semantic error, not syntax
        if (0xD800...0xDFFF).contains(value) {
            throw WAVEParserError("invalid character escape", span: SourceSpan(start: escapeStart, end: escapeStart + 1))
        }

        guard let scalar = Unicode.Scalar(value) else {
            // Invalid Unicode scalar value - semantic error
            throw WAVEParserError("invalid character escape", span: SourceSpan(start: escapeStart, end: escapeStart + 1))
        }

        return scalar
    }

    // MARK: - Label/Keyword Parsing

    private mutating func readLabelOrKeyword(start: Int) throws(WAVEParserError) -> WAVEToken {
        let label = readLabel()

        // Check for keywords
        switch label {
        case "true": return .true(SourceSpan(start: start, end: cursor.byteOffset))
        case "false": return .false(SourceSpan(start: start, end: cursor.byteOffset))
        case "nan": return .nan(SourceSpan(start: start, end: cursor.byteOffset))
        case "inf": return .inf(SourceSpan(start: start, end: cursor.byteOffset))
        case "some": return .some(SourceSpan(start: start, end: cursor.byteOffset))
        case "none": return .none(SourceSpan(start: start, end: cursor.byteOffset))
        case "ok": return .ok(SourceSpan(start: start, end: cursor.byteOffset))
        case "err": return .err(SourceSpan(start: start, end: cursor.byteOffset))
        default: return .label(label, SourceSpan(start: start, end: cursor.byteOffset))
        }
    }

    private mutating func readEscapedLabel(start: Int) throws(WAVEParserError) -> WAVEToken {
        _ = cursor.next()  // consume %

        guard let ch = cursor.peek(), ch.isASCIILetter else {
            throw WAVEParserError("invalid token", span: SourceSpan(start: start, end: cursor.byteOffset))
        }

        let label = readLabel()
        return .escapedLabel(label, SourceSpan(start: start, end: cursor.byteOffset))
    }

    /// Read a kebab-case label (word(-word)*)
    private mutating func readLabel() -> String {
        var result = ""

        // Read first word
        result += readWord()

        // Read additional -word segments
        while cursor.peek() == "-" {
            if let next = cursor.peek(at: 1), next.isASCIILetter {
                result.append(Character(cursor.next()!))  // -
                result += readWord()
            } else {
                break
            }
        }

        return result
    }

    /// Read a single word (letter followed by alphanumeric, single case)
    private mutating func readWord() -> String {
        var result = ""

        guard let first = cursor.peek(), first.isASCIILetter else {
            return result
        }
        result.append(Character(cursor.next()!))

        // Continue with alphanumeric of same case
        while let ch = cursor.peek(), ch.isASCIIAlphanumeric {
            result.append(Character(cursor.next()!))
        }

        return result
    }
}

// MARK: - Unicode.Scalar Extensions

extension Unicode.Scalar {
    var isWhitespace: Bool {
        self == " " || self == "\t" || self == "\n" || self == "\r"
    }

    var isASCIIDigit: Bool {
        self >= "0" && self <= "9"
    }

    var isASCIILetter: Bool {
        (self >= "a" && self <= "z") || (self >= "A" && self <= "Z")
    }

    var isASCIIAlphanumeric: Bool {
        isASCIIDigit || isASCIILetter
    }

    var isASCIIHexDigit: Bool {
        isASCIIDigit || (self >= "a" && self <= "f") || (self >= "A" && self <= "F")
    }
}
