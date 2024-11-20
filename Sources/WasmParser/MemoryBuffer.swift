@usableFromInline
struct BufferSlice {
    @usableFromInline
    let bytes: [UInt8]
    @usableFromInline
    let sourceOffset: Int

    /// Similar to `IndexingIterator` but throws an error when `next()`
    /// is called at the end of the buffer
    @usableFromInline
    struct Cursor {
        @usableFromInline
        let _slice: BufferSlice
        @usableFromInline
        var _offset: Int

        @inlinable
        mutating func next() throws -> UInt8 {
            guard _offset < _slice.bytes.count else {
                throw WasmParserError(.unexpectedEnd, offset: _slice.sourceOffset + _offset)
            }
            let consumed = _slice.bytes[_offset]
            _offset += 1
            return consumed
        }
    }
}
