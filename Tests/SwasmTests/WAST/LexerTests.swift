import XCTest
@testable import Swasm

private struct LexerTest {

    let input: String
    let expected: [LexicalToken]
    let file: StaticString
    let line: UInt

    init(_ input: String,
         _ expected: [LexicalToken],
         file: StaticString = #file,
         line: UInt = #line) {
        self.input = input
        self.expected = expected
        self.file = file
        self.line = line
    }

    func run() {
        let stream = UnicodeStream(input)
        let lexer = WASTLexer(stream: stream)
        var actual = [LexicalToken]()
        while let token = lexer.next() {
            actual.append(token)
            if case .unknown = token {
                break
            }
        }
        XCTAssertEqual(actual, expected, file: file, line: line)
    }
}

internal final class LexerTests: XCTestCase {
    func testLexer() {
        let tests: [LexerTest] = [
            // Whitespace
            LexerTest(" \t\n\r", []),

            // Line Comments
            LexerTest(";; a", []),
            LexerTest(";; a \n b", [.keyword("b")]),

            // Block Comments
            LexerTest("(; a ;)", []),
            LexerTest("(; \n a \n ;) b", [.keyword("b")]),

            // Keywords
            LexerTest("a!b#c$d", [.keyword("a!b#c$d")]),

            // Numbers
            LexerTest("0", [.unsigned(0)]),
            LexerTest("0123456789", [.unsigned(0123456789)]),
            LexerTest("1234567890", [.unsigned(1234567890)]),
            LexerTest("1_234_567_890", [.unsigned(1_234_567_890)]),

            LexerTest("1_a", [.unsigned(1), .unknown("_")]),
            LexerTest("1__", [.unsigned(1), .unknown("_")]),

            LexerTest("0x", [.unsigned(0), .keyword("x")]),
            LexerTest("0xg", [.unsigned(0), .keyword("xg")]),

            LexerTest("0x0", [.unsigned(0x0)]),
            LexerTest("0x0123456789", [.unsigned(0x0123456789)]),
            LexerTest("0x1234567890", [.unsigned(0x1234567890)]),
            LexerTest("0x1_234_567_890", [.unsigned(0x1_234_567_890)]),
            LexerTest("0x1_g", [.unsigned(0x1), .unknown("_")]),
            LexerTest("0xABCDEF", [.unsigned(0xabcDEF)]),
            LexerTest("0xABC_DEF", [.unsigned(0xabc_DEF)]),

            LexerTest("+", [.unknown("+")]),
            LexerTest("+0123456789", [.signed(0123456789)]),
            LexerTest("-0123456789", [.signed(-0123456789)]),
            LexerTest("+0x0123456789", [.signed(0x0123456789)]),
            LexerTest("-0x0123456789", [.signed(-0x0123456789)]),

            LexerTest("1.23456789", [.floating(1.23456789e0)]),
            LexerTest("0x1.23456789", [.floating(0x1.23456789p0)]),
            LexerTest("+1.23456789", [.floating(+1.23456789e0)]),
            LexerTest("+0x1.23456789", [.floating(+0x1.23456789p0)]),
            LexerTest("-1.23456789", [.floating(-1.23456789e0)]),
            LexerTest("-0x1.23456789", [.floating(-0x1.23456789p0)]),

            LexerTest("inf", [.floating(Double.infinity)]),
            LexerTest("+inf", [.floating(Double.infinity)]),
            LexerTest("-inf", [.floating(-Double.infinity)]),

            // Error
            LexerTest("\u{3042}", [.unknown("\u{3042}")]),
            LexerTest("🙆‍♂️", [.unknown("\u{1F646}")]),
            ]

        for test in tests {
            test.run()
        }
    }
}
