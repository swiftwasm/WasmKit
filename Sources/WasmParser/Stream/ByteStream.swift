/// A cursor-based mutable view into a `ByteStreamSource`.
@usableFromInline
struct ByteStream<Source: ByteStreamSource> {
    @usableFromInline var currentIndex: Int
    @usableFromInline let source: Source

    @inlinable
    init(_ source: Source) {
        self.currentIndex = 0
        self.source = source
    }

    /// Consumes and returns the next byte in the stream, or throws if the stream has ended.
    @inlinable
    mutating func consumeAny() throws(WasmParserError) -> UInt8 {
        guard let byte = try source.readByte(at: currentIndex) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
        }
        currentIndex += 1
        return byte
    }

    /// Consumes and returns the next `count` bytes in the stream, or throws if fewer than `count` bytes remain.
    @inlinable
    mutating func consume(count: Int) throws(WasmParserError) -> ArraySlice<UInt8> {
        guard count > 0 else { return [] }
        guard let bytes = try source.readBytes(from: currentIndex, to: currentIndex + count) else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
        }
        currentIndex += count
        return bytes
    }

    /// Returns the next byte in the stream without consuming it, or `nil` if the stream has ended.
    @inlinable
    func peek() throws(WasmParserError) -> UInt8? {
        return try source.readByte(at: currentIndex)
    }

    /// Returns `true` if the stream has reached its end, or `false` otherwise.
    @usableFromInline
    func hasReachedEnd() throws(WasmParserError) -> Bool {
        try peek() == nil
    }
}

/// A cursor-agnostic provider of the bytes backing a `ByteStream`.
///
/// Implementations are addressed by absolute offset and know nothing about the
/// stream's current position.
///
/// Rationale: the read cursor is usually a byte source's only mutable state, so
/// moving it onto `ByteStream` lets the source stay immutable. An address-mapped
/// source (one backed by a memory region) can then serve reads without mutating
/// itself. That keeps `Span`-based memory safety simple: borrowed bytes are tied
/// to the immutable source's lifetime alone.
public protocol ByteStreamSource: ~Escapable {
    /// Returns the byte at `offset`, or `nil` if `offset` is past the end.
    func readByte(at offset: Int) throws(WasmParserError) -> UInt8?
    /// Returns the bytes in `startOffset..<endOffset`, or `nil` if fewer than
    /// `endOffset` bytes are available.
    func readBytes(from startOffset: Int, to endOffset: Int) throws(WasmParserError) -> ArraySlice<UInt8>?
}

public final class StaticByteStreamSource: ByteStreamSource {
    public let bytes: ArraySlice<UInt8>
    public var count: Int { return bytes.count }

    public init(bytes: [UInt8]) {
        self.bytes = ArraySlice(bytes)
    }

    public init(bytes: ArraySlice<UInt8>) {
        self.bytes = bytes
    }

    @inlinable
    public func readByte(at offset: Int) throws(WasmParserError) -> UInt8? {
        // `offset` is relative to the start of the backing bytes, which may be a
        // slice with a non-zero start index.
        let index = bytes.startIndex + offset
        guard index < bytes.endIndex else {
            return nil
        }
        return self.bytes[index]
    }

    @inlinable
    public func readBytes(from startOffset: Int, to endOffset: Int) throws(WasmParserError) -> ArraySlice<UInt8>? {
        let lowerIndex = bytes.startIndex + startOffset
        let upperIndex = bytes.startIndex + endOffset
        guard upperIndex <= bytes.endIndex else {
            return nil
        }
        return self.bytes[lowerIndex..<upperIndex]
    }
}
