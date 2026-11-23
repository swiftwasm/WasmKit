import Testing

@testable import WIT

@Suite
struct ParseTestsTests {
    @Test func typeUseAll() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    interface types {
                        type t1 = bool;
                        type t2 = u8;
                        type t3 = u16;
                        type t4 = u32;
                        type t5 = u64;
                        type t6 = s8;
                        type t7 = s16;
                        type t8 = s32;
                        type t9 = s64;
                        type t10 = f32;
                        type t11 = f64;
                        type t12 = char;
                        type t13 = string;

                        type t14 = tuple<bool, u8, u16>;
                        type t15 = list<u32>;
                        type t16 = option<i64>;

                        type t17 = result<i32, string>;
                        type t18 = result<_, string>;
                        type t19 = result<i32>;
                        type t20 = result;

                        type t21 = future<i32>;
                        type t22 = future;

                        type t23 = stream<i32, string>;
                        type t24 = stream<_, string>;
                        type t25 = stream<i32>;
                        type t26 = stream;

                        type t27 = own<x>;
                        type t28 = borrow<x>;

                        type t29 = x;
                        type t30 = %x;
                    }
                    """
            )
        )
        let interface = try InterfaceSyntax.parse(lexer: &lexer, documents: .init(comments: []), attributes: [])
        #expect(interface.items.count == 30)
    }

    @Test func typeUseInvalid() throws {
        func parse(_ text: String) throws -> TypeReprSyntax {
            var lexer = Lexer(cursor: .init(input: text))
            return try .parse(lexer: &lexer)
        }
        #expect(throws: (any Error).self) {
            try parse("")
        }
        #expect(throws: (any Error).self) {
            try parse("1")
        }
    }

    @Test(arguments: [("f32", TypeReprSyntax.float32), ("f64", .float64)])
    func floatTypes(text: String, type: TypeReprSyntax) throws {
        var lexer = Lexer(cursor: .init(input: text))
        let parsed = try TypeReprSyntax.parse(lexer: &lexer)
        #expect(parsed == type)
    }

    @Test(arguments: ["float32", "float64"])
    func legacyFloatSpellingsAreTypeNames(text: String) throws {
        var lexer = Lexer(cursor: .init(input: text))
        guard case .name(let name) = try TypeReprSyntax.parse(lexer: &lexer) else {
            Issue.record("\(text) should parse as a type name")
            return
        }
        #expect(name.text == text)
    }

    @Test func typeDefResource() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    resource r1 {
                        // doc comment here
                        f1: func();
                    }
                    """
            )
        )
        let typeDef = try TypeDefSyntax.parseResource(lexer: &lexer, documents: .init(comments: []), attributes: [])
        #expect(typeDef.name.text == "r1")
        guard case .resource(let resource) = typeDef.body else {
            Issue.record("unexpected type kind: \(typeDef.body)")
            return
        }
        #expect(resource.functions.count == 1)
    }

    @Test func typeDefResourceFunctionAttributes() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    resource r1 {
                        @since(version = 0.2.1)
                        f1: func();
                    }
                    """
            )
        )
        let typeDef = try TypeDefSyntax.parseResource(lexer: &lexer, documents: .init(comments: []), attributes: [])
        guard case .resource(let resource) = typeDef.body, case .method(let method)? = resource.functions.first,
            case .since(let since)? = method.attributes.first
        else {
            Issue.record("unexpected type: \(typeDef.body)")
            return
        }
        #expect(method.attributes.count == 1)
        #expect(since.version.description == "0.2.1")
    }

    @Test func typeDefVariant() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    variant r1 {
                        // doc comment here
                        c1, c2,
                        c3(u8)
                    }
                    """
            )
        )
        let typeDef = try TypeDefSyntax.parseVariant(lexer: &lexer, documents: .init(comments: []), attributes: [])
        #expect(typeDef.name.text == "r1")
        guard case .variant(let variant) = typeDef.body else {
            Issue.record("unexpected type kind: \(typeDef.body)")
            return
        }
        #expect(variant.cases.count == 3)
    }

    // MARK: - Identifier grammar

    private func parseWIT(_ text: String) throws {
        var lexer = Lexer(cursor: .init(input: text))
        _ = try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
    }

    @Test(arguments: ["Foo", "aB", "a2B", "foo--bar", "-foo", "foo-", "%Foo"])
    func nonCanonicalIdentifierIsRejected(name: String) throws {
        #expect(throws: ParseError.self) {
            try parseWIT("package test:p;\nworld w { record \(name) { x: s64 } }")
        }
    }

    @Test(arguments: ["foo", "foo-bar", "FOO", "FOO-BAR", "FOO-bar", "foo-2", "size-1", "a-2b", "a2b"])
    func canonicalIdentifierIsAccepted(name: String) throws {
        try parseWIT("package test:p;\nworld w { record \(name) { x: s64 } }")
    }

    /// `TypeReprSyntax.parse` reads type references without `Identifier.parse`.
    @Test func nonCanonicalTypeReferenceIsRejected() throws {
        #expect(throws: ParseError.self) {
            try parseWIT("package test:p;\nworld w { record r { f: someTypeRef } }")
        }
    }
}
