import XCTest

@testable import WIT

class PackageResolverTests: XCTestCase {
    class InMemoryLoader: PackageFileLoader {
        enum Node: ExpressibleByDictionaryLiteral, ExpressibleByStringLiteral {
            case directory(children: [String: Node])
            case file(String)

            init(dictionaryLiteral elements: (String, Node)...) {
                self = .directory(children: Dictionary(uniqueKeysWithValues: elements))
            }
            init(stringLiteral value: String) {
                self = .file(value)
            }
        }

        struct FilePath: CustomStringConvertible {
            let fileName: String
            let node: Node
            var description: String { fileName }
        }

        func convert(_ children: [String: Node]) -> [FilePath] {
            return children.map { key, value in
                return FilePath(fileName: key, node: value)
            }
        }

        func packageFiles(in packageDirectory: FilePath) throws -> [FilePath] {
            switch packageDirectory.node {
            case .directory(let children):
                return convert(children.filter { $0.key.hasSuffix(".wit") })
            case .file: fatalError()
            }
        }

        func contentsOfWITFile(at filePath: FilePath) throws -> String {
            switch filePath.node {
            case .directory: fatalError()
            case .file(let string): return string
            }
        }

        func dependencyDirectories(from packageDirectory: FilePath) throws -> [FilePath] {
            switch packageDirectory.node {
            case .directory(let children):
                switch children["deps"] {
                case .directory(let children): return convert(children)
                default: fatalError()
                }
            case .file: fatalError()
            }
        }
    }

    func testLoadDependencies() throws {
        let loader = InMemoryLoader()
        let (mainPackage, packageResolver) = try PackageResolver.parse(
            directory: .init(
                fileName: "pkg",
                node: [
                    "apple.wit": """
                        package fruit:apple

                        interface apple {
                          use fruit:banana/types.{size}
                          use fruit:peach/types.{color}
                          type check1 = size
                          type check2 = color
                        }
                        """,
                    "deps": [
                        "banana": [
                            "banana.wit": """
                                package fruit:banana

                                interface types {
                                  type size = u32
                                }
                                """
                        ],
                        "peach-x": [
                            "peach.wit": """
                                package fruit:peach

                                interface types {
                                  type color = string
                                }
                                """
                        ],
                    ],
                ]
            ),
            loader: loader
        )
        let context = SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
        let (appleIface, sourceFile) = try context.lookupInterface(name: "apple", contextPackage: mainPackage)
        let declContext = DeclContext(
            kind: .interface(appleIface, sourceFile: sourceFile, context: .package(mainPackage.packageName)),
            packageUnit: mainPackage,
            packageResolver: packageResolver
        )
        do {
            let lookup = TypeNameLookup(context: declContext, name: "check1", evaluator: context.evaluator)
            XCTAssertEqual(try lookup.lookup(), WITType.u32)
        }
        do {
            let lookup = TypeNameLookup(context: declContext, name: "check2", evaluator: context.evaluator)
            XCTAssertEqual(try lookup.lookup(), WITType.string)
        }
    }

    func testLoadDependenciesWithVersion() throws {
        let loader = InMemoryLoader()
        let (mainPackage, packageResolver) = try PackageResolver.parse(
            directory: .init(
                fileName: "pkg",
                node: [
                    "apple.wit": """
                        package fruit:apple

                        interface apple {
                          use fruit:banana/types@1.0.0.{size as size-1}
                          use fruit:banana/types@2.0.0.{size as size-2}
                          type check1 = size-1
                          type check2 = size-2
                        }
                        """,
                    "deps": [
                        "banana-1.0.0": [
                            "banana.wit": """
                                package fruit:banana@1.0.0

                                interface types {
                                  type size = u32
                                }
                                """
                        ],
                        "banana-2.0.0": [
                            "banana.wit": """
                                package fruit:banana@2.0.0

                                interface types {
                                  type size = u8
                                }
                                """
                        ],
                    ],
                ]
            ),
            loader: loader
        )
        let context = SemanticsContext(rootPackage: mainPackage, packageResolver: packageResolver)
        let (appleIface, sourceFile) = try context.lookupInterface(name: "apple", contextPackage: mainPackage)
        let declContext = DeclContext(
            kind: .interface(appleIface, sourceFile: sourceFile, context: .package(mainPackage.packageName)),
            packageUnit: mainPackage,
            packageResolver: packageResolver
        )

        do {
            let lookup = TypeNameLookup(context: declContext, name: "check1", evaluator: context.evaluator)
            XCTAssertEqual(try lookup.lookup(), .u32)
        }
        do {
            let lookup = TypeNameLookup(context: declContext, name: "check2", evaluator: context.evaluator)
            XCTAssertEqual(try lookup.lookup(), .u8)
        }
    }
}
