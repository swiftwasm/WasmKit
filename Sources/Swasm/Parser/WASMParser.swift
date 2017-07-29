private func p2(_ n: Int) -> Int { return 1 << n }
private func p2(_ n: UInt) -> UInt { return 1 << n }

enum WASMParser {
	/// # Conventions
	/// - SeeAlso: https://webassembly.github.io/spec/binary/conventions.html#conventions

	/// ## Vector
	/// - SeeAlso: https://webassembly.github.io/spec/binary/conventions.html#vectors
	static func vector<S, R>(of parser: ChainableParser<S, R>) -> ChainableParser<S, [R]> where S.Element == Byte {
		return .init { stream, index in
			let (length, vectorStart) = try uint(32).parse(stream: stream, index: index)
			guard let parser = parser.repeated(count: Int(length)) else {
				throw ParserStreamError<S>.vectorInvalidLength(Int(length), location: index)
			}
			return try parser.parse(stream: stream, index: vectorStart)
		}
	}

	/// # Values
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#values

	/// ## Bytes
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#bytes
	static func byte<S>() -> ChainableParser<S, Byte> where S.Element == Byte {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<S>.unexpectedEnd
			}
			return (byte, stream.index(after: index))
		}
	}

	static func byte<S, C: Container>(in set: C) -> ChainableParser<S, Byte>
		where S.Element == Byte, C.Element == S.Element {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<S>.unexpectedEnd
			}
			guard set.contains(byte) else {
				throw ParserStreamError<S>.unexpected(byte, location: index)
			}
			return (byte, stream.index(after: index))
		}
	}

	static func byte<S>(_ b: UInt8) -> ChainableParser<S, Byte> where S.Element == Byte {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<S>.unexpectedEnd
			}
			guard byte == b else {
				throw ParserStreamError<S>.unexpected(byte, location: index)
			}
			return (byte, stream.index(after: index))
		}
	}

	static func bytes<S>(_ sequence: [UInt8]) -> ChainableParser<S, [Byte]>? where S.Element == Byte {
		return .concat(sequence.map { byte($0) })
	}

	static func bytes<S>(length: Int) -> ChainableParser<S, [Byte]>? where S.Element == Byte {
		return byte().repeated(count: length)
	}

	/// ## Integers
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#integers
	static func uint<S>(_ bits: Int) -> ChainableParser<S, UInt> where S.Element == Byte {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<S>.unexpectedEnd
			}

			switch UInt(byte) {
			case let n where n < p2(7) && n < p2(bits):
				return (n, stream.index(after: index))
			case let n where n >= p2(7) && bits > 7:
				let (m, endIndex) = try uint(bits).parse(stream: stream, index: stream.index(after: index))
				let result = p2(7) * m + (n - p2(7))
				return (result, endIndex)
			default:
				throw ParserStreamError<S>.unexpected(byte, location: index)
			}
		}
	}

	static func sint<S>(_ bits: Int) -> ChainableParser<S, Int> where S.Element == Byte {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<S>.unexpectedEnd
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
				throw ParserStreamError<S>.unexpected(byte, location: index)
			}
		}
	}

	static func int<S>(_ bits: Int) -> ChainableParser<S, Int> where S.Element == Byte {
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
	static func float32<S>() -> ChainableParser<S, Float> where S.Element == Byte {
		return bytes(length: 4)!.map { bytes in
			let bitPattern: UInt32 = bytes.reduce(0) { acc, byte in acc << 8 + UInt32(byte) }
			return Float(bitPattern: bitPattern)
		}
	}

	static func float64<S>() -> ChainableParser<S, Double> where S.Element == Byte {
		return bytes(length: 8)!.map { bytes in
			let bitPattern: UInt64 = bytes.reduce(0) { acc, byte in acc << 8 + UInt64(byte) }
			return Double(bitPattern: bitPattern)
		}
	}

	/// ## Names
	/// - SeeAlso: https://webassembly.github.io/spec/binary/values.html#names
	static func name<S>() -> ChainableParser<S, Name> where S.Element == Byte {
		return .init { stream, index in
			var scalars = [UnicodeScalar]()
			let (length, vectorStart) = try uint(32).parse(stream: stream, index: index)
			var index = vectorStart

			while vectorStart.distance(to: index) < length {
				guard let b1 = stream.take(at: index) else {
					throw ParserStreamError<S>.unexpectedEnd
				}
				index = stream.index(after: index)

				guard 0b11000000 <= b1 else {
					let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1]))
					scalars.append(scalar)
					continue
				}

				guard let b2 = stream.take(at: index) else {
					throw ParserStreamError<S>.unexpectedEnd
				}
				index = stream.index(after: index)

				guard 0b11100000 <= b1 else {
					let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2]))
					scalars.append(scalar)
					continue
				}

				guard let b3 = stream.take(at: index) else {
					throw ParserStreamError<S>.unexpectedEnd
				}
				index = stream.index(after: index)

				guard 0b11110000 <= b1 else {
					let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2, b3]))
					scalars.append(scalar)
					continue
				}

				guard let b4 = stream.take(at: index) else {
					throw ParserStreamError<S>.unexpectedEnd
				}
				index = stream.index(after: index)

				let scalar = Unicode.UTF8.decode(Unicode.UTF8.EncodedScalar([b1, b2, b3, b4]))
				scalars.append(scalar)
				continue
			}

			return (String(String.UnicodeScalarView(scalars)), index)
		}
	}

	/// # Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#types

	/// ## Value Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#value-types
	static func valueType<S>() -> ChainableParser<S, ValueType> where S.Element == Byte {
		return .init { stream, index in
			guard let byte = stream.take(at: index) else {
				throw ParserStreamError<S>.unexpectedEnd
			}
			switch byte {
			case 0x7F: return (.int32, stream.index(after: index))
			case 0x7E: return (.int64, stream.index(after: index))
			case 0x7D: return (.uint32, stream.index(after: index))
			case 0x7C: return (.uint64, stream.index(after: index))
			default: throw ParserStreamError<S>.unexpected(byte, location: index)
			}
		}
	}

	/// ## Result Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#result-types
	static func resultType<S>() -> ChainableParser<S, [ValueType]> where S.Element == Byte {
		return byte(0x40).map { _ in [] }.or(valueType().map { [$0] })
	}

	/// ## Function Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#function-types
	static func functionType<S>() -> ChainableParser<S, FunctionType> where S.Element == Byte {
		return byte(0x60)
			.followed(by: vector(of: valueType())) { _, types in types }
			.followed(by: vector(of: valueType())) { FunctionType(parameters: $0, results: $1) }
	}

	/// ## Limits Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#limits
	static func limits<S>() -> ChainableParser<S, Limits> where S.Element == Byte {
		let min: ChainableParser<S, UInt> = uint(32)
		let max: ChainableParser<S, UInt> = uint(32)
		let minOnly = byte(0x00).followed(by: min).map { _, min in Limits(min: UInt32(min), max: nil) }
		let minAndMax = byte(0x01)
			.followed(by: min) { _, min in min }
			.followed(by: max) { min, max in Limits(min: UInt32(min), max: UInt32(max)) }
		return minOnly.or(minAndMax)
	}

	/// ## Memory Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#memory-types
	static func memoryType<S>() -> ChainableParser<S, MemoryType> where S.Element == Byte {
		return limits()
	}

	/// ## Table Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#table-types
	static func tableType<S>() -> ChainableParser<S, TableType> where S.Element == Byte {
		return byte(0x70).followed(by: limits()) { TableType(limits: $1) }
	}

	/// ## Global Types
	/// - SeeAlso: https://webassembly.github.io/spec/binary/types.html#global-types
	static func globalType<S>() -> ChainableParser<S, GlobalType> where S.Element == Byte {
		let mutabilityParser: ChainableParser<S, Mutability> = byte(0x00).map { _ in Mutability.constant }
			.or(byte(0x01).map { _ in Mutability.variable })
		return valueType().followed(by: mutabilityParser) { GlobalType(mutability: $1, valueType: $0) }
	}
}

extension WASMParser {
	/// # Instructions
	/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#instructions

	/// ## Expressions
	/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#expressions
	static func expression<S>() -> ChainableParser<S, Expression> where S.Element == Byte {
		return ChainableParser<S, Expression> { _, index in
			return (Expression(instructions: []), index)
		}
	}
}

extension WASMParser {
	/// # Modules
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#modules

	/// ## Indices
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#indices
	static func index<S>() -> ChainableParser<S, UInt32> where S.Element == Byte {
		return uint(32).map { UInt32($0) }
	}

	/// ## Sections
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#sections
	static func section<S, Content>(_ n: UInt8, of contentParser: ChainableParser<S, Content>)
		-> ChainableParser<S, Content> where S.Element == Byte {
			return .init { stream, index in
				let (_, idEnd) = try byte(n).parse(stream: stream, index: index)
				let (size, sizeEnd) = try uint(32).parse(stream: stream, index: idEnd)
				let (content, contentEnd) = try contentParser.parse(stream: stream, index: sizeEnd)
				let actualSize = sizeEnd.distance(to: contentEnd)
				guard actualSize == S.Index(size) else {
					throw ParserStreamError<S>.sectionInvalidSize(actualSize, expected: Int(size), location: sizeEnd)
				}
				return (content, contentEnd)
			}
	}

	/// ## Type Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#type-section
	static func typeSection<S>() -> ChainableParser<S, [FunctionType]> where S.Element == Byte {
		return section(1, of: vector(of: functionType()))
	}

	/// ## Import Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#import-section
	static func importDescriptor<S>() -> ChainableParser<S, ImportDescriptor> where S.Element == Byte {
		return byte(0x00).followed(by: index()) { ImportDescriptor.function($1) }
			.or(byte(0x01).followed(by: tableType()) { ImportDescriptor.table($1) })
			.or(byte(0x02).followed(by: memoryType()) { ImportDescriptor.memory($1) })
			.or(byte(0x03).followed(by: globalType()) { ImportDescriptor.global($1) })
	}

	static func importSection<S>() -> ChainableParser<S, [Import]> where S.Element == Byte {
		let `import`: ChainableParser<S, Import> = name().followed(by: name())
			.followed(by: importDescriptor()) { Import(module: $0.0, name: $0.1, descripter: $1) }

		return section(2, of: vector(of: `import`))
	}

	/// ## Function Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#function-section
	static func functionSection<S>() -> ChainableParser<S, [TypeIndex]> where S.Element == Byte {
		return section(3, of: vector(of: index()))
	}

	/// ## Table Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#table-section
	static func tableSection<S>() -> ChainableParser<S, [Table]> where S.Element == Byte {
		return section(4, of: vector(of: tableType().map { Table(type: $0) }))
	}

	/// ## Memory Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#memory-section
	static func memorySection<S>() -> ChainableParser<S, [Memory]> where S.Element == Byte {
		return section(5, of: vector(of: memoryType().map { Memory(type: $0) }))
	}

	/// ## Global Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#global-section
	static func globalSection<S>() -> ChainableParser<S, [Global]> where S.Element == Byte {
		let globalParser: ChainableParser<S, Global> = globalType()
			.followed(by: expression()) { Global(type: $0, initializer: $1) }
		return section(6, of: vector(of: globalParser))
	}

	/// ## Export Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#export-section
	static func exportDescriptor<S>() -> ChainableParser<S, ExportDescriptor> where S.Element == Byte {
		return byte(0x00).followed(by: index()) { ExportDescriptor.function($1) }
			.or(byte(0x01).followed(by: index()) { ExportDescriptor.table($1) })
			.or(byte(0x02).followed(by: index()) { ExportDescriptor.memory($1) })
			.or(byte(0x03).followed(by: index()) { ExportDescriptor.global($1) })
	}

	static func exportSection<S>() -> ChainableParser<S, [Export]> where S.Element == Byte {
		let export: ChainableParser<S, Export> = name()
			.followed(by: exportDescriptor()) { Export(name: $0, descriptor: $1) }
		return section(7, of: vector(of: export))
	}

	/// ## Start Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#start-section
	static func startSection<S>() -> ChainableParser<S, FunctionIndex> where S.Element == Byte {
		return section(8, of: index())
	}

	/// ## Element Section
	/// - SeeAlso: https://webassembly.github.io/spec/binary/modules.html#element-section
	static func elementSection<S>() -> ChainableParser<S, [Element]> where S.Element == Byte {
		let element: ChainableParser<S, Element> = index()
			.followed(by: expression()).followed(by: vector(of: index())) {
				Element(table: $0.0, offset: $0.1, initializer: $1)
			}
		return section(9, of: vector(of: element))
	}
}
