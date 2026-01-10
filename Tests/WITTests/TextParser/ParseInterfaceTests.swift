import Testing

@testable import WIT

@Suite
struct ParseInterfaceTests {

    func parse(_ text: String) throws -> SyntaxNode<InterfaceSyntax> {
        var lexer = Lexer(cursor: .init(input: text))
        return try InterfaceSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: []), attributes: []
        )
    }

    @Test func empty() throws {
        let iface = try parse("interface empty {}")
        #expect(iface.name.text == "empty")
        #expect(iface.items.count == 0)
    }

    @Test func multipleItems() throws {
        let iface = try parse(
            """
            interface x {
                type t1 = u8
                type t2 = u8
            }
            """
        )
        #expect(iface.name.text == "x")
        #expect(iface.items.count == 2)
    }

    @Test func withComment() throws {
        let iface = try parse(
            """
            interface x {
                // doc comment here
                f1: func()
            }
            """
        )
        #expect(iface.name.text == "x")
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .function(let function) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(function.documents.comments.count == 1)
    }

    @Test func invalidItem() throws {
        #expect(throws: (any Error).self) {
            try parse("interface x { . }")
        }
    }

    @Test func itemType() throws {
        let iface = try parse(
            """
            interface x {
                type t1 = u8
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "t1")
    }

    @Test func itemFlags() throws {
        let iface = try parse(
            """
            interface x {
                flags f1 {
                    b0,
                }
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "f1")
    }

    @Test func itemEnum() throws {
        let iface = try parse(
            """
            interface x {
                enum e1 {
                    c1,
                }
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "e1")
    }

    @Test func itemVariant() throws {
        let iface = try parse(
            """
            interface x {
                variant v1 {
                    c1,
                }
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "v1")
    }

    @Test func itemResource() throws {
        let iface = try parse(
            """
            interface x {
                resource rs1
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "rs1")
    }

    @Test func itemRecord() throws {
        let iface = try parse(
            """
            interface x {
                record rc1 {
                    f1: u8
                }
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "rc1")
    }

    @Test func itemUnion() throws {
        let iface = try parse(
            """
            interface x {
                union u1 {
                    u8,
                    bool
                }
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "u1")
    }

    @Test func itemFunction() throws {
        let iface = try parse(
            """
            interface x {
                f1: func(arg: string)
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .function(let function) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(function.name.text == "f1")
    }

    @Test func itemUse() throws {
        let iface = try parse(
            """
            interface x {
                use pkg1.{thing}
            }
            """
        )
        #expect(iface.items.count == 1)
        let item = iface.items[0]
        guard case .use(let use) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(use.from.name.text == "pkg1")
    }
}
