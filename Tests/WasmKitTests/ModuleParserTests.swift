import Testing
import WasmKit

@Suite
struct ModuleParserTests {
    @Test
    func parsingSliceOfLargerBufferReadsOnlyTheSlice() throws {
        // 0xFF, then (module (func (export "f") (result i32) (i32.const 42))), then 0xFF
        let buffer: [UInt8] = [
            0xFF,
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x05, 0x01, 0x60, 0x00, 0x01, 0x7F,
            0x03, 0x02, 0x01, 0x00,
            0x07, 0x05, 0x01, 0x01, 0x66, 0x00, 0x00,
            0x0A, 0x06, 0x01, 0x04, 0x00, 0x41, 0x2A, 0x0B,
            0xFF,
        ]
        let engine = Engine()
        let module = try parseWasm(bytes: buffer[1..<(buffer.count - 1)], engine: engine)
        let instance = try module.instantiate(store: Store(engine: engine))
        let f = try #require(instance.exports[function: "f"])
        #expect(try f([]) == [.i32(42)])
    }
}
