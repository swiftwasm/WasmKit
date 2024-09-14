extension TypeReprSyntax {
    static func parse(lexer: inout Lexer) throws -> TypeReprSyntax {
        guard let token = lexer.next() else {
            throw ParseError(description: "a type expected")
        }
        switch token.kind {
        case .bool: return .bool
        case .u8: return .u8
        case .u16: return .u16
        case .u32: return .u32
        case .u64: return .u64
        case .s8: return .s8
        case .s16: return .s16
        case .s32: return .s32
        case .s64: return .s64
        case .float32: return .float32
        case .float64: return .float64
        case .char: return .char
        case .string_: return .string

        // tuple<T, U, ...>
        case .tuple:
            let types = try Parser.parseList(
                lexer: &lexer, start: .lessThan, end: .greaterThan
            ) { try TypeReprSyntax.parse(lexer: &$1) }
            return .tuple(types)

        // list<T>
        case .list:
            try lexer.expect(.lessThan)
            let type = try TypeReprSyntax.parse(lexer: &lexer)
            try lexer.expect(.greaterThan)
            return .list(type)

        // option<T>
        case .option_:
            try lexer.expect(.lessThan)
            let type = try TypeReprSyntax.parse(lexer: &lexer)
            try lexer.expect(.greaterThan)
            return .option(type)

        // result<T, E>
        // result<_, E>
        // result<T>
        // result
        case .result_:
            var ok: TypeReprSyntax?
            var error: TypeReprSyntax?
            if lexer.eat(.lessThan) {
                if lexer.eat(.underscore) {
                    try lexer.expect(.comma)
                    error = try TypeReprSyntax.parse(lexer: &lexer)
                } else {
                    ok = try TypeReprSyntax.parse(lexer: &lexer)
                    if lexer.eat(.comma) {
                        error = try TypeReprSyntax.parse(lexer: &lexer)
                    }
                }
                try lexer.expect(.greaterThan)
            }
            return .result(ResultSyntax(ok: ok, error: error))

        // future<T>
        // future
        case .future:
            var type: TypeReprSyntax?
            if lexer.eat(.lessThan) {
                type = try TypeReprSyntax.parse(lexer: &lexer)
                try lexer.expect(.greaterThan)
            }
            return .future(type)

        // stream<T, Z>
        // stream<_, Z>
        // stream<T>
        // stream
        case .stream:
            var element: TypeReprSyntax?
            var end: TypeReprSyntax?
            if lexer.eat(.lessThan) {
                if lexer.eat(.underscore) {
                    try lexer.expect(.comma)
                    end = try TypeReprSyntax.parse(lexer: &lexer)
                } else {
                    element = try TypeReprSyntax.parse(lexer: &lexer)
                    if lexer.eat(.comma) {
                        end = try TypeReprSyntax.parse(lexer: &lexer)
                    }
                }
                try lexer.expect(.greaterThan)
            }
            return .stream(StreamSyntax(element: element, end: end))

        // own<T>
        case .own:
            try lexer.expect(.lessThan)
            let resource = try Identifier.parse(lexer: &lexer)
            try lexer.expect(.greaterThan)
            return .handle(.own(resource: resource))

        // borrow<T>
        case .borrow:
            try lexer.expect(.lessThan)
            let resource = try Identifier.parse(lexer: &lexer)
            try lexer.expect(.greaterThan)
            return .handle(.borrow(resource: resource))

        // `foo`
        case .id:
            return .name(
                Identifier(
                    text: lexer.parseText(in: token.textRange),
                    textRange: token.textRange
                ))
        // `%foo`
        case .explicitId:
            return .name(
                Identifier(
                    text: lexer.parseExplicitIdentifier(in: token.textRange),
                    textRange: token.textRange
                ))
        case let tokenKind:
            throw ParseError(description: "unknown type \(String(describing: tokenKind))")
        }
    }
}

extension TypeDefSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> TypeDefSyntax {
        try lexer.expect(.type)
        let name = try Identifier.parse(lexer: &lexer)
        try lexer.expect(.equals)
        let repr = try TypeReprSyntax.parse(lexer: &lexer)
        try lexer.expectSemicolon()
        return TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: .alias(TypeAliasSyntax(typeRepr: repr)))
    }

    static func parseFlags(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> TypeDefSyntax {
        try lexer.expect(.flags)
        let name = try Identifier.parse(lexer: &lexer)
        let body = try TypeDefBodySyntax.flags(
            FlagsSyntax(
                flags: Parser.parseList(
                    lexer: &lexer,
                    start: .leftBrace, end: .rightBrace
                ) { docs, lexer in
                    let name = try Identifier.parse(lexer: &lexer)
                    return FlagSyntax(documents: docs, name: name)
                }
            ))
        return TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: body)
    }

    static func parseResource(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> SyntaxNode<TypeDefSyntax> {
        try lexer.expect(.resource)
        let name = try Identifier.parse(lexer: &lexer)
        var functions: [ResourceFunctionSyntax] = []
        if lexer.eat(.leftBrace) {
            while !lexer.eat(.rightBrace) {
                let docs = try DocumentsSyntax.parse(lexer: &lexer)
                functions.append(try ResourceFunctionSyntax.parse(lexer: &lexer, documents: docs, attributes: []))
            }
        } else {
            try lexer.expectSemicolon()
        }
        let body = TypeDefBodySyntax.resource(ResourceSyntax(functions: functions))
        return .init(syntax: TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: body))
    }

    static func parseRecord(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> TypeDefSyntax {
        try lexer.expect(.record)
        let name = try Identifier.parse(lexer: &lexer)
        let body = try TypeDefBodySyntax.record(
            RecordSyntax(
                fields: Parser.parseList(
                    lexer: &lexer,
                    start: .leftBrace, end: .rightBrace
                ) { docs, lexer in
                    let start = lexer.cursor.nextIndex
                    let name = try Identifier.parse(lexer: &lexer)
                    try lexer.expect(.colon)
                    let type = try TypeReprSyntax.parse(lexer: &lexer)
                    return FieldSyntax(documents: docs, name: name, type: type, textRange: start..<lexer.cursor.nextIndex)
                }
            ))
        return TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: body)
    }

    static func parseVariant(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> TypeDefSyntax {
        try lexer.expect(.variant)
        let name = try Identifier.parse(lexer: &lexer)
        let body = try TypeDefBodySyntax.variant(
            VariantSyntax(
                cases: Parser.parseList(
                    lexer: &lexer,
                    start: .leftBrace, end: .rightBrace
                ) { docs, lexer in
                    let start = lexer.cursor.nextIndex
                    let name = try Identifier.parse(lexer: &lexer)
                    var payloadType: TypeReprSyntax?
                    if lexer.eat(.leftParen) {
                        payloadType = try TypeReprSyntax.parse(lexer: &lexer)
                        try lexer.expect(.rightParen)
                    }
                    return CaseSyntax(documents: docs, name: name, type: payloadType, textRange: start..<lexer.cursor.nextIndex)
                },
                textRange: name.textRange
            ))
        return TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: body)
    }

    static func parseUnion(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> TypeDefSyntax {
        try lexer.expect(.union)
        let name = try Identifier.parse(lexer: &lexer)
        let body = try TypeDefBodySyntax.union(
            UnionSyntax(
                cases: Parser.parseList(
                    lexer: &lexer,
                    start: .leftBrace, end: .rightBrace
                ) { docs, lexer in
                    let start = lexer.cursor.nextIndex
                    let type = try TypeReprSyntax.parse(lexer: &lexer)
                    return UnionCaseSyntax(documents: docs, type: type, textRange: start..<lexer.cursor.nextIndex)
                },
                textRange: name.textRange
            ))
        return TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: body)
    }

    static func parseEnum(lexer: inout Lexer, documents: DocumentsSyntax, attributes: [AttributeSyntax]) throws -> TypeDefSyntax {
        try lexer.expect(.enum)
        let name = try Identifier.parse(lexer: &lexer)
        let body = try TypeDefBodySyntax.enum(
            EnumSyntax(
                cases: Parser.parseList(
                    lexer: &lexer,
                    start: .leftBrace, end: .rightBrace
                ) { docs, lexer in
                    let start = lexer.cursor.nextIndex
                    let name = try Identifier.parse(lexer: &lexer)
                    return EnumCaseSyntax(documents: docs, name: name, textRange: start..<lexer.cursor.nextIndex)
                },
                textRange: name.textRange
            ))
        return TypeDefSyntax(documents: documents, attributes: attributes, name: name, body: body)
    }
}
