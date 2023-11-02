import XCTest

@testable import WasmKit

final class EndiannessTests: XCTestCase {
    func testLoad() {
        XCTAssertEqual(UInt32(littleEndian: [1, 0, 0, 0]), 1)
        XCTAssertEqual(UInt32(1).littleEndianBytes, [1, 0, 0, 0])

        XCTAssertEqual(UInt32(littleEndian: [0xFF, 0xFF, 0xFF, 0xFF]), Int32(-1).unsigned)
        XCTAssertEqual(Int32(-1).unsigned.littleEndianBytes, [0xFF, 0xFF, 0xFF, 0xFF])
        XCTAssertEqual(UInt32(littleEndian: [0xFF, 0xFF, 0xFF, 0xFF]), Int32(-1).unsigned)
        XCTAssertEqual(Int32(-1).unsigned.littleEndianBytes, [0xFF, 0xFF, 0xFF, 0xFF])

        XCTAssertEqual(UInt32(littleEndian: [0x00, 0x01, 0x00, 0x00]), 0x100)
        XCTAssertEqual(UInt32(0x100).littleEndianBytes, [0x00, 0x01, 0x00, 0x00])

        XCTAssertEqual(UInt32(littleEndian: [0x00, 0x00, 0x01, 0x00]), 0x10000)
        XCTAssertEqual(UInt32(0x10000).littleEndianBytes, [0x00, 0x00, 0x01, 0x00])

        XCTAssertEqual(UInt32(littleEndian: [0xFF, 0xFF, 0xFF, 0xFF]), Int32(-1).unsigned)
        XCTAssertEqual(Int32(-1).unsigned.littleEndianBytes, [0xFF, 0xFF, 0xFF, 0xFF])
        XCTAssertEqual(UInt32(littleEndian: [0xFF, 0xFF, 0xFF, 0xFF]), Int32(-1).unsigned)
        XCTAssertEqual(Int32(-1).unsigned.littleEndianBytes, [0xFF, 0xFF, 0xFF, 0xFF])

        XCTAssertEqual(UInt32(littleEndian: [0xFE, 0xFF, 0xFF, 0xFF]), Int32(-2).unsigned)
        XCTAssertEqual(Int32(-2).unsigned.littleEndianBytes, [0xFE, 0xFF, 0xFF, 0xFF])
        XCTAssertEqual(UInt32(littleEndian: [0xFE, 0xFF, 0xFF, 0xFF]), Int32(-2).unsigned)
        XCTAssertEqual(Int32(-2).unsigned.littleEndianBytes, [0xFE, 0xFF, 0xFF, 0xFF])

        for i in (UInt32.min >> 16)...(UInt32.max >> 16) {
            XCTAssertEqual(i, UInt32(littleEndian: i.littleEndianBytes))
        }

        for i in (Int32.min >> 16)...(Int32.max >> 16) {
            XCTAssertEqual(i, UInt32(littleEndian: i.unsigned.littleEndianBytes).signed)
        }
    }
}
