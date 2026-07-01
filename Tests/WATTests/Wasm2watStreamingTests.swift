import Foundation
import Testing
import WAT
import WasmParser

@Suite
struct Wasm2watStreamingTests {
    @Test func collectFunctionAndCode_capturesCodeSectionBytes() throws {
        let binary = try binaryStream(forWat: "(module (func) (func) (func))")
        let info = try collectModule(stream: binary, features: .default)
        let bytes = try #require(info.codeSectionBytes)
        #expect(bytes.count > 0)
        // Verify a streaming parse over the captured slice yields the expected count.
        let p = WasmParser.Parser(sectionBodyBytes: bytes, features: info.features)
        let count: UInt32 = try p.parseUnsigned()
        #expect(count == 3)
    }

    @Test func collectModule_threadsFeaturesIntoModuleInfo() throws {
        let binary = try binaryStream(forWat: "(module)")
        let info = try collectModule(stream: binary, features: .default)
        #expect(info.features == .default)
    }

    /// Type section: declared size 4, body = [0x00, 0x00, 0xFF, 0xFF].
    /// `parseTypeSection` consumes only the count byte (0x00); the 3 trailing
    /// bytes must trip `assertFullyConsumed`.
    @Test func collectModuleRejectsOversizedSection() throws {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
            0x01, 0x04, 0x00, 0x00, 0xFF, 0xFF,
        ]
        let stream = StaticByteStream(bytes: bytes)
        #expect(throws: WasmParserError.self) {
            _ = try collectModule(stream: stream)
        }
    }
}
