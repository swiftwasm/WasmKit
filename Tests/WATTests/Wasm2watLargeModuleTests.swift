import Testing
import WAT
import WasmParser

@Suite
struct Wasm2watLargeModuleTests {
    @Test func largeDataSegmentRoundtrip() throws {
        var wat = "(module\n"
        let chunk = String(repeating: "a", count: 1024 * 1024)
        wat += "  (data \"\(chunk)\")\n)"
        let binary = try wat2wasm(wat)
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }

    /// Varying local counts and body sizes catch offset bugs in `parseCodeEntry`.
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
        let text = try wasm2wat(StaticByteStreamSource(bytes: binary))
        let binary2 = try wat2wasm(text)
        #expect(binary == binary2)
    }
}
