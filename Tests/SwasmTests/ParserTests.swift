import XCTest
@testable import Swasm

final class ParserTests: XCTestCase {

	func testParseCharacter() {
		let context1 = ParserContext(stream: StringStream(string: "abcde"))
		do {
			let c = "a".utf8.first!
			let result = try parseCharacter(c)(context1)
			XCTAssertEqual(Array("a".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}

		let context2 = ParserContext(stream: StringStream(string: "abcde"))
		do {
			let c = "c".utf8.first!
			let result = try parseCharacter(c)(context2)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(c) {
			XCTAssertEqual("a".utf8.first!, c)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseAnyCharacter() {
		let context = ParserContext(stream: StringStream(string: "abcde"))
		do {
			let result = try parseAnyCharacter(context)
			XCTAssertEqual(Array("a".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseIDCharacters() {
		let context1 = ParserContext(stream: StringStream(string: "abcde"))
		do {
			let result = try parseIDCharacter(context1)
			XCTAssertEqual(Array("a".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}

		let context2 = ParserContext(stream: StringStream(string: "$$$$$"))
		do {
			let result = try parseIDCharacter(context2)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(c) {
			XCTAssertEqual("$".utf8.first!, c)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseID() {
		let context1 = ParserContext(stream: StringStream(string: "$abc"))
		do {
			let result = try parseID(context1)
			XCTAssertEqual(Array("$abc".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}

		let context2 = ParserContext(stream: StringStream(string: "abcde"))
		do {
			let result = try parseID(context2)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(c) {
			XCTAssertEqual("a".utf8.first!, c)
		} catch let error {
			XCTFail(String(describing: error))
		}

		let context3 = ParserContext(stream: StringStream(string: "$$$$$"))
		do {
			let result = try parseID(context3)
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(c) {
			XCTAssertEqual("$".utf8.first!, c)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testRepeated() {
		let context = ParserContext(stream: StringStream(string: "aaade"))
		do {
			let c = "a".utf8.first!
			let parseCharacters = try repeated(parseCharacter(c))
			let result = try parseCharacters(context)
			XCTAssertEqual(Array("aaa".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}
