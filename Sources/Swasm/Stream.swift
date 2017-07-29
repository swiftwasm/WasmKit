protocol Stream: Equatable {
	associatedtype Element: Equatable
	associatedtype Index

	var startIndex: Index { get }
	var endIndex: Index { get }
	func take(at index: Index) -> Element?
	func index(after index: Index) -> Index
}

struct ByteStream: Stream {
	typealias Byte = UInt8

	let bytes: [Byte]

	var startIndex: Array<Byte>.Index {
		return bytes.startIndex
	}

	var endIndex: Array<Byte>.Index {
		return bytes.endIndex
	}

	init(bytes: [Byte]) {
		self.bytes = bytes
	}

	func take(at index: Array<Byte>.Index) -> Byte? {
		guard bytes.indices.contains(index) else { return nil }
		return bytes[index]
	}

	func index(after index: Int) -> Int {
		return bytes.index(after: index)
	}
}

extension ByteStream: Equatable {
	static func == (lhs: ByteStream, rhs: ByteStream) -> Bool {
		return lhs.bytes == rhs.bytes
	}
}
