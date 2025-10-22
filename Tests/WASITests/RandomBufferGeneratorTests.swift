import Testing

@testable import WASI

@Suite
struct RandomBufferGeneratorTests {
    struct DeterministicGenerator: RandomNumberGenerator, RandomBufferGenerator {
        var items: [UInt64]

        mutating func next() -> UInt64 {
            items.removeFirst()
        }
    }
    @Test
    func defaultFill() {
        var generator = DeterministicGenerator(items: [
            0x0123_4567_89ab_cdef, 0xfedc_ba98_7654_3210, 0xdead_beef_badd_cafe,
        ])
        for (bufferSize, expectedBytes): (Int, [UInt8]) in [
            (10, [0xef, 0xcd, 0xab, 0x89, 0x67, 0x45, 0x23, 0x01, 0x10, 0x32]),
            (2, [0xfe, 0xca]),
            (0, []),
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
            #expect(buffer == expected)
        }
    }
}

