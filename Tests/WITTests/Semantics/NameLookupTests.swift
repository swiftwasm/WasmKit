import XCTest

@testable import WIT

class NameLookupTests: XCTestCase {
    func buildPackages(_ packages: [[String]]) throws -> PackageResolver {
        let packageResolver = PackageResolver()
        for pkgFiles in packages {
            let unit = try buildPackageUnit(pkgFiles)
            packageResolver.register(packageUnit: unit)
        }
        return packageResolver
    }

    func buildPackageUnit(_ pkgFiles: [String]) throws -> PackageUnit {
        var packageBuilder = PackageBuilder()
        for text in pkgFiles {
            var lexer = Lexer(cursor: .init(input: text))
            let ast = try SourceFileSyntax.parse(lexer: &lexer, fileName: "test.wit")
            try packageBuilder.append(ast)
        }
        return try packageBuilder.build()
    }

    func buildPackageUnit(_ text: String) throws -> (PackageUnit, PackageResolver) {
        let packageResolver = PackageResolver()
        let unit = try buildPackageUnit([text])
        packageResolver.register(packageUnit: unit)
        return (unit, packageResolver)
    }

    func lookupType(_ source: String, interfaceName: String, typeName: String) throws -> WITType {
        let (packageUnit, packageResolver) = try buildPackageUnit(source)
        let context = SemanticsContext(rootPackage: packageUnit, packageResolver: packageResolver)
        let (interface, sourceFile) = try context.lookupInterface(name: interfaceName, contextPackage: packageUnit)
        let lookup = TypeNameLookup(
            context: .init(
                kind: .interface(interface, sourceFile: sourceFile, context: .package(packageUnit.packageName)),
                packageUnit: packageUnit,
                packageResolver: packageResolver
            ),
            name: typeName, evaluator: context.evaluator
        )
        return try lookup.lookup()
    }

    func lookupType(_ source: [[String]], namespace: String, package: String, interfaceName: String, typeName: String) throws -> WITType {
        let packageResolver = try buildPackages(source)
        let packageUnit = try XCTUnwrap(packageResolver.findPackage(namespace: namespace, package: package, version: nil))
        let context = SemanticsContext(rootPackage: packageUnit, packageResolver: packageResolver)
        let (interface, sourceFile) = try context.lookupInterface(name: interfaceName, contextPackage: packageUnit)
        let lookup = TypeNameLookup(
            context: .init(
                kind: .interface(interface, sourceFile: sourceFile, context: .package(packageUnit.packageName)),
                packageUnit: packageUnit,
                packageResolver: packageResolver
            ),
            name: typeName, evaluator: context.evaluator
        )
        return try lookup.lookup()
    }

    func assertLookup(_ source: String, interfaceName: String, typeName: String, expected: WITType, line: UInt = #line) throws {
        let type = try lookupType(source, interfaceName: interfaceName, typeName: typeName)
        XCTAssertEqual(type, expected, line: line)
    }

    func testLookupAliasPrimitiveType() throws {
        try assertLookup(
            """
            package foo:bar
            interface x {
              type my-type = u8
            }
            """,
            interfaceName: "x",
            typeName: "my-type",
            expected: .u8
        )
    }

    func testLookupAliasDefinedType() throws {
        let type = try lookupType(
            """
            package foo:bar
            interface x {
              record r1 {}
              type my-type = r1
            }
            """,
            interfaceName: "x",
            typeName: "my-type"
        )
        guard case .record(let record) = type else {
            XCTFail("expected record but got \(type)")
            return
        }
        XCTAssertEqual(record.fields, [])
    }

    func testLookupThroughUse() throws {
        let type = try lookupType(
            """
            package foo:bar

            interface x {
              use y.{r1}
              type my-type = r1
            }

            interface y {
              record r1 {}
            }
            """,
            interfaceName: "x",
            typeName: "my-type"
        )
        guard case .record(let record) = type else {
            XCTFail("expected record but got \(type)")
            return
        }
        XCTAssertEqual(record.fields, [])
    }

    func testLookupExternalType() throws {
        let type = try lookupType(
            [
                [
                    """
                    package foo:root

                    interface x {
                      use foo:pkg1/y.{r1}
                      type my-type = r1
                    }
                    """
                ],
                [
                    """
                    package foo:pkg1

                    interface y {
                      record r1 {}
                    }
                    """
                ],
            ],
            namespace: "foo", package: "root", interfaceName: "x", typeName: "my-type"
        )
        guard case .record(let record) = type else {
            XCTFail("expected record but got \(type)")
            return
        }
        XCTAssertEqual(record.fields, [])
    }

    func testLookupTopLevelUsedInterface() throws {
        let type = try lookupType(
            [
                [
                    """
                    package foo:root
                    use foo:pkg1/y

                    interface x {
                      use y.{r1}
                      type my-type = r1
                    }
                    """
                ],
                [
                    """
                    package foo:pkg1

                    interface y {
                      record r1 {}
                    }
                    """
                ],
            ],
            namespace: "foo", package: "root", interfaceName: "x", typeName: "my-type"
        )
        guard case .record(let record) = type else {
            XCTFail("expected record but got \(type)")
            return
        }
        XCTAssertEqual(record.fields, [])
    }

    func testLookupTopLevelUseIsExternallyInvisible() throws {
        XCTAssertThrowsError(
            try lookupType(
                [
                    [
                        """
                        package foo:root
                        use foo:pkg1/y

                        interface x {
                          use y.{r1}
                          type my-type = r1
                        }
                        """
                    ],
                    [
                        """
                        package foo:pkg1
                        use foo:pkg2/y
                        """
                    ],
                    [
                        """
                        package foo:pkg2

                        interface y {
                          record r1 {}
                        }
                        """
                    ],
                ],
                namespace: "foo", package: "root", interfaceName: "x", typeName: "my-type"
            ))
    }

    func testLookupTopLevelUseWithBareIdentifier() throws {
        try assertLookup(
            """
            package foo:bar
            use x as y
            interface x {
              type my-type = u8
            }
            interface z {
              use y.{my-type}
            }
            """,
            interfaceName: "z", typeName: "my-type", expected: .u8
        )
    }

    func testLookupInInterfaceInWorld() throws {
        let packageResolver = try buildPackages(
            [
                [
                    """
                    package foo:root
                    use foo:pkg1/y

                    world x {
                      import e1: interface {
                        use y.{t1}
                        type t2 = t1
                      }
                    }
                    """
                ],
                [
                    """
                    package foo:pkg1

                    interface y {
                      type t1 = u8
                    }
                    """
                ],
            ]
        )
        let rootPkg = try XCTUnwrap(packageResolver.findPackage(namespace: "foo", package: "root", version: nil))
        let world = try XCTUnwrap(
            rootPkg.sourceFiles[0].items.compactMap {
                switch $0 {
                case .world(let world): return world
                default: return nil
                }
            }.first)
        guard case .import(let importItem) = try XCTUnwrap(world.items.first) else {
            XCTFail("expected import item but got \(String(describing: world.items.first))")
            return
        }
        guard case .interface(let name, let items) = importItem.kind else {
            XCTFail("expected inline interface but got \(importItem.kind)")
            return
        }

        let evaluator = Evaluator()
        let lookup = TypeNameLookup(
            context: .init(
                kind: .inlineInterface(
                    name: name,
                    items: items,
                    sourceFile: rootPkg.sourceFiles[0],
                    parentWorld: world.name
                ),
                packageUnit: rootPkg,
                packageResolver: packageResolver
            ),
            name: "t2",
            evaluator: evaluator
        )
        XCTAssertEqual(try lookup.lookup(), .u8)
    }
}
