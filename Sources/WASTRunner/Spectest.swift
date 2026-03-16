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

/// What WasmKit cannot run yet in the spec testsuite, by path relative to its root.
package enum UnsupportedSpectests {
    private static let garbageCollection = "needs garbage collection"
    private static let branchHinting = "needs branch hinting"
    private static let nameAnnotation = "needs `@name` annotations on fields other than the module"

    /// Files with nothing WasmKit can run.
    package static let files: [String] =
        // Garbage collection
        [
            "array.wast", "array_copy.wast", "array_fill.wast", "array_init_data.wast", "array_init_elem.wast",
            "array_new_data.wast", "array_new_elem.wast", "extern.wast", "ref_cast.wast", "ref_null.wast",
            "ref_test.wast", "type-canon.wast", "type-subtyping.wast",
        ]

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
        "custom/branch_hint.wast": [
            50: branchHinting,  // Two hints on one instruction, which must be malformed
            67: branchHinting,  // A hint outside a function, which must be malformed
            85: branchHinting,  // A hint on an instruction that is not a branch, which must be invalid
        ],
        "custom/name_annot.wast": [
            25: nameAnnotation,  // `@name` on functions
            34: nameAnnotation,  // `@name` on tags
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
