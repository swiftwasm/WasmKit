import XCTest

@testable import WIT

class ParseFunctionDeclTests: XCTestCase {

    func parse(_ text: String) throws -> ResourceFunctionSyntax {
        var lexer = Lexer(cursor: .init(input: text))
        return try ResourceFunctionSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: [])
        )
    }

    func testFunction() throws {
        var lexer = Lexer(cursor: .init(input: "func(x: u8) -> u16"))
        let f = try FunctionSyntax.parse(lexer: &lexer)
        XCTAssertEqual(f.parameters.count, 1)
        guard case .anon(.u16) = f.results else {
            XCTFail("expected anon but got \(f.results)")
            return
        }
    }

    func testFunctionNamedReturn() throws {
        var lexer = Lexer(cursor: .init(input: "func() -> (a: u8, b: u16)"))
        let f = try FunctionSyntax.parse(lexer: &lexer)
        guard case .named(let results) = f.results else {
            XCTFail("expected anon but got \(f.results)")
            return
        }
        XCTAssertEqual(results.count, 2)
    }

    func testResourceFunction() throws {
        let f = try parse("%foo: func() -> bool")
        guard case .method(let method) = f else {
            XCTFail("expected method but got \(f)")
            return
        }
        XCTAssertEqual(method.name.text, "foo")
    }

    func testResourceFunctionStatic() throws {
        let f = try parse("foo: static func() -> bool")
        guard case .static(let method) = f else {
            XCTFail("expected method but got \(f)")
            return
        }
        XCTAssertEqual(method.name.text, "foo")
    }

    func testResourceFunctionConstructor() throws {
        let f = try parse("constructor(a: u8, b: u16)")
        guard case .constructor(let ctor) = f else {
            XCTFail("expected method but got \(f)")
            return
        }
        XCTAssertEqual(ctor.name.text, "constructor")
        XCTAssertEqual(ctor.function.parameters.count, 2)
    }
}
