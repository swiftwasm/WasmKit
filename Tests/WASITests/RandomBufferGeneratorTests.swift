import XCTest

@testable import WASI

final class RandomBufferGeneratorTests: XCTestCase {
    struct DeterministicGenerator: RandomNumberGenerator, RandomBufferGenerator {
        var items: [UInt64]

        mutating func next() -> UInt64 {
            items.removeFirst()
        }
    }
    func testDefaultFill() {
        var generator = DeterministicGenerator(items: [
            0x0123456789abcdef, 0xfedcba9876543210, 0xdeadbeefbaddcafe
        ])
        for (bufferSize, expectedBytes): (Int, [UInt8]) in [
            (10, [0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01, 0x10, 0x32]),
            (2, [0xfe, 0xca]),
            (0, [])
        ] {
            var buffer: [UInt8] = Array(repeating: 0, count: bufferSize)
            buffer.withUnsafeMutableBufferPointer {
                generator.fill(buffer: $0)
            }
            let expected: [UInt8]
#if _endian(little)
            expected = expectedBytes
#else
            expected = Array(expectedBytes.reversed())
#endif
            XCTAssertEqual(buffer, expected)
        }
    }
}
