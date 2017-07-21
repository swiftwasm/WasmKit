final class ParserContext {

	let stream: CharacterStream

	init(stream: CharacterStream) {
		self.stream = stream
	}

}

enum ParserError: Error {
	case unexpectedEnd
	case unexpectedCharacter(String.UTF8View.Element)
}

typealias Parser = (ParserContext) throws -> [String.UTF8View.Element]

let parseCharacter: (String.UTF8View.Element) -> Parser = { character in
	return { context in
		guard let c = context.stream.look() else {
			throw ParserError.unexpectedEnd
		}
		guard character == c else {
			throw ParserError.unexpectedCharacter(c)
		}
		context.stream.consume()
		return [c]
	}
}

let parseAnyCharacter: Parser = { context in
	guard let c = context.stream.look() else {
		throw ParserError.unexpectedEnd
	}
	context.stream.consume()
	return [c]
}

let parseIDCharacter: Parser = { context in
	guard let c = context.stream.look() else {
		throw ParserError.unexpectedEnd
	}

	let idCharacters = "a".utf8.first! ... "z".utf8.first!
	guard idCharacters.contains(c) else {
		throw ParserError.unexpectedCharacter(c)
	}
	context.stream.consume()
	return [c]
}

let parseIDCharacters: Parser = { context in
	return try repeated(parseIDCharacter)(context)
}

let parseID: Parser = { context in
	let prefix = "$".utf8.first!
	return try joined(parseCharacter(prefix), parseIDCharacters)(context)
}
