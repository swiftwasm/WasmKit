import XCTest
@testable import Swasm

private struct WASTLexerTestCase {

    let input: String
    let expected: [WASTLexicalToken]
    let file: StaticString
    let line: UInt

    init(_ input: String,
         _ expected: [WASTLexicalToken],
         file: StaticString = #file,
         line: UInt = #line) {
        self.input = input
        self.expected = expected
        self.file = file
        self.line = line
    }

    func run() {
        let stream = UnicodeStream(input)
        var lexer = WASTLexer(stream: stream)
        var actual = [WASTLexicalToken]()
        while let token = lexer.next() {
            actual.append(token)
            if case .unknown = token {
                break
            }
        }
        XCTAssertEqual(actual, expected, file: file, line: line)
    }
}

internal final class WASTLexerTests: XCTestCase {
    func testLexer() {
        let tests: [WASTLexerTestCase] = [
            // Whitespace
            WASTLexerTestCase(" \t\n\r", []),

            // Line Comments
            WASTLexerTestCase(";; a", []),
            WASTLexerTestCase(";; a \n b", [.keyword("b")]),

            // Block Comments
            WASTLexerTestCase("(; a ;)", []),
            WASTLexerTestCase("(; \n a \n ;) b", [.keyword("b")]),

            // Braces
            WASTLexerTestCase("()", [.openingBrace, .closingBrace]),

            // Identifiers
            WASTLexerTestCase("$abcde", [.identifier("abcde")]),

            // Keywords
            WASTLexerTestCase("a!b#c$d", [.keyword("a!b#c$d")]),

            // Numbers
            WASTLexerTestCase("0", [.unsigned(0)]),
            WASTLexerTestCase("0123456789", [.unsigned(0123456789)]),
            WASTLexerTestCase("1234567890", [.unsigned(1234567890)]),
            WASTLexerTestCase("1_234_567_890", [.unsigned(1_234_567_890)]),

            WASTLexerTestCase("1_a", [.unsigned(1), .unknown("_")]),
            WASTLexerTestCase("1__", [.unsigned(1), .unknown("_")]),

            WASTLexerTestCase("0x", [.unsigned(0), .keyword("x")]),
            WASTLexerTestCase("0xg", [.unsigned(0), .keyword("xg")]),

            WASTLexerTestCase("0x0", [.unsigned(0x0)]),
            WASTLexerTestCase("0x0123456789", [.unsigned(0x0123456789)]),
            WASTLexerTestCase("0x1234567890", [.unsigned(0x1234567890)]),
            WASTLexerTestCase("0x1_234_567_890", [.unsigned(0x1_234_567_890)]),
            WASTLexerTestCase("0x1_g", [.unsigned(0x1), .unknown("_")]),
            WASTLexerTestCase("0xABCDEF", [.unsigned(0xabcDEF)]),
            WASTLexerTestCase("0xABC_DEF", [.unsigned(0xabc_DEF)]),

            WASTLexerTestCase("+", [.unknown("+")]),
            WASTLexerTestCase("+0123456789", [.signed(0123456789)]),
            WASTLexerTestCase("-0123456789", [.signed(-0123456789)]),
            WASTLexerTestCase("+0x0123456789", [.signed(0x0123456789)]),
            WASTLexerTestCase("-0x0123456789", [.signed(-0x0123456789)]),

            WASTLexerTestCase("1.23456789", [.floating(1.23456789e0)]),
            WASTLexerTestCase("0x1.23456789", [.floating(0x1.23456789p0)]),
            WASTLexerTestCase("+1.23456789", [.floating(+1.23456789e0)]),
            WASTLexerTestCase("+0x1.23456789", [.floating(+0x1.23456789p0)]),
            WASTLexerTestCase("-1.23456789", [.floating(-1.23456789e0)]),
            WASTLexerTestCase("-0x1.23456789", [.floating(-0x1.23456789p0)]),

            WASTLexerTestCase("inf", [.floating(Double.infinity)]),
            WASTLexerTestCase("+inf", [.floating(Double.infinity)]),
            WASTLexerTestCase("-inf", [.floating(-Double.infinity)]),

            // String
            WASTLexerTestCase("\"\"", [.string("")]),
            WASTLexerTestCase("\"asdf\"", [.string("asdf")]),
            WASTLexerTestCase("\"\\t\\n\\r\\\\\\\"\'\"", [.string("\t\n\r\\\"\'")]),
            WASTLexerTestCase("\"\\F0\\9F\\8C\\8D\"", [.string("🌍")]),
            WASTLexerTestCase("\"\\u{1F30D}\"", [.string("🌍")]),

            // Error
            WASTLexerTestCase("\u{3042}", [.unknown("\u{3042}")]),
            WASTLexerTestCase("🙆‍♂️", [.unknown("\u{1F646}")]),
            ]

        for test in tests {
            test.run()
        }
    }
}
