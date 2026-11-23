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
        #expect(try collectToken("_") == [.keyword(.underscore)])
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
        #expect(try collectToken("func") == [.keyword(.func)])
        #expect(try collectToken("func()") == [.keyword(.func), .leftParen, .rightParen])

        #expect(try collectToken("resource") == [.keyword(.resource)])

        #expect(try collectToken("own") == [.keyword(.own)])
        #expect(try collectToken("borrow") == [.keyword(.borrow)])

        #expect(
            try collectToken("own<file>") == [.keyword(.own), .lessThan, .id, .greaterThan]
        )

        #expect(try collectToken("f32").map(\.description) == ["f32"])
        #expect(try collectToken("f64").map(\.description) == ["f64"])
        #expect(try collectToken("float32") == [.id])
        #expect(try collectToken("float64") == [.id])
    }

    @Test func lexInteger() throws {
        #expect(try collectToken("0") == [.integer])
        #expect(try collectToken("0123") == [.integer])
        #expect(try collectToken("0123a") == [.integer, .id])
    }

    @Test func lexFunction() throws {
        #expect(
            try collectToken("stat-file: func()") == [
                .id, .colon, .keyword(.func), .leftParen, .rightParen,
            ])
        #expect(
            try collectToken("stat-file: func(path: string)") == [
                .id, .colon, .keyword(.func),
                .leftParen, .id, .colon, .keyword(.string), .rightParen,
            ])

        #expect(
            try collectToken("stat-file: func() -> result<stat>") == [
                .id, .colon, .keyword(.func), .leftParen, .rightParen,
                .rArrow, .keyword(.result), .lessThan, .id, .greaterThan,
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
