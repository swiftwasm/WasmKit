@testable import Swasm

import XCTest

func expect<P: Parser>(
	_ parser: P?,
	_ stream: P.Input,
	toBe expectation: P.Result,
	_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line)
	where P.Input == ByteStream, P.Result: Equatable {
		XCTAssertNotNil(parser, message, file: file, line: line)
		guard let parser = parser else {
			return
		}
		XCTAssertNoThrow(try {
			let (result, endIndex) = try parser.parse(stream: stream, index: stream.startIndex)
			XCTAssertEqual(result, expectation, message, file: file, line: line)
			XCTAssertEqual(endIndex, stream.endIndex, message, file: file, line: line)
			}(), message, file: file, line: line)
}

func expect<P: Parser, E>(
	_ parser: P?,
	_ stream: P.Input,
	toBe expectation: [E],
	_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line)
	where P.Input == ByteStream, P.Result == [E], E: Equatable {
		XCTAssertNotNil(parser, message, file: file, line: line)
		guard let parser = parser else {
			return
		}
		XCTAssertNoThrow(try {
			let (result, endIndex) = try parser.parse(stream: stream, index: stream.startIndex)
			XCTAssertEqual(result, expectation, message, file: file, line: line)
			XCTAssertEqual(endIndex, stream.endIndex, message, file: file, line: line)
			}(), message, file: file, line: line)
}

func expect<P: Parser>(
	_ parser: P?,
	_ stream: P.Input,
	toBe expectation: Value.Type,
	_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line)
	where P.Input == ByteStream, P.Result == Value.Type {
		XCTAssertNotNil(parser, message, file: file, line: line)
		guard let parser = parser else {
			return
		}
		XCTAssertNoThrow(try {
			let (result, endIndex) = try parser.parse(stream: stream, index: stream.startIndex)
			XCTAssert(result == expectation, message, file: file, line: line)
			XCTAssertEqual(endIndex, stream.endIndex, message, file: file, line: line)
			}(), message, file: file, line: line)
}

func expect<P: Parser>(
	_ parser: P?,
	_ stream: P.Input,
	toBe expectation: [Value.Type],
	_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line)
	where P.Input == ByteStream, P.Result == [Value.Type] {
		XCTAssertNotNil(parser, message, file: file, line: line)
		guard let parser = parser else {
			return
		}
		XCTAssertNoThrow(try {
			let (result, endIndex) = try parser.parse(stream: stream, index: stream.startIndex)
			XCTAssert(result == expectation, message, file: file, line: line)
			XCTAssertEqual(endIndex, stream.endIndex, message, file: file, line: line)
			}(), message, file: file, line: line)
}

func expect<P: Parser, E: Error>(
	_ parser: P?,
	_ stream: P.Input,
	toBe expectation: E,
	_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line)
	where P.Input == ByteStream, E: Equatable {
		XCTAssertNotNil(parser, message, file: file, line: line)
		guard let parser = parser else {
			return
		}
		XCTAssertThrowsError(try {
			_ = try parser.parse(stream: stream, index: stream.startIndex)
			}(), message, file: file, line: line) { error in
				guard let error = error as? E else {
					XCTFail()
					return
				}
				XCTAssertEqual(error, expectation, message, file: file, line: line)
		}
}
