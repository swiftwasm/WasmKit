public enum LexicalToken {
    case keyword(String)
    case reserved(String)
    case unsigned(UInt)
    case signed(Int)
    case floating
    case string
    case identifier
    case openingBrace
    case closingBrace
}

extension LexicalToken: Equatable {
    public static func == (lhs: LexicalToken, rhs: LexicalToken) -> Bool {
        switch (lhs, rhs) {
        case let (.keyword(l), .keyword(r)):
            return l == r
        case let (.reserved(l), .reserved(r)):
            return l == r
        case let (.unsigned(l), .unsigned(r)):
            return l == r
        case let (.signed(l), .signed(r)):
            return l == r
        case (.floating, .floating):
            return true
        case (.string, .string):
            return true
        case (.identifier, .identifier):
            return true
        case (.openingBrace, .openingBrace):
            return true
        case (.closingBrace, .closingBrace):
            return true
        default:
            return false
        }
    }
}

public class WASTLexer<InputStream: PeekableStream> where InputStream.Token == UnicodeScalar {
    enum Error: Swift.Error {
        case unexpectedEnd
        case unexpectedUnicodeScalar(UnicodeScalar, at: InputStream.Index)
    }

    var stream: InputStream

    init(stream: InputStream) {
        self.stream = stream
    }
}

extension WASTLexer.Error: Equatable {
    public static func == (lhs: WASTLexer<InputStream>.Error, rhs: WASTLexer<InputStream>.Error) -> Bool {
        switch (lhs, rhs) {
        case (.unexpectedEnd, .unexpectedEnd):
            return true
        case let (.unexpectedUnicodeScalar(l1, l2), .unexpectedUnicodeScalar(r1, r2)):
            return l1 == r1 && l2 == r2
        default: return false
        }
    }
}

extension WASTLexer: Stream {

    public var position: InputStream.Index {
        return stream.position
    }

    public func pop() throws -> LexicalToken? {
        while let c = try stream.peek() {
            switch c {
            case " ", "\t", "\n", "\r": // Whitespace and Format Effectors
                try stream.pop()
                // Skip

            case ";": // Line Comment?
                try stream.pop()

                switch try stream.peek() {
                case ";"?:
                    try stream.pop()
                case let c2?:
                    throw Error.unexpectedUnicodeScalar(c2, at: stream.position)
                case nil:
                    throw Error.unexpectedEnd
                }

                while let c2 = try stream.peek(), c2 != "\n" {
                    try stream.pop()
                }
                // Skip

            case "(": // Opening Brace or Block Comment
                try stream.pop()

                guard let c2 = try stream.peek(), c2 == ";" else {
                    return .openingBrace
                }
                try stream.pop()

                BlockComment: while let c3 = try stream.peek() {
                    try stream.pop()

                    if c3 == ";", let c4 = try stream.peek(), c4 == ")" {
                        try stream.pop()
                        break BlockComment
                    }
                }

            case let c where "a" ... "z" ~= c: // Keyword
                try stream.pop()

                var keywordChars = [c]
                while let idChar = try stream.peek(), idChar.isIDCharacter {
                    try stream.pop()
                    keywordChars.append(idChar)
                }

                return .keyword(String(String.UnicodeScalarView(keywordChars)))

            default: // Unexpected
                throw Error.unexpectedUnicodeScalar(c, at: stream.position)
            }
        }

        return nil
    }
}

private extension UnicodeScalar {
    var isIDCharacter: Bool {
        return ("0" ... "9" ~= self
            ||	"A" ... "Z" ~= self
            ||	"a" ... "z" ~= self
            || ["!", "#", "$", "%", "&", "`", "*", "+", "-", ".", "/",
                ":", "<", "=", ">", "?", "@", "\\", "^", "_", "`", ",", "~",
                ].contains(self)
        )
    }
}

private extension ExpressibleByIntegerLiteral {
    init?(_ unicodeScalar: UnicodeScalar, hex: Bool) {
        switch unicodeScalar {
        case "0": self = 0
        case "1": self = 1
        case "2": self = 2
        case "3": self = 3
        case "4": self = 4
        case "5": self = 5
        case "6": self = 6
        case "7": self = 7
        case "8": self = 8
        case "9": self = 9
        default:
            guard hex else { return nil }
            switch unicodeScalar {
            case "a", "A": self = 10
            case "b", "B": self = 11
            case "c", "C": self = 12
            case "d", "D": self = 13
            case "e", "E": self = 14
            case "f", "F": self = 15
            default: return nil
            }
        }
    }
}
