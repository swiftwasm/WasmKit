import XCTest

@testable import WasmParser

final class LEBTest: XCTestCase {
    func testUnsigned() {
        XCTAssertEqual(try UInt8(LEB: [0x00]), 0)
        XCTAssertEqual(try UInt8(LEB: [0x01]), 1)
        XCTAssertEqual(try UInt8(LEB: [0x7f]), 127)
        XCTAssertEqual(try UInt8(LEB: [0x80, 0x01]), 128)
        XCTAssertEqual(try UInt8(LEB: [0xFF, 0x01]), 255)

        XCTAssertEqual(try UInt16(LEB: [0x00]), 0)
        XCTAssertEqual(try UInt16(LEB: [0x7f]), 127)
        XCTAssertEqual(try UInt16(LEB: [0x80, 0x01]), 128)
        XCTAssertEqual(try UInt16(LEB: [0xff, 0xff, 0x3]), 0xffff)

        XCTAssertEqual(try UInt32(LEB: [0x00]), 0)
        XCTAssertEqual(try UInt32(LEB: [0x7f]), 127)
        XCTAssertEqual(try UInt32(LEB: [0x80, 0x01]), 128)
        XCTAssertEqual(try UInt32(LEB: [0xe5, 0x8e, 0x26]), 624485)

        XCTAssertEqual(try UInt64(LEB: [0x00]), 0)
        XCTAssertEqual(try UInt64(LEB: [0x7f]), 127)
        XCTAssertEqual(try UInt64(LEB: [0x80, 0x01]), 128)
        XCTAssertEqual(try UInt64(LEB: [0xe5, 0x8e, 0x26]), 624485)

        XCTAssertThrowsError(try UInt8(LEB: []))

        XCTAssertThrowsError(try UInt8(LEB: [0x80]))

        XCTAssertThrowsError(try UInt8(LEB: [0x80, 0x02]))

        XCTAssertThrowsError(try UInt16(LEB: [0x80, 0x80, 0x04]))

        XCTAssertThrowsError(try UInt32(LEB: [0x80, 0x80, 0x80, 0x80, 0x16]))

        XCTAssertThrowsError(try UInt64(LEB: [0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x02]))
    }

    func testSigned() {
        XCTAssertEqual(try Int8(LEB: [0x00]), 0)
        XCTAssertEqual(try Int8(LEB: [0x01]), 1)
        XCTAssertEqual(try Int8(LEB: [0x7f]), -1)
        XCTAssertEqual(try Int8(LEB: [0xff, 0x00]), 127)
        XCTAssertEqual(try Int8(LEB: [0x81, 0x7f]), -127)
        XCTAssertEqual(try Int8(LEB: [0x80, 0x7f]), -128)

        XCTAssertEqual(try Int16(LEB: [0x00]), 0)
        XCTAssertEqual(try Int16(LEB: [0x01]), 1)
        XCTAssertEqual(try Int16(LEB: [0x7f]), -1)
        XCTAssertEqual(try Int16(LEB: [0xff, 0x00]), 127)
        XCTAssertEqual(try Int16(LEB: [0x81, 0x7f]), -127)
        XCTAssertEqual(try Int16(LEB: [0x80, 0x7f]), -128)
        XCTAssertEqual(try Int16(LEB: [0x81, 1]), 129)
        XCTAssertEqual(try Int16(LEB: [0xff, 0x7e]), -129)

        XCTAssertThrowsError(try Int32(LEB: [0x80, 0x80, 0x80, 0x80, 0x70]))
        XCTAssertThrowsError(try Int8(LEB: []))
        XCTAssertThrowsError(try Int8(LEB: [0x80]))
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
