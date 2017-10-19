public enum LexicalToken {
    case keyword(String)
    case unsigned
    case signed
    case floating
    case string
    case identifier
    case openingBrace
    case closingBrace
    case whitespace(String)
}

public class WASTLexer<InputStream: Stream> where InputStream.Token == UnicodeScalar {
    var stream: InputStream

    init(stream: InputStream) {
        self.stream = stream
    }
}

private extension UnicodeScalar {
    func isIDCharacter() -> Bool {
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

extension WASTLexer {
    func consumeWhitespace() -> String? {
        var codes = String.UnicodeScalarView()

        loop:
            while let c1 = stream.next() {
                let c2 = stream.next(offset: 1)
                switch (c1, c2) {
                case (" ", _): // whitespace
                    codes.append(c1)
                    stream.advance()
                case ("\t", _), ("\n", _), ("\r", _): // format
                    codes.append(c1)
                    stream.advance()
                case (";", ";"?): // line comment
                    codes.append(c1); codes.append(c2!)
                    stream.advance(); stream.advance()

                    while let cc = stream.next(), cc != "\n" {
                        codes.append(cc)
                        stream.advance()
                    }
                case ("(", ";"?): // block comment
                    codes.append(c1); codes.append(c2!)
                    stream.advance(); stream.advance()

                    while let cc1 = stream.next() {
                        codes.append(cc1)
                        stream.advance()

                        if cc1 == ";", let cc2 = stream.next(), cc2 == ")" {
                            codes.append(cc2)
                            stream.advance()
                            break
                        }
                    }
                default:
                    break loop
                }
        }

        return codes.isEmpty ? nil : String(codes)
    }

    func consumeIdentifierCharacters() -> String? {
        var codes = String.UnicodeScalarView()

        while let c = stream.next(), c.isIDCharacter() {
            codes.append(c)
            stream.advance()
        }

        return codes.isEmpty ? nil : String(codes)
    }

    func consumeKeyword() -> String? {
        guard let c = stream.next(), "a" ... "z" ~= c else { return nil }
        var codes = String.UnicodeScalarView([c])
        stream.advance()

        if let cs = consumeIdentifierCharacters() {
            codes.append(contentsOf: cs.unicodeScalars)
        }

        return String(codes)
    }
}

extension WASTLexer {
    func consumeDigits() -> UInt? {
        var result: UInt?
        while let c = stream.next(), let d = UInt(c, hex: false) {
            result = (result ?? 0) * 10 + d
            stream.advance()
        }
        return result
    }

    func consumeHexDigits() -> UInt? {
        var result: UInt?
        while let c = stream.next(), let d = UInt(c, hex: true) {
            result = (result ?? 0) * 16 + d
            stream.advance()
        }
        return result
    }

    func consumeNumber() -> UInt? {
        guard var result = consumeDigits() else { return nil }

        while let c = stream.next() {
            if let d = UInt(c, hex: false) {
                result = result * 10 + d
                stream.advance()
            } else if c == "_" {
                stream.advance()
            } else {
                break
            }
        }

        return result
    }

    func consumeHexNumber() -> UInt? {
        guard var result = consumeHexDigits() else { return nil }

        while let c = stream.next() {
            if let d = UInt(c, hex: true) {
                result = result * 16 + d
                stream.advance()
            } else if c == "_" {
                stream.advance()
            } else {
                break
            }
        }

        return result
    }

    func consumeUnsignedInteger() -> UInt? {
        hex:
        if let c1 = stream.next(), c1 == "0", let c2 = stream.next(offset: 1), c2 == "x" {
            stream.advance(); stream.advance()

            guard let result = consumeHexNumber() else {
                break hex
            }
            return result
        }

        guard let result = consumeNumber() else {
            return nil
        }

        return result
    }

    func consumeSignedInteger() -> Int? {
        guard let c = stream.next() else {
            return nil
        }

        switch c {
        case "+":
            stream.advance()
            return consumeUnsignedInteger().flatMap { Int($0) }
        case "-":
            stream.advance()
            return consumeUnsignedInteger().flatMap { -Int($0) }
        default:
            return nil
        }
    }

    func consumeInteger() -> Int? {
        return (consumeUnsignedInteger().flatMap { Int($0) } ?? consumeSignedInteger())
    }
}
