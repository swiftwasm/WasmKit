import Testing

@testable import WITExtractor

@Suite(TestEnvironmentTraits.witExtractorAvailability)
struct TypeTranslationTests {
    @Test func structEmpty() throws {
        try TestSupport.assertTranslation(
            """
            @_spi(WIT) public struct EmptyStruct {
            }
            @_spi(WIT) public enum NamespaceEnum {
                @_spi(WIT) public struct NestedEmptyStruct {
                }
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public struct StructFields {
                @_spi(WIT) public var varField: Int
                @_spi(WIT) public let letField: Int
                @_spi(WIT) public static var staticVarField: Int = 0
                @_spi(WIT) public static let staticLetField: Int = 0

                // WIT Keywords
                @_spi(WIT) public let `static`: Int
                @_spi(WIT) public let resource: Int

                internal var internalField: Int
            }
            """,
            """
            package swift:wasmkit

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
            package swift:wasmkit

            interface test {
            }
            """)
    }

    @Test func structFieldNumberTypes() throws {
        try TestSupport.assertTranslation(
            """
            @_spi(WIT) public struct NumberFields {
                @_spi(WIT) public var fb: Bool

                @_spi(WIT) public var fu8: UInt8
                @_spi(WIT) public var fu16: UInt16
                @_spi(WIT) public var fu32: UInt32
                @_spi(WIT) public var fu64: UInt64
                @_spi(WIT) public var fu: UInt

                @_spi(WIT) public var fs8: Int8
                @_spi(WIT) public var fs16: Int16
                @_spi(WIT) public var fs32: Int32
                @_spi(WIT) public var fs64: Int64
                @_spi(WIT) public var fs: Int

                @_spi(WIT) public var ffloat32: Float
                @_spi(WIT) public var ffloat64: Double
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public struct OptionalTypes {
                @_spi(WIT) public var optInt: Optional<Int>
                @_spi(WIT) public var optOptInt: Optional<Optional<Int>>
                @_spi(WIT) public var optShorthand: Int?
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public struct ArrayTypes {
                @_spi(WIT) public var arrayInt: Array<Int>
                @_spi(WIT) public var arrayArrayInt: Array<Array<Int>>
                @_spi(WIT) public var arrayShorthand: [Int]
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public struct DictionaryTypes {
                @_spi(WIT) public var dict: Dictionary<String, Int>
                @_spi(WIT) public var dictDict: Dictionary<String, Dictionary<String, Int>>
                @_spi(WIT) public var dictShorthand: [String: Int]
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public enum EmptyEnum {
            }
            @_spi(WIT) public enum EnumType {
                case c1, c2(Int), c3(String)
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public enum EnumType {
                case c1, c2, c3
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public enum EnumType: Codable {
                case genericInParen([String])
            }
            """,
            """
            package swift:wasmkit

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
            @_spi(WIT) public struct A {
                public var f1: String
            }

            @_spi(WIT) public struct B {
                public var f2: String
            }
            """,
            """
            package swift:wasmkit

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
}
