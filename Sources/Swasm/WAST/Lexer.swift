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

            case ("a" ... "z", _, _): // Keyword
                var cs = [c0]
                while let c = stream.next(), c.isIDCharacter {
                    cs.append(c)
                }

                return .keyword(String(String.UnicodeScalarView(cs)))

            default: // Unexpected
                return .unknown(c0)
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
