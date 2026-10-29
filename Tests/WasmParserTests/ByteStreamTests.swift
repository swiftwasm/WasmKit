import Testing

@testable import WasmParser

// On 32-bit platforms the sizes a module declares reach `Int.max`.
@Suite struct ByteStreamTests {
    @Test func consumeThrowsWhenRangeEndOverflows() throws {
        var stream = ByteStream(StaticByteStreamSource(bytes: [0x00]))
        _ = try stream.consumeAny()
        let error = try #require(throws: WasmParserError.self) {
            _ = try stream.consume(count: Int.max)
        }
        guard case .parserUnexpectedEnd = error.kind else {
            Issue.record("Expected a .parserUnexpectedEnd error, got \(error.kind)")
            return
        }
        #expect(error.location == 1)
    }

    @Test func sliceSourceReturnsNilWhenRangeEndOverflows() throws {
        let bytes: [UInt8] = [0x00, 0x01]
        let source = StaticByteStreamSource(bytes: bytes[1...])
        #expect(try source.readBytes(from: 0, to: Int.max) == nil)
    }
}
