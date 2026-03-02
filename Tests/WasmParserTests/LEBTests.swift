import Testing

@testable import WasmParser

@Suite struct LEBTest {
    @Test func unsigned() throws {
        #expect(try UInt8(LEB: [0x00]) == 0)
        #expect(try UInt8(LEB: [0x01]) == 1)
        #expect(try UInt8(LEB: [0x7f]) == 127)
        #expect(try UInt8(LEB: [0x80, 0x01]) == 128)
        #expect(try UInt8(LEB: [0xFF, 0x01]) == 255)

        #expect(try UInt16(LEB: [0x00]) == 0)
        #expect(try UInt16(LEB: [0x7f]) == 127)
        #expect(try UInt16(LEB: [0x80, 0x01]) == 128)
        #expect(try UInt16(LEB: [0xff, 0xff, 0x3]) == 0xffff)

        #expect(try UInt32(LEB: [0x00]) == 0)
        #expect(try UInt32(LEB: [0x7f]) == 127)
        #expect(try UInt32(LEB: [0x80, 0x01]) == 128)
        #expect(try UInt32(LEB: [0xe5, 0x8e, 0x26]) == 624485)

        #expect(try UInt64(LEB: [0x00]) == 0)
        #expect(try UInt64(LEB: [0x7f]) == 127)
        #expect(try UInt64(LEB: [0x80, 0x01]) == 128)
        #expect(try UInt64(LEB: [0xe5, 0x8e, 0x26]) == 624485)
        #expect(throws: (any Error).self) { try UInt8(LEB: []) }
        #expect(throws: (any Error).self) { try UInt8(LEB: [0x80]) }
        #expect(throws: (any Error).self) { try UInt8(LEB: [0x80, 0x02]) }
        #expect(throws: (any Error).self) { try UInt16(LEB: [0x80, 0x80, 0x04]) }
        #expect(throws: (any Error).self) { try UInt32(LEB: [0x80, 0x80, 0x80, 0x80, 0x16]) }
        #expect(throws: (any Error).self) { try UInt64(LEB: [0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x02]) }
    }

    @Test func signed() throws {
        #expect(try Int8(LEB: [0x00]) == 0)
        #expect(try Int8(LEB: [0x01]) == 1)
        #expect(try Int8(LEB: [0x7f]) == -1)
        #expect(try Int8(LEB: [0xff, 0x00]) == 127)
        #expect(try Int8(LEB: [0x81, 0x7f]) == -127)
        #expect(try Int8(LEB: [0x80, 0x7f]) == -128)

        #expect(try Int16(LEB: [0x00]) == 0)
        #expect(try Int16(LEB: [0x01]) == 1)
        #expect(try Int16(LEB: [0x7f]) == -1)
        #expect(try Int16(LEB: [0xff, 0x00]) == 127)
        #expect(try Int16(LEB: [0x81, 0x7f]) == -127)
        #expect(try Int16(LEB: [0x80, 0x7f]) == -128)
        #expect(try Int16(LEB: [0x81, 1]) == 129)
        #expect(try Int16(LEB: [0xff, 0x7e]) == -129)
        #expect(throws: (any Error).self) { try Int32(LEB: [0x80, 0x80, 0x80, 0x80, 0x70]) }
        #expect(throws: (any Error).self) { try Int8(LEB: []) }
        #expect(throws: (any Error).self) { try Int8(LEB: [0x80]) }
    }
}

extension FixedWidthInteger where Self: UnsignedInteger {
    fileprivate init(LEB bytes: [UInt8]) throws {
        let stream = StaticByteStream(bytes: bytes)
        self = try decodeLEB128(stream: stream)
    }
}

extension FixedWidthInteger where Self: RawSignedInteger {
    fileprivate init(LEB bytes: [UInt8]) throws {
        let stream = StaticByteStream(bytes: bytes)
        self = try decodeLEB128(stream: stream)
    }
}
