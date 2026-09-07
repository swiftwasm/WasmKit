import Foundation
import WAT
import WasmKit

/// Replays the [wasmi-benchmarks](https://github.com/wasmi-labs/wasmi-benchmarks)
/// `execute/*` suite and CoreMark against WasmKit.
///
/// The inputs and the result assertions are the ones from the suite's own
/// `benches/criterion/execute.rs`, so the numbers printed here can be compared
/// against a `cargo bench --bench criterion -- execute/` run of the same
/// checkout on the same machine. See `Benchmarks/README.md`.
///
/// Output is CSV on stdout:
///
///     execute/<name>,<mean_ms>,<min_ms>,<iters>
///     coremark,<score>
@main
struct WasmiBenchmarks {
    static func main() throws {
        let options = try Options.parse(CommandLine.arguments)
        let runner = Runner(options: options)
        try runner.run()
        exit(runner.hasMismatch ? EXIT_FAILURE : EXIT_SUCCESS)
    }
}

// MARK: - Options

struct Options {
    /// Root of a wasmi-benchmarks checkout (the directory holding `res/`).
    var root: URL
    /// Only run cases whose name contains this substring.
    var filter: String?
    var compilationMode: EngineConfiguration.CompilationMode?
    var threadingModel: EngineConfiguration.ThreadingModel?
    var memoryBoundsChecking: EngineConfiguration.MemoryBoundsChecking?

    /// `<repo>/Vendor/wasmi-benchmarks`, derived from this source file's location
    /// (`<repo>/Benchmarks/Sources/WasmiBenchmarks/`).
    static var defaultRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // WasmiBenchmarks
            .deletingLastPathComponent()  // Sources
            .deletingLastPathComponent()  // Benchmarks
            .deletingLastPathComponent()  // <repo>
            .appendingPathComponent("Vendor")
            .appendingPathComponent("wasmi-benchmarks")
    }

    static let usage = """
        usage: WasmiBenchmarks [filter] [--root <wasmi-benchmarks>] [--eager] [--token] [--software-bounds]

          filter               Only run cases whose name contains this substring.
          --root <path>        wasmi-benchmarks checkout to replay.
                               (default: <repo>/Vendor/wasmi-benchmarks)
          --eager              Compile eagerly instead of lazily.
          --token              Use token-threaded dispatch instead of direct threading.
          --software-bounds    Use software memory bounds checking.
        """

    static func parse(_ arguments: [String]) throws -> Options {
        var options = Options(root: defaultRoot)
        var arguments = arguments.dropFirst().makeIterator()
        while let argument = arguments.next() {
            switch argument {
            case "--root":
                guard let path = arguments.next() else {
                    throw CommandError("--root requires a path")
                }
                options.root = URL(fileURLWithPath: path)
            case "--eager": options.compilationMode = .eager
            case "--token": options.threadingModel = .token
            case "--software-bounds": options.memoryBoundsChecking = .software
            case "-h", "--help":
                print(usage)
                exit(EXIT_SUCCESS)
            case let argument where argument.hasPrefix("-"):
                throw CommandError("unknown option '\(argument)'\n\(usage)")
            case let argument:
                guard options.filter == nil else {
                    throw CommandError("unexpected extra argument '\(argument)'\n\(usage)")
                }
                options.filter = argument
            }
        }
        return options
    }
}

struct CommandError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

// MARK: - Cases

/// `Value` has both `i32` as a case and as an accessor, so spell the signed
/// constructors out instead of extending it.
private func i32(_ value: Int32) -> Value { Value(signed: value) }
private func i64(_ value: Int64) -> Value { Value(signed: value) }

/// A case built from `res/wat/<name>.wat`, exporting `run(input) -> input`.
private struct WatCase {
    let name: String
    let input: Value
}

/// A case built from `res/rust/cases/<name>/out.wasm`.
///
/// Rust cases export `setup`, `run` and `teardown`. `setup` either takes the
/// workload size, or the byte length of a text input that is then written into
/// the guest memory at `input_ptr`.
private struct RustCase {
    enum Input {
        /// `setup(size) -> data`
        case size(Value)
        /// `setup() -> data`
        case none
        /// `setup(len(<file>)) -> data`, then `<file>` copied to `input_ptr(data)`.
        case text(String)
    }

    let name: String
    let input: Input
    /// Assertions run once after the measurement, against `data` from `setup`.
    let check: ((Runner, Instance, Value) throws -> Void)?

    init(_ name: String, _ input: Input, check: ((Runner, Instance, Value) throws -> Void)? = nil) {
        self.name = name
        self.input = input
        self.check = check
    }
}

private let alice = "res/rust/res/alice29.txt"
private let fasta = "res/rust/cases/reverse-complement/input.txt"

// MARK: - Runner

final class Runner {
    private let options: Options
    /// Set when a result assertion failed; turns into a non-zero exit status.
    private(set) var hasMismatch = false

    init(options: Options) {
        self.options = options
    }

    func run() throws {
        if shouldRun("coremark") {
            try runCoreMark()
        }
        for watCase in watCases where shouldRun(watCase.name) {
            try run(watCase)
        }
        for rustCase in rustCases where shouldRun(rustCase.name) {
            try run(rustCase)
        }
    }

    private func shouldRun(_ name: String) -> Bool {
        guard let filter = options.filter else { return true }
        return name.contains(filter)
    }

    // MARK: Case tables

    private var watCases: [WatCase] {
        [
            WatCase(name: "counter-local", input: i32(1_000_000)),
            WatCase(name: "counter-param", input: i32(1_000_000)),
            WatCase(name: "counter-global", input: i32(500_000)),
            WatCase(name: "fibonacci-rec", input: i64(30)),
            WatCase(name: "fibonacci-iter", input: i64(2_000_000)),
            WatCase(name: "fibonacci-tail", input: i64(1_000_000)),
            WatCase(name: "bulk-ops", input: i64(5_000)),
        ]
    }

    private var rustCases: [RustCase] {
        [
            RustCase("sort", .size(i32(1_000_000))),
            RustCase("sort-dyn", .size(i32(400_000))),
            RustCase("prime-sieve", .size(i64(10_000_000))) { runner, instance, data in
                try runner.expect(instance, "len_primes", data, i64: 664_579)
                try runner.expect(instance, "largest_prime", data, i64: 9_999_991)
            },
            RustCase("matrix-mul", .size(i32(400))),
            RustCase("nbody", .size(i32(400))),
            RustCase("argon2", .size(i32(3_000))) { runner, instance, data in
                try runner.expect(instance, "output", data, rawI64: 0x7631_8FB4_8BBA_1258)
            },
            RustCase("tiny-keccak", .none),
            RustCase("mandelbrot", .size(i32(150))) { runner, instance, data in
                try runner.expect(instance, "output", data, i64: 5_595_328)
            },
            RustCase("spectralnorm", .size(i32(500))) { runner, instance, data in
                try runner.expect(instance, "output", data, f64: 1.2742241159529095)
            },
            RustCase("compression", .text(alice)) { runner, instance, data in
                try runner.expect(instance, "len_compressed", data, i64: 97_649)
            },
            RustCase("word-count", .text(alice)) { runner, instance, data in
                try runner.expect(instance, "len_unique_words", data, i64: 2_213)
                try runner.expect(instance, "len_special_chars", data, i64: 6_314)
            },
            RustCase("json-parse", .text("res/rust/res/citm_catalog.json")) { runner, instance, data in
                try runner.expect(instance, "node_count", data, i64: 37_778)
            },
            RustCase("reverse-complement", .text(fasta)) { runner, instance, data in
                let expected = try runner.readFile("res/rust/cases/reverse-complement/output.txt")
                let pointer = try instance.exports[function: "output_ptr"]!([data])[0].i32
                let actual = runner.readMemory(instance, at: pointer, count: expected.count)
                runner.expect(actual == expected, true, "reverse-complement.output")
            },
            RustCase("regex-redux", .text(fasta)) { runner, instance, data in
                try runner.expect(instance, "output", data, i32: 2)
            },
        ]
    }

    // MARK: Engine and module loading

    private func makeStore() -> Store {
        let engine = Engine(
            configuration: EngineConfiguration(
                threadingModel: options.threadingModel,
                compilationMode: options.compilationMode,
                // The deeply recursive cases (fibonacci-rec) need more than the default.
                stackSize: 8 << 20,
                memoryBoundsChecking: options.memoryBoundsChecking
            ))
        return Store(engine: engine)
    }

    private func url(_ relativePath: String) -> URL {
        options.root.appendingPathComponent(relativePath)
    }

    func readFile(_ relativePath: String) throws -> [UInt8] {
        Array(try Data(contentsOf: url(relativePath)))
    }

    private func loadWat(_ name: String) throws -> Module {
        let source = try String(contentsOf: url("res/wat/\(name).wat"), encoding: .utf8)
        return try parseWasm(bytes: try wat2wasm(source))
    }

    private func loadWasm(_ relativePath: String) throws -> Module {
        try parseWasm(filePath: url(relativePath).path)
    }

    // MARK: Cases

    private func run(_ watCase: WatCase) throws {
        let store = makeStore()
        let instance = try loadWat(watCase.name).instantiate(store: store)
        let run = instance.exports[function: "run"]!
        try measure(watCase.name) { _ = try run([watCase.input]) }
    }

    private func run(_ rustCase: RustCase) throws {
        let store = makeStore()
        let instance = try loadWasm("res/rust/cases/\(rustCase.name)/out.wasm").instantiate(store: store)
        let setup = instance.exports[function: "setup"]!

        let data: Value
        switch rustCase.input {
        case .size(let size):
            data = try setup([size])[0]
        case .none:
            data = try setup([])[0]
        case .text(let relativePath):
            let bytes = try readFile(relativePath)
            data = try setup([i32(Int32(bytes.count))])[0]
            let pointer = try instance.exports[function: "input_ptr"]!([data])[0].i32
            writeMemory(instance, at: pointer, bytes)
        }

        let run = instance.exports[function: "run"]!
        try measure(rustCase.name) { _ = try run([data]) }
        try rustCase.check?(self, instance, data)
        _ = try instance.exports[function: "teardown"]!([data])
    }

    /// CoreMark reports its own score, so it is run exactly once instead of being timed.
    private func runCoreMark() throws {
        let store = makeStore()
        let module = try loadWasm("res/wasm/coremark.wasm")
        let start = Self.now()
        let clockMs = Function(store: store, parameters: [], results: [.i32]) { _, _ in
            [Value(signed: Int32(truncatingIfNeeded: (Self.now() - start) / 1_000_000))]
        }
        let instance = try module.instantiate(store: store, imports: ["env": ["clock_ms": clockMs]])
        let result = try instance.exports[function: "run"]!([])
        let score = Float(bitPattern: result[0].f32)
        emit(String(format: "coremark,%.2f", score))
    }

    // MARK: Measurement

    private static func now() -> UInt64 { DispatchTime.now().uptimeNanoseconds }

    /// Criterion-like: warm up for ~1 s, then measure for ~2 s and at least 10
    /// iterations. Reports the mean and the minimum wall time of one `run`.
    private func measure(_ name: String, _ body: () throws -> Void) rethrows {
        let warmupNanoseconds: UInt64 = 1_000_000_000
        let measureNanoseconds: UInt64 = 2_000_000_000
        let minimumIterations = 10

        var start = Self.now()
        while Self.now() - start < warmupNanoseconds { try body() }

        var iterations = 0
        var minimum = UInt64.max
        var elapsed: UInt64 = 0
        start = Self.now()
        while elapsed < measureNanoseconds || iterations < minimumIterations {
            let iterationStart = Self.now()
            try body()
            minimum = min(minimum, Self.now() - iterationStart)
            iterations += 1
            elapsed = Self.now() - start
        }

        let meanMilliseconds = Double(elapsed) / Double(iterations) / 1e6
        emit(
            String(
                format: "execute/%@,%.3f,%.3f,%d",
                name, meanMilliseconds, Double(minimum) / 1e6, iterations))
    }

    private func emit(_ line: String) {
        print(line)
        fflush(nil)
    }

    // MARK: Guest memory

    private func writeMemory(_ instance: Instance, at pointer: UInt32, _ bytes: [UInt8]) {
        let memory = instance.exports[memory: "memory"]!
        memory.withUnsafeMutableBufferPointer(offset: UInt(pointer), count: bytes.count) { buffer in
            bytes.withUnsafeBytes { source in
                buffer.baseAddress!.copyMemory(from: source.baseAddress!, byteCount: source.count)
            }
        }
    }

    func readMemory(_ instance: Instance, at pointer: UInt32, count: Int) -> [UInt8] {
        let memory = instance.exports[memory: "memory"]!
        return memory.withUnsafeMutableBufferPointer(offset: UInt(pointer), count: count) { buffer in
            Array(buffer.bindMemory(to: UInt8.self))
        }
    }

    // MARK: Assertions

    func expect<T: Equatable>(_ actual: T, _ expected: T, _ what: String) {
        guard actual != expected else { return }
        hasMismatch = true
        FileHandle.standardError.write(
            Data("MISMATCH \(what): got \(actual), expected \(expected)\n".utf8))
    }

    private func call(_ instance: Instance, _ name: String, _ data: Value) throws -> Value {
        try instance.exports[function: name]!([data])[0]
    }

    func expect(_ instance: Instance, _ name: String, _ data: Value, i32 expected: Int32) throws {
        expect(Int32(bitPattern: try call(instance, name, data).i32), expected, name)
    }

    func expect(_ instance: Instance, _ name: String, _ data: Value, i64 expected: Int64) throws {
        expect(Int64(bitPattern: try call(instance, name, data).i64), expected, name)
    }

    func expect(_ instance: Instance, _ name: String, _ data: Value, rawI64 expected: UInt64) throws {
        expect(try call(instance, name, data).i64, expected, name)
    }

    func expect(_ instance: Instance, _ name: String, _ data: Value, f64 expected: Double) throws {
        expect(Double(bitPattern: try call(instance, name, data).f64), expected, name)
    }
}
