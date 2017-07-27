@testable import Swasm

import XCTest

class WASMParserTests: XCTestCase {}

extension WASMParserTests {
	func testByte() {
		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [])
			let parser = WASMParser.byte(0x01)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x01])
			let parser = WASMParser.byte(0x01)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 0x01)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0x02])
			let parser = WASMParser.byte(0x01)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(0x02) = error else {
					XCTFail(String(describing: error))
					return
				}
		}
	}

	func testByteInRange() {
		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [])
			let parser = WASMParser.byte(in: 0x01..<0x03)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x02])
			let parser = WASMParser.byte(in: 0x01..<0x03)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 0x02)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0x00])
			let parser = WASMParser.byte(in: 0x01..<0x03)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(0x00) = error else {
					XCTFail(String(describing: error))
					return
				}
		}
	}

	func testByteInSet() {
		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [])
			let parser = WASMParser.byte(in: Set([0x01, 0x02, 0x03]))
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x02])
			let parser = WASMParser.byte(in: Set([0x01, 0x02, 0x03]))
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 2)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0])
			let parser = WASMParser.byte(in: Set([0x01, 0x02, 0x03]))
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(0x00) = error else {
					XCTFail(String(describing: error))
					return
				}
		}
	}

	func testBytes() {
		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0x00])
			let parser = WASMParser.bytes([0x00, 0x01, 0x02])
			XCTAssertNotNil(parser)
			_ = try parser!.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x00, 0x01, 0x02])
			let parser = WASMParser.bytes([0x00, 0x01, 0x02])
			XCTAssertNotNil(parser)
			let (result, endIndex) = try parser!.parse(stream: stream)
			XCTAssertEqual(result, [0x00, 0x01, 0x02])
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0x00, 0x02, 0x02])
			let parser = WASMParser.bytes([0x00, 0x01, 0x02])
			XCTAssertNotNil(parser)
			_ = try parser!.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(0x02) = error else {
					XCTFail(String(describing: error))
					return
				}
		}
	}
}

extension WASMParserTests {
	func testUInt() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b01111111])
			let parser = WASMParser.uint(8)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 127)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b10000000])
			let parser = WASMParser.uint(8)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b10000000, 0b10000000])
			let parser = WASMParser.uint(1)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(0b10000000) = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b10000000, 0b10000000])
			let parser = WASMParser.uint(8)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b10000010, 0b00000001])
			let parser = WASMParser.uint(8)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 0b0000001_0000010)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b10000011, 0b10000010, 0b00000001])
			let parser = WASMParser.uint(8)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 0b0000001_0000010_0000011)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())
	}

	func testSInt() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b01000001])
			let parser = WASMParser.sint(8)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, -0b00111111)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b10000000])
			let parser = WASMParser.sint(8)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b10000000, 0b10000000])
			let parser = WASMParser.sint(1)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(0b10000000) = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b10000000, 0b10000000])
			let parser = WASMParser.sint(8)
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b10000000, 0b00000001])
			let parser = WASMParser.sint(8)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 0b10000000)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b11000010, 0b11000001, 0b01000000])
			let parser = WASMParser.sint(8)
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, -0b0111111_0111110_0111110)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())
	}
}

extension WASMParserTests {
	func testFloat() {
		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0b11111111])
			let parser = WASMParser.float32()
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b00111111, 0b10000000, 0b00000000, 0b00000000])
			let parser = WASMParser.float32()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, 1.0)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b01000000, 0b01001001, 0b00001111, 0b11011010])
			let parser = WASMParser.float32()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, .pi)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0b11000000, 0b01001001, 0b00001111, 0b11011010])
			let parser = WASMParser.float32()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, -.pi)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())
	}
}

extension WASMParserTests {
	func testName() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x61])
			let parser = WASMParser.unicode()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, "a")
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0xC3, 0xA6])
			let parser = WASMParser.unicode()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, "æ")
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0xE3, 0x81, 0x82])
			let parser = WASMParser.unicode()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, "あ")
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0xF0, 0x9F, 0x8D, 0xA3])
			let parser = WASMParser.unicode()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result, "🍣")
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0xF0])
			let parser = WASMParser.unicode()
			_ = try parser.parse(stream: stream)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpectedEnd = error else {
					XCTFail(String(describing: error))
					return
				}
		}
	}
}

extension WASMParserTests {
	func testValueType() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x7F])
			let parser = WASMParser.valueType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result == Int32.self)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x7E])
			let parser = WASMParser.valueType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result == Int64.self)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x7D])
			let parser = WASMParser.valueType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result == UInt32.self)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x7C])
			let parser = WASMParser.valueType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result == UInt64.self)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertThrowsError(try {
			let stream = ByteStream(bytes: [0x7B])
			let parser = WASMParser.valueType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result == UInt64.self)
			XCTAssertEqual(endIndex, stream.endIndex)
			}()) { error in
				guard case ParserStreamError<ByteStream>.unexpected(element: 0x7B) = error else {
					XCTFail(String(describing: error))
					return
				}
		}
	}

	func testResultType() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x7F])
			let parser = WASMParser.valueType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result == Int32.self)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())
	}

	func testFunctionType() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x60, 0x01, 0x7E, 0x01, 0x7D])
			let parser = WASMParser.functionType()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssert(result.parameters == [Int64.self])
			XCTAssert(result.results == [UInt32.self])
			XCTAssertEqual(endIndex, stream.endIndex)
			}())
	}

	func testLimits() {
		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x00, 0x01])
			let parser = WASMParser.limits()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result.min, 1)
			XCTAssertNil(result.max)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())

		XCTAssertNoThrow(try {
			let stream = ByteStream(bytes: [0x01, 0x01, 0x02])
			let parser = WASMParser.limits()
			let (result, endIndex) = try parser.parse(stream: stream)
			XCTAssertEqual(result.min, 1)
			XCTAssertEqual(result.max, 2)
			XCTAssertEqual(endIndex, stream.endIndex)
			}())
	}
}
