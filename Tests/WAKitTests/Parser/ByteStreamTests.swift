import WAKit
import XCTest

final class ByteStreamTests: XCTestCase {
    func testStaticByteStream() {
        var stream = StaticByteStream(bytes: [1, 2])
        XCTAssertThrowsError(try stream.consume(3)) { error in
            guard case let WAKit.StreamError<UInt8>.unexpected(actual, index, expected: expected) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(actual, 1)
            XCTAssertEqual(index, 0)
            XCTAssertEqual(expected, [3])
            XCTAssertEqual(stream.currentIndex, 0)
        }

        stream = StaticByteStream(bytes: [1, 2])
        XCTAssertEqual(stream.bytes, [1, 2])
        XCTAssertEqual(stream.currentIndex, 0)

        XCTAssertEqual(stream.peek(), 1)
        XCTAssertEqual(stream.currentIndex, 0)
        XCTAssertEqual(try stream.hasReachedEnd(), false)

        XCTAssertNoThrow(try stream.consume(1))
        XCTAssertEqual(stream.currentIndex, 1)
        XCTAssertEqual(try stream.hasReachedEnd(), false)

        XCTAssertEqual(stream.peek(), 2)
        XCTAssertEqual(stream.currentIndex, 1)
        XCTAssertEqual(try stream.hasReachedEnd(), false)

        XCTAssertNoThrow(try stream.consume(2))
        XCTAssertEqual(stream.currentIndex, 2)
        XCTAssertEqual(try stream.hasReachedEnd(), true)

        XCTAssertEqual(stream.peek(), nil)

        XCTAssertThrowsError(try stream.consume(3)) { error in
            guard case WAKit.StreamError<UInt8>.unexpectedEnd = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stream.currentIndex, 2)
        }
    }
}
