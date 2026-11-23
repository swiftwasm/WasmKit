import Testing

@testable import WIT

@Suite
struct AsyncFuncParseTests {

    private func parse(_ text: String) throws -> SyntaxNode<InterfaceSyntax> {
        var lexer = Lexer(cursor: .init(input: text))
        return try InterfaceSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: []),
            attributes: []
        )
    }

    private func parseWorld(_ text: String) throws -> SyntaxNode<WorldSyntax> {
        var lexer = Lexer(cursor: .init(input: text))
        return try WorldSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: []),
            attributes: []
        )
    }

    @Test func parsesInterfaceAsyncFunc() throws {
        let iface = try parse(
            """
            interface x {
                wait-until: async func(when: u64);
                now: func() -> u64;
            }
            """
        )
        var funcs: [String: FunctionSyntax] = [:]
        for item in iface.items {
            guard case .function(let f) = item else { continue }
            funcs[f.name.text] = f.function
        }
        let waitUntil = try #require(funcs["wait-until"])
        let now = try #require(funcs["now"])
        #expect(waitUntil.isAsync)
        #expect(!now.isAsync)
    }

    @Test func formatsAsyncFunc() throws {
        let iface = try parse(
            """
            interface x {
                wait-until: async func(when: u64);
                now: func() -> u64;
            }
            """
        )
        var formatter = WITFormatter(output: "")
        formatter.write(interface: iface.syntax, indent: 0)
        let out = formatter.output
        #expect(out.contains("wait-until: async func(when: u64);"))
        #expect(out.contains("now: func() -> u64;"))
    }

    @Test func parsesResourceStaticAsyncFunc() throws {
        let iface = try parse(
            """
            interface x {
                resource r {
                    bar: async func();
                    foo: static async func();
                }
            }
            """
        )
        var resourceFuncs: [ResourceFunctionSyntax] = []
        for item in iface.items {
            guard case .typeDef(let td) = item, case .resource(let r) = td.body else { continue }
            resourceFuncs = r.functions
        }
        var byName: [String: (isAsync: Bool, isStatic: Bool)] = [:]
        for rf in resourceFuncs {
            switch rf {
            case .method(let nf): byName[nf.name.text] = (nf.function.isAsync, false)
            case .static(let nf): byName[nf.name.text] = (nf.function.isAsync, true)
            case .constructor: break
            }
        }
        #expect(byName["bar"]?.isAsync == true)
        #expect(byName["bar"]?.isStatic == false)
        #expect(byName["foo"]?.isAsync == true)
        #expect(byName["foo"]?.isStatic == true)

        var formatter = WITFormatter(output: "")
        formatter.write(interface: iface.syntax, indent: 0)
        let out = formatter.output
        #expect(out.contains("bar: async func();"))
        #expect(out.contains("foo: static async func();"))
    }

    @Test func worldInlineAsyncFuncRoundTrips() throws {
        let world = try parseWorld(
            """
            world w {
                import a: async func();
                export b: async func() -> u64;
                import c: func();
            }
            """
        )
        func externFunc(_ kind: ExternKindSyntax) -> (name: String, isAsync: Bool)? {
            guard case .function(let name, let function) = kind else { return nil }
            return (name.text, function.isAsync)
        }
        var byName: [String: Bool] = [:]
        for item in world.items {
            switch item {
            case .import(let imp): if let f = externFunc(imp.kind) { byName[f.name] = f.isAsync }
            case .export(let exp): if let f = externFunc(exp.kind) { byName[f.name] = f.isAsync }
            default: break
            }
        }
        #expect(byName["a"] == true)
        #expect(byName["b"] == true)
        #expect(byName["c"] == false)

        var formatter = WITFormatter(output: "")
        formatter.write(world: world.syntax, indent: 0)
        let out = formatter.output
        #expect(out.contains("import a: async func();"))
        #expect(out.contains("export b: async func() -> u64;"))
        #expect(out.contains("import c: func();"))

        // The formatter output must parse.
        _ = try parseWorld(out)
    }
}
