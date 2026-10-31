import Testing
import WAT
import WasmParser

@_spi(OnlyForCLI) @testable import WasmKit

/// Checks the wide arithmetic instructions against Swift's own 128-bit integers.
@Suite
struct WideArithmeticTests {
    /// Each function exists twice. The `_locals` form stores both results into
    /// locals right after the instruction, which the translator turns into
    /// writes straight to the locals' registers.
    static let wat = """
        (module
          (func (export "add128") (param i64 i64 i64 i64) (result i64 i64)
            (i64.add128 (local.get 0) (local.get 1) (local.get 2) (local.get 3)))
          (func (export "sub128") (param i64 i64 i64 i64) (result i64 i64)
            (i64.sub128 (local.get 0) (local.get 1) (local.get 2) (local.get 3)))
          (func (export "mul_wide_s") (param i64 i64) (result i64 i64)
            (i64.mul_wide_s (local.get 0) (local.get 1)))
          (func (export "mul_wide_u") (param i64 i64) (result i64 i64)
            (i64.mul_wide_u (local.get 0) (local.get 1)))
          (func (export "add128_locals") (param i64 i64 i64 i64) (result i64 i64) (local $low i64) (local $high i64)
            (i64.add128 (local.get 0) (local.get 1) (local.get 2) (local.get 3))
            (local.set $high) (local.set $low) (local.get $low) (local.get $high))
          (func (export "sub128_locals") (param i64 i64 i64 i64) (result i64 i64) (local $low i64) (local $high i64)
            (i64.sub128 (local.get 0) (local.get 1) (local.get 2) (local.get 3))
            (local.set $high) (local.set $low) (local.get $low) (local.get $high))
          (func (export "mul_wide_s_locals") (param i64 i64) (result i64 i64) (local $low i64) (local $high i64)
            (i64.mul_wide_s (local.get 0) (local.get 1))
            (local.set $high) (local.set $low) (local.get $low) (local.get $high))
          (func (export "mul_wide_u_locals") (param i64 i64) (result i64 i64) (local $low i64) (local $high i64)
            (i64.mul_wide_u (local.get 0) (local.get 1))
            (local.set $high) (local.set $low) (local.get $low) (local.get $high))
        )
        """

    /// 64-bit operands around the sign bit, the 32-bit boundary and the carries between them.
    static let edges: [UInt64] = [
        0, 1, 2, 3, .max, .max - 1, 0x7FFF_FFFF_FFFF_FFFF, 0x8000_0000_0000_0000, 0x8000_0000_0000_0001,
        0xFFFF_FFFF, 0x1_0000_0000, 0xFFFF_FFFF_0000_0000, 0x7FFF_FFFF, 0xFFFF_FFFF_8000_0000,
        0x1_FFFF_FFFF, 0x5555_5555_5555_5555, 0xAAAA_AAAA_AAAA_AAAA, 0x1234_5678_9ABC_DEF0,
    ]

    /// A pair of operands for one call.
    struct Operands {
        let lhs: UInt128
        let rhs: UInt128
    }

    /// The operands of the 128-bit instructions: every pair of edges as low
    /// and high halves, followed by `randomCount` pseudo-random pairs.
    static func wideOperands(randomCount: Int) -> [Operands] {
        let highs: [UInt64] = [0, 1, .max, 0x8000_0000_0000_0000]
        let values = edges.flatMap { low in highs.map { high in UInt128(high) << 64 | UInt128(low) } }
        var operands = values.flatMap { lhs in values.map { rhs in Operands(lhs: lhs, rhs: rhs) } }
        var generator = SplitMix64(seed: 0x5EED)
        for _ in 0..<randomCount {
            let lhs = UInt128(generator.next()) << 64 | UInt128(generator.next())
            let rhs = UInt128(generator.next()) << 64 | UInt128(generator.next())
            operands.append(Operands(lhs: lhs, rhs: rhs))
        }
        return operands
    }

    /// The operands of the multiplications: every pair of edges, followed by
    /// `randomCount` pseudo-random pairs.
    static func narrowOperands(randomCount: Int) -> [Operands] {
        var operands = edges.flatMap { lhs in edges.map { rhs in Operands(lhs: UInt128(lhs), rhs: UInt128(rhs)) } }
        var generator = SplitMix64(seed: 0xC0FFEE)
        for _ in 0..<randomCount {
            operands.append(Operands(lhs: UInt128(generator.next()), rhs: UInt128(generator.next())))
        }
        return operands
    }

    static func halves(_ value: UInt128) -> [Value] {
        [.i64(UInt64(truncatingIfNeeded: value)), .i64(UInt64(truncatingIfNeeded: value >> 64))]
    }

    static func instance(threadingModel: EngineConfiguration.ThreadingModel) throws -> Instance {
        let features: WasmFeatureSet = [.wideArithmetic]
        let module = try parseWasm(bytes: wat2wasm(wat, features: features), features: features)
        let configuration = EngineConfiguration(threadingModel: threadingModel, features: features)
        return try module.instantiate(store: Store(engine: Engine(configuration: configuration)))
    }

    @Test(arguments: testedThreadingModels, ["", "_locals"])
    func addsAndSubtractsLikeUInt128(threadingModel: EngineConfiguration.ThreadingModel, suffix: String) throws {
        let instance = try Self.instance(threadingModel: threadingModel)
        let add = try #require(instance.exports[function: "add128" + suffix])
        let sub = try #require(instance.exports[function: "sub128" + suffix])
        for operands in Self.wideOperands(randomCount: 2_000) {
            let arguments = Self.halves(operands.lhs) + Self.halves(operands.rhs)
            #expect(try add(arguments) == Self.halves(operands.lhs &+ operands.rhs))
            #expect(try sub(arguments) == Self.halves(operands.lhs &- operands.rhs))
        }
    }

    @Test(arguments: testedThreadingModels, ["", "_locals"])
    func multipliesLikeInt128(threadingModel: EngineConfiguration.ThreadingModel, suffix: String) throws {
        let instance = try Self.instance(threadingModel: threadingModel)
        let signed = try #require(instance.exports[function: "mul_wide_s" + suffix])
        let unsigned = try #require(instance.exports[function: "mul_wide_u" + suffix])
        for operands in Self.narrowOperands(randomCount: 4_000) {
            let lhs = UInt64(truncatingIfNeeded: operands.lhs)
            let rhs = UInt64(truncatingIfNeeded: operands.rhs)
            let arguments: [Value] = [.i64(lhs), .i64(rhs)]
            let signedProduct = Int128(Int64(bitPattern: lhs)) * Int128(Int64(bitPattern: rhs))
            #expect(try signed(arguments) == Self.halves(UInt128(bitPattern: signedProduct)))
            #expect(try unsigned(arguments) == Self.halves(UInt128(lhs) * UInt128(rhs)))
        }
    }

    #if Disassembler
        /// Results stored into locals right after the instruction are written there
        /// by the instruction itself.
        @Test(arguments: testedThreadingModels)
        func storesResultsIntoLocalsWithoutCopies(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let features: WasmFeatureSet = [.wideArithmetic]
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (func (export "f") (param i64 i64) (result i64) (local $low i64) (local $high i64)
                        (i64.mul_wide_s (local.get 0) (local.get 1))
                        (local.set $high)
                        (local.set $low)
                        (i64.add (local.get $low) (local.get $high))))
                    """, features: features), features: features)
            let configuration = EngineConfiguration(threadingModel: threadingModel, features: features)
            let instance = try module.instantiate(store: Store(engine: Engine(configuration: configuration)))
            var listing = ""
            try instance.dumpFunctions(to: &listing, module: module)
            let lines = listing.replacing(/\u{1B}\[[^m]*m/, with: "").split(separator: "\n")
            // The slot table prints each local as `[ -5] Local 0 (i64)`.
            let localRegisters = lines.compactMap { line -> String? in
                guard line.contains("] Local "), let open = line.firstIndex(of: "["), let close = line.firstIndex(of: "]")
                else { return nil }
                return String(line[line.index(after: open)..<close].drop { $0 == " " })
            }
            try #require(localRegisters.count == 2)
            let multiply = try #require(lines.first { $0.contains("i64.mul_wide_s") })
            #expect(multiply.contains("reg:\(localRegisters[0]), reg:\(localRegisters[1]) = i64.mul_wide_s"))
            #expect(lines.filter { $0.contains(" = copy ") }.count == 1, "only the copy of the function's result remains")
        }
    #endif
}

/// A small deterministic generator, so that a failure reproduces.
struct SplitMix64 {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
