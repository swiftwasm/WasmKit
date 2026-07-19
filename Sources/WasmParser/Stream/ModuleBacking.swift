/// A zero-copy, owning reference to a byte range of a module's ``ModuleBacking``. Retains the backing,
/// so the bytes (e.g. a memory-mapped file) stay valid, and exposes them as a `RawSpan`. Used for
/// function bodies and data-segment initializers so the parser never copies them out of the module.
public struct ModuleBytes: Sendable {
    @usableFromInline let backing: ModuleBacking
    @usableFromInline let range: Range<Int>

    public init(backing: ModuleBacking, range: Range<Int>) {
        self.backing = backing
        self.range = range
    }

    /// A shared empty value.
    public static let empty = ModuleBytes(backing: .empty, range: 0..<0)

    /// The number of bytes in this range.
    @inlinable public var count: Int { range.count }
    @inlinable public var isEmpty: Bool { range.isEmpty }

    /// The bytes as a zero-copy `RawSpan` view into the module's backing storage.
    public var span: RawSpan {
        @_lifetime(borrow self)
        get {
            // The span points into memory owned by `backing`, which `self` retains; tie its lifetime to
            // the `self` borrow. Constructed directly (not via `.bytes.extracting`) to dodge a SIL
            // optimizer crash in the experimental Lifetimes feature on Swift 6.3.
            let start = range.isEmpty ? nil : backing.buffer.baseAddress?.advanced(by: range.lowerBound)
            let span = unsafe RawSpan(_unsafeStart: start ?? UnsafeRawPointer(bitPattern: -1)!, byteCount: range.count)
            return unsafe _overrideLifetime(span, borrowing: self)
        }
    }

    /// Calls `body` with a pointer to the bytes (valid only for the duration of the call).
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        let base = range.isEmpty ? nil : backing.buffer.baseAddress.map { $0 + range.lowerBound }
        return try body(UnsafeRawBufferPointer(start: base, count: range.count))
    }
}

extension ModuleBytes: Equatable {
    public static func == (lhs: ModuleBytes, rhs: ModuleBytes) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return lhs.withUnsafeBytes { l in rhs.withUnsafeBytes { r in l.elementsEqual(r) } }
    }
}

/// Shared owner of the raw bytes a module was parsed from. The region may be a memory-mapped file,
/// a heap allocation, or a retained Swift array; `deinit` releases it.
///
/// This is a reference type so parsed function bodies can reference the module's bytes directly (as
/// `RawSpan` views — see ``ModuleBytes``) instead of copying them out, while keeping the underlying
/// storage (e.g. a memory-mapped file) alive for as long as any ``ModuleBytes`` references it. The
/// bytes are immutable, so concurrent reads are safe.
public final class ModuleBacking: @unchecked Sendable {
    /// A shared empty backing, for empty ``ModuleBytes`` values.
    static let empty = ModuleBacking(retaining: [])

    /// How the bytes are owned. Stored inline (no closure allocation / ARC): either a retained Swift
    /// array whose storage `buffer` points into, or externally-mapped memory freed by a C deallocator
    /// (e.g. `munmap`) — its `base`/`size` are taken from `buffer`.
    @usableFromInline
    enum Storage: @unchecked Sendable {
        case retained([UInt8])
        case external(unmap: @convention(c) (UnsafeMutableRawPointer?, Int) -> CInt)
    }

    /// The whole-module byte region. Function bodies are sub-ranges of this buffer.
    @usableFromInline let buffer: UnsafeRawBufferPointer
    @usableFromInline let storage: Storage

    /// Take ownership of externally-mapped memory; `unmap` runs on `buffer` at `deinit`.
    public init(buffer: UnsafeRawBufferPointer, unmap: @escaping @convention(c) (UnsafeMutableRawPointer?, Int) -> CInt) {
        self.buffer = buffer
        self.storage = .external(unmap: unmap)
    }

    /// Retain a Swift array and view its storage in place (zero-copy). Safe because the array is held
    /// for this object's lifetime and never mutated, so its buffer neither moves nor frees.
    @usableFromInline
    init(retaining array: [UInt8]) {
        if array.isEmpty {
            self.buffer = UnsafeRawBufferPointer(start: nil, count: 0)
        } else {
            self.buffer = array.withUnsafeBytes {
                UnsafeRawBufferPointer(start: $0.baseAddress, count: $0.count)
            }
        }
        self.storage = .retained(array)
    }

    deinit {
        switch storage {
        case .retained: break
        case .external(let unmap):
            if let base = buffer.baseAddress {
                _ = unmap(UnsafeMutableRawPointer(mutating: base), buffer.count)
            }
        }
    }
}

/// A `ByteStream` over a byte range of a ``ModuleBacking``. Retains the backing, so the underlying
/// memory stays valid for the stream's lifetime. Used to decode function bodies (which reference the
/// module's memory-mapped storage) without copying them out first.
public final class ModuleBackingStream: ByteStream {
    @usableFromInline let backing: ModuleBacking
    @usableFromInline let base: UnsafeRawPointer?
    @usableFromInline let endIndex: Int
    public var currentIndex: Int

    public init(backing: ModuleBacking, range: Range<Int>) {
        self.backing = backing
        self.base = backing.buffer.baseAddress
        self.currentIndex = range.lowerBound
        self.endIndex = range.upperBound
    }

    @inline(__always)
    private func byte(at index: Int) -> UInt8 {
        base!.load(fromByteOffset: index, as: UInt8.self)
    }

    @discardableResult
    public func consumeAny() throws(WasmParserError) -> UInt8 {
        guard currentIndex < endIndex else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
        }
        defer { currentIndex += 1 }
        return byte(at: currentIndex)
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws(WasmParserError) -> UInt8 {
        guard currentIndex < endIndex else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: Set(expected)), offset: currentIndex)
        }
        let consumed = byte(at: currentIndex)
        guard expected.contains(consumed) else {
            throw WasmParserError(
                kind: .parserUnexpectedByte(consumed, expected: Set(expected)), offset: currentIndex)
        }
        currentIndex += 1
        return consumed
    }

    public func consume(count: Int) throws(WasmParserError) -> ArraySlice<UInt8> {
        guard count > 0 else { return [] }
        let updatedIndex = currentIndex + count
        guard updatedIndex <= endIndex else {
            throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
        }
        defer { currentIndex = updatedIndex }
        return ArraySlice(UnsafeRawBufferPointer(rebasing: backing.buffer[currentIndex..<updatedIndex]))
    }

    public func peek() -> UInt8? {
        guard currentIndex < endIndex else { return nil }
        return byte(at: currentIndex)
    }
}
