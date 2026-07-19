public protocol ByteStream: ~Copyable {
    var currentIndex: Int { get }

    func consumeAny() throws(WasmParserError) -> UInt8
    func consume(_ expected: Set<UInt8>) throws(WasmParserError) -> UInt8
    func consume(count: Int) throws(WasmParserError) -> ArraySlice<UInt8>

    /// Consume `count` bytes as a range of a ``ModuleBacking`` without copying them out. Streams backed
    /// by stable whole-module memory (an array or a memory-mapped file) return that shared backing and
    /// the range in place; the default copies. Used for function bodies, which are retained past parsing
    /// and decoded lazily per instantiation, so avoiding the copy keeps parse from touching body bytes.
    func consumeBody(count: Int) throws(WasmParserError) -> (backing: ModuleBacking, range: Range<Int>)

    func peek() throws(WasmParserError) -> UInt8?
}

extension ByteStream {
    func consume(_ expected: UInt8) throws(WasmParserError) -> UInt8 {
        try consume(Set([expected]))
    }

    /// Default: copy the consumed range into a freshly-owned backing.
    public func consumeBody(count: Int) throws(WasmParserError) -> (backing: ModuleBacking, range: Range<Int>) {
        let array = Array(try consume(count: count))
        return (ModuleBacking(retaining: array), 0..<array.count)
    }

    @usableFromInline
    func hasReachedEnd() throws(WasmParserError) -> Bool {
        try peek() == nil
    }
}
public final class StaticByteStream: ByteStream {
    public let bytes: ArraySlice<UInt8>
    /// Whole-buffer backing shared with any bodies handed out by `consumeBody`, aligned so that
    /// `currentIndex` (kept zero-based) is a direct offset into it.
    @usableFromInline let backing: ModuleBacking
    public var currentIndex: Int

    public init(bytes: [UInt8]) {
        // Retain the array in place (zero-copy); `ArraySlice(bytes)` shares its storage and is zero-based.
        self.backing = ModuleBacking(retaining: bytes)
        self.bytes = ArraySlice(bytes)
        currentIndex = 0
    }

    public init(bytes: ArraySlice<UInt8>) {
        // Normalize to a zero-based array so body ranges index by `currentIndex` directly. Copies, but
        // only on this rarely-used slice entry point (the file/mmap paths never hit it).
        let normalized = Array(bytes)
        self.backing = ModuleBacking(retaining: normalized)
        self.bytes = ArraySlice(normalized)
        currentIndex = 0
    }

    @discardableResult
    public func consumeAny() throws(WasmParserError) -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: self.currentIndex)
        }

        let consumed = bytes[currentIndex]
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws(WasmParserError) -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: Set(expected)), offset: currentIndex)
        }

        let consumed = bytes[currentIndex]
        guard expected.contains(consumed) else {
            throw WasmParserError(
                kind: .parserUnexpectedByte(
                    consumed,
                    expected: Set(expected)
                ), offset: currentIndex)
        }

        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func consume(count: Int) throws(WasmParserError) -> ArraySlice<UInt8> {
        guard count > 0 else { return [] }
        let updatedIndex = currentIndex + count

        guard bytes.indices.contains(updatedIndex - 1) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
        }

        defer { currentIndex = updatedIndex }

        return bytes[currentIndex..<updatedIndex]
    }

    public func consumeBody(count: Int) throws(WasmParserError) -> (backing: ModuleBacking, range: Range<Int>) {
        guard count > 0 else { return (backing, currentIndex..<currentIndex) }
        let updatedIndex = currentIndex + count
        guard bytes.indices.contains(updatedIndex - 1) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
        }
        defer { currentIndex = updatedIndex }
        // `currentIndex` is a zero-based offset into `backing` (see init), so no copy is needed.
        return (backing, currentIndex..<updatedIndex)
    }

    public func peek() -> UInt8? {
        guard bytes.indices.contains(currentIndex) else {
            return nil
        }
        return bytes[currentIndex]
    }
}
