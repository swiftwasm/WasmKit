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

    /// `.default` has no SIMD, so this fails if a section's sub-parser ignores the feature set.
    @Test func featureSetThreadsIntoCodeSubparser() throws {
        let wat = """
            (module (func (result v128) v128.const i32x4 1 2 3 4))
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
        // and the rest of the binary. Section bytes: id 0, size 0x0B, name-len 9,
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
}
