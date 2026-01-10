import Testing

@testable import WIT

@Suite

struct ParseFunctionDeclTests {

    func parse(_ text: String) throws -> ResourceFunctionSyntax {
        var lexer = Lexer(cursor: .init(input: text))
        return try ResourceFunctionSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: []),
            attributes: []
        )
    }

    @Test func function() throws {
        var lexer = Lexer(cursor: .init(input: "func(x: u8) -> u16"))
        let f = try FunctionSyntax.parse(lexer: &lexer)
        #expect(f.parameters.count == 1)
        guard case .anon(.u16) = f.results else {
            Issue.record("expected anon but got \(f.results)")
            return
        }
    }

    @Test func functionNamedReturn() throws {
        var lexer = Lexer(cursor: .init(input: "func() -> (a: u8, b: u16)"))
        let f = try FunctionSyntax.parse(lexer: &lexer)
        guard case .named(let results) = f.results else {
            Issue.record("expected anon but got \(f.results)")
            return
        }
        #expect(results.count == 2)
    }

    @Test func resourceFunction() throws {
        let f = try parse("%foo: func() -> bool")
        guard case .method(let method) = f else {
            Issue.record("expected method but got \(f)")
            return
        }
        #expect(method.name.text == "foo")
    }

    @Test func resourceFunctionStatic() throws {
        let f = try parse("foo: static func() -> bool")
        guard case .static(let method) = f else {
            Issue.record("expected method but got \(f)")
            return
        }
        #expect(method.name.text == "foo")
    }

    @Test func resourceFunctionConstructor() throws {
        let f = try parse("constructor(a: u8, b: u16)")
        guard case .constructor(let ctor) = f else {
            Issue.record("expected method but got \(f)")
            return
        }
        #expect(ctor.name.text == "constructor")
        #expect(ctor.function.parameters.count == 2)
    }
}
