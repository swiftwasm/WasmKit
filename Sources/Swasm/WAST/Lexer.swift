public enum LexicalToken {
    case keyword(String)
    case reserved(String)
    case unsigned(UInt)
    case signed(Int)
    case floating(Double)
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
        case let (.floating(l), .floating(r)):
            return l == r
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
            case (" ", _, _), ("\t", _, _), ("\n", _, _), ("\r", _, _): // Whitespace and format effectors
                continue

            case (";", ";"?, _): // Line comment
                var c = c2
                while c != nil, c != "\n" {
                    c = stream.next()
                }
                continue

            case ("(", ";"?, _): // Block comment
                while case let (end1?, end2?) = stream.look(), (end1, end2) != (";", ")") {
                    _ = stream.next()
                }
                _ = stream.next(); _ = stream.next() // skip ";)"

            case (CharacterSet.decimalDigits, _, _), // Number
                 (CharacterSet.signs, _?, _),
                 ("i", "n"?, "f"?):
                return consumeNumber(from: c0)

            case (CharacterSet.keywordPrefixes, _, _): // Keyword
                var cs = [c0]
                while let c: UnicodeScalar = stream.next(), CharacterSet.IDCharacters.contains(c) {
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

internal extension WASTLexer {
    func consumeNumber(from c0: UnicodeScalar) -> LexicalToken? {
        var c0 = c0
        var (isPositive, isHex): (Bool?, Bool)
        (isPositive, c0) = consumeSign(from: c0)
        (isHex, c0) = consumeHexPrefix(from: c0)
        return consumeNumber(from: c0, positive: isPositive, hex: isHex)
    }

    func consumeSign(from c0: UnicodeScalar) -> (Bool?, UnicodeScalar) {
        let (c1, _) = stream.look()
        switch (c0, c1) {
        case ("+", let c1?):
            _ = stream.next()
            return (true, c1)
        case ("-", let c1?):
            _ = stream.next()
            return (false, c1)
        default:
            return (nil, c0)
        }
    }

    func consumeHexPrefix(from c0: UnicodeScalar) -> (Bool, UnicodeScalar) {
        let (c1, c2) = stream.look()
        switch (c0, c1, c2) {
        case ("0", "x"?, let c2?) where CharacterSet.hexDigits.contains(c2):
            _ = stream.next(); _ = stream.next()
            return (true, c2)
        default:
            return (false, c0)
        }
    }

    func consumeNumber(from c0: UnicodeScalar, positive: Bool?, hex: Bool) -> LexicalToken? {
        var result: LexicalToken = positive == nil ? .unsigned(0) : .signed(0)

        var c0 = c0
        var (c1, c2): (UnicodeScalar?, UnicodeScalar?)
        while true {
            (c1, c2) = stream.look()

            switch (result, c0, c1, c2) {
            case let (.unsigned(n), CharacterSet.decimalDigits, _, _) where !hex,
                 let (.unsigned(n), CharacterSet.hexDigits, _, _) where hex:
                result = .unsigned(n * (!hex ? 10 : 16) + UInt(c0, hex: hex)!)

            case let (.signed(n), CharacterSet.decimalDigits, _, _) where !hex,
                 let (.signed(n), CharacterSet.hexDigits, _, _) where hex:
                result = positive == false
                    ? .signed(-(abs(n) * (!hex ? 10 : 16) + Int(c0, hex: hex)!))
                    : .signed(n * (!hex ? 10 : 16) + Int(c0, hex: hex)!)

            case let (.floating(n), CharacterSet.decimalDigits, _, _) where !hex,
                 let (.floating(n), CharacterSet.hexDigits, _, _) where hex:
                var p: Double = 1
                while abs((n * p).remainder(dividingBy: 1)) >= Double.ulpOfOne * p {
                    p *= !hex ? 10 : 16
                }
                p *= !hex ? 10 : 16

                let frac = Double(c0, hex: hex)! / p
                result = positive == false
                    ? .floating(-(abs(Double(n)) + frac))
                    : .floating(Double(n) + frac)

            case (_, "i", "n"?, "f"?):
                _ = stream.next(); _ = stream.next()
                return .floating(positive == false ? -Double.infinity : Double.infinity)

            default:
                return .unknown(c0)
            }

            func skip(_ c: UnicodeScalar) {
                c0 = c
                _ = stream.next()
            }

            guard let c1 = c1 else { return result }

            switch (result, c1, c2, hex) {
            case (_, "_", let c2?, false) where CharacterSet.decimalDigits.contains(c2),
                 (_, "_", let c2?, true) where CharacterSet.hexDigits.contains(c2):
                _ = stream.next()
                skip(c2)

            case (let .unsigned(n), ".", let c2?, false) where CharacterSet.decimalDigits.contains(c2),
                 (let .unsigned(n), ".", let c2?, true) where CharacterSet.hexDigits.contains(c2):
                result = .floating(Double(n))
                _ = stream.next()
                skip(c2)

            case (let .signed(n), ".", let c2?, false) where CharacterSet.decimalDigits.contains(c2),
                 (let .signed(n), ".", let c2?, true) where CharacterSet.hexDigits.contains(c2):
                result = .floating(Double(n))
                _ = stream.next()
                skip(c2)

            case (_, CharacterSet.decimalDigits, _, false),
                 (_, CharacterSet.hexDigits, _, true),
                 (_, "i", _, _):
                skip(c1)

            default:
                return result
            }
        }
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

    static var signs: CharacterSet {
        return CharacterSet().with("+", "-")
    }

    static var digits: CharacterSet {
        return CharacterSet().with("0" ... "9", "a" ... "f", "A" ... "F")
    }

    static var decimalDigits: CharacterSet {
        return CharacterSet().with("0" ... "9")
    }

    static var hexDigits: CharacterSet {
        return CharacterSet().with("0" ... "9", "a" ... "f", "A" ... "F")
    }
}
