extension InterfaceSyntax {
    static func parse(
        lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]
    ) throws -> SyntaxNode<InterfaceSyntax> {
        try lexer.expect(.interface)
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
        switch lexer.peek()?.kind {
        case .type:
            return try .typeDef(.init(syntax: .parse(lexer: &lexer, documents: documents, attributes: attributes)))
        case .flags:
            return try .typeDef(.init(syntax: .parseFlags(lexer: &lexer, documents: documents, attributes: attributes)))
        case .enum:
            return try .typeDef(.init(syntax: .parseEnum(lexer: &lexer, documents: documents, attributes: attributes)))
        case .variant:
            return try .typeDef(.init(syntax: .parseVariant(lexer: &lexer, documents: documents, attributes: attributes)))
        case .resource:
            return try .typeDef(TypeDefSyntax.parseResource(lexer: &lexer, documents: documents, attributes: attributes))
        case .record:
            return try .typeDef(.init(syntax: .parseRecord(lexer: &lexer, documents: documents, attributes: attributes)))
        case .union:
            return try .typeDef(.init(syntax: .parseUnion(lexer: &lexer, documents: documents, attributes: attributes)))
        case .id, .explicitId:
            return try .function(NamedFunctionSyntax.parse(lexer: &lexer, documents: documents))
        case .use:
            return try .use(UseSyntax.parse(lexer: &lexer))
        default:
            throw ParseError(description: "`import`, `export`, `include`, `use`, or type definition")
        }
    }
}
