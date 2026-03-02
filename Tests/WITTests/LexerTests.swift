import Testing

@testable import WIT

@Suite
struct LexerTests {
    func collectToken(_ s: String) throws -> [TokenKind] {
        let cursor = Lexer.Cursor(input: s)
        var lexer = Lexer(cursor: cursor)
        var tokens: [TokenKind] = []
        while let token = lexer.lex() {
            tokens.append(token.kind)
        }
        return tokens
    }

    @Test func lexIdentifier() throws {
        #expect(try collectToken("") == [])
        #expect(try collectToken("_") == [.underscore])
        #expect(try collectToken("a") == [.id])
        #expect(try collectToken("a1") == [.id])
        #expect(try collectToken("a1b") == [.id])
        #expect(try collectToken("apple") == [.id])
        #expect(try collectToken("apple-banana") == [.id])
        #expect(try collectToken("_a_p_p_l_e_") == [.id])
        #expect(try collectToken("アップル") == [.id])

        #expect(try collectToken("%a") == [.explicitId])
        #expect(try collectToken("%a-b") == [.explicitId])
        #expect(try collectToken("%") == [.explicitId])

        #expect(try collectToken("func-tion") == [.id])
        #expect(try collectToken("a:") == [.id, .colon])
    }

    @Test func lexKeyword() throws {
        #expect(try collectToken("func") == [.func])
        #expect(try collectToken("func()") == [.func, .leftParen, .rightParen])

        #expect(try collectToken("resource") == [.resource])

        #expect(try collectToken("own") == [.own])
        #expect(try collectToken("borrow") == [.borrow])

        #expect(
            try collectToken("own<file>") == [.own, .lessThan, .id, .greaterThan]
        )
    }

    @Test func lexInteger() throws {
        #expect(try collectToken("0") == [.integer])
        #expect(try collectToken("0123") == [.integer])
        #expect(try collectToken("0123a") == [.integer, .id])
    }

    @Test func lexFunction() throws {
        #expect(
            try collectToken("stat-file: func()") == [
                .id, .colon, .func, .leftParen, .rightParen,
            ])
        #expect(
            try collectToken("stat-file: func(path: string)") == [
                .id, .colon, .func,
                .leftParen, .id, .colon, .string_, .rightParen,
            ])

        #expect(
            try collectToken("stat-file: func() -> result<stat>") == [
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

    @Test func textRange() throws {
        #expect(try tokenSpan("a") == [.init(offset: 0, length: 1)])
        #expect(try tokenSpan("ab") == [.init(offset: 0, length: 2)])
        #expect(
            try tokenSpan("a b") == [
                .init(offset: 0, length: 1),
                .init(offset: 2, length: 1),
            ])
    }
}
