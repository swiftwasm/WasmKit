import XCTest
@testable import Swasm

private struct LexerTest {

    let input: String
    let expectedResult: [LexicalToken]?
    let expectedError: WASTLexer<UnicodeStream>.Error?
    let file: StaticString
    let line: UInt

    init(_ input: String,
         expectedResult: [LexicalToken]? = nil,
         expectedError: WASTLexer<UnicodeStream>.Error? = nil,
         file: StaticString = #file,
         line: UInt = #line) {
        self.input = input
        self.expectedResult = expectedResult
        self.expectedError = expectedError
        self.file = file
        self.line = line
    }

    func run() {
        guard expectedResult != nil || expectedError != nil else {
            XCTFail("LexerTest must have either expectedResult or expectedError", file: file, line: line)
            return
        }

        let stream = UnicodeStream(input)
        let lexer = WASTLexer(stream: stream)
        do {
            var actual = [LexicalToken]()
            while let token = try lexer.pop() {
                actual.append(token)
            }
            guard let expected = expectedResult else {
                XCTFail("Expected to raise an error \(expectedError!) but got \(actual)", file: file, line: line)
                return
            }
            XCTAssertEqual(actual, expected, file: file, line: line)
        } catch let error as WASTLexer<UnicodeStream>.Error {
            guard let expected = expectedError else {
                XCTFail("Expected to return \(expectedResult!) but raised an error \(error)", file: file, line: line)
                return
            }
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch let error {
            XCTFail(error.localizedDescription, file: file, line: line)
        }
    }
}

internal final class LexerTests: XCTestCase {
    func testLexer() {
        let tests: [LexerTest] = [
            // Whitespace
            LexerTest(" \t\n\r", expectedResult: []),
            LexerTest(" a", expectedResult: [.keyword("a")]),
            LexerTest("a \t b \n c \r d", expectedResult: [.keyword("a"), .keyword("b"), .keyword("c"), .keyword("d")]),

            // Line Comments
            LexerTest(";; a", expectedResult: []),
            LexerTest(";; a \n ;; b", expectedResult: []),
            LexerTest(";; a \n b", expectedResult: [.keyword("b")]),

            // Block Comments
            LexerTest("(; a ;)", expectedResult: []),
            LexerTest("(; \n a \n ;) b", expectedResult: [.keyword("b")]),

            // Keywords
            LexerTest("a", expectedResult: [.keyword("a")]),

            // Error
            LexerTest("あ", expectedError: .unexpectedUnicodeScalar("あ", at: 0)),
            LexerTest("🙆‍♂️", expectedError: .unexpectedUnicodeScalar("\u{1F646}", at: 0)),
            ]

        for test in tests {
            test.run()
        }
    }
}
