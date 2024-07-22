import Foundation
import SystemPackage
import WAT
import WasmKit

@available(macOS 11, *)
public func spectest(
    path: [String],
    include: String?,
    exclude: String?,
    verbose: Bool = false,
    parallel: Bool = true
) async throws -> Bool {
    let printVerbose = verbose
    @Sendable func log(_ message: String, verbose: Bool = false) {
        if !verbose || printVerbose {
            fputs(message + "\n", stderr)
        }
    }
    func percentage(_ numerator: Int, _ denominator: Int) -> String {
        "\(Int(Double(numerator) / Double(denominator) * 100))%"
    }

    let include = include.flatMap { $0.split(separator: ",").map(String.init) } ?? []
    let exclude = exclude.flatMap { $0.split(separator: ",").map(String.init) } ?? []

    let testCases: [TestCase]
    do {
        testCases = try TestCase.load(include: include, exclude: exclude, in: path, log: { log($0) })
    } catch {
        fatalError("failed to load test: \(error)")
    }

    guard !testCases.isEmpty else {
        log("No test found")
        return true
    }

    // https://github.com/WebAssembly/spec/tree/8a352708cffeb71206ca49a0f743bdc57269fb1a/interpreter#spectest-host-module
    let hostModule = try parseWasm(
        bytes: wat2wasm(
            """
                (module
                  (global (export "global_i32") i32 (i32.const 666))
                  (global (export "global_i64") i64 (i64.const 666))
                  (global (export "global_f32") f32 (f32.const 666))
                  (global (export "global_f64") f64 (f64.const 666))

                  (table (export "table") 10 20 funcref)

                  (memory (export "memory") 1 2)

                  (func (export "print"))
                  (func (export "print_i32") (param i32))
                  (func (export "print_i64") (param i64))
                  (func (export "print_f32") (param f32))
                  (func (export "print_f64") (param f64))
                  (func (export "print_i32_f32") (param i32 f32))
                  (func (export "print_f64_f64") (param f64 f64))
                )
            """))

    @Sendable func runTestCase(testCase: TestCase) throws -> [Result] {
        var testCaseResults = [Result]()
        log("Testing \(testCase.path)")
        try testCase.run(spectestModule: hostModule) { testCase, location, result in
            let (line, _) = location.computeLineAndColumn()
            switch result {
            case let .failed(reason):
                log("\(testCase.path):\(line): \(result.banner) \(reason)")
            case let .skipped(reason):
                log("\(testCase.path):\(line): \(result.banner) \(reason)", verbose: true)
            case .passed:
                log("\(testCase.path):\(line): \(result.banner)", verbose: true)
            default:
                log("\(testCase.path):\(line): \(result.banner)")
            }
            testCaseResults.append(result)
        }

        return testCaseResults
    }

    let results: [Result]

    if parallel {
        results = try await withThrowingTaskGroup(of: [Result].self) { group in
            for testCase in testCases {
                group.addTask {
                    try await Task { try runTestCase(testCase: testCase) }.value
                }
            }

            var results = [Result]()
            for try await testCaseResults in group {
                results.append(contentsOf: testCaseResults)
            }

            return results
        }
    } else {
        results = try testCases.flatMap { try runTestCase(testCase: $0) }
    }

    let passingCount = results.filter { if case .passed = $0 { return true } else { return false } }.count
    let skippedCount = results.filter { if case .skipped = $0 { return true } else { return false } }.count
    let failedCount = results.filter { if case .failed = $0 { return true } else { return false } }.count

    print(
        """
        \(passingCount)/\(results.count) (\(
            percentage(passingCount, results.count)
        ) passing, \(
            percentage(skippedCount, results.count)
        ) skipped, \(
            percentage(failedCount, results.count)
        ) failed)
        """
    )
    return failedCount == 0
}
