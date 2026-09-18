import ArgumentParser
import Darwin
import Foundation
import WAT
import WasmKit

/// Reproducible token-dispatch workloads for an ordinary and optionally controlled store.
@main
struct EngineBench: ParsableCommand {
    /// The control configuration selected for this process.
    @Option var mode = "unmetered"
    /// The interpreter dispatch mode shared by compared processes.
    @Option var threading = "token"
    /// The workload names selected for this process.
    @Option var workloads = "dispatch,exports,imports,exceptions"
    /// The discarded repetitions before recording a workload.
    @Option var warmups = 2
    /// Checks workload outputs without reading the clock or recording timings.
    @Flag var verifyOnly = false
    /// The repeated invocations in the export and host-import workloads.
    @Option var calls: UInt32 = 200_000
    /// The caught exceptions handled by each exception workload.
    @Option var exceptions: UInt32 = 100_000
    /// The number of measured samples after the configured discarded batches.
    @Option var samples = 7
    /// The loop iterations performed by each WAT sample.
    @Option var iterations: UInt32 = 10_000_000

    /// Executes the selected workloads consecutively and emits their raw timings as JSON.
    ///
    /// - Throws: Argument, module, interpreter, or JSON encoding failures.
    mutating func run() throws {
        guard samples > 0, warmups > 0, iterations > 0, calls > 0, exceptions > 0,
            ["unmetered", "controlled"].contains(mode), ["token", "direct"].contains(threading),
            mode != "controlled" || threading == "token"
        else {
            throw ValidationError(
                "Positive sample counts and an unmetered or controlled mode are required."
            )
        }
        guard pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0) == 0 else {
            throw ValidationError("The benchmark could not select its execution thread's QoS.")
        }
        var results: [Measurement] = []
        for workload in workloads.split(separator: ",") {
            switch workload {
            case "dispatch": results.append(try loopBenchmark())
            case "exports": results.append(try exportBenchmark())
            case "imports": results.append(try importBenchmark())
            case "exceptions": results.append(try exceptionBenchmark())
            default: throw ValidationError("Unknown workload.")
            }
        }
        let encoded = try JSONEncoder().encode(results)
        FileHandle.standardOutput.write(encoded)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    /// Creates one store with the selected dispatch model and software memory bounds checks.
    ///
    /// - Returns: An ordinary or controlled store with lazy compilation and software bounds checks.
    /// - Throws: An unsupported benchmark mode or control configuration failure.
    private func store() throws -> Store {
        let engine = Engine(
            configuration: EngineConfiguration(
                threadingModel: threading == "token" ? .token : .direct,
                compilationMode: .lazy,
                memoryBoundsChecking: .software
            ))
        #if CONTROLLED
            if mode != "unmetered" {
                return try Store(
                    engine: engine,
                    executionControl: ExecutionControl(
                        pollingInterval: 1024
                    ))
            }
        #else
            guard mode == "unmetered"
            else { throw ValidationError("The baseline build has no execution controller.") }
        #endif
        return Store(engine: engine)
    }

    /// Measures a function-local arithmetic loop after its first lazy translation has completed.
    ///
    /// - Returns: Raw sample durations with the result checked against the same integer recurrence.
    /// - Throws: WAT parsing, instantiation, invocation, or result-validation failures.
    private func loopBenchmark() throws -> Measurement {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module
                  (func (export "work") (param $n i32) (result i32) (local $x i32)
                    i32.const 123 local.set $x
                    loop $loop
                      local.get $x i32.const 1664525 i32.mul
                      i32.const 1013904223 i32.add local.set $x
                      local.get $n i32.const 1 i32.sub local.tee $n br_if $loop
                    end
                    local.get $x))
                """))
        let instance = try module.instantiate(store: store())
        guard let function = instance.exports[function: "work"]
        else { throw ValidationError("Missing work export.") }
        var expected: UInt32 = 123
        for _ in 0..<iterations {
            expected = expected &* 1_664_525 &+ 1_013_904_223
        }
        var times: [Double] = []
        for sample in 0..<(verifyOnly ? 1 : warmups + samples) {
            let start: ContinuousClock.Instant? = verifyOnly ? nil : .now
            let values = try function([.i32(iterations)])
            let duration = start.map { milliseconds($0.duration(to: .now)) } ?? 0
            guard values == [.i32(expected)]
            else { throw ValidationError("The loop produced the wrong result.") }
            if !verifyOnly && sample >= warmups { times.append(duration) }
        }
        return Measurement(
            workload: "wat_arithmetic",
            mode: mode,
            count: Int(iterations),
            milliseconds: times
        )
    }

    /// Measures short export invocations after lazy translation is complete.
    ///
    /// - Returns: The raw durations after every batch produces the expected result.
    /// - Throws: Fixture parsing, invocation, or result-validation failures.
    private func exportBenchmark() throws -> Measurement {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module (func (export "work") (param i32) (result i32)
                    local.get 0 i32.const 1 i32.add))
                """))
        let instance = try module.instantiate(store: store())
        guard let function = instance.exports[function: "work"] else { throw ValidationError("Missing work export.") }
        return try measure("short_exports", count: Int(calls)) {
            var value: UInt32 = 0
            for _ in 0..<calls {
                let result = try function([.i32(value)])
                guard result.count == 1 else { throw ValidationError("Missing export result.") }
                value = result[0].i32
            }
            guard value == calls else { throw ValidationError("Unexpected export result.") }
        }
    }

    /// Measures calls from a guest loop into a small native integer import.
    ///
    /// - Returns: The raw durations after every batch produces the expected result.
    /// - Throws: Fixture parsing, invocation, or result-validation failures.
    private func importBenchmark() throws -> Measurement {
        let store = try store()
        var imports = Imports()
        imports.define(
            module: "host", name: "step",
            Function(store: store, parameters: [.i32], results: [.i32]) { _, values in
                [.i32(values[0].i32 &+ 1)]
            })
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module (import "host" "step" (func $step (param i32) (result i32)))
                    (func (export "work") (param $n i32) (result i32) (local $x i32)
                        loop $again
                            local.get $x call $step local.set $x
                            local.get $n i32.const 1 i32.sub local.tee $n br_if $again
                        end local.get $x))
                """))
        let instance = try module.instantiate(store: store, imports: imports)
        guard let function = instance.exports[function: "work"] else { throw ValidationError("Missing work export.") }
        return try measure("host_imports", count: Int(calls)) {
            guard try function([.i32(calls)]) == [.i32(calls)] else { throw ValidationError("Unexpected import result.") }
        }
    }

    /// Measures repeated guest throws caught by a surrounding exception handler.
    ///
    /// - Returns: The raw durations after every batch produces the expected result.
    /// - Throws: Fixture parsing, invocation, or result-validation failures.
    private func exceptionBenchmark() throws -> Measurement {
        let module = try parseWasm(
            bytes: wat2wasm(
                """
                (module (tag $failure)
                    (func (export "work") (param $n i32) (result i32) (local $x i32)
                        loop $again
                            block $caught
                                try_table (catch_all $caught) throw $failure end
                            end
                            local.get $x i32.const 1 i32.add local.set $x
                            local.get $n i32.const 1 i32.sub local.tee $n br_if $again
                        end local.get $x))
                """))
        let instance = try module.instantiate(store: store())
        guard let function = instance.exports[function: "work"] else { throw ValidationError("Missing work export.") }
        return try measure("caught_exceptions", count: Int(exceptions)) {
            guard try function([.i32(exceptions)]) == [.i32(exceptions)] else { throw ValidationError("Unexpected exception result.") }
        }
    }

    /// Checks every measured result after discarded warmups and retains each raw duration.
    ///
    /// - Parameters:
    ///   - workload: The stable workload name shared by both executables.
    ///   - count: The number of loop iterations or invocations performed by one batch.
    ///   - body: The synchronous workload that validates its result before returning.
    /// - Returns: A measurement containing raw durations, or no durations during untimed verification.
    /// - Throws: A workload or result-validation failure.
    private func measure(_ workload: String, count: Int, body: () throws -> Void) throws -> Measurement {
        var times: [Double] = []
        for sample in 0..<(verifyOnly ? 1 : warmups + samples) {
            let start: ContinuousClock.Instant? = verifyOnly ? nil : .now
            try body()
            if let start, sample >= warmups {
                times.append(milliseconds(start.duration(to: .now)))
            }
        }
        return Measurement(workload: workload, mode: mode, count: count, milliseconds: times)
    }

}

/// Raw timings retained independently of summary statistics and cross-build comparisons.
private struct Measurement: Encodable {
    /// The stable workload name shared by baseline and modified builds.
    let workload: String
    /// The execution-control configuration selected by the CLI.
    let mode: String
    /// The iterations or calls performed by each sample.
    let count: Int
    /// The measured durations after configured warmup batches, or none during untimed verification.
    let milliseconds: [Double]
}

/// Converts a monotonic duration to fractional milliseconds without rounding raw samples.
///
/// - Parameter duration: The time spent in one benchmark sample.
/// - Returns: Elapsed milliseconds for JSON output.
private func milliseconds(_ duration: Duration) -> Double {
    Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15
}
