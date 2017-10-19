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

        measure {
            tests.forEach { $0.run() }
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

        measure {
            tests.forEach { $0.run() }
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

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeDigits() {
        let tests = [
            ConsumerTest("00123456789", 123456789, WASTLexer.consumeDigits),
            ConsumerTest("123abczxc", 123, WASTLexer.consumeDigits),
            ConsumerTest("123_abc_zxc", 123, WASTLexer.consumeDigits),

            ConsumerTest("", nil, WASTLexer.consumeDigits),
            ConsumerTest("asdf", nil, WASTLexer.consumeDigits),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeHexDigits() {
        let tests = [
            ConsumerTest("00123456789abcdef", 0x123456789abcdef, WASTLexer.consumeHexDigits),
            ConsumerTest("123abczxc", 0x123abc, WASTLexer.consumeHexDigits),
            ConsumerTest("123_abc_zxc", 0x123, WASTLexer.consumeHexDigits),

            ConsumerTest("", nil, WASTLexer.consumeHexDigits),
            ConsumerTest("zxcv", nil, WASTLexer.consumeHexDigits),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeNumber() {
        let tests = [
            ConsumerTest("00123456789abcdef", 123456789, WASTLexer.consumeDigits),
            ConsumerTest("123abczxc", 123, WASTLexer.consumeDigits),
            ConsumerTest("123_abc_zxc", 123, WASTLexer.consumeDigits),

            ConsumerTest("", nil, WASTLexer.consumeDigits),
            ConsumerTest("asdf", nil, WASTLexer.consumeDigits),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeHexNumber() {
        let tests = [
            ConsumerTest("00123456789abcdef", 0x123456789abcdef, WASTLexer.consumeHexNumber),
            ConsumerTest("123abczxc", 0x123abc, WASTLexer.consumeHexNumber),
            ConsumerTest("123_abc_zxc", 0x123abc, WASTLexer.consumeHexNumber),

            ConsumerTest("", nil, WASTLexer.consumeHexNumber),
            ConsumerTest("zxcv", nil, WASTLexer.consumeHexNumber),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeUnsignedInteger() {
        let tests = [
            ConsumerTest("00123456789", 123456789, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("0x00123456789", 0x123456789, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("0_012_300_456_789", 12300456789, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("0x0_012_300_456_789", 0x12300456789, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("123asdf", 123, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("0x123asdf", 0x123a, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("123_zxcv", 123, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("0x123_zxcv", 0x123, WASTLexer.consumeUnsignedInteger),

            ConsumerTest("", nil, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("0xzxcv", nil, WASTLexer.consumeUnsignedInteger),
            ConsumerTest("zxcv", nil, WASTLexer.consumeUnsignedInteger),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeSignedInteger() {
        let tests = [
            ConsumerTest("+00123456789", 123456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("-00123456789", -123456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("+0x00123456789", 0x123456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("-0x00123456789", -0x123456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("+0_012_300_456_789", 12300456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("-0_012_300_456_789", -12300456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("+0x0_012_300_456_789", 0x12300456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("-0x0_012_300_456_789", -0x12300456789, WASTLexer.consumeSignedInteger),
            ConsumerTest("+123asdf", 123, WASTLexer.consumeSignedInteger),
            ConsumerTest("-123asdf", -123, WASTLexer.consumeSignedInteger),
            ConsumerTest("+0x123asdf", 0x123a, WASTLexer.consumeSignedInteger),
            ConsumerTest("-0x123asdf", -0x123a, WASTLexer.consumeSignedInteger),
            ConsumerTest("+123_zxcv", 123, WASTLexer.consumeSignedInteger),
            ConsumerTest("-123_zxcv", -123, WASTLexer.consumeSignedInteger),
            ConsumerTest("+0x123_zxcv", 0x123, WASTLexer.consumeSignedInteger),
            ConsumerTest("-0x123_zxcv", -0x123, WASTLexer.consumeSignedInteger),

            ConsumerTest("", nil, WASTLexer.consumeSignedInteger),
            ConsumerTest("+zxcv", nil, WASTLexer.consumeSignedInteger),
            ConsumerTest("-zxcv", nil, WASTLexer.consumeSignedInteger),
            ConsumerTest("+0xzxcv", nil, WASTLexer.consumeSignedInteger),
            ConsumerTest("-0xzxcv", nil, WASTLexer.consumeSignedInteger),
            ConsumerTest("zxcv", nil, WASTLexer.consumeSignedInteger),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }

    func testConsumeInteger() {
        let tests = [
            ConsumerTest("00123456789", 123456789, WASTLexer.consumeInteger),
            ConsumerTest("+00123456789", 123456789, WASTLexer.consumeInteger),
            ConsumerTest("-00123456789", -123456789, WASTLexer.consumeInteger),
            ConsumerTest("0x00123456789", 0x123456789, WASTLexer.consumeInteger),
            ConsumerTest("+0x00123456789", 0x123456789, WASTLexer.consumeInteger),
            ConsumerTest("-0x00123456789", -0x123456789, WASTLexer.consumeInteger),
            ConsumerTest("0_012_300_456_789", 12300456789, WASTLexer.consumeInteger),
            ConsumerTest("+0_012_300_456_789", 12300456789, WASTLexer.consumeInteger),
            ConsumerTest("-0_012_300_456_789", -12300456789, WASTLexer.consumeInteger),
            ConsumerTest("0x0_012_300_456_789", 0x12300456789, WASTLexer.consumeInteger),
            ConsumerTest("+0x0_012_300_456_789", 0x12300456789, WASTLexer.consumeInteger),
            ConsumerTest("-0x0_012_300_456_789", -0x12300456789, WASTLexer.consumeInteger),
            ConsumerTest("123asdf", 123, WASTLexer.consumeInteger),
            ConsumerTest("+123asdf", 123, WASTLexer.consumeInteger),
            ConsumerTest("-123asdf", -123, WASTLexer.consumeInteger),
            ConsumerTest("0x123asdf", 0x123a, WASTLexer.consumeInteger),
            ConsumerTest("+0x123asdf", 0x123a, WASTLexer.consumeInteger),
            ConsumerTest("-0x123asdf", -0x123a, WASTLexer.consumeInteger),
            ConsumerTest("123_zxcv", 123, WASTLexer.consumeInteger),
            ConsumerTest("+123_zxcv", 123, WASTLexer.consumeInteger),
            ConsumerTest("-123_zxcv", -123, WASTLexer.consumeInteger),
            ConsumerTest("0x123_zxcv", 0x123, WASTLexer.consumeInteger),
            ConsumerTest("+0x123_zxcv", 0x123, WASTLexer.consumeInteger),
            ConsumerTest("-0x123_zxcv", -0x123, WASTLexer.consumeInteger),

            ConsumerTest("", nil, WASTLexer.consumeInteger),
            ConsumerTest("zxcv", nil, WASTLexer.consumeInteger),
            ConsumerTest("+zxcv", nil, WASTLexer.consumeInteger),
            ConsumerTest("-zxcv", nil, WASTLexer.consumeInteger),
            ConsumerTest("0xzxcv", nil, WASTLexer.consumeInteger),
            ConsumerTest("+0xzxcv", nil, WASTLexer.consumeInteger),
            ConsumerTest("-0xzxcv", nil, WASTLexer.consumeInteger),
            ConsumerTest("zxcv", nil, WASTLexer.consumeInteger),
            ]

        measure {
            tests.forEach { $0.run() }
        }
    }
}
