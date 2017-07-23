/// ParserError
enum ParserError: Error {
	case unexpectedEnd
	case unexpectedCharacter(ParserCharacter, expected: CharacterSet)
	case unexpectedToken(ParserResult)
}

protocol ParserResult {}

extension Optional: ParserResult {}
extension ParserCharacter: ParserResult {}
extension Array: ParserResult {}
extension Int: ParserResult {}
extension Int32: ParserResult {}
extension Int64: ParserResult {}
extension UInt: ParserResult {}
extension UInt32: ParserResult {}
extension UInt64: ParserResult {}

struct BinaryResult<A: ParserResult, B: ParserResult>: ParserResult {
	let first: A
	let second: B
	init(_ first: A, _ second: B) {
		self.first = first
		self.second = second
	}
}

enum EitherResult<A: ParserResult, B: ParserResult>: ParserResult {
	case first(A)
	case second(B)
}

/// Parser

struct Parser<Result: ParserResult> {

	typealias ParserFunction = (CharacterStream) throws -> Result

	let function: ParserFunction
	let expectation: CharacterSet

	init(expects expectation: CharacterSet, _ function: @escaping ParserFunction) {
		self.function = function
		self.expectation = expectation
	}

	func parse(stream: CharacterStream) throws -> Result {
		return try function(stream)
	}

}

/// # Lexical Format
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#lexical-format

/// ## Characters
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#characters

typealias ParserCharacter = CharacterStream.Element

indirect enum CharacterSet {
	case single(ParserCharacter)
	case set(Set<ParserCharacter>)
	case range(ClosedRange<ParserCharacter>)
	case union([CharacterSet])
	case all

	@discardableResult func contains(_ character: ParserCharacter) -> Bool {
		switch self {
		case let .single(single):
			return single == character
		case let .set(set):
			return set.contains(character)
		case let .range(range):
			return range.contains(character)
		case let .union(sets):
			return sets.reduce(true) { $0 && $1.contains(character) }
		case .all:
			return true
		}
	}
}

extension Parser {

	static func character(_ set: CharacterSet) -> Parser<ParserCharacter> {
		return Parser<ParserCharacter>(expects: set) { stream in
			guard let c = stream.look() else {
				throw ParserError.unexpectedEnd
			}

			guard set.contains(c) else {
				throw ParserError.unexpectedCharacter(c, expected: set)
			}

			stream.consume()
			return c
		}
	}

}

/// ## Tokens
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#tokens

extension Parser {

	static var keyword: Parser<[ParserCharacter]> {
		return Parser.character(.range("a".utf8.first! ... "z".utf8.first!))
			.followed(by: Parser.idCharacter.repeatedOrZero())
			.map { result in [result.first] + result.second }
	}

	static var reserved: Parser<[ParserCharacter]> {
		return Parser.idCharacter.repeated()
	}

}

/// ## White Space
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#white-space

/// ## Comments
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#comments

/// # Values
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#values

/// ## Integers
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#integers

extension Parser {

	static var sign: Parser<Int> {
		let signs = CharacterSet.set(["+".utf8.first!, "-".utf8.first!])
		return Parser.character(signs)
			.optional()
			.map { c in
				switch c {
				case nil:
					return 1
				case let c? where c == "+".utf8.first!:
					return 1
				case let c? where c == "-".utf8.first!:
					return -1
				case let c?:
					throw ParserError.unexpectedCharacter(c, expected: signs)
				}
		}
	}

	static var digit: Parser<Int> {
		let digits = CharacterSet.range("0".utf8.first! ... "9".utf8.first!)
		return Parser<Int>.character(digits)
			.map { character -> Int in
				switch character {
				case "0".utf8.first!:
					return 0
				case "1".utf8.first!:
					return 1
				case "2".utf8.first!:
					return 2
				case "3".utf8.first!:
					return 3
				case "4".utf8.first!:
					return 4
				case "5".utf8.first!:
					return 5
				case "6".utf8.first!:
					return 6
				case "7".utf8.first!:
					return 7
				case "8".utf8.first!:
					return 8
				case "9".utf8.first!:
					return 9
				default:
					throw ParserError.unexpectedCharacter(character, expected: digits)
				}
		}
	}

	static var hexDigit: Parser<Int> {
		let hexAlphabets = CharacterSet.union([
			.range("A".utf8.first! ... "F".utf8.first!),
			.range("a".utf8.first! ... "z".utf8.first!),
			])
		let hexAlphabetParser = Parser.character(hexAlphabets).map { character -> Int in
			switch character {
			case "A".utf8.first!, "a".utf8.first!:
				return 10
			case "B".utf8.first!, "b".utf8.first!:
				return 11
			case "C".utf8.first!, "c".utf8.first!:
				return 12
			case "D".utf8.first!, "d".utf8.first!:
				return 13
			case "E".utf8.first!, "e".utf8.first!:
				return 14
			case "F".utf8.first!, "f".utf8.first!:
				return 15
			default:
				throw ParserError.unexpectedCharacter(character, expected: hexAlphabets)
			}
		}
		return .any([Parser.digit, hexAlphabetParser])
	}

	static var number: Parser<Int> {
		return Parser.digit.repeated().map { cs in
			cs.reduce(0) { n, d in n * 10 + d }
		}
	}

	static var hexNumber: Parser<Int> {
		return Parser.hexDigit.repeated().map { cs in
			cs.reduce(0) { n, d in n * 10 + d }
		}
	}
	
	static var u32: Parser<UInt32> {
		return Parser.character(.single("0".utf8.first!))
			.followed(by: Parser.character(.single("x".utf8.first!)))
			.followed(by: Parser.hexNumber)
			.map { results in UInt32(results.second) }
	}

	static var s32: Parser<Int32> {
		return Parser.sign.followed(by: Parser.u32).map { result in
			Int32(result.first) * Int32(result.second)
		}
	}

	static var u64: Parser<UInt64> {
		return Parser.character(.single("0".utf8.first!))
			.followed(by: Parser.character(.single("x".utf8.first!)))
			.followed(by: Parser.hexNumber)
			.map { results in UInt64(results.second) }
	}

	static var s64: Parser<Int64> {
		return Parser.sign.followed(by: Parser.u64).map { result in
			Int64(result.first) * Int64(result.second)
		}
	}

}

/// ## Floating-Point
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#floating-point

/// ## Strings
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#strings

/// ## Names
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#names

/// ## Identifiers
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#text-id
extension Parser {

	static var idCharacter: Parser<ParserCharacter> {
		let symbols = [
			"!", "#", "$", "%", "&", "′", "*", "+", "-", ".", "/",
			":", "<", "=", ">", "?", "@", "\\", "^", "_", "`", "|", "~",
			]
			.map { $0.utf8.first! }

		return Parser.character(.union([
			.range("a".utf8.first! ... "z".utf8.first!),
			.range("A".utf8.first! ... "Z".utf8.first!),
			.set(Set(symbols)),
			]))
	}

	static var id: Parser<[ParserCharacter]> {
		return Parser.character(.single("$".utf8.first!))
			.followed(by: Parser.idCharacter.repeated())
			.map { result in [result.first] + result.second }
	}

}

/// # Combinators
extension Parser {

	static func any(_ parsers: [Parser<Result>]) -> Parser<Result> {
		let expectation = CharacterSet.union(parsers.map { $0.expectation })
		return Parser<Result>(expects: expectation) { stream in
			for parser in parsers {
				guard let result = try? parser.parse(stream: stream) else {
					continue
				}
				return result
			}
			guard let c = stream.look() else { throw ParserError.unexpectedEnd }
			throw ParserError.unexpectedCharacter(c, expected: expectation)
		}
	}

	func map<Another>(transformation transform: @escaping ((Result) throws -> Another)) -> Parser<Another> {
		return Parser<Another>(expects: expectation) { stream in
			try transform(try self.parse(stream: stream))
		}
	}

	func followed(by parser: Parser<Result>) -> Parser<BinaryResult<Result, Result>> {
		return Parser<BinaryResult<Result, Result>>(expects: expectation) { stream in
			let first = try self.parse(stream: stream)
			let second = try parser.parse(stream: stream)
			return BinaryResult(first, second)
		}
	}

	func followed<Another>(by parser: Parser<Another>) -> Parser<BinaryResult<Result, Another>> {
		return Parser<BinaryResult<Result, Another>>(expects: expectation) { stream in
			let first = try self.parse(stream: stream)
			let second = try parser.parse(stream: stream)
			return BinaryResult(first, second)
		}
	}

	func or<Another>(by parser: Parser<Another>) -> Parser<EitherResult<Result, Another>> {
		let expectation = CharacterSet.union([self.expectation, parser.expectation])
		return Parser<EitherResult<Result, Another>>(expects: expectation) { stream in
			if let first = try? self.parse(stream: stream) {
				return EitherResult.first(first)
			} else if let second = try? parser.parse(stream: stream) {
				return EitherResult.second(second)
			}
			guard let c = stream.look() else { throw ParserError.unexpectedEnd }
			throw ParserError.unexpectedCharacter(c, expected: expectation)
		}
	}

	func repeated() -> Parser<[Result]> {
		return self.followed(by: self.repeatedOrZero()).map { results in
			[results.first] + results.second
		}
	}

	func repeatedOrZero() -> Parser<[Result]> {
		return Parser<[Result]>(expects: expectation) { stream in
			var results = [Result]()
			while let result = try? self.parse(stream: stream) {
				results.append(result)
			}
			return results
		}
	}

	func optional() -> Parser<Result?> {
		return Parser<Result?>(expects: .all) { stream in
			return try? self.parse(stream: stream)
		}
	}

}
