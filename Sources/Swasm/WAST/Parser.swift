/// ParserError
enum ParserError: Error {
	case unexpectedEnd
	case unexpectedCharacter(String.UTF8View.Element, expected: Parser.CharacterSet)
}

/// Parser
struct Parser {

	let stream: CharacterStream

	init(stream: CharacterStream) {
		self.stream = stream
	}

	typealias ParseFunction = () throws -> [String.UTF8View.Element]
}

/// # Lexical Format
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#lexical-format

/// ## Characters
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#characters
extension Parser {

	indirect enum CharacterSet {
		case single(String.UTF8View.Element)
		case set(Set<String.UTF8View.Element>)
		case range(ClosedRange<String.UTF8View.Element>)
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
			case .all: break
			}

			stream.consume()
			return [c]
		}
	}
}

/// ## Tokens
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#tokens

/// ## White Space
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#white-space

/// ## Comments
/// - SeeAlso: https://webassembly.github.io/spec/text/lexical.html#comments

/// # Values
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#values

/// ## Integers
/// - SeeAlso: https://webassembly.github.io/spec/text/values.html#integers

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
			return try parsers.reduce([]) { acc, parse in
				let result = try parse()
				return acc + result
			}
		}
	}

	func any(_ parsers: ParseFunction...) -> ParseFunction {
		return any(parsers)
	}

	func any(_ parsers: [ParseFunction]) -> ParseFunction {
		return {
			var actual: String.UTF8View.Element?
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
			var result: [String.UTF8View.Element] = []
			while let cs = try? parse() {
				result += cs
			}
			return result
		}
	}

}
