@testable import Parser
import XCTest

final class ByteStreamTests: XCTestCase {
    func testStaticByteStream() {
        var stream = StaticByteStream(bytes: [1, 2])
        do {
            try stream.consume(3)
            XCTFail("Should occur an error")
        } catch let error {
            if case let Parser.Error<UInt8>.unexpected(actual, expected: expected) = error,
                actual == 1, expected == [3] {
                XCTAssertEqual(stream.currentIndex, 0)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }

        stream = StaticByteStream(bytes: [1, 2])
        XCTAssertEqual(stream.bytes, [1, 2])
        XCTAssertEqual(stream.currentIndex, 0)

        do {
            XCTAssertEqual(try stream.peek(), 1)
            XCTAssertEqual(stream.currentIndex, 0)
            XCTAssertEqual(try stream.hasReachedEnd(), false)

            try stream.consume(1)
            XCTAssertEqual(stream.currentIndex, 1)
            XCTAssertEqual(try stream.hasReachedEnd(), false)

            XCTAssertEqual(try stream.peek(), 2)
            XCTAssertEqual(stream.currentIndex, 1)
            XCTAssertEqual(try stream.hasReachedEnd(), false)

            try stream.consume(2)
            XCTAssertEqual(stream.currentIndex, 2)
            XCTAssertEqual(try stream.hasReachedEnd(), true)

            XCTAssertEqual(try stream.peek(), nil)
            XCTAssertEqual(stream.currentIndex, 2)
        } catch let error {
            XCTFail("\(error)")
        }

        do {
            try stream.consume(3)
            XCTFail("Should occur an error")
        } catch let error {
            if case Parser.Error<UInt8>.unexpectedEnd = error {
                XCTAssertEqual(stream.currentIndex, 2)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testStaticByteStream_equatable() {
        let a = StaticByteStream(bytes: [1, 2])
        let b = StaticByteStream(bytes: [1, 2])
        let c = StaticByteStream(bytes: [1, 2])
        let d = StaticByteStream(bytes: [1, 2, 3])

        XCTAssertNoThrow(try c.consume(1))

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(b, c)
        XCTAssertNotEqual(c, d)
    }

    func testString_byteStream() {
        let actual = "Web🌏Assembly".byteStream
        let expected = StaticByteStream(bytes: [
            0x57, 0x65, 0x62, 0xF0, 0x9F, 0x8C, 0x8F, 0x41, 0x73, 0x73, 0x65, 0x6D, 0x62, 0x6C, 0x79,
        ])
        XCTAssertEqual(actual, expected)
    }
}
