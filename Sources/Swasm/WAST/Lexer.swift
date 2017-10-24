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
    case unknown(UnicodeScalar)
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
        case let (.unknown(l), .unknown(r)):
            return l == r
        default:
            return false
        }
    }
}

public class WASTLexer<InputStream: LA2Stream> where InputStream.Element == UnicodeScalar {
    var stream: InputStream

    init(stream: InputStream) {
        self.stream = stream
    }
}

extension WASTLexer: Stream {
    public var position: InputStream.Index {
        return stream.position
    }

    public func next() -> LexicalToken? {
        while let c0 = stream.next() {
            let (c1, c2) = stream.look()

            switch (c0, c1, c2) {
            case (" ", _, _), ("\t", _, _), ("\n", _, _), ("\r", _, _): // Whitespace and Format Effectors
                continue

            case (";", ";"?, _): // Line Comment
                var c = c2
                while c != nil, c != "\n" {
                    c = stream.next()
                }
                continue

            case ("(", ";"?, _): // Block Comment
                while case let (end1?, end2?) = stream.look(), (end1, end2) != (";", ")") {
                    _ = stream.next()
                }
                _ = stream.next(); _ = stream.next() // skip ";)"

            case (CharacterSet.keywordPrefixes, _, _): // Keyword
                var cs = [c0]
                while let c: UnicodeScalar = stream.next(), CharacterSet.IDCharacters.contains(c) {
                    cs.append(c)
                }

                return .keyword(String(String.UnicodeScalarView(cs)))

            case ("0", "x"?, CharacterSet.hexDigits?): // Hexadecimal Unsigned
                _ = stream.next(); _ = stream.next() // skip "x", c2
                let result: UInt = consumeNumber(startsFrom: c2!, hex: true)
                return .unsigned(result)

            case (CharacterSet.decimalDigits, _, _): // Decimal Unsigned
                let result: UInt = consumeNumber(startsFrom: c0, hex: false)
                return .unsigned(result)

            default: // Unexpected
                return .unknown(c0)
            }
        }

        return nil
    }
}

internal extension WASTLexer {
    func consumeNumber<T: Numeric>(startsFrom c: UnicodeScalar, hex: Bool) -> T {
        var result = T(c, hex: hex)!
        while let c: UnicodeScalar = stream.look() {
            if let d = T(c, hex: hex) {
                _ = stream.next()
                result = result * (hex ? 16 : 10) + d
            } else if c == "_" {
                _ = stream.next()
            } else {
                break
            }
        }
        return result
    }
}

internal extension CharacterSet {
    static var keywordPrefixes: CharacterSet {
        return CharacterSet().with("a" ... "z")
    }

    static var IDCharacters: CharacterSet {
        return CharacterSet()
            .with("0" ... "9", "a" ... "z", "A" ... "Z")
            .with("!", "#", "$", "%", "&", "`", "*", "+", "-", ".", "/",
                  ":", "<", "=", ">", "?", "@", "\\", "^", "_", "`", ",", "~")
    }

    static var decimalDigits: CharacterSet {
        return CharacterSet().with("0" ... "9")
    }

    static var hexDigits: CharacterSet {
        return CharacterSet().with("0" ... "9", "a" ... "f", "A" ... "F")
    }
}
