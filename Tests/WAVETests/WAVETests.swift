#if ComponentModel
    import ComponentModel
    import Foundation
    import Testing
    import WAVE

    @Suite
    struct WAVELexerTests {

        @Test
        func lexBasicTokens() throws {
            var lexer = WAVELexer("true false 123 -42 3.14")

            let t1 = try lexer.next()
            #expect(t1 == .true(t1.span))

            let t2 = try lexer.next()
            #expect(t2 == .false(t2.span))

            let t3 = try lexer.next()
            if case .number(let s, _) = t3 {
                #expect(s == "123")
            } else {
                Issue.record("Expected number")
            }

            let t4 = try lexer.next()
            if case .number(let s, _) = t4 {
                #expect(s == "-42")
            } else {
                Issue.record("Expected number")
            }

            let t5 = try lexer.next()
            if case .number(let s, _) = t5 {
                #expect(s == "3.14")
            } else {
                Issue.record("Expected number")
            }
        }

        @Test
        func lexStringWithEscapes() throws {
            var lexer = WAVELexer(#""hello\nworld""#)

            let token = try lexer.next()
            if case .string(let s, _) = token {
                #expect(s == "hello\nworld")
            } else {
                Issue.record("Expected string, got \(token)")
            }
        }

        @Test
        func lexChar() throws {
            var lexer = WAVELexer("'x' '\\n' '\\u{2603}'")

            let t1 = try lexer.next()
            if case .char(let c, _) = t1 {
                #expect(c == "x")
            } else {
                Issue.record("Expected char")
            }

            let t2 = try lexer.next()
            if case .char(let c, _) = t2 {
                #expect(c == "\n")
            } else {
                Issue.record("Expected char")
            }

            let t3 = try lexer.next()
            if case .char(let c, _) = t3 {
                #expect(c == "☃")
            } else {
                Issue.record("Expected char")
            }
        }

        @Test
        func lexKeywords() throws {
            var lexer = WAVELexer("nan inf -inf some none ok err")

            #expect(try lexer.next() == .nan(SourceSpan(start: 0, end: 3)))

            let inf = try lexer.next()
            if case .inf = inf {} else { Issue.record("Expected inf") }

            let negInf = try lexer.next()
            if case .negInf = negInf {} else { Issue.record("Expected -inf") }

            let some = try lexer.next()
            if case .some = some {} else { Issue.record("Expected some") }

            let none = try lexer.next()
            if case .none = none {} else { Issue.record("Expected none") }

            let ok = try lexer.next()
            if case .ok = ok {} else { Issue.record("Expected ok") }

            let err = try lexer.next()
            if case .err = err {} else { Issue.record("Expected err") }
        }

        @Test
        func lexLabels() throws {
            var lexer = WAVELexer("my-func field-name %true")

            let t1 = try lexer.next()
            if case .label(let s, _) = t1 {
                #expect(s == "my-func")
            } else {
                Issue.record("Expected label")
            }

            let t2 = try lexer.next()
            if case .label(let s, _) = t2 {
                #expect(s == "field-name")
            } else {
                Issue.record("Expected label")
            }

            let t3 = try lexer.next()
            if case .escapedLabel(let s, _) = t3 {
                #expect(s == "true")
            } else {
                Issue.record("Expected escaped label")
            }
        }

        @Test
        func lexDelimiters() throws {
            var lexer = WAVELexer("() [] {} : , ;")

            if case .leftParen = try lexer.next() {} else { Issue.record("Expected (") }
            if case .rightParen = try lexer.next() {} else { Issue.record("Expected )") }
            if case .leftBracket = try lexer.next() {} else { Issue.record("Expected [") }
            if case .rightBracket = try lexer.next() {} else { Issue.record("Expected ]") }
            if case .leftBrace = try lexer.next() {} else { Issue.record("Expected {") }
            if case .rightBrace = try lexer.next() {} else { Issue.record("Expected }") }
            if case .colon = try lexer.next() {} else { Issue.record("Expected :") }
            if case .comma = try lexer.next() {} else { Issue.record("Expected ,") }
            if case .semicolon = try lexer.next() {} else { Issue.record("Expected ;") }
        }

        @Test
        func lexComments() throws {
            var lexer = WAVELexer(
                """
                // This is a comment
                true // inline comment
                false
                """)

            let t1 = try lexer.next()
            if case .true = t1 {} else { Issue.record("Expected true") }

            let t2 = try lexer.next()
            if case .false = t2 {} else { Issue.record("Expected false") }
        }

        @Test
        func lexMultilineString() throws {
            let input = #"""
                """
                Hello
                World
                """
                """#

            var lexer = WAVELexer(input)
            let token = try lexer.next()

            if case .string(let s, _) = token {
                #expect(s == "Hello\nWorld")
            } else {
                Issue.record("Expected string, got \(token)")
            }
        }

        @Test
        func rejectInvalidSurrogate() throws {
            var lexer = WAVELexer(#""\u{d800}""#)

            do {
                _ = try lexer.next()
                Issue.record("Should have thrown error")
            } catch let error {
                #expect(error.message == "invalid character escape")
            }
        }
    }

    @Suite
    struct WAVEParserTests {

        @Test
        func parseBool() throws {
            var parser = WAVEParser("true")
            let value = try parser.parse(type: .bool)
            if case .bool(true) = value {} else { Issue.record("Expected bool(true)") }

            var parser2 = WAVEParser("false")
            let value2 = try parser2.parse(type: .bool)
            if case .bool(false) = value2 {} else { Issue.record("Expected bool(false)") }
        }

        @Test
        func parseIntegers() throws {
            var parser = WAVEParser("42")
            let value = try parser.parse(type: .u32)
            if case .u32(42) = value {} else { Issue.record("Expected u32(42)") }

            var parser2 = WAVEParser("-123")
            let value2 = try parser2.parse(type: .s32)
            if case .s32(-123) = value2 {} else { Issue.record("Expected s32(-123)") }
        }

        @Test
        func parseFloats() throws {
            var parser = WAVEParser("3.14")
            let value = try parser.parse(type: .float32)
            if case .float32(let f) = value {
                #expect(abs(f - 3.14) < 0.001)
            } else {
                Issue.record("Expected float32")
            }

            var parser2 = WAVEParser("nan")
            let value2 = try parser2.parse(type: .float64)
            if case .float64(let f) = value2 {
                #expect(f.isNaN)
            } else {
                Issue.record("Expected float64")
            }
        }

        @Test
        func parseString() throws {
            var parser = WAVEParser(#""hello world""#)
            let value = try parser.parse(type: .string)
            if case .string("hello world") = value {} else { Issue.record("Expected string") }
        }

        @Test
        func parseChar() throws {
            var parser = WAVEParser("'x'")
            let value = try parser.parse(type: .char)
            if case .char(let c) = value, c == "x" {} else { Issue.record("Expected char 'x'") }
        }

        @Test
        func parseEnum() throws {
            var parser = WAVEParser("left")
            let value = try parser.parse(type: .enum(["left", "right"]))
            if case .enum("left") = value {} else { Issue.record("Expected enum 'left'") }
        }

        @Test
        func parseFlags() throws {
            var parser = WAVEParser("{read, write}")
            let value = try parser.parse(type: .flags(["read", "write", "exec"]))
            if case .flags(let set) = value {
                #expect(set == Set(["read", "write"]))
            } else {
                Issue.record("Expected flags")
            }
        }
    }

    @Suite
    struct WAVEFormatterTests {

        let formatter = WAVEFormatter()

        @Test
        func formatBool() {
            #expect(formatter.format(.bool(true)) == "true")
            #expect(formatter.format(.bool(false)) == "false")
        }

        @Test
        func formatIntegers() {
            #expect(formatter.format(.u32(42)) == "42")
            #expect(formatter.format(.s32(-123)) == "-123")
        }

        @Test
        func formatFloats() {
            #expect(formatter.format(.float32(.nan)) == "nan")
            #expect(formatter.format(.float32(.infinity)) == "inf")
            #expect(formatter.format(.float32(-.infinity)) == "-inf")
        }

        @Test
        func formatString() {
            #expect(formatter.format(.string("hello")) == "\"hello\"")
            #expect(formatter.format(.string("line\nbreak")) == "\"line\\nbreak\"")
        }

        @Test
        func formatChar() {
            #expect(formatter.format(.char("x")) == "'x'")
            #expect(formatter.format(.char("\n")) == "'\\n'")
        }

        @Test
        func formatList() {
            let value = ComponentValue.list([.u32(1), .u32(2), .u32(3)])
            #expect(formatter.format(value) == "[1, 2, 3]")
        }

        @Test
        func formatTuple() {
            let value = ComponentValue.tuple([.string("abc"), .u32(123)])
            #expect(formatter.format(value) == "(\"abc\", 123)")
        }

        @Test
        func formatFlags() {
            let value = ComponentValue.flags(Set(["read", "write"]))
            #expect(formatter.format(value) == "{read, write}")

            let empty = ComponentValue.flags(Set())
            #expect(formatter.format(empty) == "{}")
        }

        @Test
        func formatOption() {
            #expect(formatter.format(.option(nil)) == "none")
            #expect(formatter.format(.option(.u32(42))) == "some(42)")  // explicit form
            #expect(formatter.format(.option(.option(.u32(42)))) == "some(some(42))")  // nested
        }

        @Test
        func formatResult() {
            #expect(formatter.format(.result(ok: nil, error: nil)) == "ok")
            #expect(formatter.format(.result(ok: .u32(42), error: nil)) == "ok(42)")  // explicit form
            #expect(formatter.format(.result(ok: nil, error: .string("oops"))) == "err(\"oops\")")
        }

        @Test
        func formatEnumKeyword() {
            // Enum case that matches a keyword needs % prefix
            #expect(formatter.format(.enum("true")) == "%true")
            #expect(formatter.format(.enum("left")) == "left")
        }
    }

#endif
