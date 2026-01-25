import Testing

@testable import WIT

@Suite struct ParseWorldTests {

    func parse(_ text: String) throws -> SyntaxNode<WorldSyntax> {
        var lexer = Lexer(cursor: .init(input: text))
        return try WorldSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: []),
            attributes: []
        )
    }

    @Test func empty() throws {
        let world = try parse("world empty {}")
        #expect(world.name.text == "empty")
        #expect(world.items.count == 0)
    }

    @Test func multipleItems() throws {
        let world = try parse(
            """
            world x {
                type t1 = u8
                type t2 = u8
            }
            """
        )
        #expect(world.name.text == "x")
        #expect(world.items.count == 2)
    }

    @Test func withComment() throws {
        let world = try parse(
            """
            world x {
                // doc comment here
                type t1 = u8
            }
            """
        )
        #expect(world.name.text == "x")
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.documents.comments.count == 1)
    }

    @Test func invalidItem() throws {
        #expect(throws: (any Error).self) {
            try parse("world x { . }")
        }
    }

    @Test func itemImport() throws {
        let world = try parse(
            """
            world x {
                import foo: func()
                import bar: interface {}
                import baz
            }
            """
        )
        #expect(world.items.count == 3)
        do {
            let item = world.items[0]
            guard case .import(let importItem) = item else {
                Issue.record("unexpected item type: \(item)")
                return
            }
            guard case .function(let name, _) = importItem.kind else {
                Issue.record("unexpected import type: \(importItem.kind)")
                return
            }
            #expect(name.text == "foo")
        }

        do {
            let item = world.items[1]
            guard case .import(let importItem) = item else {
                Issue.record("unexpected item type: \(item)")
                return
            }
            guard case .interface(let name, let iface) = importItem.kind else {
                Issue.record("unexpected import type: \(importItem.kind)")
                return
            }
            #expect(name.text == "bar")
            #expect(iface.count == 0)
        }

        do {
            let item = world.items[2]
            guard case .import(let importItem) = item else {
                Issue.record("unexpected item type: \(item)")
                return
            }
            guard case .path(let path) = importItem.kind else {
                Issue.record("unexpected import type: \(importItem.kind)")
                return
            }
            #expect(path.name.text == "baz")
        }
    }

    @Test func itemExport() throws {
        let world = try parse(
            """
            world x {
                export foo: func()
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .export(let export) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        guard case .function(let name, _) = export.kind else {
            Issue.record("unexpected export type: \(export.kind)")
            return
        }
        #expect(name.text == "foo")
    }

    @Test func itemInclude() throws {
        let world = try parse(
            """
            world x {
                include foo
                include bar with { baz as qux }
                include multiple with { n1 as a1, n2 as a2 }
            }
            """
        )
        #expect(world.items.count == 3)
        do {
            let item = world.items[0]
            guard case .include(let include) = item else {
                Issue.record("unexpected item type: \(item)")
                return
            }
            #expect(include.from.name.text == "foo")
            #expect(include.names.count == 0)
        }

        do {
            let item = world.items[1]
            guard case .include(let include) = item else {
                Issue.record("unexpected item type: \(item)")
                return
            }
            #expect(include.from.name.text == "bar")
            #expect(include.names.count == 1)
            let alias = include.names[0]
            #expect(alias.name.text == "baz")
            #expect(alias.asName.text == "qux")
        }

        do {
            let item = world.items[2]
            guard case .include(let include) = item else {
                Issue.record("unexpected item type: \(item)")
                return
            }
            #expect(include.names.count == 2)
            let alias1 = include.names[0]
            #expect(alias1.name.text == "n1")
            #expect(alias1.asName.text == "a1")
            let alias2 = include.names[1]
            #expect(alias2.name.text == "n2")
            #expect(alias2.asName.text == "a2")
        }
    }

    @Test func itemType() throws {
        let world = try parse(
            """
            world x {
                type t1 = u8
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "t1")
    }

    @Test func itemFlags() throws {
        let world = try parse(
            """
            world x {
                flags f1 {
                    b0,
                }
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "f1")
    }

    @Test func itemEnum() throws {
        let world = try parse(
            """
            world x {
                enum e1 {
                    c1,
                }
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "e1")
    }

    @Test func itemVariant() throws {
        let world = try parse(
            """
            world x {
                variant v1 {
                    c1,
                }
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "v1")
    }

    @Test func itemResource() throws {
        let world = try parse(
            """
            world x {
                resource rs1
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "rs1")
    }

    @Test func itemRecord() throws {
        let world = try parse(
            """
            world x {
                record rc1 {
                    f1: u8
                }
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "rc1")
    }

    @Test func itemUnion() throws {
        let world = try parse(
            """
            world x {
                union u1 {
                    u8,
                    bool
                }
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .type(let typeDef) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(typeDef.name.text == "u1")
    }

    @Test func itemUse() throws {
        let world = try parse(
            """
            world x {
                use pkg1.{thing}
            }
            """
        )
        #expect(world.items.count == 1)
        let item = world.items[0]
        guard case .use(let use) = item else {
            Issue.record("unexpected item type: \(item)")
            return
        }
        #expect(use.from.name.text == "pkg1")
    }
}
