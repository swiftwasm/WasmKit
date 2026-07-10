import Foundation
import Testing
import WAT
import WasmParser

@Suite
struct Wasm2watLargeModuleTests {
    /// Roundtrips a 1 MB passive data segment.
    @Test func largeDataSegmentRoundtrip() throws {
        var wat = "(module\n"
        let chunk = String(repeating: "a", count: 1024 * 1024)
        wat += "  (data \"\(chunk)\")\n)"
        let binary = try wat2wasm(wat)
        let text = try wasm2wat(StaticByteStream(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }

    /// Mixed function sizes: exposes index-arithmetic / mutating bugs in
    /// `parseCodeEntry` that 2000-zero-body functions would miss.
    @Test func mixedFunctionSizesRoundtrip() throws {
        var wat = "(module\n"
        for i in 0..<500 {
            let locals = i % 8
            let instructions = (i % 16) + 1
            wat += "  (func"
            if locals > 0 {
                wat += " (local"
                for _ in 0..<locals { wat += " i32" }
                wat += ")"
            }
            for _ in 0..<instructions { wat += " (drop (i32.const 1))" }
            wat += ")\n"
        }
        wat += ")"
        let binary = try wat2wasm(wat)
        let text = try wasm2wat(StaticByteStream(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }

    /// Mixed data segment shapes: active w/ explicit table, passive,
    /// active w/ default memory; exercises all three
    /// `parseDataSegmentEntry` branches in a single binary.
    @Test func mixedDataSegmentKindsRoundtrip() throws {
        let wat = """
            (module (memory 1)
                    (data (i32.const 0) "first")
                    (data "passive")
                    (data (memory 0) (i32.const 100) "third"))
            """
        let binary = try wat2wasm(wat)
        let text = try wasm2wat(StaticByteStream(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }

    /// Verifies WatPrinter's per-section sub-parsers honor the feature set
    /// passed to `wasm2wat`. Uses a SIMD instruction with `.all` features
    /// (`.default` does NOT include `.simd`). If the streaming sub-parsers
    /// hardcoded `.default`, parsing the v128.const instruction would throw
    /// because `.simd` would be missing.
    @Test func featureSetThreadsIntoCodeSubparser() throws {
        let wat = """
            (module (func (result v128) v128.const i32x4 1 2 3 4))
            """
        let binary = try wat2wasm(wat, features: .all)
        let text = try wasm2wat(StaticByteStream(bytes: binary), features: .all)
        let binary2 = try wat2wasm(text, features: .all)
        #expect(binary == binary2)
    }

    /// Empty code / data / element sections: count=0 must not trip
    /// `assertFullyConsumed`.
    @Test func emptySectionsRoundtrip() throws {
        let cases = [
            "(module)",
            "(module (memory 1))",
            "(module (table 1 funcref))",
        ]
        for wat in cases {
            let binary = try wat2wasm(wat)
            let text = try wasm2wat(StaticByteStream(bytes: binary))
            let binary2 = try wat2wasm(text)
            #expect(binary == binary2, "Roundtrip mismatch for: \(wat)")
        }
    }

    /// A custom section with a name other than "name" is skipped in skim
    /// and ignored in collectModule. Non-name custom sections don't appear
    /// in WAT output.
    @Test func nonNameCustomSectionRoundtrip() throws {
        let originalBinary = try wat2wasm("(module)")
        // Splice in a custom "producers" section between magic+version (8 bytes)
        // and the rest of the binary. Section bytes: id 0, size 0x0B, name-len 9,
        // "producers" (9 bytes), then a single 0x00 placeholder content byte.
        var withCustom = Array(originalBinary[0..<8])
        withCustom += [0x00, 0x0B, 0x09, 0x70, 0x72, 0x6F, 0x64, 0x75, 0x63, 0x65, 0x72, 0x73, 0x00]
        withCustom += Array(originalBinary[8...])
        let text = try wasm2wat(StaticByteStream(bytes: withCustom))
        let binary2 = try wat2wasm(text)
        // wasm2wat doesn't emit custom sections, so binary2 matches the
        // original (without custom).
        #expect(originalBinary == binary2)
    }

    /// Tag-section roundtrip. Exercises:
    /// - `parseNextRawSection` accepts id 13 with `.exceptionHandling`;
    /// - `collectModule`'s `case .tag` populates `info.tags`;
    /// - `WatPrinter.printTags` emits `(tag (type ...))` forms;
    /// - WAT parser side round-trips back to the same binary.
    /// `WasmFeatureSet.default` includes `.exceptionHandling`.
    @Test func tagSectionRoundtrip() throws {
        let wat = """
            (module
              (type (func (param i32)))
              (tag (type 0)))
            """
        let binary = try wat2wasm(wat)
        let text = try wasm2wat(StaticByteStream(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }

    /// All-10-ParsedNames roundtrip. Constructs a module with rich name
    /// annotations across multiple entity kinds, runs binary→text→binary,
    /// and verifies the resulting WAT contains $-prefixed names on every
    /// entity form. Crucially, also verifies the round trip preserves the
    /// name section.
    ///
    /// `wat2wasm` only emits a name section when `EncodeOptions(nameSection: true)`
    /// is passed; the default drops names entirely.
    @Test func richNameSectionRoundtrip() throws {
        let wat = """
            (module $myMod
              (type $T (func (param i32) (result i32)))
              (memory $mem 1)
              (table $tbl 1 funcref)
              (global $g i32 (i32.const 0))
              (func $main (type $T) (local $iter i32) local.get $iter))
            """
        let opts = EncodeOptions(nameSection: true)
        let binary = try wat2wasm(wat, options: opts)
        let text = try wasm2wat(StaticByteStream(bytes: binary))
        // Spot-check that each $name kind survived the binary→text trip.
        #expect(text.contains("$myMod"))
        #expect(text.contains("$T"))
        #expect(text.contains("$mem"))
        #expect(text.contains("$tbl"))
        #expect(text.contains("$g"))
        #expect(text.contains("$main"))
        #expect(text.contains("$iter"))
        // Round-trip back to binary; the name section must survive.
        let binary2 = try wat2wasm(text, options: opts)
        #expect(binary == binary2)
    }
}
