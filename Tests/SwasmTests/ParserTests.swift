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
			guard let character = result as? Parser.Character else {
				XCTFail(String(describing: result))
				return
			}
			XCTAssertEqual(character, query)
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
			guard let character = result as? Parser.Character else {
				XCTFail(String(describing: result))
				return
			}
			XCTAssertEqual(character, "a".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}

final class ParserValueTests: ParserTestCase {

	func testParseU32() {
		parser = Parser(stream: StringStream(string: "123"))
		do {
			let result = try parser.parseU32()
			guard let number = result as? Int, number == 123 else {
				XCTFail(String(describing: result))
				return
			}
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "+123"))
		do {
			let result = try parser.parseU32()
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "+".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "-123"))
		do {
			let result = try parser.parseU32()
			XCTFail("shoud throw, but got \(result)")
		} catch let ParserError.unexpectedCharacter(actual, _) {
			XCTAssertEqual(actual, "-".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseI32() {
		parser = Parser(stream: StringStream(string: "123"))
		do {
			let result = try parser.parseI32()
			guard let number = result as? Int, number == 123 else {
				XCTFail(String(describing: result))
				return
			}
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "+123"))
		do {
			let result = try parser.parseI32()
			guard let number = result as? Int, number == 123 else {
				XCTFail(String(describing: result))
				return
			}
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "-123"))
		do {
			let result = try parser.parseI32()
			guard let number = result as? Int, number == -123 else {
				XCTFail(String(describing: result))
				return
			}
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testParseIDCharacters() {
		parser = Parser(stream: StringStream(string: "abcde"))
		do {
			let result = try parser.parseIDCharacters()
			guard let cs = result as? [Parser.Character] else {
				XCTFail(String(describing: result))
				return
			}
			XCTAssertEqual(cs, "abcde".utf8.map { $0 })
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
			guard let results = result as? [ParserResult] else {
				XCTFail(String(describing: result))
				return
			}
			guard let cs = results as? [Parser.Character] else {
				XCTFail(String(describing: result))
				return
			}
			XCTAssertEqual(cs, "aaa".utf8.map { $0 })
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

	func testOptional() {
		parser = Parser(stream: StringStream(string: "abcde"))
		do {
			let c = "f".utf8.first!
			let parseOptional = parser.optional(parser.parse(character: .single(c)))
			let result = try parseOptional()
			guard let results = result as? [ParserResult], results.isEmpty else {
				XCTFail(String(describing: result))
				return
			}
		} catch let error {
			XCTFail(String(describing: error))
		}

		parser = Parser(stream: StringStream(string: "abcde"))
		do {
			let c = "a".utf8.first!
			let parseOptional = parser.optional(parser.parse(character: .single(c)))
			let result = try parseOptional()
			guard let character = result as? Parser.Character else {
				XCTFail(String(describing: result))
				return
			}
			XCTAssertEqual(character, "a".utf8.first!)
		} catch let error {
			XCTFail(String(describing: error))
		}
	}

}
