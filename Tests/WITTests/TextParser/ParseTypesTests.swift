import Testing

@testable import WIT

@Suite
struct ParseTestsTests {
    @Test func typeUseAll() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    interface types {
                        type t1 = bool
                        type t2 = u8
                        type t3 = u16
                        type t4 = u32
                        type t5 = u64
                        type t6 = s8
                        type t7 = s16
                        type t8 = s32
                        type t9 = s64
                        type t10 = float32
                        type t11 = float64
                        type t12 = char
                        type t13 = string

                        type t14 = tuple<bool, u8, u16>
                        type t15 = list<u32>
                        type t16 = option<i64>

                        type t17 = result<i32, string>
                        type t18 = result<_, string>
                        type t19 = result<i32>
                        type t20 = result

                        type t21 = future<i32>
                        type t22 = future

                        type t23 = stream<i32, string>
                        type t24 = stream<_, string>
                        type t25 = stream<i32>
                        type t26 = stream

                        type t27 = own<x>
                        type t28 = borrow<x>

                        type t29 = x
                        type t30 = %x
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

    @Test func typeDefResource() throws {
        var lexer = Lexer(
            cursor: .init(
                input: """
                    resource r1 {
                        // doc comment here
                        f1: func()
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
}
