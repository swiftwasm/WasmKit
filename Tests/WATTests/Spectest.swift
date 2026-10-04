import Foundation
import WasmParser

enum Spectest {
    static let rootDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // WATTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // Root
    static let vendorDirectory: URL =
        rootDirectory
        .appendingPathComponent("Vendor")

    static var testsuitePath: URL { Self.vendorDirectory.appendingPathComponent("testsuite") }

    static func path(_ file: String) -> URL {
        testsuitePath.appendingPathComponent(file)
    }

    /// Files at the top level of the testsuite that use typed function references. wast2json
    /// needs its flag for them, and the flag changes how it encodes element segments, so only
    /// these files get it.
    static let functionReferencesFiles: Set<String> = [
        "br_if.wast", "br_on_non_null.wast", "br_on_null.wast", "br_table.wast", "call_ref.wast",
        "linking.wast", "local_init.wast", "local_tee.wast", "ref.wast", "ref_as_non_null.wast",
        "ref_is_null.wast", "return_call.wast", "return_call_indirect.wast", "return_call_ref.wast",
        "select.wast", "table-sub.wast", "table.wast", "unreached-invalid.wast", "unreached-valid.wast",
    ]

    private static let unparsedGC = "WAT does not parse GC instructions yet"
    private static let usesSkippedModule = "Uses a skipped module"

    /// Directives at the top level of the testsuite that the WAT tests skip, by the line they start
    /// on. They are also left out of the script that the reference tool encodes.
    static let skippedDirectives: [String: [Int: String]] = [
        "array.wast": [
            60: unparsedGC,  // Uses `array.new_default`, `array.new`, `array.get`, `array.set`, `array.len`
            97: unparsedGC,  // Expects a `(ref.array)` result
            98: unparsedGC,  // Expects a `(ref.eq)` result
            106: unparsedGC,  // Uses `array.new_fixed`, `array.get`, `array.set`, `array.len`
            142: unparsedGC,  // Expects a `(ref.array)` result
            143: unparsedGC,  // Expects a `(ref.eq)` result
            151: unparsedGC,  // Uses `array.new_data`, `array.get_s`, `array.get_u`, `array.set`, `array.len`
            202: unparsedGC,  // Expects a `(ref.array)` result
            203: unparsedGC,  // Expects a `(ref.eq)` result
            219: unparsedGC,  // Uses `array.new_fixed`, `array.new_elem`, `array.new`, `array.get_u`, `array.get`, `array.set`, `array.len`
            276: unparsedGC,  // Expects a `(ref.array)` result
            277: unparsedGC,  // Expects a `(ref.eq)` result
            332: unparsedGC,  // Uses `array.get`, `array.set`
        ],
        "array_copy.wast": [
            54: unparsedGC  // Uses `array.new_default`, `array.new_data`, `array.new`, `array.get_u`, `array.copy`
        ],
        "array_fill.wast": [
            38: unparsedGC  // Uses `array.new_default`, `array.new`, `array.get_u`, `array.fill`
        ],
        "array_init_data.wast": [
            31: unparsedGC,  // Uses `array.new_default`, `array.new`, `array.get_u`, `array.init_data`
            113: unparsedGC,  // Uses `array.new_default`, `array.init_data`
        ],
        "array_init_elem.wast": [
            44: unparsedGC,  // Uses `array.new_default`, `array.get`, `array.init_elem`
            117: unparsedGC,  // Uses `array.new_default`, `array.get`, `array.len`, `array.init_elem`, `ref.eq`
            160: unparsedGC,  // Uses `array.new_default`, `array.get`, `array.init_elem`, `ref.eq`
        ],
        "array_new_data.wast": [
            1: unparsedGC,  // Uses `array.new_data`
            12: unparsedGC,  // Expects a `(ref.array)` result
            13: unparsedGC,  // Expects a `(ref.array)` result
            14: unparsedGC,  // Expects a `(ref.array)` result
            15: unparsedGC,  // Expects a `(ref.array)` result
            23: unparsedGC,  // Uses `array.new_data`
            89: unparsedGC,  // Uses `array.new_data`, `array.get_u`
            105: unparsedGC,  // Uses `array.new_data`, `array.get`
            120: unparsedGC,  // Uses `array.new_data`, `array.get_u`
        ],
        "array_new_elem.wast": [
            3: unparsedGC,  // Uses `array.new_elem`, `ref.i31`
            18: unparsedGC,  // Expects a `(ref.array)` result
            19: unparsedGC,  // Expects a `(ref.array)` result
            20: unparsedGC,  // Expects a `(ref.array)` result
            21: unparsedGC,  // Expects a `(ref.array)` result
            29: unparsedGC,  // Uses `array.new_elem`, `array.get`, `ref.i31`, `i31.get_u`
            51: unparsedGC,  // Uses `array.new_elem`
            66: unparsedGC,  // Expects a `(ref.array)` result
            67: unparsedGC,  // Expects a `(ref.array)` result
            68: unparsedGC,  // Expects a `(ref.array)` result
            69: unparsedGC,  // Expects a `(ref.array)` result
            77: unparsedGC,  // Uses `array.new_elem`, `array.get`
            106: unparsedGC,  // Uses `array.new_default`, `array.new_elem`, `array.get`, `ref.eq`
        ],
        "br_on_cast.wast": [
            3: unparsedGC,  // Uses `struct.new`, `struct.get_s`, `array.new`, `array.get_u`, `array.len`, `br_on_cast`, `any.convert_extern`, `ref.i31`, `i31.get_u`
            104: unparsedGC,  // Uses `struct.new_default`, `br_on_cast`
            211: unparsedGC,  // Uses `br_on_cast`
        ],
        "br_on_cast_fail.wast": [
            3: unparsedGC,  // Uses `struct.new`, `struct.get_s`, `array.new`, `array.get_u`, `array.len`, `br_on_cast_fail`, `br_on_cast`, `any.convert_extern`, `ref.i31`, `i31.get_u`
            104: unparsedGC,  // Uses `struct.new_default`, `br_on_cast_fail`
            226: unparsedGC,  // Uses `br_on_cast_fail`
        ],
        "extern.wast": [
            1: unparsedGC,  // Uses `struct.new_default`, `array.new_default`, `any.convert_extern`, `extern.convert_any`, `ref.i31`
            39: unparsedGC,  // Expects a `(ref.host)` result
            42: unparsedGC,  // Expects a `(ref.host)` result
            53: unparsedGC,  // Expects a `(ref.i31)` result
            54: unparsedGC,  // Expects a `(ref.struct)` result
            55: unparsedGC,  // Expects a `(ref.array)` result
            56: unparsedGC,  // Expects a `(ref.host)` result
        ],
        "i31.wast": [
            1: unparsedGC,  // Uses `ref.i31`, `i31.get_s`, `i31.get_u`
            33: unparsedGC,  // Expects a `(ref.i31)` result
            61: unparsedGC,  // Uses `ref.i31`, `i31.get_u`
            128: unparsedGC,  // Uses `ref.i31`, `i31.get_u`
            140: unparsedGC,  // Uses `ref.i31`, `i31.get_u`
            150: unparsedGC,  // Uses `ref.cast`, `ref.i31`, `i31.get_u`
            168: unparsedGC,  // Uses `ref.cast`, `ref.i31`, `i31.get_u`
        ],
        "ref_cast.wast": [
            3: unparsedGC,  // Uses `struct.new_default`, `array.new_default`, `ref.cast`, `any.convert_extern`, `ref.i31`
            99: unparsedGC,  // Uses `struct.new_default`, `ref.cast`
        ],
        "ref_eq.wast": [
            1: unparsedGC  // Uses `struct.new_default`, `array.new_default`, `ref.i31`, `ref.eq`
        ],
        "ref_test.wast": [
            3: unparsedGC,  // Uses `struct.new_default`, `array.new_default`, `ref.test`, `any.convert_extern`, `extern.convert_any`, `ref.i31`
            182: unparsedGC,  // Uses `struct.new_default`, `ref.test`
        ],
        "struct.wast": [
            48: unparsedGC,  // Uses `struct.get`
            70: unparsedGC,  // Uses `struct.new_default`, `struct.new`, `struct.get`, `struct.set`
            122: unparsedGC,  // Expects a `(ref.struct)` result
            145: unparsedGC,  // Uses `struct.get`, `struct.set`
            160: unparsedGC,  // Uses `struct.new`, `struct.get_s`, `struct.get_u`, `struct.set`
        ],
        "table_init.wast": [
            2272: unparsedGC,  // Uses `array.new_default`, `ref.eq`
            2286: usesSkippedModule,  // Invokes the module on line 2272, which wast2json needs left out too
        ],
        "table_init64.wast": [
            2457: unparsedGC,  // Uses `array.new_default`, `ref.eq`
            2471: usesSkippedModule,  // Invokes the module on line 2457, which wast2json needs left out too
        ],
        "type-subtyping.wast": [
            283: unparsedGC,  // Uses `ref.cast`
            344: unparsedGC,  // Uses `ref.cast`
            402: unparsedGC,  // Uses `ref.test`
            414: unparsedGC,  // Uses `ref.test`
            432: unparsedGC,  // Uses `ref.test`
            444: unparsedGC,  // Uses `ref.test`
            455: unparsedGC,  // Uses `ref.test`
            476: unparsedGC,  // Uses `ref.test`
            492: unparsedGC,  // Uses `ref.test`
            515: unparsedGC,  // Uses `ref.test`
            525: unparsedGC,  // Uses `ref.test`
        ],
    ]

    /// Directives that wasm-tools cannot parse, by file name and the line they start on. They are
    /// left out of the script it encodes.
    static let unparsedByWasmTools: [String: [Int: String]] = [
        "type-subtyping.wast": [
            954: "wasm-tools reads at most one supertype"  // A type with two supertypes, which must be invalid
        ]
    ]

    /// Whether `wast` is at the top level of the testsuite.
    static func isTopLevel(_ wast: URL) -> Bool {
        wast.deletingLastPathComponent().path == testsuitePath.path
    }

    static func usesFunctionReferences(_ wast: URL) -> Bool {
        let directory = wast.deletingLastPathComponent()
        return directory.lastPathComponent == "function-references"
            || (directory.path == testsuitePath.path && functionReferencesFiles.contains(wast.lastPathComponent))
    }

    /// - Parameter exclude: File names, or path suffixes such as `proposals/threads/memory.wast`.
    static func wastFiles(include: [String] = [], exclude: [String] = ["annotations.wast"]) -> [URL] {
        #if os(Android)
            return []
        #else
            return [
                testsuitePath,
                testsuitePath.appendingPathComponent("proposals/threads"),
                rootDirectory.appendingPathComponent("Tests/WasmKitTests/ExtraSuite"),
                rootDirectory.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/function-references"),
                rootDirectory.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/multi-memory"),
                rootDirectory.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/multi-memory/threads"),
                rootDirectory.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/gc"),
                rootDirectory.appendingPathComponent("Tests/WasmKitTests/ExtraSuite/annotations"),
            ].flatMap {
                try! FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)
            }.compactMap { filePath in
                guard filePath.pathExtension == "wast" else {
                    return nil
                }
                guard !filePath.lastPathComponent.starts(with: "simd_") else { return nil }

                if !include.isEmpty {
                    guard include.contains(filePath.lastPathComponent) else { return nil }
                } else {
                    guard !exclude.contains(where: { filePath.path.hasSuffix("/" + $0) }) else { return nil }
                }
                return filePath
            }
        #endif
    }

    static func deriveFeatureSet(wast: URL) -> WasmFeatureSet {
        var features = WasmFeatureSet.default
        if wast.deletingLastPathComponent().path == testsuitePath.path {
            // The spec testsuite's top level is Wasm 3.0, which merged these proposals.
            features.insert(.memory64)
            features.insert(.tailCall)
            features.insert(.multiMemory)
            features.insert(.gc)
        }
        if wast.deletingLastPathComponent().path.hasSuffix("proposals/threads") {
            features.insert(.threads)
        }
        if usesFunctionReferences(wast) {
            features.insert(.functionReferences)
        }
        if wast.deletingLastPathComponent().lastPathComponent == "multi-memory" {
            features.insert(.multiMemory)
        }
        if wast.deletingLastPathComponent().path.hasSuffix("multi-memory/threads") {
            features.insert(.multiMemory)
            features.insert(.threads)
        }
        if wast.deletingLastPathComponent().lastPathComponent == "gc" {
            features.insert(.gc)
        }
        return features
    }

    struct Command: Decodable {
        enum CommandType: String, Decodable {
            case module
            /// `(module instance ...)`, which instantiates an earlier module definition.
            case instance
            case action
            case register
            case assertReturn = "assert_return"
            case assertInvalid = "assert_invalid"
            case assertTrap = "assert_trap"
            case assertMalformed = "assert_malformed"
            case assertExhaustion = "assert_exhaustion"
            case assertException = "assert_exception"
            case assertUnlinkable = "assert_unlinkable"
            case assertUninstantiable = "assert_uninstantiable"
            case assertReturnCanonicalNan = "assert_return_canonical_nan"
            case assertReturnArithmeticNan = "assert_return_arithmetic_nan"
        }

        enum ModuleType: String, Decodable {
            case binary
            case text
        }

        enum ValueType: String, Decodable {
            case i32
            case i64
            case f32
            case f64
            case externref
            case funcref
        }

        struct Value: Decodable {
            let type: ValueType
            let value: String
        }

        struct Expectation: Decodable {
            let type: ValueType
            let value: String?
        }

        struct Action: Decodable {
            enum ActionType: String, Decodable {
                case invoke
                case get
            }

            let type: ActionType
            let module: String?
            let field: String
            let args: [Value]?
        }

        let type: CommandType
        let line: Int
        let `as`: String?
        let name: String?
        let filename: String?
        let text: String?
        let moduleType: ModuleType?
        let action: Action?
        let expected: [Expectation]?
    }

    struct Content: Decodable {
        let sourceFilename: String
        let commands: [Command]
    }

    static func moduleFiles(json: URL) throws -> [(binary: URL, name: String?)] {
        var modules: [(binary: URL, name: String?)] = []
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let content = try decoder.decode(Content.self, from: Data(contentsOf: json))
        for command in content.commands {
            guard command.type == .module else { continue }
            let binary = json.deletingLastPathComponent().appendingPathComponent(command.filename!)
            modules.append((binary, command.name))
        }
        return modules
    }
}
