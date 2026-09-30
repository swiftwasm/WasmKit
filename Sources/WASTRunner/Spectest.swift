import Foundation
import WAT
import WasmKit

private func loadStringArrayFromEnvironment(_ key: String) -> [String] {
    ProcessInfo.processInfo.environment[key]?.split(separator: ",").map(String.init) ?? []
}

package struct SpectestDiscovery {
    let path: [String]
    let include: [String]
    package let exclude: [String]

    package init(
        path: [String],
        include: [String] = loadStringArrayFromEnvironment("WASMKIT_SPECTEST_INCLUDE"),
        exclude: [String] = loadStringArrayFromEnvironment("WASMKIT_SPECTEST_EXCLUDE")
    ) {
        self.path = path
        self.include = include
        self.exclude = exclude
    }

    package func discover() throws -> [TestCase] {
        return try TestCase.load(include: include, exclude: exclude, in: path)
    }
}

/// What WasmKit cannot run yet at the top level of the spec testsuite, by file name.
package enum UnsupportedSpectests {
    private static let garbageCollection = "needs garbage collection"
    private static let moduleDefinitions = "needs `module definition` and `module instance`"
    private static let limits = "needs limits checked against their address type"
    private static let definedGlobalsInConstExpr = "needs constant expressions to read globals defined in the module"
    private static let memargOffsets = "needs a memarg offset checked against a 32-bit memory"
    private static let quotedIdentifiers = "needs quoted identifiers"

    /// Files with nothing WasmKit can run.
    package static let files: [String] =
        // Garbage collection
        [
            "array.wast", "array_copy.wast", "array_fill.wast", "array_init_data.wast", "array_init_elem.wast",
            "array_new_data.wast", "array_new_elem.wast", "extern.wast", "ref_cast.wast", "ref_null.wast",
            "ref_test.wast", "type-canon.wast", "type-subtyping.wast",
        ]
        + ["annotations.wast"]

    /// Directives to skip in the other files, by the line they start on. Skipping a module also
    /// skips the directives that use it.
    package static let directives: [String: [Int: String]] = [
        "br_on_cast.wast": [
            3: garbageCollection,  // Struct and array types
            104: garbageCollection,  // Subtypes of struct types
            211: garbageCollection,  // A struct type
            225: garbageCollection,  // A struct type, in a module that must be invalid
            234: garbageCollection,  // A struct type, in a module that must be invalid
            243: garbageCollection,  // A struct type, in a module that must be invalid
            252: garbageCollection,  // `eqref` and `anyref`, in a module that must be invalid
            260: garbageCollection,  // `structref` and `arrayref`, in a module that must be invalid
        ],
        "br_on_cast_fail.wast": [
            3: garbageCollection,  // Struct and array types
            104: garbageCollection,  // Subtypes of struct types
            226: garbageCollection,  // A struct type
            240: garbageCollection,  // A struct type, in a module that must be invalid
            249: garbageCollection,  // A struct type, in a module that must be invalid
            258: garbageCollection,  // A struct type, in a module that must be invalid
            267: garbageCollection,  // `eqref` and `anyref`, in a module that must be invalid
            275: garbageCollection,  // `structref` and `arrayref`, in a module that must be invalid
        ],
        "i31.wast": [
            1: garbageCollection,  // `ref.i31` and `(ref i31)`
            33: garbageCollection,  // A `(ref.i31)` result, which the WAST parser does not read
            61: garbageCollection,  // A table of `i31ref`
            128: garbageCollection,  // A table of `(ref i31)` initialized from an imported global
            140: garbageCollection,  // A global of `i31ref` initialized from an imported global
            150: garbageCollection,  // Globals of `anyref` holding `i31ref` values
            168: garbageCollection,  // A table of `anyref` holding `i31ref` values
        ],
        "ref_eq.wast": [
            1: garbageCollection,  // Struct types and `eqref`
            121: garbageCollection,  // `(ref any)`, in a module that must be invalid
            129: garbageCollection,  // `(ref null any)`, in a module that must be invalid
        ],
        "struct.wast": [
            3: garbageCollection,  // Struct types
            25: garbageCollection,  // A recursion group of struct types
            36: garbageCollection,  // A struct type, in a module that must be invalid
            40: garbageCollection,  // A struct type, in a module that must be invalid
            48: garbageCollection,  // Struct types with named fields
            58: garbageCollection,  // A struct type, in a module that must be invalid
            70: garbageCollection,  // A struct type and the `struct.*` instructions
            122: garbageCollection,  // A `(ref.struct)` result, which the WAST parser does not read
            132: garbageCollection,  // A struct type, in a module that must be invalid
            145: garbageCollection,  // A struct type and `struct.get` on null
            160: garbageCollection,  // A struct type with packed fields
        ],
        "table_init.wast": [
            2272: garbageCollection  // A table of `arrayref`
        ],
        "table_init64.wast": [
            2457: garbageCollection  // A table of `arrayref`
        ],
        "tag.wast": [
            30: garbageCollection,  // A recursion group; exports the tag the directives below import
            40: garbageCollection,  // A recursion group
            48: garbageCollection,  // A recursion group, in a module that must fail to link
            59: garbageCollection,  // Expects an incompatible import of the tag exported by the module on line 30
        ],
        "type-equivalence.wast": [
            30: garbageCollection,  // A recursion group
            38: garbageCollection,  // A function type that refers to itself, which needs a recursion group
            49: garbageCollection,  // A recursion group
            136: garbageCollection,  // A recursion group
            161: garbageCollection,  // A recursion group
            233: garbageCollection,  // A recursion group
            238: garbageCollection,  // A recursion group; imports from the module on line 233
            246: garbageCollection,  // A recursion group
            257: garbageCollection,  // A recursion group
            268: garbageCollection,  // A recursion group
            279: garbageCollection,  // A recursion group
            290: garbageCollection,  // A recursion group
            308: garbageCollection,  // A recursion group
        ],
        "type-rec.wast": [
            3: garbageCollection,  // A function type that refers to itself, and recursion groups
            28: garbageCollection,  // A recursion group, in a module that must be invalid
            39: garbageCollection,  // A recursion group
            45: garbageCollection,  // A recursion group
            51: garbageCollection,  // A recursion group, in a module that must be invalid
            59: garbageCollection,  // A recursion group, in a module that must be invalid
            71: garbageCollection,  // A recursion group
            78: garbageCollection,  // A recursion group
            93: garbageCollection,  // A recursion group, in a module that must be invalid
            103: garbageCollection,  // A recursion group, in a module that must be invalid
            114: garbageCollection,  // A recursion group, in a module that must be invalid
            124: garbageCollection,  // A recursion group, in a module that must be invalid
            137: garbageCollection,  // A recursion group
            143: garbageCollection,  // A recursion group; imports from the module on line 137
            148: garbageCollection,  // A recursion group; expects an incompatible import from the module on line 137
            156: garbageCollection,  // A recursion group; expects an incompatible import from the module on line 137
            167: garbageCollection,  // A recursion group
            176: garbageCollection,  // A recursion group
            185: garbageCollection,  // A recursion group
            197: garbageCollection,  // A recursion group
            204: garbageCollection,  // A recursion group, in a module that must be invalid
            216: garbageCollection,  // A recursion group, in a module that must be invalid
        ],

        // Not implemented yet by WasmKit itself.
        "instance.wast": [
            3: moduleDefinitions,  // Defines `$M`, which the directives below instantiate
            10: moduleDefinitions,  // Instantiates `$M`
            11: moduleDefinitions,  // Instantiates `$M`
            12: moduleDefinitions,  // Registers the instance from line 10
            13: moduleDefinitions,  // Registers the instance from line 11
            15: moduleDefinitions,  // Imports from the instances made on lines 10 and 11
            62: moduleDefinitions,  // Imports from the instance made on line 10
            109: moduleDefinitions,  // Defines `$N`, which the directives below instantiate
            125: moduleDefinitions,  // Instantiates `$N`
            126: moduleDefinitions,  // Registers the instance from line 125
            128: moduleDefinitions,  // Imports from the instance made on line 125
        ],
        "memory.wast": [
            8: moduleDefinitions,  // A memory of 65536 pages, defined but not instantiated
            77: limits,  // `(memory 0x1_0000_0000)`, which must fail validation rather than parsing
            81: limits,  // An i32 minimum and maximum beyond u32, which must fail validation rather than parsing
            85: limits,  // An i32 maximum beyond u32, which must fail validation rather than parsing
            90: limits,  // An imported i32 memory with a minimum beyond u32, which must be invalid
            94: limits,  // An imported i32 memory with a minimum and maximum beyond u32, which must be invalid
            98: limits,  // An imported i32 memory with a maximum beyond u32, which must be invalid
        ],
        "memory64.wast": [
            8: moduleDefinitions,  // A memory of 2^48 pages, defined but not instantiated
            57: limits,  // A memory64 maximum of more than 2^48 pages, which must be invalid
        ],
        "table.wast": [
            9: moduleDefinitions  // A table of 2^32 - 1 elements, defined but not instantiated
        ],
        "table64.wast": [
            8: limits,  // A table64 maximum beyond 2^32 - 1
            9: moduleDefinitions,  // A table of 2^64 - 1 elements, defined but not instantiated
            10: limits,  // A table64 maximum of 2^64 - 1
        ],
        "data.wast": [
            89: definedGlobalsInConstExpr,  // A data segment offset read from a defined global
            90: definedGlobalsInConstExpr,  // A data segment offset read from a defined global, by name
        ],
        "elem.wast": [
            178: definedGlobalsInConstExpr,  // An element segment offset read from a defined global
            182: definedGlobalsInConstExpr,  // An element segment offset read from a defined global, by name
        ],
        "global.wast": [
            373: definedGlobalsInConstExpr,  // A global initialized from a defined global
            374: definedGlobalsInConstExpr,  // A global initialized from a defined global, by name
            634: definedGlobalsInConstExpr,  // Globals, segment offsets and table entries read from defined globals
        ],
        "load64.wast": [
            571: memargOffsets  // An i32 load from a 32-bit memory beside a memory64, with `offset=4294967296`, which must be invalid
        ],
        "align.wast": [
            1004: memargOffsets  // An i32 memory with `offset=0xFFFF_FFFF_FFFF_FFFF`, which must be invalid
        ],
        "id.wast": [
            1: quotedIdentifiers,  // Quoted identifiers such as `$"fh"`
            26: quotedIdentifiers,  // An empty identifier, `$`, which must be malformed
            27: quotedIdentifiers,  // An empty quoted identifier, which must be malformed
            29: quotedIdentifiers,  // A raw newline in a quoted identifier, which must be malformed
            30: quotedIdentifiers,  // A raw tab in a quoted identifier, which must be malformed
            31: quotedIdentifiers,  // A quoted identifier of invalid UTF-8, which must be malformed
        ],
    ]

    /// Every file that `files` or `directives` names.
    package static var affectedFiles: [String] { files + directives.keys }

}

package protocol SpectestProgressReporter {
    /// `verbose` marks a message that only a verbose reporter should surface.
    func log(_ message: String, verbose: Bool)
    func log(_ message: String, path: String, location: Location, verbose: Bool)
}

package struct NullSpectestProgressReporter: SpectestProgressReporter {
    package init() {}

    package func log(_ message: String, verbose: Bool) {}
    package func log(_ message: String, path: String, location: Location, verbose: Bool) {}
}

package struct SpectestRunner {
    let hostModule: Module
    let configuration: EngineConfiguration

    package init(configuration: EngineConfiguration) throws {
        self.configuration = configuration
        // https://github.com/WebAssembly/spec/tree/8a352708cffeb71206ca49a0f743bdc57269fb1a/interpreter#spectest-host-module
        hostModule = try parseWasm(
            bytes: wat2wasm(
                """
                    (module
                      (global (export "global_i32") i32 (i32.const 666))
                      (global (export "global_i64") i64 (i64.const 666))
                      (global (export "global_f32") f32 (f32.const 666.6))
                      (global (export "global_f64") f64 (f64.const 666.6))

                      (table (export "table") 10 20 funcref)
                      (table (export "table64") 10 20 funcref)

                      (memory (export "memory") 1 2)

                      (func (export "print"))
                      (func (export "print_i32") (param i32))
                      (func (export "print_i64") (param i64))
                      (func (export "print_f32") (param f32))
                      (func (export "print_f64") (param f64))
                      (func (export "print_i32_f32") (param i32 f32))
                      (func (export "print_f64_f64") (param f64 f64))
                    )
                """
            ),
            features: [.referenceTypes]
        )
    }

    struct Failures: Error, CustomStringConvertible {
        let test: TestCase
        let failures: [(Location, reason: String)]

        var description: String {
            return failures.map { (location, reason) in
                let (line, _) = location.computeLineAndColumn()
                return "\(test.relativePath):\(line): \(reason)"
            }.joined(separator: "\n")
        }
    }

    package struct Outcome {
        package var passed = 0
        package var failed = 0
        package var skipped = 0
        package var failures: [(Location, reason: String)] = []
    }

    /// A failing assertion lands in ``Outcome/failures``; only a script that cannot be parsed throws.
    /// - Parameter skip: Why each directive to skip is skipped, keyed by the line it starts on.
    package func evaluate(test: TestCase, reporter: SpectestProgressReporter, skip: [Int: String] = [:]) throws -> Outcome {
        var outcome = Outcome()
        try test.run(spectestModule: hostModule, configuration: configuration, skip: skip) { test, location, result in
            switch result {
            case .failed(let reason):
                reporter.log("\(result.banner) \(reason)", path: test.path, location: location, verbose: false)
                outcome.failed += 1
                outcome.failures.append((location, reason))
            case .skipped(let reason):
                reporter.log("\(result.banner) \(reason)", path: test.path, location: location, verbose: true)
                outcome.skipped += 1
            case .passed:
                reporter.log(result.banner, path: test.path, location: location, verbose: true)
                outcome.passed += 1
            }
        }
        return outcome
    }

    /// - Parameter skip: Why each directive to skip is skipped, keyed by the line it starts on.
    package func run(test: TestCase, reporter: SpectestProgressReporter, skip: [Int: String] = [:]) throws {
        let logDuration: () -> Void
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            let start = ContinuousClock.now
            logDuration = {
                let elapsed = ContinuousClock.now - start
                reporter.log("Finished \(test.relativePath) in \(elapsed)", verbose: false)
            }
        } else {
            // Fallback on earlier versions
            logDuration = {}
        }
        reporter.log("Testing  \(test.relativePath)", verbose: false)
        let outcome = try evaluate(test: test, reporter: reporter, skip: skip)
        logDuration()

        if !outcome.failures.isEmpty {
            throw Failures(test: test, failures: outcome.failures)
        }
    }
}
