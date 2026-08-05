import Foundation
import Testing
import WASTRunner
import WasmKit

@Suite struct WASTRunnerTests {
    private static let script = """
        (module
          (func (export "answer") (result i32) (i32.const 42))
        )
        (assert_return (invoke "answer") (i32.const 42))
        (assert_return (invoke "answer") (i32.const 7))
        """

    @Test func evaluateTalliesPassingAndFailingAssertions() throws {
        try withScript(Self.script) { script in
            let outcome = try SpectestRunner(configuration: EngineConfiguration())
                .evaluate(test: script, reporter: NullSpectestProgressReporter())

            // The module directive counts as a pass alongside the one passing assertion.
            #expect(outcome.passed == 2)
            #expect(outcome.failed == 1)
            #expect(outcome.failures.count == 1)
            #expect(outcome.failures.first?.reason.contains("result mismatch") == true)
        }
    }

    @Test func runReportsAFailingAssertionAsAnError() throws {
        try withScript(Self.script) { script in
            #expect(throws: (any Error).self) {
                try SpectestRunner(configuration: EngineConfiguration())
                    .run(test: script, reporter: NullSpectestProgressReporter())
            }
        }
    }

    /// Keeps the script out of `ExtraSuite`, which `SpectestTests` scans and would fail on it.
    private func withScript(_ text: String, _ body: (TestCase) throws -> Void) throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wast-runner-\(UUID().uuidString).wast")
        try Data(text.utf8).write(to: url)
        do {
            let script = try #require(TestCase.load(include: [], exclude: [], in: [url.path]).first)
            try body(script)
        } catch {
            try FileManager.default.removeItem(at: url)
            throw error
        }
        try FileManager.default.removeItem(at: url)
    }
}
