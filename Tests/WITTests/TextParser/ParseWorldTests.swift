import XCTest

@testable import WIT

final class ParseWorldTests: XCTestCase {

    func parse(_ text: String) throws -> SyntaxNode<WorldSyntax> {
        var lexer = Lexer(cursor: .init(input: text))
        return try WorldSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: [])
        )
    }

    func testEmpty() throws {
        let world = try parse("world empty {}")
        XCTAssertEqual(world.name.text, "empty")
        XCTAssertEqual(world.items.count, 0)
    }

    func testMultipleItems() throws {
        let world = try parse(
            """
            world x {
                type t1 = u8
                type t2 = u8
            }
            """
        )
        XCTAssertEqual(world.name.text, "x")
        XCTAssertEqual(world.items.count, 2)
    }

    func testWithComment() throws {
        let world = try parse(
            """
            world x {
                // doc comment here
                type t1 = u8
            }
            """
        )
        XCTAssertEqual(world.name.text, "x")
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.documents.comments.count, 1)
    }

    func testInvalidItem() throws {
        XCTAssertThrowsError(try parse("world x { . }"))
    }

    func testItemImport() throws {
        let world = try parse(
            """
            world x {
                import foo: func()
                import bar: interface {}
                import baz
            }
            """
        )
        XCTAssertEqual(world.items.count, 3)
        do {
            let item = world.items[0]
            guard case let .import(importItem) = item else {
                XCTFail("unexpected item type: \(item)")
                return
            }
            guard case let .function(name, _) = importItem.kind else {
                XCTFail("unexpected import type: \(importItem.kind)")
                return
            }
            XCTAssertEqual(name.text, "foo")
        }

        do {
            let item = world.items[1]
            guard case let .import(importItem) = item else {
                XCTFail("unexpected item type: \(item)")
                return
            }
            guard case let .interface(name, iface) = importItem.kind else {
                XCTFail("unexpected import type: \(importItem.kind)")
                return
            }
            XCTAssertEqual(name.text, "bar")
            XCTAssertEqual(iface.count, 0)
        }

        do {
            let item = world.items[2]
            guard case let .import(importItem) = item else {
                XCTFail("unexpected item type: \(item)")
                return
            }
            guard case let .path(path) = importItem.kind else {
                XCTFail("unexpected import type: \(importItem.kind)")
                return
            }
            XCTAssertEqual(path.name.text, "baz")
        }
    }

    func testItemExport() throws {
        let world = try parse(
            """
            world x {
                export foo: func()
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .export(export) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        guard case let .function(name, _) = export.kind else {
            XCTFail("unexpected export type: \(export.kind)")
            return
        }
        XCTAssertEqual(name.text, "foo")
    }

    func testItemInclude() throws {
        let world = try parse(
            """
            world x {
                include foo
                include bar with { baz as qux }
                include multiple with { n1 as a1, n2 as a2 }
            }
            """
        )
        XCTAssertEqual(world.items.count, 3)
        do {
            let item = world.items[0]
            guard case let .include(include) = item else {
                XCTFail("unexpected item type: \(item)")
                return
            }
            XCTAssertEqual(include.from.name.text, "foo")
            XCTAssertEqual(include.names.count, 0)
        }

        do {
            let item = world.items[1]
            guard case let .include(include) = item else {
                XCTFail("unexpected item type: \(item)")
                return
            }
            XCTAssertEqual(include.from.name.text, "bar")
            XCTAssertEqual(include.names.count, 1)
            let alias = include.names[0]
            XCTAssertEqual(alias.name.text, "baz")
            XCTAssertEqual(alias.asName.text, "qux")
        }

        do {
            let item = world.items[2]
            guard case let .include(include) = item else {
                XCTFail("unexpected item type: \(item)")
                return
            }
            XCTAssertEqual(include.names.count, 2)
            let alias1 = include.names[0]
            XCTAssertEqual(alias1.name.text, "n1")
            XCTAssertEqual(alias1.asName.text, "a1")
            let alias2 = include.names[1]
            XCTAssertEqual(alias2.name.text, "n2")
            XCTAssertEqual(alias2.asName.text, "a2")
        }
    }

    func testItemType() throws {
        let world = try parse(
            """
            world x {
                type t1 = u8
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "t1")
    }

    func testItemFlags() throws {
        let world = try parse(
            """
            world x {
                flags f1 {
                    b0,
                }
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "f1")
    }

    func testItemEnum() throws {
        let world = try parse(
            """
            world x {
                enum e1 {
                    c1,
                }
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "e1")
    }

    func testItemVariant() throws {
        let world = try parse(
            """
            world x {
                variant v1 {
                    c1,
                }
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "v1")
    }

    func testItemResource() throws {
        let world = try parse(
            """
            world x {
                resource rs1
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "rs1")
    }

    func testItemRecord() throws {
        let world = try parse(
            """
            world x {
                record rc1 {
                    f1: u8
                }
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "rc1")
    }

    func testItemUnion() throws {
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
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .type(typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "u1")
    }

    func testItemUse() throws {
        let world = try parse(
            """
            world x {
                use pkg1.{thing}
            }
            """
        )
        XCTAssertEqual(world.items.count, 1)
        let item = world.items[0]
        guard case let .use(use) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(use.from.name.text, "pkg1")
    }
}
