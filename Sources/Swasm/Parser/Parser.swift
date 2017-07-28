enum ParserStreamError<S: Stream>: Error {
	case unexpected(element: S.Element)
	case unexpectedEnd
	case vectorInvalidLength(Int)
}

protocol Parser {
	associatedtype Input: Stream
	associatedtype Result
	func parse(stream: Input, index: Input.Index) throws -> (Result, Input.Index)
}

struct ChainableParser<Input: Stream, Result>: Parser {
	typealias Function = (Input, Input.Index) throws -> (Result, Input.Index)

	let function: Function

	init(function: @escaping Function) {
		self.function = function
	}

	func parse(stream: Input, index: Input.Index) throws -> (Result, Input.Index) {
		return try function(stream, index)
	}

	func parse(stream: Input) throws -> (Result, Input.Index) {
		return try function(stream, stream.startIndex)
	}
}

protocol Container {
	associatedtype Element: Equatable
	func contains(_ element: Element) -> Bool
}

extension Set: Container {}
extension Range: Container {}
extension ClosedRange: Container {}

extension ChainableParser {
	func optional() -> ChainableParser<Input, Result?> {
		return .init { stream, index in
			guard let (result, endIndex) = try? self.parse(stream: stream, index: index) else {
				return (nil, index)
			}
			return (result, endIndex)
		}
	}
}

extension ChainableParser {
	func map<Another>(transform: @escaping (Result) throws -> Another) rethrows -> ChainableParser<Input, Another> {
		return .init { stream, index in
			let (result, endIndex) = try self.parse(stream: stream, index: index)
			return (try transform(result), endIndex)
		}
	}
}

extension ChainableParser {
	func or(_ another: ChainableParser) -> ChainableParser {
		return .init { stream, index in
			guard let (result, endIndex) = try? self.parse(stream: stream, index: index) else {
				return try another.parse(stream: stream, index: index)
			}
			return (result, endIndex)
		}
	}
}

extension ChainableParser {
	func followed<Another>(by another: ChainableParser<Input, Another>) -> ChainableParser<Input, (Result, Another)> {
		return followed(by: another) { a, b in (a, b) }
	}

	func followed<Another, R>
		(by another: ChainableParser<Input, Another>, resultSelector: @escaping (Result, Another) -> R)
		-> ChainableParser<Input, R> {
			return .init { stream, index in
				let (first, firstEnd) = try self.parse(stream: stream, index: index)
				let (second, secondEnd) = try another.parse(stream: stream, index: firstEnd)
				return (resultSelector(first, second), secondEnd)
			}
	}
}

extension ChainableParser {
	static func concat<I, R>(_ first: ChainableParser<I, R>, _ parsers: ChainableParser<I, R>...)
		-> ChainableParser<I, [R]> {
		return concat(first, parsers)
	}

	static func concat<I, R>(_ parsers: [ChainableParser<I, R>]) -> ChainableParser<I, [R]>? {
		guard let first = parsers.first else { return nil }
		return concat(first, Array(parsers.dropFirst()))
	}

	private static func concat<I, R>(_ first: ChainableParser<I, R>, _ parsers: [ChainableParser<I, R>])
		-> ChainableParser<I, [R]> {
		let first = first.map { [$0] }
		guard !parsers.isEmpty else { return first }
		return parsers.reduce(first) { parser, another in
			parser.followed(by: another).map { $0 + [$1] }
		}
	}
}

extension ChainableParser {
	func repeatedOrZero() -> ChainableParser<Input, [Result]> {
		return ChainableParser<Input, [Result]> { stream, index in
			var results = [Result]()
			var endIndex = index
			while let (result, index) = try? self.parse(stream: stream, index: endIndex) {
				results.append(result)
				endIndex = index
			}
			return (results, endIndex)
		}
	}

	func repeated() -> ChainableParser<Input, [Result]> {
		return followed(by: repeatedOrZero()) { a, b in [a] + b }
	}

	func repeated(count: Int) -> ChainableParser<Input, [Result]>? {
		guard count >= 1 else { return nil }
		let parsers = (0 ..< count - 1).map { _ in self }
		return .concat(self, parsers)
	}
}
