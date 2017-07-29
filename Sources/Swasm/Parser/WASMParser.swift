private func p2(_ n: Int) -> Int { return 1 << n }
private func p2(_ n: UInt) -> UInt { return 1 << n }

enum WASMParser {
	/// # Conventions
	/// - SeeAlso: https://webassembly.github.io/spec/binary/conventions.html#conventions

	/// ## Vector
	/// - SeeAlso: https://webassembly.github.io/spec/binary/conventions.html#vectors
	static func vector<R>(of parser: ChainableParser<ByteStream, R>) -> ChainableParser<ByteStream, [R]> {
		return .init { stream, index in
			let (length, vectorStart) = try uint(32).parse(stream: stream, index: index)
			guard let parser = parser.repeated(count: Int(length)) else {
				throw ParserStreamError<ByteStream>.vectorInvalidLength(Int(length))
			}
			return try parser.parse(stream: stream, index: vectorStart)
		}
	}

	/// # Values
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#values

	/// ## Bytes
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#bytes
	static func byte() -> ChainableParser<ByteStream, ByteStream.Element> {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			return (byte, stream.index(after: index))
		}
	}

	static func byte<C: Container>(in set: C) -> ChainableParser<ByteStream, ByteStream.Element>
		where C.Element == UInt8 {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			guard set.contains(byte) else {
				throw ParserStreamError<ByteStream>.unexpected(byte)
			}
			return (byte, stream.index(after: index))
		}
	}

	static func byte(_ b: UInt8) -> ChainableParser<ByteStream, ByteStream.Element> {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			guard byte == b else {
				throw ParserStreamError<ByteStream>.unexpected(byte)
			}
			return (byte, stream.index(after: index))
		}
	}

	static func bytes(_ sequence: [UInt8]) -> ChainableParser<ByteStream, [ByteStream.Element]>? {
		return .concat(sequence.map { byte($0) })
	}

	static func bytes(length: Int) -> ChainableParser<ByteStream, [ByteStream.Element]>? {
		return byte().repeated(count: length)
	}

	/// ## Integers
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#integers
	static func uint(_ bits: Int) -> ChainableParser<ByteStream, UInt> {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}

			switch UInt(byte) {
			case let n where n < p2(7) && n < p2(bits):
				return (n, stream.index(after: index))
			case let n where n >= p2(7) && bits > 7:
				let (m, endIndex) = try uint(bits).parse(stream: stream, index: stream.index(after: index))
				let result = p2(7) * m + (n - p2(7))
				return (result, endIndex)
			default:
				throw ParserStreamError<ByteStream>.unexpected(byte)
			}
		}
	}

	static func sint(_ bits: Int) -> ChainableParser<ByteStream, Int> {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}

			switch Int(byte) {
			case let n where n < p2(6) && n < p2(bits - 1):
				return (n, stream.index(after: index))
			case let n where p2(6) <= n && n < p2(7) && n >= p2(7) - p2(bits - 1):
				return (n - p2(7), stream.index(after: index))
			case let n where n >= p2(7) && bits > 7:
				let (m, endIndex) = try sint(bits).parse(stream: stream, index: stream.index(after: index))
				let result = m << 7 + (n - p2(7))
				return (result, endIndex)
			default:
				throw ParserStreamError<ByteStream>.unexpected(byte)
			}
		}
	}

	static func int(_ bits: Int) -> ChainableParser<ByteStream, Int> {
		return .init { stream, index in
			let (i, endIndex) = try sint(bits).parse(stream: stream, index: index)
			switch i {
			case ..<p2(bits - 1):
				return (i, endIndex)
			default:
				return (i - p2(bits), endIndex)
			}
		}
	}

	/// ## Floating-Point
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#floating-point
	static func float32() -> ChainableParser<ByteStream, Float> {
		return bytes(length: 4)!.map { bytes in
			let bitPattern: UInt32 = bytes.reduce(0) { acc, byte in acc << 8 + UInt32(byte) }
			return Float(bitPattern: bitPattern)
		}
	}

	static func float64() -> ChainableParser<ByteStream, Double> {
		return bytes(length: 8)!.map { bytes in
			let bitPattern: UInt64 = bytes.reduce(0) { acc, byte in acc << 8 + UInt64(byte) }
			return Double(bitPattern: bitPattern)
		}
	}

	/// ## Names
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#names
	static func name() -> ChainableParser<ByteStream, Name> {
		return vector(of: unicode()).map { String(String.UnicodeScalarView($0)) }
	}

	static func unicode() -> ChainableParser<ByteStream, Unicode.Scalar> {
		return .init { stream, index in
			var index = index
			guard let b1 = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			guard 0b11000000 <= b1 else {
				let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1]))
				return (scalar, stream.index(after: index))
			}

			index = stream.index(after: index)
			guard let b2 = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			guard 0b11100000 <= b1 else {
				let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2]))
				return (scalar, stream.index(after: index))
			}

			index = stream.index(after: index)
			guard let b3 = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			guard 0b11110000 <= b1 else {
				let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2, b3]))
				return (scalar, stream.index(after: index))
			}

			index = stream.index(after: index)
			guard let b4 = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2, b3, b4]))
			return (scalar, stream.index(after: index))
		}
	}

	/// # Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#types

	/// ## Value Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#value-types
	static func valueType() -> ChainableParser<ByteStream, ValueType> {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<ByteStream>.unexpectedEnd
			}
			switch byte {
			case 0x7F: return (.int32, stream.index(after: index))
			case 0x7E: return (.int64, stream.index(after: index))
			case 0x7D: return (.uint32, stream.index(after: index))
			case 0x7C: return (.uint64, stream.index(after: index))
			default: throw ParserStreamError<ByteStream>.unexpected(byte)
			}
		}
	}

	/// ## Result Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#result-types
	static func resultType() -> ChainableParser<ByteStream, [ValueType]> {
		return byte(0x40).map { _ in [] }.or(valueType().map { [$0] })
	}

	/// ## Function Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#function-types
	static func functionType() -> ChainableParser<ByteStream, FunctionType> {
		return byte(0x60)
			.followed(by: vector(of: valueType())) { _, types in types }
			.followed(by: vector(of: valueType())) { FunctionType(parameters: $0, results: $1) }
	}

	/// ## Limits Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#limits
	static func limits() -> ChainableParser<ByteStream, Limits> {
		let minOnly = byte(0x00).followed(by: uint(32)) { _, min in Limits(min: UInt32(min), max: nil) }
		let minAndMax = byte(0x01)
			.followed(by: uint(32)) { _, min in min }
			.followed(by: uint(32)) { min, max in Limits(min: UInt32(min), max: UInt32(max)) }
		return minOnly.or(minAndMax)
	}

	/// ## Memory Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#memory-types
	static func memoryType() -> ChainableParser<ByteStream, MemoryType> {
		return limits()
	}

	/// ## Table Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#table-types
	static func tableType() -> ChainableParser<ByteStream, TableType> {
		return byte(0x70).followed(by: limits()) { TableType(limits: $1) }
	}

	/// ## Global Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#global-types
	static func globalType() -> ChainableParser<ByteStream, GlobalType> {
		let mutabilityParser = byte(0x00).map { _ in Mutability.constant }
			.or(byte(0x01).map { _ in Mutability.variable })
		return valueType().followed(by: mutabilityParser) { GlobalType(mutability: $1, valueType: $0) }
	}

	/// # Instructions
	/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#instructions

	/// ## Expressions
	/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#expressions
	static func expression() -> ChainableParser<ByteStream, Expression> {
		return ChainableParser<ByteStream, Expression> { _, index in
			return (Expression(instructions: []), index)
		}
	}

	/// # Modules
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#modules

	/// ## Indices
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#indices

	static func index() -> ChainableParser<ByteStream, UInt32> {
		return uint(32).map { UInt32($0) }
	}

	/// ## Sections
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#sections

	static func section<Content>(of contentParser: ChainableParser<ByteStream, Content>)
		-> ChainableParser<ByteStream, Content> {
		return byte(1)
			.followed(by: uint(32)) { _, size in size }
			.followed(by: contentParser) { _, content in content }
	}

	/// ## Type Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#type-section
	static func typeSection() -> ChainableParser<ByteStream, [FunctionType]> {
		return section(of: vector(of: functionType()))
	}

	/// ## Import Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#import-section
	static func importSection() -> ChainableParser<ByteStream, [Import]> {
		let importDesc = byte(0x00).followed(by: index()) { ImportDescriptor.function($1) }
			.or(byte(0x01).followed(by: tableType()) { ImportDescriptor.table($1) })
			.or(byte(0x02).followed(by: memoryType()) { ImportDescriptor.memory($1) })
			.or(byte(0x03).followed(by: globalType()) { ImportDescriptor.global($1) })

		let importParser = byte(2)
			.followed(by: name()) { _, name in name }
			.followed(by: name())
			.followed(by: importDesc) { Import(module: $0.0, name: $0.1, descripter: $1) }

		return vector(of: importParser)
	}

	/// ## Function Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#function-section
	static func functionSection() -> ChainableParser<ByteStream, [TypeIndex]> {
		return byte(3).followed(by: vector(of: index())) { $1 }
	}

	/// ## Table Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#table-section
	static func tableSection() -> ChainableParser<ByteStream, [Table]> {
		return byte(4).followed(by: vector(of: tableType().map { Table(type: $0) })) { $1 }
	}

	/// ## Memory Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#memory-section
	static func memorySection() -> ChainableParser<ByteStream, [Memory]> {
		return byte(5).followed(by: vector(of: memoryType().map { Memory(type: $0) })) { $1 }
	}

	/// ## Global Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#global-section
	static func globalSection() -> ChainableParser<ByteStream, [Global]> {
		let globalParser = globalType().followed(by: expression()) { Global(type: $0, initializer: $1) }
		return byte(6).followed(by: vector(of: globalParser)) { $1 }
	}

	/// ## Export Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#export-section
	static func exportSection() -> ChainableParser<ByteStream, [Export]> {
		let exportDesc = byte(0x00).followed(by: index()) { ExportDescriptor.function($1) }
			.or(byte(0x01).followed(by: index()) { ExportDescriptor.table($1) })
			.or(byte(0x02).followed(by: index()) { ExportDescriptor.memory($1) })
			.or(byte(0x03).followed(by: index()) { ExportDescriptor.global($1) })
		let exportParser = name().followed(by: exportDesc) { Export(name: $0, descriptor: $1) }
		return byte(7).followed(by: vector(of: exportParser)) { $1 }
	}

	/// ## Start Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#start-section
	static func startSection() -> ChainableParser<ByteStream, FunctionIndex?> {
		return byte(8).followed(by: index().optional()) { $1 }
	}

	/// ## Element Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#element-section
	static func elementSection() -> ChainableParser<ByteStream, [Element]> {
		let element = index().followed(by: expression()).followed(by: vector(of: index())) {
			Element(table: $0.0, offset: $0.1, initializer: $1)
		}
		return byte(9).followed(by: vector(of: element)).map { $1 }
	}
}
