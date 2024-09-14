import XCTest

@testable import WIT

class ParseTopTests: XCTestCase {

    func testASTEmpty() throws {
        var lexer = Lexer(cursor: .init(input: ""))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        XCTAssertNil(ast.packageId)
        XCTAssertEqual(ast.items.count, 0)
    }

    func testASTEndingWithNewline() throws {
        var lexer = Lexer(cursor: .init(input: "\n"))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        XCTAssertNil(ast.packageId)
        XCTAssertEqual(ast.items.count, 0)
    }

    func testASTWithPackageId() throws {
        var lexer = Lexer(cursor: .init(input: "package foo:bar"))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        XCTAssertNotNil(ast.packageId)
    }

    func testASTWithItem() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    interface x {}
                    world y {}
                    use z
                    """))
        let ast = try SourceFileSyntax.parse(lexer: &lexer)
        XCTAssertEqual(ast.items.count, 3)
    }

    func testASTWithInvalidItem() throws {
        var lexer = Lexer(cursor: .init(input: "."))
        XCTAssertThrowsError(try SourceFileSyntax.parse(lexer: &lexer))
    }

    func parsePackageName(_ text: String) throws -> PackageNameSyntax {
        var lexer = Lexer(cursor: .init(input: text))
        return try PackageNameSyntax.parse(lexer: &lexer)
    }

    func testPackageName() throws {
        let packageId = try parsePackageName("package foo:bar")
        XCTAssertEqual(packageId.namespace.text, "foo")
        XCTAssertEqual(packageId.name.text, "bar")
    }

    func testPackageNameWithVersion() throws {
        let packageId = try parsePackageName("package foo:bar@1.0.0")
        XCTAssertEqual(packageId.namespace.text, "foo")
        XCTAssertEqual(packageId.name.text, "bar")
    }

    func testIdentifier() throws {
        var lexer = Lexer(cursor: .init(input: "xyz"))
        let id = try Identifier.parse(lexer: &lexer)
        XCTAssertEqual(id.text, "xyz")
    }

    func testIdentifierEmpty() throws {
        var lexer = Lexer(cursor: .init(input: ""))
        XCTAssertThrowsError(try Identifier.parse(lexer: &lexer))
    }

    func testIdentifierExplicit() throws {
        var lexer = Lexer(cursor: .init(input: "%abcd"))
        let id = try Identifier.parse(lexer: &lexer)
        XCTAssertEqual(id.text, "abcd")
    }

    func testIdentifierWithInvalidToken() throws {
        var lexer = Lexer(cursor: .init(input: "."))
        XCTAssertThrowsError(try Identifier.parse(lexer: &lexer))
    }

    func testDocuments() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    // comment here
                    /* multi-line
                    comment */
                    """))
        let docs = try DocumentsSyntax.parse(lexer: &lexer)
        XCTAssertEqual(docs.comments.count, 2)
        XCTAssertEqual(
            docs.comments,
            [
                "// comment here\n",
                """
                /* multi-line
                comment */
                """,
            ])
    }

    func testDocumentsEmpty() throws {
        var lexer = Lexer(cursor: .init(input: ""))
        let docs = try DocumentsSyntax.parse(lexer: &lexer)
        XCTAssertEqual(docs.comments.count, 0)
    }

    func testTopLevelUseAs() throws {
        var lexer = Lexer(cursor: .init(input: "use abc as xyz"))
        let use = try TopLevelUseSyntax.parse(lexer: &lexer, documents: .init(comments: []), attributes: [])
        XCTAssertEqual(use.item.name.text, "abc")
        XCTAssertEqual(use.asName?.text, "xyz")
    }

    func testUse() throws {
        var lexer = Lexer(cursor: .init(input: "use abc.{x, y, z}"))
        let use = try UseSyntax.parse(lexer: &lexer)
        XCTAssertEqual(use.from.name.text, "abc")
        XCTAssertEqual(use.names.map(\.name.text), ["x", "y", "z"])
        XCTAssertEqual(use.names.map(\.asName?.text), [nil, nil, nil])
    }

    func testUseAs() throws {
        var lexer = Lexer(cursor: .init(input: "use abc.{x as d, y as e, z}"))
        let use = try UseSyntax.parse(lexer: &lexer)
        XCTAssertEqual(use.from.name.text, "abc")
        XCTAssertEqual(use.names.map(\.name.text), ["x", "y", "z"])
        XCTAssertEqual(use.names.map(\.asName?.text), ["d", "e", nil])
    }

    func testUsePath() throws {
        var lexer = Lexer(cursor: .init(input: "use ns1:pkg1/item1@1.0.0"))
        let use = try TopLevelUseSyntax.parse(lexer: &lexer, documents: .init(comments: []), attributes: [])
        XCTAssertEqual(use.item.name.text, "item1")
        guard case let .package(id, _) = use.item else {
            XCTFail("expected package but got \(use.item)")
            return
        }
        XCTAssertEqual(id.namespace.text, "ns1")
        XCTAssertEqual(id.name.text, "pkg1")
    }

    func testAttributeSince() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    @since(version = 1.0.0)
                    @since(version = 1.0.0, feature = foo-bar)
                    """
            ))
        let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
        guard attributes.count == 2 else {
            XCTFail("expected 2 attributes but got \(attributes)")
            return
        }
        do {
            guard case let .since(attribute) = attributes[0] else {
                XCTFail("expected since but got \(attributes[0])")
                return
            }
            XCTAssertEqual(attribute.version.description, "1.0.0")
            XCTAssertEqual(attribute.feature?.text, nil)
        }
        do {
            guard case let .since(attribute) = attributes[1] else {
                XCTFail("expected since but got \(attributes[1])")
                return
            }
            XCTAssertEqual(attribute.version.description, "1.0.0")
            XCTAssertEqual(attribute.feature?.text, "foo-bar")
        }
    }

    func testAttributeUnstable() throws {
        var lexer = Lexer(cursor: .init(input: "@unstable(feature = foo)"))
        let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
        XCTAssertEqual(attributes.count, 1)
        guard case let .unstable(attribute) = attributes.first else {
            XCTFail("expected since but got \(attributes)")
            return
        }
        XCTAssertEqual(attribute.feature.text, "foo")
    }

    func testAttributeDeprecated() throws {
        var lexer = Lexer(cursor: .init(input: "@deprecated(version = 1.0.3)"))
        let attributes = try AttributeSyntax.parseItems(lexer: &lexer)
        XCTAssertEqual(attributes.count, 1)
        guard case let .deprecated(attribute) = attributes.first else {
            XCTFail("expected since but got \(attributes)")
            return
        }
        XCTAssertEqual(attribute.version.description, "1.0.3")
    }
}

extension SourceFileSyntax {
    static func parse(lexer: inout Lexer) throws -> SyntaxNode<SourceFileSyntax> {
        try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
    }
}
