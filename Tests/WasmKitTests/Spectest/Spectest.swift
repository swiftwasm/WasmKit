import Foundation
import SystemPackage
import WAT
import WasmKit

private func loadStringArrayFromEnvironment(_ key: String) -> [String] {
    ProcessInfo.processInfo.environment[key]?.split(separator: ",").map(String.init) ?? []
}

struct SpectestDiscovery {
    let path: [String]
    let include: [String]
    let exclude: [String]

    init(
        path: [String],
        include: [String] = loadStringArrayFromEnvironment("WASMKIT_SPECTEST_INCLUDE"),
        exclude: [String] = loadStringArrayFromEnvironment("WASMKIT_SPECTEST_EXCLUDE")
    ) {
        self.path = path
        self.include = include
        self.exclude = exclude
    }

    func discover() throws -> [TestCase] {
        return try TestCase.load(include: include, exclude: exclude, in: path)
    }
}

protocol SpectestProgressReporter {
    func log(_ message: String, verbose: Bool)
    func log(_ message: String, path: String, location: Location, verbose: Bool)
}

extension SpectestProgressReporter {
    func log(_ message: String, verbose: Bool = false) {
        log(message, verbose: verbose)
    }
    func log(_ message: String, path: String, location: Location, verbose: Bool = false) {
        log(message, path: path, location: location, verbose: verbose)
    }
}

struct NullSpectestProgressReporter: SpectestProgressReporter {
    func log(_ message: String, verbose: Bool) {}
    func log(_ message: String, path: String, location: Location, verbose: Bool) {}
}

struct StderrSpectestProgressReporter: SpectestProgressReporter {
    func log(_ message: String, verbose: Bool) {
        try! FileHandle.standardError.write(contentsOf: Data((message + "\n").utf8))
    }
    func log(_ message: String, path: String, location: Location, verbose: Bool) {
        let (line, _) = location.computeLineAndColumn()
        try! FileHandle.standardError.write(contentsOf: Data(("\(path):\(line): " + message + "\n").utf8))
    }
}

struct SpectestRunner {
    let hostModule: Module
    let configuration: EngineConfiguration

    init(configuration: EngineConfiguration) throws {
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

    func run(test: TestCase, reporter: SpectestProgressReporter) throws {
        let logDuration: () -> Void
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            let start = ContinuousClock.now
            logDuration = {
                let elapsed = ContinuousClock.now - start
                reporter.log("Finished \(test.relativePath) in \(elapsed)")
            }
        } else {
            // Fallback on earlier versions
            logDuration = {}
        }
        reporter.log("Testing  \(test.relativePath)")
        var failures = [(Location, reason: String)]()
        try test.run(spectestModule: hostModule, configuration: configuration) { test, location, result in
            switch result {
            case .failed(let reason):
                reporter.log("\(result.banner) \(reason)", path: test.path, location: location)
                failures.append((location, reason))
            case .skipped(let reason):
                reporter.log("\(result.banner) \(reason)", path: test.path, location: location, verbose: true)
            case .passed:
                reporter.log(result.banner, path: test.path, location: location, verbose: true)
            }
        }
        logDuration()

        if !failures.isEmpty {
            throw Failures(test: test, failures: failures)
        }
    }
}
