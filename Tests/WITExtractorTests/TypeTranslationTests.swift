#if !(os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
    import Testing

    @testable import WITExtractor

    struct TypeTranslationTests {
        @Test func structEmpty() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct EmptyStruct {
                }
                @WIT public enum NamespaceEnum {
                    @WIT public struct NestedEmptyStruct {
                    }
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record empty-struct {
                    }

                    record namespace-enum-nested-empty-struct {
                    }
                }
                """)
        }

        @Test func structField() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct StructFields {
                    @WIT public var varField: Int
                    @WIT public let letField: Int
                    @WIT public static var staticVarField: Int = 0
                    @WIT public static let staticLetField: Int = 0

                    // WIT Keywords
                    @WIT public let `static`: Int
                    @WIT public let resource: Int

                    internal var internalField: Int
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record struct-fields {
                        var-field: s64,
                        let-field: s64,
                        %static: s64,
                        %resource: s64,
                    }
                }
                """)
        }

        @Test func nonExposed() throws {
            try TestSupport.assertTranslation(
                """
                public struct NonExposed {
                    public var field: Int
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                }
                """)
        }

        @Test func structFieldNumberTypes() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct NumberFields {
                    @WIT public var fb: Bool

                    @WIT public var fu8: UInt8
                    @WIT public var fu16: UInt16
                    @WIT public var fu32: UInt32
                    @WIT public var fu64: UInt64
                    @WIT public var fu: UInt

                    @WIT public var fs8: Int8
                    @WIT public var fs16: Int16
                    @WIT public var fs32: Int32
                    @WIT public var fs64: Int64
                    @WIT public var fs: Int

                    @WIT public var ffloat32: Float
                    @WIT public var ffloat64: Double
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record number-fields {
                        fb: bool,
                        fu8: u8,
                        fu16: u16,
                        fu32: u32,
                        fu64: u64,
                        fu: u64,
                        fs8: s8,
                        fs16: s16,
                        fs32: s32,
                        fs64: s64,
                        fs: s64,
                        ffloat32: f32,
                        ffloat64: f64,
                    }
                }
                """)
        }

        @Test func optionalType() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct OptionalTypes {
                    @WIT public var optInt: Optional<Int>
                    @WIT public var optOptInt: Optional<Optional<Int>>
                    @WIT public var optShorthand: Int?
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record optional-types {
                        opt-int: option<s64>,
                        opt-opt-int: option<option<s64>>,
                        opt-shorthand: option<s64>,
                    }
                }
                """)
        }

        @Test func arrayType() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct ArrayTypes {
                    @WIT public var arrayInt: Array<Int>
                    @WIT public var arrayArrayInt: Array<Array<Int>>
                    @WIT public var arrayShorthand: [Int]
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record array-types {
                        array-int: list<s64>,
                        array-array-int: list<list<s64>>,
                        array-shorthand: list<s64>,
                    }
                }
                """)
        }

        @Test func dictionaryType() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct DictionaryTypes {
                    @WIT public var dict: Dictionary<String, Int>
                    @WIT public var dictDict: Dictionary<String, Dictionary<String, Int>>
                    @WIT public var dictShorthand: [String: Int]
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record dictionary-types {
                        dict: list<tuple<string, s64>>,
                        dict-dict: list<tuple<string, list<tuple<string, s64>>>>,
                        dict-shorthand: list<tuple<string, s64>>,
                    }
                }
                """)
        }

        @Test func enumType() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public enum EmptyEnum {
                }
                @WIT public enum EnumType {
                    case c1, c2(Int), c3(String)
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    variant enum-type {
                        c1,
                        c2(s64),
                        c3(string),
                    }
                }
                """)
        }

        @Test func enumTypeWithoutPayload() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public enum EnumType {
                    case c1, c2, c3
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    enum enum-type {
                        c1,
                        c2,
                        c3,
                    }
                }
                """)
        }

        @Test func enumTypeWithListPayload() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public enum EnumType: Codable {
                    case genericInParen([String])
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    variant enum-type {
                        generic-in-paren(list<string>),
                    }
                }
                """)
        }

        @Test func multipleTypes() throws {
            try TestSupport.assertTranslation(
                """
                @WIT public struct A {
                    public var f1: String
                }

                @WIT public struct B {
                    public var f2: String
                }
                """,
                """
                package swift:wasmkit;

                interface test {
                    record A {
                        f1: string,
                    }

                    record B {
                        f2: string,
                    }
                }
                """)
        }

        @Test func resolvesSameModuleFieldAcrossSources() throws {
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: [
                    "@WIT public struct Widget { public var size: Int }",
                    "@WIT public struct Container { public var widget: Widget }",
                ])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            let widgetAt = try #require(wit.range(of: "record widget"))
            let containerAt = try #require(wit.range(of: "record container"))
            #expect(widgetAt.lowerBound < containerAt.lowerBound)
            #expect(wit.contains("widget: widget,"))
        }

        @Test func widensCrossModuleDependencyType() throws {
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: ["@WIT public struct UsesExternal { public var ext: External }"],
                dependencySources: ["ExternalLib": ["public struct External { public var label: String; public init(label: String) { self.label = label } }"]])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            #expect(wit.contains("ext: external,"))
            #expect(wit.contains("record external {"))
            #expect(wit.contains("label: string,"))
            #expect(extractor.diagnostics.isEmpty)
        }

        @Test func mainModuleTypeWinsNameCollisionWithDependency() throws {
            // Dependency-first merge order gives main-module nominals precedence over a same-named dep type.
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: [
                    "@WIT public struct Token { public var n: Int }",
                    "@WIT public struct Box { public var t: Token }",
                ],
                dependencySources: ["Dep": ["public struct Token { public var s: String }"]])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            #expect(wit.contains("t: token,"))
            #expect(wit.contains("n: s64,"))
            #expect(!wit.contains("s: string"))
        }

        @Test func dropsCrossModuleTypeMissingPublicInit() throws {
            // A dep type with only the implicit (internal) memberwise init is not constructible cross-module,
            // so it is dropped, and the referencing field drops with it via the emit-gate cascade.
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: ["@WIT public struct UsesExternal { public var ext: External }"],
                dependencySources: ["ExternalLib": ["public struct External { public var label: String }"]])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            #expect(!wit.contains("record external"))
            #expect(!wit.contains("ext:"))
            #expect(
                extractor.diagnostics.contains {
                    $0.message.contains("External") && $0.message.contains("initializer")
                })
        }

        @Test func dropsUnresolvedFieldWithDiagnostic() {
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: ["@WIT public struct S { public var ok: Int; public var bad: SomeExternalThing }"])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            #expect(wit.contains("ok: s64"))
            #expect(!wit.contains("bad"))
            #expect(
                extractor.diagnostics.contains {
                    $0.message.contains("bad") && $0.message.contains("SomeExternalThing")
                })
        }

        @Test func dropsUnresolvedResultWithDiagnostic() {
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: ["@WIT public func bad() -> SomeExternalThing { fatalError() }"])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            #expect(!wit.contains("bad"))
            #expect(
                extractor.diagnostics.contains {
                    $0.message.contains("bad") && $0.message.contains("SomeExternalThing")
                })
        }

        // An unresolvable enum-case payload keeps the case (payloadless) and drops only the payload. Pinning
        // `c2,` (not `c2(`) distinguishes this from dropping the whole case or keeping the payload.
        @Test func enumKeepsCaseButDropsUnresolvablePayloadWithDiagnostic() {
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: ["@WIT public enum E { case c1, c2(SomeExternalThing), c3(Int) }"])
            let wit = extractor.runWithoutHeader(moduleName: "test").witContents
            #expect(wit.contains("variant E"))  // payload c3 keeps this a variant, not an enum
            #expect(wit.contains("c2,"))
            #expect(wit.contains("c3(s64),"))
            #expect(
                extractor.diagnostics.contains {
                    $0.message.contains("E/c2") && $0.message.contains("SomeExternalThing")
                })
        }

        @Test func sourceSummaryCarriesOriginalRecordFieldNames() throws {
            // The summary retains exact Swift identifiers, including a non-round-tripping name
            // (`snake_name` -> WIT `snake-name`), so the overlay can access the real member.
            let extractor = WITExtractor(
                namespace: "swift", packageName: "wasmkit",
                sources: ["@WIT public struct Point { public var snake_name: Int; public var okFine: Int }"])
            let output = extractor.runWithoutHeader(moduleName: "test")
            #expect(output.sourceSummary.recordFieldNames(byWITName: "point") == ["snake_name", "okFine"])
        }
    }
#endif
