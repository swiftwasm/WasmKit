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
                _ = stream.next(); _ = stream.next()

            case (CharacterSet.keywordPrefixes, _, _): // Keyword
                var cs = [c0]
                while let c = stream.next(), CharacterSet.IDCharacters.contains(c) {
                    cs.append(c)
                }

                return .keyword(String(String.UnicodeScalarView(cs)))

            case ("0", "x"?, CharacterSet.hexDigits?): // Hexadecimal Unsigned
                var result = UInt(c0, hex: true)!

                _ = stream.next() // skip "x"
                while let c: UnicodeScalar = stream.next() {
                    if let d = UInt(c, hex: true) {
                        result = result * 16 + d
                    } else if c == "_" {
                        continue
                    } else {
                        break
                    }
                }
                return .unsigned(result)

            case (CharacterSet.decimalDigits, _, _): // Decimal Unsigned
                var result = UInt(c0, hex: false)!
                while let c: UnicodeScalar = stream.look() {
                    if let d = UInt(c, hex: false) {
                        _ = stream.next()
                        result = result * 10 + d
                    } else if c == "_" {
                        _ = stream.next()
                        continue
                    } else {
                        break
                    }
                }
                return .unsigned(result)

            default: // Unexpected
                return .unknown(c0)
            }
        }

        return nil
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
