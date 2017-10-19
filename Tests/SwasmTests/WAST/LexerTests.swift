import XCTest
@testable import Swasm

struct ConsumerTest<Type: Equatable> {
    typealias Consumer = (WASTLexer<UnicodeStream>) -> () -> Type?

    let input: String
    let expected: Type?
    let consumer: Consumer
    let file: StaticString
    let line: UInt

    init(_ input: String,
         _ expected: Type?,
         _ consumer: @escaping Consumer,
         file: StaticString = #file,
         line: UInt = #line) {
        self.input = input
        self.expected = expected
        self.consumer = consumer
        self.file = file
        self.line = line
    }

    func run() {
        let stream = UnicodeStream(input)
        let lexer = WASTLexer(stream: stream)
        let actual = consumer(lexer)()
        if let expected = expected {
            XCTAssertEqual(
                actual, expected,
                "\(consumer) should return \(expected) but got \(String(describing: actual))",
                file: file, line: line
            )
        } else {
            XCTAssertNil(
                actual,
                "\(consumer) should return nil but got \(String(describing: actual))",
                file: file, line: line
            )
        }
    }
}

class LexerTests: XCTestCase {
    func testConsumeWhitespace() {
        let tests = [
            ConsumerTest(" asdf", " ", WASTLexer.consumeWhitespace),
            ConsumerTest(" \n \r \t asdf", " \n \r \t ", WASTLexer.consumeWhitespace),
            ConsumerTest(";; this is a line comment\nasdf", ";; this is a line comment\n", WASTLexer.consumeWhitespace),
            ConsumerTest("""
            (;
            We ❤️ Unicode 👍🏽;
            ;)asdf
            """, """
            (;
            We ❤️ Unicode 👍🏽;
            ;)
            """, WASTLexer.consumeWhitespace),

            ConsumerTest("", nil, WASTLexer.consumeWhitespace),
            ConsumerTest("a", nil, WASTLexer.consumeWhitespace),
            ConsumerTest("; ;", nil, WASTLexer.consumeWhitespace),
            ConsumerTest("( ;", nil, WASTLexer.consumeWhitespace),
            ConsumerTest(";)", nil, WASTLexer.consumeWhitespace),
            ]

        for test in tests {
            test.run()
        }
    }

    func testIdentifierCharacters() {
        let tests = [
            ConsumerTest("asdf", "asdf", WASTLexer.consumeIdentifierCharacters),
            ConsumerTest("!#$%&`*+-./:<=>?@\\^_`,~", "!#$%&`*+-./:<=>?@\\^_`,~",
                         WASTLexer.consumeIdentifierCharacters),
            ConsumerTest("1asdf", "1asdf", WASTLexer.consumeIdentifierCharacters),
            ConsumerTest("!fasdf", "!fasdf", WASTLexer.consumeIdentifierCharacters),
            ConsumerTest("Aa)sdf", "Aa", WASTLexer.consumeIdentifierCharacters),

            ConsumerTest("", nil, WASTLexer.consumeIdentifierCharacters),
        ]

        for test in tests {
            test.run()
        }
    }

    func testConsumeKeyword() {
        let tests = [
            ConsumerTest("asdf", "asdf", WASTLexer.consumeKeyword),
            ConsumerTest("a!#$%&`*+-./:<=>?@\\^_`,~", "a!#$%&`*+-./:<=>?@\\^_`,~",
                         WASTLexer.consumeKeyword),
            ConsumerTest("as)df", "as", WASTLexer.consumeKeyword),

            ConsumerTest("", nil, WASTLexer.consumeKeyword),
            ConsumerTest("Aasdf", nil, WASTLexer.consumeKeyword),
            ConsumerTest("1asdf", nil, WASTLexer.consumeKeyword),
            ConsumerTest("!fasdf", nil, WASTLexer.consumeKeyword),
            ]

        for test in tests {
            test.run()
        }
    }

    func testConsumeDigits() {
        let tests = [
            ConsumerTest("00123456789", 123456789, WASTLexer.consumeDigits),
            ConsumerTest("00123_0045678", 123, WASTLexer.consumeDigits),
            ConsumerTest("123asdf", 123, WASTLexer.consumeDigits),
            ConsumerTest("123_", 123, WASTLexer.consumeNumber),
            ConsumerTest("123_asdf", 123, WASTLexer.consumeNumber),

            ConsumerTest("", nil, WASTLexer.consumeDigits),
            ConsumerTest("asdf", nil, WASTLexer.consumeDigits),
            ]

        for test in tests {
            test.run()
        }
    }

    func testConsumeNumber() {
        let tests = [
            ConsumerTest("00123456789", 123456789, WASTLexer.consumeNumber),
            ConsumerTest("00123_0045678", 1230045678, WASTLexer.consumeNumber),
            ConsumerTest("123asdf", 123, WASTLexer.consumeNumber),
            ConsumerTest("123_", 123, WASTLexer.consumeNumber),
            ConsumerTest("123_asdf", 123, WASTLexer.consumeNumber),

            ConsumerTest("", nil, WASTLexer.consumeNumber),
            ConsumerTest("asdf", nil, WASTLexer.consumeNumber),
            ]

        for test in tests {
            test.run()
        }
    }
}
