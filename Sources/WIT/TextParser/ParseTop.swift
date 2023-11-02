extension SourceFileSyntax {
    static func parse(lexer: inout Lexer, fileName: String) throws -> SyntaxNode<SourceFileSyntax> {
        var packageId: PackageNameSyntax?
        if lexer.peek()?.kind == .package {
            packageId = try PackageNameSyntax.parse(lexer: &lexer)
        }

        var items: [ASTItemSyntax] = []
        while !lexer.isEOF {
            let docs = try DocumentsSyntax.parse(lexer: &lexer)
            let item = try ASTItemSyntax.parse(lexer: &lexer, documents: docs)
            items.append(item)
        }

        return .init(syntax: SourceFileSyntax(fileName: fileName, packageId: packageId, items: items))
    }
}

extension PackageNameSyntax {
    static func parse(lexer: inout Lexer) throws -> PackageNameSyntax {
        try lexer.expect(.package)
        let namespace = try Identifier.parse(lexer: &lexer)
        try lexer.expect(.colon)
        let name = try Identifier.parse(lexer: &lexer)
        let version = try lexer.eat(.at) ? Version.parse(lexer: &lexer) : nil
        let rangeStart = namespace.textRange.lowerBound
        let rangeEnd = (version?.textRange ?? name.textRange).upperBound
        return PackageNameSyntax(namespace: namespace, name: name, version: version, textRange: rangeStart..<rangeEnd)
    }
}

extension Identifier {
    static func parse(lexer: inout Lexer) throws -> Identifier {
        guard let token = lexer.lex() else {
            throw ParseError(description: "an identifier expected but got nothing")
        }
        let text: String
        switch token.kind {
        case .id:
            text = lexer.parseText(in: token.textRange)
        case .explicitId:
            text = lexer.parseExplicitIdentifier(in: token.textRange)
        default:
            throw ParseError(description: "an identifier expected but got \(token.kind)")
        }

        return Identifier(text: text, textRange: token.textRange)
    }
}

extension Version {
    static func parse(lexer: inout Lexer) throws -> Version {

        // Parse semantic version: https://semver.org
        let (major, start) = try parseNumericIdentifier(lexer: &lexer)
        try lexer.expect(.period)
        let (minor, _) = try parseNumericIdentifier(lexer: &lexer)
        try lexer.expect(.period)
        let (patch, _) = try parseNumericIdentifier(lexer: &lexer)

        let prerelease = try parseMetaIdentifier(lexer: &lexer, prefix: .minus, acceptLeadingZero: false)
        let buildMetadata = try parseMetaIdentifier(lexer: &lexer, prefix: .plus, acceptLeadingZero: true)

        return Version(
            major: major, minor: minor, patch: patch,
            prerelease: prerelease, buildMetadata: buildMetadata,
            textRange: start.lowerBound..<lexer.cursor.nextIndex
        )

        func parseNumericIdentifier(lexer: inout Lexer) throws -> (Int, TextRange) {
            let token = try lexer.expect(.integer)
            let text = lexer.parseText(in: token.textRange)
            if text.hasPrefix("0"), text.count > 1 {
                throw ParseError(description: "leading zero not accepted")
            }
            // integer token contains only digits and it's guaranteed to be parsable by `Int.init`
            let value = Int(text)!
            return (value, token.textRange)
        }

        func parseAlphanumericIdentifier(lexer: inout Lexer) throws {
            while lexer.eat(.integer) || lexer.eat(.id) || lexer.eat(.minus) {}
        }

        func parseDigits(lexer: inout Lexer) throws {
            try lexer.expect(.integer)
        }

        func parseIdentifier(lexer: inout Lexer, acceptLeadingZero: Bool) throws {
            guard let firstToken = lexer.peek() else {
                throw ParseError(description: "expected an identifier token")
            }

            switch firstToken.kind {
            case .integer:
                if acceptLeadingZero {
                    // <alphanumeric identifier> or <numeric identifier>
                    try parseDigits(lexer: &lexer)
                } else {
                    // <numeric identifier>
                    _ = try parseNumericIdentifier(lexer: &lexer)
                }
                // Consume rest of alphanumeric tokens for the case when
                // it starts with integer
                fallthrough
            case .id, .minus:  // <alphanumeric identifier>
                try parseAlphanumericIdentifier(lexer: &lexer)
            default:
                throw ParseError(description: "an id or integer for pre-release id expected")
            }
        }

        func parseMetaIdentifier(lexer: inout Lexer, prefix: TokenKind, acceptLeadingZero: Bool) throws -> String? {
            guard lexer.eat(prefix) else { return nil }
            let start = lexer.cursor.nextIndex
            func buildResultText(_ lexer: inout Lexer) -> String {
                return lexer.parseText(in: start..<lexer.cursor.nextIndex)
            }

            try parseIdentifier(lexer: &lexer, acceptLeadingZero: acceptLeadingZero)

            while true {
                // If there's no trailing period, then this identifier is
                // done.
                guard lexer.eat(.period) else {
                    return buildResultText(&lexer)
                }

                try parseIdentifier(lexer: &lexer, acceptLeadingZero: acceptLeadingZero)
            }
        }
    }
}

extension ASTItemSyntax {
    static func parse(
        lexer: inout Lexer, documents: DocumentsSyntax
    ) throws -> ASTItemSyntax {
        switch lexer.peek()?.kind {
        case .interface:
            return try .interface(InterfaceSyntax.parse(lexer: &lexer, documents: documents))
        case .world:
            return try .world(WorldSyntax.parse(lexer: &lexer, documents: documents))
        case .use: return try .use(.init(syntax: .parse(lexer: &lexer, documents: documents)))
        default:
            throw ParseError(description: "`world`, `interface` or `use` expected")
        }
    }
}

extension TopLevelUseSyntax {
    static func parse(lexer: inout Lexer, documents: DocumentsSyntax) throws -> TopLevelUseSyntax {
        try lexer.expect(.use)
        let item = try UsePathSyntax.parse(lexer: &lexer)
        var asName: Identifier?
        if lexer.eat(.as) {
            asName = try .parse(lexer: &lexer)
        }
        return TopLevelUseSyntax(item: item, asName: asName)
    }
}

extension UseSyntax {
    static func parse(lexer: inout Lexer) throws -> SyntaxNode<UseSyntax> {
        try lexer.expect(.use)
        let from = try UsePathSyntax.parse(lexer: &lexer)
        try lexer.expect(.period)
        try lexer.expect(.leftBrace)

        var names: [UseNameSyntax] = []
        while !lexer.eat(.rightBrace) {
            var name = try UseNameSyntax(name: .parse(lexer: &lexer))
            if lexer.eat(.as) {
                name.asName = try .parse(lexer: &lexer)
            }
            names.append(name)
            if !lexer.eat(.comma) {
                try lexer.expect(.rightBrace)
                break
            }
        }
        return .init(syntax: UseSyntax(from: from, names: names))
    }
}

extension UsePathSyntax {
    static func parse(lexer: inout Lexer) throws -> UsePathSyntax {
        let id = try Identifier.parse(lexer: &lexer)
        if lexer.eat(.colon) {
            let namespace = id
            let pkgName = try Identifier.parse(lexer: &lexer)
            try lexer.expect(.slash)
            let name = try Identifier.parse(lexer: &lexer)
            let version = lexer.eat(.at) ? try Version.parse(lexer: &lexer) : nil
            return .package(
                id: PackageNameSyntax(
                    namespace: namespace, name: pkgName, version: version,
                    textRange: namespace.textRange.lowerBound..<pkgName.textRange.upperBound
                ),
                name: name
            )
        } else {
            return .id(id)
        }
    }
}

extension DocumentsSyntax {
    static func parse(lexer: inout Lexer) throws -> DocumentsSyntax {
        var comments: [String] = []
        var copy = lexer
        while let token = copy.rawLex() {
            switch token.kind {
            case .whitespace: continue
            case .comment:
                comments.append(lexer.parseText(in: token.textRange))
            default:
                return DocumentsSyntax(comments: comments)
            }
            lexer = copy  // consume comments for real
        }
        return DocumentsSyntax(comments: comments)
    }
}
