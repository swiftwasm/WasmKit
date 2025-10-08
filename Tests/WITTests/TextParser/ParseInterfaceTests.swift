import XCTest

@testable import WIT

class ParseInterfaceTests: XCTestCase {

    func parse(_ text: String) throws -> SyntaxNode<InterfaceSyntax> {
        var lexer = Lexer(cursor: .init(input: text))
        return try InterfaceSyntax.parse(
            lexer: &lexer,
            documents: DocumentsSyntax(comments: []), attributes: []
        )
    }

    func testEmpty() throws {
        let iface = try parse("interface empty {}")
        XCTAssertEqual(iface.name.text, "empty")
        XCTAssertEqual(iface.items.count, 0)
    }

    func testMultipleItems() throws {
        let iface = try parse(
            """
            interface x {
                type t1 = u8
                type t2 = u8
            }
            """
        )
        XCTAssertEqual(iface.name.text, "x")
        XCTAssertEqual(iface.items.count, 2)
    }

    func testWithComment() throws {
        let iface = try parse(
            """
            interface x {
                // doc comment here
                f1: func()
            }
            """
        )
        XCTAssertEqual(iface.name.text, "x")
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .function(let function) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(function.documents.comments.count, 1)
    }

    func testInvalidItem() throws {
        XCTAssertThrowsError(try parse("interface x { . }"))
    }

    func testItemType() throws {
        let iface = try parse(
            """
            interface x {
                type t1 = u8
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "t1")
    }

    func testItemFlags() throws {
        let iface = try parse(
            """
            interface x {
                flags f1 {
                    b0,
                }
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "f1")
    }

    func testItemEnum() throws {
        let iface = try parse(
            """
            interface x {
                enum e1 {
                    c1,
                }
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "e1")
    }

    func testItemVariant() throws {
        let iface = try parse(
            """
            interface x {
                variant v1 {
                    c1,
                }
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "v1")
    }

    func testItemResource() throws {
        let iface = try parse(
            """
            interface x {
                resource rs1
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "rs1")
    }

    func testItemRecord() throws {
        let iface = try parse(
            """
            interface x {
                record rc1 {
                    f1: u8
                }
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "rc1")
    }

    func testItemUnion() throws {
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
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .typeDef(let typeDef) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(typeDef.name.text, "u1")
    }

    func testItemFunction() throws {
        let iface = try parse(
            """
            interface x {
                f1: func(arg: string)
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .function(let function) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(function.name.text, "f1")
    }

    func testItemUse() throws {
        let iface = try parse(
            """
            interface x {
                use pkg1.{thing}
            }
            """
        )
        XCTAssertEqual(iface.items.count, 1)
        let item = iface.items[0]
        guard case .use(let use) = item else {
            XCTFail("unexpected item type: \(item)")
            return
        }
        XCTAssertEqual(use.from.name.text, "pkg1")
    }
}
