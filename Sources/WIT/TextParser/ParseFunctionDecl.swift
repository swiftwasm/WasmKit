extension ResourceFunctionSyntax {
    static func parse(
        lexer: inout Lexer,
        documents: DocumentsSyntax,
        attributes: [AttributeSyntax]
    ) throws -> ResourceFunctionSyntax {
        guard let token = lexer.peek() else {
            throw ParseError(description: "`constructor` or identifier expected but got nothing")
        }
        switch token.kind {
        case .constructor:
            try lexer.expect(.constructor)
            try lexer.expect(.leftParen)

            let funcStart = lexer.cursor.nextIndex
            let params = try Parser.parseListTrailer(
                lexer: &lexer, end: .rightParen
            ) { docs, lexer in
                let start = lexer.cursor.nextIndex
                let name = try Identifier.parse(lexer: &lexer)
                try lexer.expect(.colon)
                let type = try TypeReprSyntax.parse(lexer: &lexer)
                return ParameterSyntax(name: name, type: type, textRange: start..<lexer.cursor.nextIndex)
            }
            try lexer.expectSemicolon()
            return .constructor(
                .init(
                    syntax: NamedFunctionSyntax(
                        documents: documents,
                        attributes: attributes,
                        name: Identifier(text: "constructor", textRange: token.textRange),
                        function: FunctionSyntax(
                            parameters: params,
                            results: .named([]),
                            textRange: funcStart..<lexer.cursor.nextIndex
                        )
                    )
                )
            )
        case .explicitId, .id:
            let name = try Identifier.parse(lexer: &lexer)
            try lexer.expect(.colon)
            let ctor: (SyntaxNode<NamedFunctionSyntax>) -> ResourceFunctionSyntax
            if lexer.eat(.static) {
                ctor = ResourceFunctionSyntax.static
            } else {
                ctor = ResourceFunctionSyntax.method
            }
            let function = try FunctionSyntax.parse(lexer: &lexer)
            try lexer.expectSemicolon()
            return ctor(
                .init(
                    syntax:
                        NamedFunctionSyntax(
                            documents: documents,
                            attributes: attributes,
                            name: name,
                            function: function
                        )
                )
            )
        default:
            throw ParseError(description: "`constructor` or identifier expected but got \(token.kind)")
        }
    }
}

extension FunctionSyntax {
    static func parse(lexer: inout Lexer) throws -> FunctionSyntax {
        func parseParameters(lexer: inout Lexer, leftParen: Bool) throws -> ParameterList {
            if leftParen {
                try lexer.expect(.leftParen)
            }
            return try Parser.parseListTrailer(lexer: &lexer, end: .rightParen) { docs, lexer in
                let start = lexer.cursor.nextIndex
                let name = try Identifier.parse(lexer: &lexer)
                try lexer.expect(.colon)
                let type = try TypeReprSyntax.parse(lexer: &lexer)
                return ParameterSyntax(name: name, type: type, textRange: start..<lexer.cursor.nextIndex)
            }
        }

        let start = lexer.cursor.nextIndex
        try lexer.expect(.func)
        let params = try parseParameters(lexer: &lexer, leftParen: true)
        let results: ResultListSyntax
        if lexer.eat(.rArrow) {
            if lexer.eat(.leftParen) {
                results = .named(try parseParameters(lexer: &lexer, leftParen: false))
            } else {
                results = try .anon(TypeReprSyntax.parse(lexer: &lexer))
            }
        } else {
            results = .named([])
        }

        return FunctionSyntax(parameters: params, results: results, textRange: start..<lexer.cursor.nextIndex)
    }
}

extension NamedFunctionSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax) throws -> SyntaxNode<NamedFunctionSyntax> {
        let name = try Identifier.parse(lexer: &lexer)
        try lexer.expect(.colon)
        let function = try FunctionSyntax.parse(lexer: &lexer)
        try lexer.expectSemicolon()
        return .init(syntax: NamedFunctionSyntax(documents: documents, attributes: [], name: name, function: function))
    }
}
