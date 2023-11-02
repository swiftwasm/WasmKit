import XCTest

@testable import WIT

class LexerTests: XCTestCase {
    func collectToken(_ s: String) throws -> [TokenKind] {
        let cursor = Lexer.Cursor(input: s)
        var lexer = Lexer(cursor: cursor)
        var tokens: [TokenKind] = []
        while let token = lexer.lex() {
            tokens.append(token.kind)
        }
        return tokens
    }

    func testLexIdentifier() {
        try XCTAssertEqual(collectToken(""), [])
        try XCTAssertEqual(collectToken("_"), [.underscore])
        try XCTAssertEqual(collectToken("a"), [.id])
        try XCTAssertEqual(collectToken("a1"), [.id])
        try XCTAssertEqual(collectToken("a1b"), [.id])
        try XCTAssertEqual(collectToken("apple"), [.id])
        try XCTAssertEqual(collectToken("apple-banana"), [.id])
        try XCTAssertEqual(collectToken("_a_p_p_l_e_"), [.id])
        try XCTAssertEqual(collectToken("アップル"), [.id])

        try XCTAssertEqual(collectToken("%a"), [.explicitId])
        try XCTAssertEqual(collectToken("%a-b"), [.explicitId])
        try XCTAssertEqual(collectToken("%"), [.explicitId])

        try XCTAssertEqual(collectToken("func-tion"), [.id])
        try XCTAssertEqual(collectToken("a:"), [.id, .colon])
    }

    func testLexKeyword() {
        try XCTAssertEqual(collectToken("func"), [.func])
        try XCTAssertEqual(collectToken("func()"), [.func, .leftParen, .rightParen])

        try XCTAssertEqual(collectToken("resource"), [.resource])

        try XCTAssertEqual(collectToken("own"), [.own])
        try XCTAssertEqual(collectToken("borrow"), [.borrow])

        try XCTAssertEqual(
            collectToken("own<file>"),
            [.own, .lessThan, .id, .greaterThan]
        )
    }

    func testLexInteger() {
        try XCTAssertEqual(collectToken("0"), [.integer])
        try XCTAssertEqual(collectToken("0123"), [.integer])
        try XCTAssertEqual(collectToken("0123a"), [.integer, .id])
    }

    func testLexFunction() {
        try XCTAssertEqual(
            collectToken("stat-file: func()"),
            [
                .id, .colon, .func, .leftParen, .rightParen,
            ])
        try XCTAssertEqual(
            collectToken("stat-file: func(path: string)"),
            [
                .id, .colon, .func,
                .leftParen, .id, .colon, .string_, .rightParen,
            ])

        try XCTAssertEqual(
            collectToken("stat-file: func() -> result<stat>"),
            [
                .id, .colon, .func, .leftParen, .rightParen,
                .rArrow, .result_, .lessThan, .id, .greaterThan,
            ])
    }

    struct Span: Equatable {
        let offset: Int
        let length: Int
    }

    func tokenSpan(_ s: String) throws -> [Span] {
        let cursor = Lexer.Cursor(input: s)
        var lexer = Lexer(cursor: cursor)
        var spans: [Span] = []
        while let token = lexer.lex() {
            let offset = s.distance(from: s.startIndex, to: token.textRange.lowerBound)
            let length = s.distance(from: token.textRange.lowerBound, to: token.textRange.upperBound)
            spans.append(Span(offset: offset, length: length))
        }
        return spans
    }

    func testTextRange() throws {
        try XCTAssertEqual(tokenSpan("a"), [.init(offset: 0, length: 1)])
        try XCTAssertEqual(tokenSpan("ab"), [.init(offset: 0, length: 2)])
        try XCTAssertEqual(
            tokenSpan("a b"),
            [
                .init(offset: 0, length: 1),
                .init(offset: 2, length: 1),
            ])
    }
}
