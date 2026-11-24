import Testing

@testable import WIT

@Suite
struct SemicolonEnforcementTests {

    private func parseDoc(_ input: String) throws -> SyntaxNode<SourceFileSyntax> {
        var lexer = Lexer(cursor: .init(input: input))
        return try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
    }

    @Test(arguments: [
        ("package foo:bar\n\ninterface i {}", "semicolon expected but got interface"),
        ("package foo:bar;\n\nuse a:b/c", "semicolon expected but got nothing"),
        ("package foo:bar;\n\ninterface i {\n  f: func()\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\ninterface i {\n  type t = u8\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\nworld w {\n  export f: func()\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\nworld w {\n  import a:b/c\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\nworld w {\n  include a:b/c\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\ninterface i {\n  resource r {\n    f: func()\n  }\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\ninterface i {\n  resource r {\n    constructor()\n  }\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\ninterface i {\n  resource r\n}", "semicolon expected but got rightBrace"),
        ("package foo:bar;\n\ninterface i {\n  use a.{b}\n}", "semicolon expected but got rightBrace"),
    ])
    func missingSemicolonIsRejected(input: String, message: String) throws {
        let error = try #require(throws: ParseError.self) {
            try parseDoc(input)
        }
        #expect(error.description == message)
    }

    @Test(arguments: [
        "package foo:bar;\n\ninterface i {\n  f: func();\n\n  type t = u8;\n}\n",
        "package foo:bar;\n\nworld w {\n  export f: func();\n  import a:b/c;\n  include a:b/d;\n}\n",
        "package foo:bar;\n\ninterface i {\n  resource r {\n    f: func();\n  }\n}\n",
        // wasm-tools rejects `import bar: interface {};`.
        "package foo:bar;\n\nworld w {\n  import bar: interface {\n  }\n}\n",
    ])
    func terminatedItemsRoundTrip(input: String) throws {
        let ast = try parseDoc(input)
        #expect(WITFormatter.format(sourceFile: ast.syntax, includeDocs: true) == input)
    }

    @Test(arguments: [
        ("package foo:bar;\n\ninterface i {};", "`world`, `interface` or `use` expected"),
        ("package foo:bar;\n\ninterface i {\n  f: func();;\n}", "`type`, `resource` or `func` expected but got semicolon"),
        ("package foo:bar;\n\nworld w {\n  import a:b/c;;\n}", "`import`, `export`, `include`, `use`, or type definition expected but got semicolon"),
        ("package foo:bar;\n\ninterface i {\n  resource r {\n    f: func();;\n  }\n}", "`constructor` or identifier expected but got semicolon"),
    ])
    func straySemicolonIsRejected(input: String, message: String) throws {
        let error = try #require(throws: ParseError.self) {
            try parseDoc(input)
        }
        #expect(error.description == message)
    }
}
