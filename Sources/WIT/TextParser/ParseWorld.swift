extension WorldSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax) throws -> SyntaxNode<WorldSyntax> {
        try lexer.expect(.world)
        let name = try Identifier.parse(lexer: &lexer)
        let items = try parseItems(lexer: &lexer)
        return .init(syntax: WorldSyntax(documents: documents, name: name, items: items))
    }

    static func parseItems(lexer: inout Lexer) throws -> [WorldItemSyntax] {
        try lexer.expect(.leftBrace)
        var items: [WorldItemSyntax] = []
        while true {
            let docs = try DocumentsSyntax.parse(lexer: &lexer)
            if lexer.eat(.rightBrace) {
                break
            }
            items.append(try WorldItemSyntax.parse(lexer: &lexer, documents: docs))
        }
        return items
    }
}

extension WorldItemSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax) throws -> WorldItemSyntax {
        switch lexer.peek()?.kind {
        case .import:
            return try .import(.parse(lexer: &lexer, documents: documents))
        case .export:
            return try .export(.parse(lexer: &lexer, documents: documents))
        case .use:
            return try .use(UseSyntax.parse(lexer: &lexer))
        case .type:
            return try .type(.init(syntax: .parse(lexer: &lexer, documents: documents)))
        case .flags:
            return try .type(.init(syntax: .parseFlags(lexer: &lexer, documents: documents)))
        case .enum:
            return try .type(.init(syntax: .parseEnum(lexer: &lexer, documents: documents)))
        case .variant:
            return try .type(.init(syntax: .parseVariant(lexer: &lexer, documents: documents)))
        case .resource:
            return try .type(TypeDefSyntax.parseResource(lexer: &lexer, documents: documents))
        case .record:
            return try .type(.init(syntax: .parseRecord(lexer: &lexer, documents: documents)))
        case .union:
            return try .type(.init(syntax: .parseUnion(lexer: &lexer, documents: documents)))
        case .include:
            return try .include(.parse(lexer: &lexer))
        default:
            throw ParseError(description: "`type`, `resource` or `func` expected")
        }
    }
}

extension ImportSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax) throws -> ImportSyntax {
        try lexer.expect(.import)
        let kind = try ExternKindSyntax.parse(lexer: &lexer)
        return ImportSyntax(documents: documents, kind: kind)
    }
}

extension ExportSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax) throws -> ExportSyntax {
        try lexer.expect(.export)
        let kind = try ExternKindSyntax.parse(lexer: &lexer)
        return ExportSyntax(documents: documents, kind: kind)
    }
}

extension ExternKindSyntax {
    static func parse(lexer: inout Lexer) throws -> ExternKindSyntax {
        var clone = lexer
        let id = try Identifier.parse(lexer: &clone)
        if clone.eat(.colon) {
            switch clone.peek()?.kind {
            case .func:
                // import foo: func(...)
                lexer = clone
                return try .function(id, .parse(lexer: &lexer))
            case .interface:
                // import foo: interface { ... }
                try clone.expect(.interface)
                lexer = clone
                return try .interface(id, InterfaceSyntax.parseItems(lexer: &lexer))
            default: break
            }
        }
        // import foo:bar/baz
        return try .path(.parse(lexer: &lexer))
    }
}

extension IncludeSyntax {
    static func parse(lexer: inout Lexer) throws -> IncludeSyntax {
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
        return IncludeSyntax(from: from, names: names)
    }
}
