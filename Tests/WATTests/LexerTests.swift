import Foundation
import WasmParser
import XCTest

@testable import WAT

class LexerTests: XCTestCase {
    func collectToken(_ source: String) throws -> [TokenKind] {
        var lexer = Lexer(input: source)
        var tokens: [TokenKind] = []
        while let token = try lexer.rawLex() {
            tokens.append(token.kind)
        }
        return tokens
    }

    func testLexBasics() {
        try XCTAssertEqual(collectToken(""), [])
        try XCTAssertEqual(collectToken("(module"), [.leftParen, .keyword])
        try XCTAssertEqual(collectToken("( module"), [.leftParen, .keyword])
        try XCTAssertEqual(collectToken("(\tmodule"), [.leftParen, .keyword])
        try XCTAssertEqual(collectToken("(\nmodule"), [.leftParen, .keyword])
        try XCTAssertEqual(collectToken("(module)"), [.leftParen, .keyword, .rightParen])

    }

    func testLexComment() {
        try XCTAssertEqual(
            collectToken(
                """
                (;
                  multi-line comment
                ;)
                """
            ),
            [.blockComment]
        )
        try XCTAssertEqual(collectToken(";; foo"), [.lineComment])
        try XCTAssertEqual(collectToken(";; foo\n(bar"), [.lineComment, .leftParen, .keyword])

    }

    func testLexIdAndString() throws {
        try XCTAssertEqual(collectToken("$foo"), [.id])
        try XCTAssertEqual(collectToken("\"foo\""), [.string(Array("foo".utf8))])
        try XCTAssertEqual(collectToken("\"\\t\\n\\r\\\"\\\\\""), [.string(Array("\t\n\r\"\\".utf8))])
        try XCTAssertEqual(collectToken("\"\\u{1F600}\""), [.string(Array("😀".utf8))])
        try XCTAssertEqual(collectToken("$\"foo\""), [.id])
        try XCTAssertEqual(collectToken("0$x"), [.unknown])
    }

    func testLexInteger() throws {
        try XCTAssertEqual(collectToken("inf"), [.float(nil, .inf)])
        try XCTAssertEqual(collectToken("+inf"), [.float(.plus, .inf)])
        try XCTAssertEqual(collectToken("-inf"), [.float(.minus, .inf)])
        try XCTAssertEqual(collectToken("nan"), [.float(nil, .nan(hexPattern: nil))])
        try XCTAssertEqual(collectToken("+nan"), [.float(.plus, .nan(hexPattern: nil))])
        try XCTAssertEqual(collectToken("-nan"), [.float(.minus, .nan(hexPattern: nil))])
        try XCTAssertEqual(collectToken("nan:0x7f_ffff"), [.float(nil, .nan(hexPattern: "7fffff"))])
        try XCTAssertEqual(collectToken("3.14"), [.float(nil, .decimalPattern("3.14"))])
        try XCTAssertEqual(collectToken("1e+07"), [.float(nil, .decimalPattern("1e+07"))])
        try XCTAssertEqual(collectToken("1E+07"), [.float(nil, .decimalPattern("1E+07"))])
        try XCTAssertEqual(collectToken("0xff"), [.integer(nil, .hexPattern("ff"))])
        try XCTAssertEqual(collectToken("8_128"), [.integer(nil, .decimalPattern("8128"))])
        try XCTAssertEqual(collectToken("1.e10"), [.float(nil, .decimalPattern("1.e10"))])
    }

    func testLexFloatLiteral() throws {
        try XCTAssertEqual(collectToken("nan:canonical"), [.keyword])
        try XCTAssertEqual(collectToken("0x1.921fb6p+2"), [.float(nil, .hexPattern("1.921fb6p+2"))])
    }

    func testLexMemory() throws {
        try XCTAssertEqual(collectToken("(module (memory 1))"), [.leftParen, .keyword, .leftParen, .keyword, .integer(nil, .decimalPattern("1")), .rightParen, .rightParen])
    }

    func testLexSpectest() throws {
        var failureCount = 0
        for filePath in Spectest.wastFiles() {
            print("Lexing \(filePath.path)...")
            let source = try String(contentsOf: filePath)
            do {
                _ = try collectToken(source)
            } catch {
                failureCount += 1
                XCTFail("Failed to lex \(filePath.path):\(error)")
            }
        }

        if failureCount > 0 {
            XCTFail("Failed to lex \(failureCount) files")
        }
    }
}
