import Testing

@testable import WIT

@Suite
struct SemicolonEnforcementTests {

    private func parseDoc(_ input: String) throws -> SyntaxNode<SourceFileSyntax> {
        var lexer = Lexer(cursor: .init(input: input))
        return try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
    }

    private func expectMissingSemicolon(
        _ input: String, sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(sourceLocation: sourceLocation) {
            try parseDoc(input)
        } throws: { error in
            String(describing: error).contains("semicolon expected")
        }
    }

    // MARK: - Missing semicolons

    @Test func missingPackageSemicolon() {
        expectMissingSemicolon("package foo:bar\n\ninterface i {}")
    }

    @Test func missingTopLevelUseSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\nuse a:b/c")
    }

    @Test func missingFuncItemSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\ninterface i {\n  f: func()\n}")
    }

    @Test func missingTypeAliasSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\ninterface i {\n  type t = u8\n}")
    }

    @Test func missingWorldFuncExportSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\nworld w {\n  export f: func()\n}")
    }

    @Test func missingWorldPathImportSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\nworld w {\n  import a:b/c\n}")
    }

    @Test func missingIncludeSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\nworld w {\n  include a:b/c\n}")
    }

    @Test func missingResourceMethodSemicolon() {
        expectMissingSemicolon("package foo:bar;\n\ninterface i {\n  resource r {\n    f: func()\n  }\n}")
    }

    // MARK: - Terminated items

    @Test func interfaceWithSemicolonsParses() throws {
        let ast = try parseDoc("package foo:bar;\n\ninterface i {\n  f: func();\n  type t = u8;\n}")
        #expect(ast.items.count == 1)
    }

    @Test func worldWithSemicolonsParses() throws {
        let ast = try parseDoc(
            "package foo:bar;\n\nworld w {\n  export f: func();\n  import a:b/c;\n  include a:b/d;\n}")
        #expect(ast.items.count == 1)
    }

    @Test func resourceMethodWithSemicolonParses() throws {
        let ast = try parseDoc(
            "package foo:bar;\n\ninterface i {\n  resource r {\n    f: func();\n  }\n}")
        #expect(ast.items.count == 1)
    }

    /// wasm-tools rejects `import bar: interface {};`.
    @Test func inlineInterfaceExternWithoutSemicolonParses() throws {
        let ast = try parseDoc("package foo:bar;\n\nworld w {\n  import bar: interface {}\n}")
        #expect(ast.items.count == 1)
    }

    // MARK: - Stray semicolons

    @Test func strayInterfaceBlockSemicolonRejected() {
        #expect(throws: (any Error).self) {
            try parseDoc("package foo:bar;\n\ninterface i {};")
        }
    }
}
