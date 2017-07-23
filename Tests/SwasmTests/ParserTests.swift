import XCTest
@testable import Swasm

class ParserTestCase: XCTestCase {
	var parser: Parser!
}

final class ParserLexicalFormatTests: ParserTestCase {

	var query: String.UTF8View.Element!

	func testParseCharacter() {
		parser = Parser(stream: StringStream(string: "abcde"))
		query = "a".utf8.first
		do {
			let result = try parser.parse(character: .single(query))()
			XCTAssertEqual([query], result)
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "cdeab"))
		query = "a".utf8.first
		do {
			let result = try parser.parse(character: .single(query))()
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "c".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseAnyCharacter() {
		parser = Parser(stream: StringStream(string: "abcde"))
		do {
			let result = try parser.parse(character: .all)()
			XCTAssertEqual(Array("a".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}

final class ParserTokenTests: ParserTestCase {

	func testParseIDCharacters() {
		parser = Parser(stream: StringStream(string: "abcde"))
		do {
			let result = try parser.parseIDCharacter()
			XCTAssertEqual(Array("a".utf8), result)
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "あああ"))
		do {
			let result = try parser.parseIDCharacter()
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "あ".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}

final class ParserCombinatorTests: ParserTestCase {

	func testRepeated() {
		parser = Parser(stream: StringStream(string: "aaabcde"))
		do {
			let c = "a".utf8.first!
			let parseRepeated = parser.repeated(parser.parse(character: .single(c)))
			let result = try parseRepeated()
			XCTAssertEqual(result, Array("aaa".utf8))
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}
