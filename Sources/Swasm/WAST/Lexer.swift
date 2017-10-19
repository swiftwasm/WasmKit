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
    public var stream: InputStream

    init(stream: InputStream) {
        self.stream = stream
    }
}

extension UnicodeScalar {
    internal func isIDCharacter() -> Bool {
        return ("0" ... "9" ~= self
            ||	"A" ... "Z" ~= self
            ||	"a" ... "z" ~= self
            || ["!", "#", "$", "%", "&", "`", "*", "+", "-", ".", "/",
                ":", "<", "=", ">", "?", "@", "\\", "^", "_", "`", ",", "~",
                ].contains(self)
        )
    }
}

extension Int {
    internal init?(_ unicodeScalar: UnicodeScalar) {
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
        default: return nil
        }
    }
}

extension WASTLexer {
    internal func consumeWhitespace() -> String? {
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

    internal func consumeIdentifierCharacters() -> String? {
        var codes = String.UnicodeScalarView()

        while let c = stream.next(), c.isIDCharacter() {
            codes.append(c)
            stream.advance()
        }

        return codes.isEmpty ? nil : String(codes)
    }

    internal func consumeKeyword() -> String? {
        guard let c = stream.next(), "a" ... "z" ~= c else { return nil }
        var codes = String.UnicodeScalarView([c])
        stream.advance()

        if let cs = consumeIdentifierCharacters() {
            codes.append(contentsOf: cs.unicodeScalars)
        }

        return String(codes)
    }

    internal func consumeDigits() -> Int? {
        var result: Int?
        while let c = stream.next(), let d = Int(c) {
            result = (result ?? 0) * 10 + d
            stream.advance()
        }
        return result
    }

    internal func consumeNumber() -> Int? {
        guard var result = consumeDigits() else { return nil }

        while let c = stream.next() {
            if let d = Int(c) {
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
}
