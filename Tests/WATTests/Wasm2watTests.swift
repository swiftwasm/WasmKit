import Testing
import WasmParser

@testable import WAT

@Suite
struct Wasm2watTests {
    private static func printed(_ wat: String) throws -> String {
        var printer = WatPrinter(info: try collectModule(stream: binaryStream(forWat: wat)), output: "")
        try printer.print()
        return printer.output
    }

    @Test func printEmptyModule() throws {
        let wat = try Self.printed("(module)")
        #expect(wat == "(module\n)\n")
    }

    @Test func printFunctionType() throws {
        let wat = try Self.printed(
            """
            (module
              (type (func (param i32 i32) (result i32)))
            )
            """)
        #expect(wat.contains("(type (;0;) (func (param i32 i32) (result i32)))"))
    }

    @Test func printMemoryWithMax() throws {
        let wat = try Self.printed("(module (memory 1 4))")
        #expect(wat.contains("(memory (;0;) 1 4)"))
    }

    @Test func printExport() throws {
        let wat = try Self.printed(
            """
            (module
              (func (export "add") (param i32 i32) (result i32)
                local.get 0
                local.get 1
                i32.add)
            )
            """)
        #expect(wat.contains(#"(export "add" (func 0))"#))
    }

    @Test func printGlobalMutable() throws {
        let wat = try Self.printed(
            """
            (module
              (global (mut i32) (i32.const 0))
            )
            """)
        #expect(wat.contains("(global (;0;) (mut i32) (i32.const 0))"))
    }

    @Test func printDataSegment() throws {
        let wat = try Self.printed(
            """
            (module
              (memory 1)
              (data (i32.const 0) "hello")
            )
            """)
        #expect(wat.contains("(data (;0;)"))
        #expect(wat.contains("hello"))
    }

    private struct RecordingOutput: TextOutputStream {
        var pieces: [String] = []
        mutating func write(_ string: String) { pieces.append(string) }
    }

    @Test func outputArrivesOneFieldAtATime() throws {
        let binary = try wat2wasm("(module (func (drop (i32.const 1))) (func (drop (i32.const 2))))")
        var output = RecordingOutput()
        try wasm2wat(StaticByteStreamSource(bytes: binary), features: .default, to: &output)
        #expect(output.pieces.joined() == (try wasm2wat(StaticByteStreamSource(bytes: binary))))
        #expect(!output.pieces.contains { $0.contains("i32.const 1") && $0.contains("i32.const 2") })
    }

    @Test func largeFunctionBodyArrivesInPieces() throws {
        let instructionCount = 50_000
        let binary = try wat2wasm("(module (func \(String(repeating: "nop ", count: instructionCount))))")
        var output = RecordingOutput()
        try wasm2wat(StaticByteStreamSource(bytes: binary), features: .default, to: &output)
        #expect(try wat2wasm(output.pieces.joined()) == binary)
        // A piece holds up to 64 KiB of body text plus the line that crossed that size.
        let line = "    nop\n".utf8.count
        #expect(output.pieces.allSatisfy { $0.utf8.count <= (1 << 16) + line })
    }

    @Test func largeDataSegmentArrivesInPieces() throws {
        let binary = try wat2wasm(#"(module (memory 1) (data (i32.const 0) "\#(String(repeating: #"\00"#, count: 100_000))"))"#)
        var output = RecordingOutput()
        try wasm2wat(StaticByteStreamSource(bytes: binary), features: .default, to: &output)
        #expect(try wat2wasm(output.pieces.joined()) == binary)
        // A piece holds up to 64 KiB of text plus the string that crossed that size: 16 KiB of bytes
        // escaped as `\00`, its quotes and the space before it.
        #expect(output.pieces.allSatisfy { $0.utf8.count <= (1 << 16) + 3 * (1 << 14) + 3 })
    }

    @Test(arguments: zip(["func", "funcref"], [" 0", " (item ref.null func)"]))
    func largeElementSegmentArrivesInPieces(type: String, item: String) throws {
        let binary = try wat2wasm("(module (func) (elem \(type)\(String(repeating: item, count: 40_000))))")
        var output = RecordingOutput()
        try wasm2wat(StaticByteStreamSource(bytes: binary), features: .default, to: &output)
        #expect(try wat2wasm(output.pieces.joined()) == binary)
        #expect(output.pieces.allSatisfy { $0.utf8.count <= (1 << 16) + item.utf8.count })
    }

    /// A load from the second memory, which `.default` misreads.
    @Test func featureSetThreadsIntoCodeSubparser() throws {
        let wat = """
            (module (memory 1) (memory 1) (func (result i32) i32.const 0 i32.load 1))
            """
        let binary = try wat2wasm(wat, features: .all)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary), features: .all)
        let binary2 = try wat2wasm(text, features: .all)
        #expect(binary == binary2)
    }

    /// Modules that have no code, data or element section.
    @Test func emptySectionsRoundtrip() throws {
        let cases = [
            "(module)",
            "(module (memory 1))",
            "(module (table 1 funcref))",
        ]
        for wat in cases {
            let binary = try wat2wasm(wat)
            let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
            let binary2 = try wat2wasm(text)
            #expect(binary == binary2, "Roundtrip mismatch for: \(wat)")
        }
    }

    @Test func nonNameCustomSectionRoundtrip() throws {
        let originalBinary = try wat2wasm("(module)")
        // Splice in a custom "producers" section between magic+version (8 bytes)
        // and the rest of the binary. Section bytes: id 0x00, size 0x0B, name-len 0x09,
        // "producers" (9 bytes), then a single 0x00 placeholder content byte.
        var withCustom = Array(originalBinary[0..<8])
        withCustom += [0x00, 0x0B, 0x09, 0x70, 0x72, 0x6F, 0x64, 0x75, 0x63, 0x65, 0x72, 0x73, 0x00]
        withCustom += Array(originalBinary[8...])
        let text = try wasm2wat(StaticByteStreamSource(bytes: withCustom))
        let binary2 = try wat2wasm(text)
        // wasm2wat drops custom sections.
        #expect(originalBinary == binary2)
    }

    /// `WasmFeatureSet.default` includes `.exceptionHandling`.
    @Test func tagSectionRoundtrip() throws {
        let wat = """
            (module
              (type (func (param i32)))
              (tag (type 0)))
            """
        let binary = try wat2wasm(wat)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }

    /// One data segment of each binary kind: active in memory 0 (kind 0),
    /// passive (kind 1), and active in another memory (kind 2).
    @Test func mixedDataSegmentKindsRoundtrip() throws {
        let wat = """
            (module (memory 1) (memory 1)
                    (data (i32.const 0) "first")
                    (data "passive")
                    (data (memory 1) (i32.const 100) "third"))
            """
        let binary = try wat2wasm(wat, features: .all)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary), features: .all)
        #expect(text.contains(#"(data (;2;) (memory 1) (i32.const 100) "third")"#))
        #expect(try wat2wasm(text, features: .all) == binary)
    }

    /// Every instruction with a memory argument, its natural alignment in bytes, and the immediate
    /// that follows the memory argument.
    static let memoryAccesses: [(mnemonic: String, naturalAlignment: Int, trailing: String)] =
        [
            ("i32.load", 4, ""), ("i64.load", 8, ""), ("f32.load", 4, ""), ("f64.load", 8, ""),
            ("i32.load8_s", 1, ""), ("i32.load8_u", 1, ""), ("i32.load16_s", 2, ""), ("i32.load16_u", 2, ""),
            ("i64.load8_s", 1, ""), ("i64.load8_u", 1, ""), ("i64.load16_s", 2, ""), ("i64.load16_u", 2, ""),
            ("i64.load32_s", 4, ""), ("i64.load32_u", 4, ""),
            ("i32.store", 4, ""), ("i64.store", 8, ""), ("f32.store", 4, ""), ("f64.store", 8, ""),
            ("i32.store8", 1, ""), ("i32.store16", 2, ""), ("i64.store8", 1, ""), ("i64.store16", 2, ""),
            ("i64.store32", 4, ""),
            ("v128.load", 16, ""), ("v128.store", 16, ""),
            ("v128.load8x8_s", 8, ""), ("v128.load8x8_u", 8, ""), ("v128.load16x4_s", 8, ""),
            ("v128.load16x4_u", 8, ""), ("v128.load32x2_s", 8, ""), ("v128.load32x2_u", 8, ""),
            ("v128.load8_splat", 1, ""), ("v128.load16_splat", 2, ""), ("v128.load32_splat", 4, ""),
            ("v128.load64_splat", 8, ""), ("v128.load32_zero", 4, ""), ("v128.load64_zero", 8, ""),
            ("v128.load8_lane", 1, " 0"), ("v128.load16_lane", 2, " 0"), ("v128.load32_lane", 4, " 0"),
            ("v128.load64_lane", 8, " 0"), ("v128.store8_lane", 1, " 0"), ("v128.store16_lane", 2, " 0"),
            ("v128.store32_lane", 4, " 0"), ("v128.store64_lane", 8, " 0"),
            ("memory.atomic.notify", 4, ""), ("memory.atomic.wait32", 4, ""), ("memory.atomic.wait64", 8, ""),
            ("i32.atomic.load", 4, ""), ("i64.atomic.load", 8, ""), ("i32.atomic.load8_u", 1, ""),
            ("i32.atomic.load16_u", 2, ""), ("i64.atomic.load8_u", 1, ""), ("i64.atomic.load16_u", 2, ""),
            ("i64.atomic.load32_u", 4, ""),
            ("i32.atomic.store", 4, ""), ("i64.atomic.store", 8, ""), ("i32.atomic.store8", 1, ""),
            ("i32.atomic.store16", 2, ""), ("i64.atomic.store8", 1, ""), ("i64.atomic.store16", 2, ""),
            ("i64.atomic.store32", 4, ""),
        ]
        + ["add", "sub", "and", "or", "xor", "xchg", "cmpxchg"].flatMap { op in
            [
                ("i32.atomic.rmw.\(op)", 4, ""), ("i64.atomic.rmw.\(op)", 8, ""),
                ("i32.atomic.rmw8.\(op)_u", 1, ""), ("i32.atomic.rmw16.\(op)_u", 2, ""),
                ("i64.atomic.rmw8.\(op)_u", 1, ""), ("i64.atomic.rmw16.\(op)_u", 2, ""),
                ("i64.atomic.rmw32.\(op)_u", 4, ""),
            ]
        }

    @Test(arguments: memoryAccesses)
    func alignmentIsPrintedOnlyWhenNotNatural(mnemonic: String, naturalAlignment: Int, trailing: String) throws {
        let cases = [
            (naturalAlignment, "\(mnemonic)\(trailing)"),
            (naturalAlignment * 2, "\(mnemonic) align=\(naturalAlignment * 2)\(trailing)"),
        ]
        for (alignment, expected) in cases {
            let binary = try wat2wasm(
                "(module (memory 1) (func \(mnemonic) align=\(alignment)\(trailing)))", features: .all)
            let text = try wasm2wat(StaticByteStreamSource(bytes: binary), features: .all)
            #expect(text.contains("\n    \(expected)\n"), "\(text)")
            #expect(try wat2wasm(text, features: .all) == binary)
        }
    }
}
