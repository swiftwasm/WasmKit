func joined(_ parsers: Parser...) throws -> Parser {
	return { context in
		return try parsers.reduce([]) { acc, parse in
			let result = try parse(context)
			return acc + result
		}
	}
}

func repeated(_ parse: @escaping Parser) throws -> Parser {
	return try joined(parse, repeatedOrZero(parse))
}

func repeatedOrZero(_ parse: @escaping Parser) -> Parser {
	return { context in
		var result: [String.UTF8View.Element] = []
		while let cs = try? parse(context) {
			result += cs
		}
		return result
	}
}
