public protocol ByteStream: ~Copyable {
    var currentIndex: Int { get }

    func consumeAny() throws(WasmKitError) -> UInt8
    func consume(_ expected: Set<UInt8>) throws(WasmKitError) -> UInt8
    func consume(count: Int) throws(WasmKitError) -> ArraySlice<UInt8>

    func peek() throws(WasmKitError) -> UInt8?
}

extension ByteStream {
    func consume(_ expected: UInt8) throws(WasmKitError) -> UInt8 {
        try consume(Set([expected]))
    }

    @usableFromInline
    func hasReachedEnd() throws(WasmKitError) -> Bool {
        try peek() == nil
    }
}
public final class StaticByteStream: ByteStream {
    public let bytes: ArraySlice<UInt8>
    public var currentIndex: Int

    public init(bytes: [UInt8]) {
        self.bytes = ArraySlice(bytes)
        currentIndex = bytes.startIndex
    }

    public init(bytes: ArraySlice<UInt8>) {
        self.bytes = bytes
        currentIndex = bytes.startIndex
    }

    @discardableResult
    public func consumeAny() throws(WasmKitError) -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw WasmKitError.wasmParser(WasmParserError(kind: .unexpectedEnd(expected: nil), offset: self.currentIndex))
        }

        let consumed = bytes[currentIndex]
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws(WasmKitError) -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw WasmKitError.wasmParser(WasmParserError(kind: .unexpectedEnd(expected: Set(expected)), offset: currentIndex))
        }

        let consumed = bytes[currentIndex]
        guard expected.contains(consumed) else {
            throw WasmKitError.wasmParser(WasmParserError(
                kind: .unexpectedByte(
                    consumed,
                    index: currentIndex,
                    expected: Set(expected)
                ), offset: currentIndex))
        }

        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func consume(count: Int) throws(WasmKitError) -> ArraySlice<UInt8> {
        guard count > 0 else { return [] }
        let updatedIndex = currentIndex + count

        guard bytes.indices.contains(updatedIndex - 1) else {
            throw WasmKitError.wasmParser(WasmParserError(kind: .unexpectedEnd(expected: nil), offset: currentIndex))
        }

        defer { currentIndex = updatedIndex }

        return bytes[currentIndex..<updatedIndex]
    }

    public func peek() -> UInt8? {
        guard bytes.indices.contains(currentIndex) else {
            return nil
        }
        return bytes[currentIndex]
    }
}
