extension WorldSyntax {
    static func parse(
        lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]
    ) throws -> SyntaxNode<WorldSyntax> {
        try lexer.expect(.world)
        let name = try Identifier.parse(lexer: &lexer)
        let items = try parseItems(lexer: &lexer)
        return .init(
            syntax: WorldSyntax(
                documents: documents, attributes: attributes, name: name, items: items
            ))
    }

    static func parseItems(lexer: inout Lexer) throws -> [WorldItemSyntax] {
        try lexer.expect(.leftBrace)
        var items: [WorldItemSyntax] = []
        while true {
            let docs = try DocumentsSyntax.parse(lexer: &lexer)
            if lexer.eat(.rightBrace) {
                break
            }
            let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
            items.append(try WorldItemSyntax.parse(lexer: &lexer, documents: docs, attributes: attributes))
        }
        return items
    }
}

extension WorldItemSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> WorldItemSyntax {
        switch lexer.peek()?.kind {
        case .import:
            return try .import(.parse(lexer: &lexer, documents: documents, attributes: attributes))
        case .export:
            return try .export(.parse(lexer: &lexer, documents: documents, attributes: attributes))
        case .use:
            return try .use(UseSyntax.parse(lexer: &lexer))
        case .type:
            return try .type(.init(syntax: .parse(lexer: &lexer, documents: documents, attributes: attributes)))
        case .flags:
            return try .type(.init(syntax: .parseFlags(lexer: &lexer, documents: documents, attributes: attributes)))
        case .enum:
            return try .type(.init(syntax: .parseEnum(lexer: &lexer, documents: documents, attributes: attributes)))
        case .variant:
            return try .type(.init(syntax: .parseVariant(lexer: &lexer, documents: documents, attributes: attributes)))
        case .resource:
            return try .type(TypeDefSyntax.parseResource(lexer: &lexer, documents: documents, attributes: attributes))
        case .record:
            return try .type(.init(syntax: .parseRecord(lexer: &lexer, documents: documents, attributes: attributes)))
        case .union:
            return try .type(.init(syntax: .parseUnion(lexer: &lexer, documents: documents, attributes: attributes)))
        case .include:
            return try .include(.parse(lexer: &lexer, attributes: attributes))
        default:
            throw ParseError(description: "`type`, `resource` or `func` expected")
        }
    }
}

extension ImportSyntax {
    static func parse(
        lexer: inout Lexer,
        documents: DocumentsSyntax,
        attributes: [AttributeSyntax]
    ) throws -> ImportSyntax {
        try lexer.expect(.import)
        let kind = try ExternKindSyntax.parse(lexer: &lexer)
        return ImportSyntax(documents: documents, attributes: attributes, kind: kind)
    }
}

extension ExportSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> ExportSyntax {
        try lexer.expect(.export)
        let kind = try ExternKindSyntax.parse(lexer: &lexer)
        return ExportSyntax(documents: documents, attributes: attributes, kind: kind)
    }
}

extension ExternKindSyntax {
    static func parse(lexer: inout Lexer) throws -> ExternKindSyntax {
        var clone = lexer
        let id = try Identifier.parse(lexer: &clone)
        if clone.eat(.colon) {
            switch clone.peek()?.kind {
            case .func:
                // import foo: func(...);
                lexer = clone
                let result: ExternKindSyntax = try .function(id, .parse(lexer: &lexer))
                try lexer.expectSemicolon()
                return result
            case .interface:
                // import foo: interface { ... }
                try clone.expect(.interface)
                lexer = clone
                return try .interface(id, InterfaceSyntax.parseItems(lexer: &lexer))
            default: break
            }
        }
        // import foo:bar/baz;
        let result: ExternKindSyntax = try .path(.parse(lexer: &lexer))
        try lexer.expectSemicolon()
        return result
    }
}

extension IncludeSyntax {
    static func parse(lexer: inout Lexer, attributes: [AttributeSyntax]) throws -> IncludeSyntax {
        try lexer.expect(.include)
        let from = try UsePathSyntax.parse(lexer: &lexer)

        var names: [IncludeNameSyntax] = []
        if lexer.eat(.with) {
            names = try Parser.parseList(lexer: &lexer, start: .leftBrace, end: .rightBrace) { _, lexer in
                let name = try Identifier.parse(lexer: &lexer)
                try lexer.expect(.as)
                let asName = try Identifier.parse(lexer: &lexer)
                return IncludeNameSyntax(name: name, asName: asName)
            }
        }
        try lexer.expectSemicolon()
        return IncludeSyntax(attributes: attributes, from: from, names: names)
    }
}
