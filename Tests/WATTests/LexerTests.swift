#if canImport(Testing)
    import Testing
    import Foundation
    import WasmParser

    @testable import WAT

    @Suite
    struct LexerTests {
        func collectToken(_ source: String) throws -> [TokenKind] {
            var lexer = Lexer(input: source)
            var tokens: [TokenKind] = []
            while let token = try lexer.rawLex() {
                tokens.append(token.kind)
            }
            return tokens
        }

        @Test
        func lexBasics() throws {
            #expect(try collectToken("") == [])
            #expect(try collectToken("(module") == [.leftParen, .keyword])
            #expect(try collectToken("( module") == [.leftParen, .keyword])
            #expect(try collectToken("(\tmodule") == [.leftParen, .keyword])
            #expect(try collectToken("(\nmodule") == [.leftParen, .keyword])
            #expect(try collectToken("(module)") == [.leftParen, .keyword, .rightParen])

        }

        @Test
        func testLexComment() throws {
            #expect(try collectToken("(; foo ;)") == [.blockComment])
            #expect(
                try collectToken(
                    """
                    (;
                      multi-line comment
                    ;)
                    """
                ) == [.blockComment]
            )
            #expect(try collectToken(";; foo") == [.lineComment])
            #expect(try collectToken(";; foo\n(bar") == [.lineComment, .leftParen, .keyword])

        }

        @Test
        func lexBrokenComment() throws {
            #expect(throws: (any Error).self) { try collectToken("(;)") }
            #expect(throws: (any Error).self) { try collectToken("(; foo )") }
            #expect(throws: (any Error).self) { try collectToken(";)") }
        }

        @Test
        func lexIdAndString() throws {
            #expect(try collectToken("$foo") == [.id])
            #expect(try collectToken("\"foo\"") == [.string(Array("foo".utf8))])
            #expect(try collectToken("\"\\t\\n\\r\\\"\\\\\"") == [.string(Array("\t\n\r\"\\".utf8))])
            #expect(try collectToken("\"\\u{1F600}\"") == [.string(Array("😀".utf8))])
            #expect(try collectToken("$\"foo\"") == [.id])
            #expect(try collectToken("0$x") == [.unknown])
        }

        @Test
        func lexInteger() throws {
            #expect(try collectToken("inf") == [.float(nil, .inf)])
            #expect(try collectToken("+inf") == [.float(.plus, .inf)])
            #expect(try collectToken("-inf") == [.float(.minus, .inf)])
            #expect(try collectToken("nan") == [.float(nil, .nan(hexPattern: nil))])
            #expect(try collectToken("+nan") == [.float(.plus, .nan(hexPattern: nil))])
            #expect(try collectToken("-nan") == [.float(.minus, .nan(hexPattern: nil))])
            #expect(try collectToken("nan:0x7f_ffff") == [.float(nil, .nan(hexPattern: "7fffff"))])
            #expect(try collectToken("3.14") == [.float(nil, .decimalPattern("3.14"))])
            #expect(try collectToken("1e+07") == [.float(nil, .decimalPattern("1e+07"))])
            #expect(try collectToken("1E+07") == [.float(nil, .decimalPattern("1E+07"))])
            #expect(try collectToken("0xff") == [.integer(nil, .hexPattern("ff"))])
            #expect(try collectToken("8_128") == [.integer(nil, .decimalPattern("8128"))])
            #expect(try collectToken("1.e10") == [.float(nil, .decimalPattern("1.e10"))])
        }

        @Test
        func lexFloatLiteral() throws {
            #expect(try collectToken("nan:canonical") == [.keyword])
            #expect(try collectToken("0x1.921fb6p+2") == [.float(nil, .hexPattern("1.921fb6p+2"))])
        }

        @Test
        func lexMemory() throws {
            #expect(try collectToken("(module (memory 1))") == [.leftParen, .keyword, .leftParen, .keyword, .integer(nil, .decimalPattern("1")), .rightParen, .rightParen])
        }

        // NOTE: We do the same check as a part of the EncoderTests, so it's
        // usually redundant and time-wasting to run this test every time.
        // Keeping it here just for local unit testing purposes.
        @Test(
            .enabled(if: ProcessInfo.processInfo.environment["WASMKIT_PARSER_SPECTEST"] == "1"),
            arguments: Spectest.wastFiles(include: [])
        )
        func lexSpectest(wastFile: URL) throws {
            let source = try String(contentsOf: wastFile)
            _ = try collectToken(source)
        }
    }
#endif
