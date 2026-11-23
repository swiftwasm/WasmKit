extension InterfaceSyntax {
    static func parse(
        lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]
    ) throws -> SyntaxNode<InterfaceSyntax> {
        try lexer.expect(.keyword(.interface))
        let name = try Identifier.parse(lexer: &lexer)
        let items = try parseItems(lexer: &lexer)
        return .init(
            syntax: InterfaceSyntax(
                documents: documents, attributes: attributes, name: name, items: items
            ))
    }

    static func parseItems(lexer: inout Lexer) throws -> [InterfaceItemSyntax] {
        try lexer.expect(.leftBrace)
        var items: [InterfaceItemSyntax] = []
        while true {
            let docs = try DocumentsSyntax.parse(lexer: &lexer)
            if lexer.eat(.rightBrace) {
                break
            }
            let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
            items.append(try InterfaceItemSyntax.parse(lexer: &lexer, documents: docs, attributes: attributes))
        }
        return items
    }
}

extension InterfaceItemSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> InterfaceItemSyntax {
        guard let token = lexer.peek() else {
            throw ParseError(description: "`type`, `resource` or `func` expected but got nothing")
        }
        switch token.kind {
        case .keyword(.type):
            return try .typeDef(.init(syntax: .parse(lexer: &lexer, documents: documents, attributes: attributes)))
        case .keyword(.flags):
            return try .typeDef(.init(syntax: .parseFlags(lexer: &lexer, documents: documents, attributes: attributes)))
        case .keyword(.enum):
            return try .typeDef(.init(syntax: .parseEnum(lexer: &lexer, documents: documents, attributes: attributes)))
        case .keyword(.variant):
            return try .typeDef(.init(syntax: .parseVariant(lexer: &lexer, documents: documents, attributes: attributes)))
        case .keyword(.resource):
            return try .typeDef(TypeDefSyntax.parseResource(lexer: &lexer, documents: documents, attributes: attributes))
        case .keyword(.record):
            return try .typeDef(.init(syntax: .parseRecord(lexer: &lexer, documents: documents, attributes: attributes)))
        case .keyword(.union):
            return try .typeDef(.init(syntax: .parseUnion(lexer: &lexer, documents: documents, attributes: attributes)))
        case .id, .explicitId:
            return try .function(NamedFunctionSyntax.parse(lexer: &lexer, documents: documents, attributes: attributes))
        case .keyword(.use):
            return try .use(UseSyntax.parse(lexer: &lexer, attributes: attributes))
        default:
            throw ParseError(description: "`type`, `resource` or `func` expected but got \(token.kind)")
        }
    }
}
