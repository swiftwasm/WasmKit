import XCTest
@testable import Swasm

class ParserTestCase: XCTestCase {
	var stream: CharacterStream!
}

final class ParserLexicalFormatTests: ParserTestCase {

	var query: String.UTF8View.Element!

	func testParseCharacter() {
		stream = StringStream(string: "abcde")
		query = "a".utf8.first
		do {
			let result = try Parser<ParserCharacter>.character(.single(query)).parse(stream: stream)
			XCTAssertEqual(result, query)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "cdeab")
		query = "a".utf8.first
		do {
			let result = try Parser<ParserCharacter>.character(.single(query)).parse(stream: stream)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "c".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseAnyCharacter() {
		stream = StringStream(string: "abcde")
		do {
			let result = try Parser<ParserCharacter>.character(.all).parse(stream: stream)
			XCTAssertEqual(result, "a".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}

final class ParserValueTests: ParserTestCase {

	func testParseU32() {
		stream = StringStream(string: "123")
		do {
			let result = try Parser<UInt32>.u32.parse(stream: stream)
			XCTAssertEqual(result, 123)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "+123")
		do {
			let result = try Parser<UInt32>.u32.parse(stream: stream)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "+".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "-123")
		do {
			let result = try Parser<UInt32>.u32.parse(stream: stream)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "-".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseI32() {
		stream = StringStream(string: "123")
		do {
			let result = try Parser<Int32>.s32.parse(stream: stream)
			XCTAssertEqual(result, 123)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "+123")
		do {
			let result = try Parser<Int32>.s32.parse(stream: stream)
			XCTAssertEqual(result, 123)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "-123")
		do {
			let result = try Parser<Int32>.s32.parse(stream: stream)
			XCTAssertEqual(result, -123)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseFloat() {
		stream = StringStream(string: "123.456")
		do {
			let result = try Parser<Float>.float.parse(stream: stream)
			XCTAssertEqual(result, 123.456)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "123.456E-10")
		do {
			let result = try Parser<Float>.float.parse(stream: stream)
			XCTAssertEqual(result, 1)
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "0x1AF.B13")
		do {
			let result = try Parser<Float>.hexFloat.parse(stream: stream)
			XCTAssertEqual(result, 0x1AF.B13p0)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseID() {
		stream = StringStream(string: "$abcde")
		do {
			let result = try Parser<ParserCharacter>.id.parse(stream: stream)
			XCTAssertEqual(result, "$abcde".utf8.map { $0 })
		} catch let error {
			XCTFail(String(describing: error))
		}

		stream = StringStream(string: "あいうえお")
		do {
			let result = try Parser<ParserCharacter>.id.parse(stream: stream)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "あ".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}
