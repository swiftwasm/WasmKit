/// ParserError
enum ParserError: Error {
	case unexpectedEnd
	case unexpectedCharacter(Parser.Character, expected: Parser.CharacterSet)
	case unexpectedToken(ParserResult)
}

protocol ParserResult {}

extension Parser.Character: ParserResult {}
extension Array: ParserResult {}

typealias Digit = Int
extension Digit: ParserResult {}

/// Parser
struct Parser {

	typealias Character = String.UTF8View.Element

	let stream: CharacterStream

	init(stream: CharacterStream) {
		self.stream = stream
	}

	typealias ParseFunction = () throws -> ParserResult
}

/// # Lexical Format
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#lexical-format

/// ## Characters
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#characters
extension Parser {

	indirect enum CharacterSet {
		case single(Parser.Character)
		case set(Set<Parser.Character>)
		case range(ClosedRange<Parser.Character>)
		case union([CharacterSet])
		case all
	}

	func parse(character cs: CharacterSet) -> ParseFunction {
		return { [stream] in
			guard let c = stream.look() else {
				throw ParserError.unexpectedEnd
			}

			switch cs {
			case let .single(single):
				guard single == c else {
					throw ParserError.unexpectedCharacter(c, expected: cs)
				}
			case let .set(set):
				guard set.contains(c) else {
					throw ParserError.unexpectedCharacter(c, expected: cs)
				}
			case let .range(range):
				guard range.contains(c) else {
					throw ParserError.unexpectedCharacter(c, expected: cs)
				}
			case let .union(sets):
				return try self.any(sets.map { self.parse(character: $0) })()
			case .all:
				break
			}

			stream.consume()
			return Parser.Character(c)
		}
	}

	func parse(characters: [Character]) -> ParseFunction {
		return joined(characters.map { parse(character: .single($0)) })
	}

}

/// ## Tokens
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#tokens

extension Parser {

	var parseKeyword: ParseFunction {
		return joined(
			parse(character: .range("a".utf8.first! ... "z".utf8.first!)),
			repeatedOrZero(parseIDCharacter)
		)
	}

	var parseReserved: ParseFunction {
		return repeated(parseIDCharacter)
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

	var parseSign: ParseFunction {
		return optional(parse(character: .set([
			"+".utf8.first!,
			"-".utf8.first!,
			])))
	}

	var parseDigit: ParseFunction {
		let digits = CharacterSet.range("0".utf8.first! ... "9".utf8.first!)
		return map(parse(character: digits)) { result in
			guard let c = result as? Parser.Character else {
				throw ParserError.unexpectedToken(result)
			}
			switch c {
			case "0".utf8.first!:
				return Digit(0)
			case "1".utf8.first!:
				return Digit(1)
			case "2".utf8.first!:
				return Digit(2)
			case "3".utf8.first!:
				return Digit(3)
			case "4".utf8.first!:
				return Digit(4)
			case "5".utf8.first!:
				return Digit(5)
			case "6".utf8.first!:
				return Digit(6)
			case "7".utf8.first!:
				return Digit(7)
			case "8".utf8.first!:
				return Digit(8)
			case "9".utf8.first!:
				return Digit(9)
			default:
				throw ParserError.unexpectedCharacter(c, expected: digits)
			}
		}
	}

	var parseHexDigit: ParseFunction {
		let hexAlphabets = CharacterSet.union([
			.range("A".utf8.first! ... "F".utf8.first!),
			.range("a".utf8.first! ... "z".utf8.first!),
			])
		let parseHexAlphabet = parse(character: hexAlphabets)
		return any([parseDigit, parseHexAlphabet])
	}

	var parseNumber: ParseFunction {
		return map(repeated(parseDigit)) { result in
			guard let results = result as? [Int] else {
				throw ParserError.unexpectedToken(result)
			}
			return results.reduce(0) { n, d in n * 10 + Int(d) }
		}
	}

	var parseHexNumber: ParseFunction {
		return map(repeated(parseHexDigit)) { result in
			guard let results = result as? [Int] else {
				throw ParserError.unexpectedToken(result)
			}
			return results.reduce(0) { n, d in n * 16 + Int(d) }
		}
	}

	var parseU32: ParseFunction {
		return any([
			parseNumber,
			map(joined(parse(characters: "0x".utf8.map { $0 }), parseHexNumber)) { result in
				guard let results = result as? [ParserResult], results.count == 2 else {
					throw ParserError.unexpectedToken(result)
				}
				guard let number = results.last as? Int else {
					throw ParserError.unexpectedToken(result)
				}
				return number
			},
			])
	}

	var parseI32: ParseFunction {
		return map(joined(optional(parseSign), parseU32)) { result in
			guard let results = result as? [ParserResult], results.count == 2 else {
				guard let results = result as? [Int], results.count == 1, let number = results.first else {
					throw ParserError.unexpectedToken(result)
				}
				return number
			}

			guard let sign = results.first, let number = results.last as? Int else {
				throw ParserError.unexpectedToken(result)
			}
			switch sign {
			case let array as [ParserResult] where array.isEmpty:
				return number
			case let c as Character where c == "+".utf8.first!:
				return number
			case let c as Character where c == "-".utf8.first!:
				return -number
			default:
				throw ParserError.unexpectedToken(result)
			}
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

	var parseIDCharacter: ParseFunction {
		let symbols = [
			"!", "#", "$", "%", "&", "′", "*", "+", "-", ".", "/",
			":", "<", "=", ">", "?", "@", "\\", "^", "_", "`", "|", "~",
			]
			.map { $0.utf8.first! }

		let chars = CharacterSet.union([
			.range("a".utf8.first! ... "z".utf8.first!),
			.range("A".utf8.first! ... "Z".utf8.first!),
			.set(Set(symbols)),
			])

		return parse(character: chars)
	}

	var parseIDCharacters: ParseFunction {
		return repeated(parseIDCharacter)
	}

	var parseID: ParseFunction {
		return joined(
			parse(character: .single("$".utf8.first!)),
			repeated(parseIDCharacter)
		)
	}

}

/// # Combinators
extension Parser {

	func joined(_ parsers: ParseFunction...) -> ParseFunction {
		return joined(parsers)
	}

	func joined(_ parsers: [ParseFunction]) -> ParseFunction {
		return {
			return try parsers.reduce([ParserResult]()) { results, parse in
				let result = try parse()
				if let rs = result as? [ParserResult] {
					return results + rs
				} else {
					return results + [result]
				}
			}
		}
	}

	func any(_ parsers: ParseFunction...) -> ParseFunction {
		return any(parsers)
	}

	func any(_ parsers: [ParseFunction]) -> ParseFunction {
		return {
			var actual: Parser.Character?
			var expected = [CharacterSet]()

			for parse in parsers {
				do {
					return try parse()
				} catch let ParserError.unexpectedCharacter(a, e) {
					actual = a
					expected.append(e)
				}
			}

			guard let a = actual else {
				throw ParserError.unexpectedEnd
			}

			throw ParserError.unexpectedCharacter(a, expected: .union(expected))
		}
	}

	func repeated(_ parse: @escaping ParseFunction) -> ParseFunction {
		return joined(parse, repeatedOrZero(parse))
	}

	func repeatedOrZero(_ parse: @escaping ParseFunction) -> ParseFunction {
		return {
			var results: [ParserResult] = []
			while let result = try? parse() {
				if let rs = result as? [ParserResult] {
					results.append(contentsOf: rs)
				} else {
					results.append(result)
				}
			}
			return results
		}
	}

	func optional(_ parse: @escaping ParseFunction) -> ParseFunction {
		return { (try? parse()) ?? [] }
	}

	func map(
		_ parse: @escaping ParseFunction,
		transformation transform: @escaping (ParserResult) throws -> ParserResult
		) -> ParseFunction {
		return { try transform(try parse()) }
	}

}
