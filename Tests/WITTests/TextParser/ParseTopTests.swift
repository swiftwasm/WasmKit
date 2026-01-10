import Testing

@testable import WIT

@Suite
struct ParseTopTests {

    @Test func aSTEmpty() throws {
        var lexer = Lexer(cursor: .init(input: ""))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        #expect(ast.packageId == nil)
        #expect(ast.items.count == 0)
    }

    @Test func aSTEndingWithNewline() throws {
        var lexer = Lexer(cursor: .init(input: "\n"))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        #expect(ast.packageId == nil)
        #expect(ast.items.count == 0)
    }

    @Test func aSTWithPackageId() throws {
        var lexer = Lexer(cursor: .init(input: "package foo:bar"))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        #expect(ast.packageId != nil)
    }

    @Test func aSTWithItem() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    interface x {}
                    world y {}
                    use z
                    """))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        #expect(ast.items.count == 3)
    }

    @Test func aSTWithInvalidItem() throws {
        var lexer = Lexer(cursor: .init(input: "."))
        #expect(throws: (any Error).self) {
            try SourceFileSyntax.parse(lexer: &lexer)
        }
    }

    func parsePackageName(_ text: String) throws -> PackageNameSyntax {
        var lexer = Lexer(cursor: .init(input: text))
        return try PackageNameSyntax.parse(lexer: &lexer)
    }

    @Test func packageName() throws {
        let packageId = try parsePackageName("package foo:bar")
        #expect(packageId.namespace.text == "foo")
        #expect(packageId.name.text == "bar")
    }

    @Test func packageNameWithVersion() throws {
        let packageId = try parsePackageName("package foo:bar@1.0.0")
        #expect(packageId.namespace.text == "foo")
        #expect(packageId.name.text == "bar")
    }

    @Test func identifier() throws {
        var lexer = Lexer(cursor: .init(input: "xyz"))
        let id = try Identifier.parse(lexer: &lexer)
        #expect(id.text == "xyz")
    }

    @Test func identifierEmpty() throws {
        var lexer = Lexer(cursor: .init(input: ""))
        #expect(throws: (any Error).self) {
            try Identifier.parse(lexer: &lexer)
        }
    }

    @Test func identifierExplicit() throws {
        var lexer = Lexer(cursor: .init(input: "%abcd"))
        let id = try Identifier.parse(lexer: &lexer)
        #expect(id.text == "abcd")
    }

    @Test func identifierWithInvalidToken() throws {
        var lexer = Lexer(cursor: .init(input: "."))
        #expect(throws: (any Error).self) {
            try Identifier.parse(lexer: &lexer)
        }
    }

    @Test func documents() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    // comment here
                    /* multi-line
                    comment */
                    """))
        let docs = try DocumentsSyntax.parse(lexer: &lexer)
        #expect(docs.comments.count == 2)
        #expect(
            docs.comments == [
                "// comment here\n",
                """
                /* multi-line
                comment */
                """,
            ])
    }

    @Test func documentsEmpty() throws {
        var lexer = Lexer(cursor: .init(input: ""))
        let docs = try DocumentsSyntax.parse(lexer: &lexer)
        #expect(docs.comments.count == 0)
    }

    @Test func topLevelUseAs() throws {
        var lexer = Lexer(cursor: .init(input: "use abc as xyz"))
        let use = try TopLevelUseSyntax.parse(lexer: &lexer, documents: .init(comments: []), attributes: [])
        #expect(use.item.name.text == "abc")
        #expect(use.asName?.text == "xyz")
    }

    @Test func use() throws {
        var lexer = Lexer(cursor: .init(input: "use abc.{x, y, z}"))
        let use = try UseSyntax.parse(lexer: &lexer)
        #expect(use.from.name.text == "abc")
        #expect(use.names.map(\.name.text) == ["x", "y", "z"])
        #expect(use.names.map(\.asName?.text) == [nil, nil, nil])
    }

    @Test func useAs() throws {
        var lexer = Lexer(cursor: .init(input: "use abc.{x as d, y as e, z}"))
        let use = try UseSyntax.parse(lexer: &lexer)
        #expect(use.from.name.text == "abc")
        #expect(use.names.map(\.name.text) == ["x", "y", "z"])
        #expect(use.names.map(\.asName?.text) == ["d", "e", nil])
    }

    @Test func usePath() throws {
        var lexer = Lexer(cursor: .init(input: "use ns1:pkg1/item1@1.0.0"))
        let use = try TopLevelUseSyntax.parse(lexer: &lexer, documents: .init(comments: []), attributes: [])
        #expect(use.item.name.text == "item1")
        guard case .package(let id, _) = use.item else {
            Issue.record("expected package but got \(use.item)")
            return
        }
        #expect(id.namespace.text == "ns1")
        #expect(id.name.text == "pkg1")
    }

    @Test func attributeSince() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    @since(version = 1.0.0)
                    @since(version = 1.0.0, feature = foo-bar)
                    """
            ))
        let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
        guard attributes.count == 2 else {
            Issue.record("expected 2 attributes but got \(attributes)")
            return
        }
        do {
            guard case .since(let attribute) = attributes[0] else {
                Issue.record("expected since but got \(attributes[0])")
                return
            }
            #expect(attribute.version.description == "1.0.0")
            #expect(attribute.feature?.text == nil)
        }
        do {
            guard case .since(let attribute) = attributes[1] else {
                Issue.record("expected since but got \(attributes[1])")
                return
            }
            #expect(attribute.version.description == "1.0.0")
            #expect(attribute.feature?.text == "foo-bar")
        }
    }

    @Test func attributeUnstable() throws {
        var lexer = Lexer(cursor: .init(input: "@unstable(feature = foo)"))
        let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
        #expect(attributes.count == 1)
        guard case .unstable(let attribute) = attributes.first else {
            Issue.record("expected since but got \(attributes)")
            return
        }
        #expect(attribute.feature.text == "foo")
    }

    @Test func attributeDeprecated() throws {
        var lexer = Lexer(cursor: .init(input: "@deprecated(version = 1.0.3)"))
        let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
        #expect(attributes.count == 1)
        guard case .deprecated(let attribute) = attributes.first else {
            Issue.record("expected since but got \(attributes)")
            return
        }
        #expect(attribute.version.description == "1.0.3")
    }
}

extension SourceFileSyntax {
    static func parse(lexer: inout Lexer) throws -> SyntaxNode<SourceFileSyntax> {
        try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
    }
}
