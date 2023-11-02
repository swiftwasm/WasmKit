enum Parser {
    static func parseList<Item>(
        lexer: inout Lexer, start: TokenKind, end: TokenKind,
        parse: (DocumentsSyntax, inout Lexer) throws -> Item
    ) throws -> [Item] {
        try lexer.expect(start)
        return try parseListTrailer(lexer: &lexer, end: end, parse: parse)
    }

    static func parseListTrailer<Item>(
        lexer: inout Lexer, end: TokenKind,
        parse: (DocumentsSyntax, inout Lexer) throws -> Item
    ) throws -> [Item] {
        var items: [Item] = []
        while true {
            let docs = try DocumentsSyntax.parse(lexer: &lexer)
            if lexer.eat(end) {
                break
            }

            let item = try parse(docs, &lexer)
            items.append(item)

            guard lexer.eat(.comma) else {
                try lexer.expect(end)
                break
            }
        }
        return items
    }
}
