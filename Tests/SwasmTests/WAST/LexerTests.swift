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
            LexerTest(" abcde", [.keyword("abcde")]),
            LexerTest("a \t b \n c \r d", [.keyword("a"), .keyword("b"), .keyword("c"), .keyword("d")]),

            // Line Comments
            LexerTest(";; a", []),
            LexerTest(";; a \n ;; b", []),
            LexerTest(";; a \n b", [.keyword("b")]),

            // Block Comments
            LexerTest("(; a ;)", []),
            LexerTest("(; \n a \n ;) b", [.keyword("b")]),

            // Keywords
            LexerTest("a", [.keyword("a")]),

            // Error
            LexerTest("\u{3042}", [.unknown("\u{3042}")]),
            LexerTest("🙆‍♂️", [.unknown("\u{1F646}")]),
            ]

        for test in tests {
            test.run()
        }
    }
}
