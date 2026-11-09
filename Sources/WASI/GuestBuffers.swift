import WasmTypes

/// A vector of guest buffers (WASI iovecs), resolved against guest memory on
/// demand.
///
/// File implementations receive this instead of a `GuestMemory` so that
/// ``WASIFile`` stays free of generic requirements. Embedded Swift forbids a
/// protocol used as an existential from carrying generic methods, and
/// ``FdEntry`` stores files as `any WASIFile`, so the concrete memory type is
/// erased here -- at the WASI call boundary, where it is still statically
/// known -- rather than threaded through the file protocol.
///
/// Each buffer is resolved inside its own guest-memory access scope, one at a
/// time, matching how vectored I/O was performed before the erasure existed.
///
/// The iovec array is copied out of guest memory once, like `readv` and
/// `writev` do, and every buffer is checked before the first one is used. A
/// bad buffer therefore stops the call before any data moves, and a read into
/// one buffer cannot change where a later one points.
@_spi(WASIPlatform) public struct GuestBuffers {
    /// The number of buffers in the vector.
    public let count: Int

    private let access: (Int, (UnsafeMutableRawBufferPointer) throws -> Int) throws -> Int

    /// Throws ``WASIMemoryAccessError`` if the iovec array or any buffer it
    /// describes does not lie inside `memory`.
    init<M: GuestMemory>(iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>, memory: M) throws {
        try iovs.checkBounds(in: memory)
        let iovecs = (0..<iovs.count).map { iovs.read(at: $0, in: memory) }
        for iovec in iovecs {
            try memory.checkBounds(iovec.buffer, count: UInt64(iovec.length))
        }
        self.count = iovecs.count
        self.access = { index, body in
            let iovec = iovecs[index]
            // An empty buffer may point past the end of memory, which cannot be mapped.
            guard iovec.length > 0 else {
                return try body(UnsafeMutableRawBufferPointer(start: nil, count: 0))
            }
            return try iovec.withHostBufferPointer(in: memory) { try body($0) }
        }
    }

    /// Calls `body` with the host buffer backing the buffer at `index`.
    ///
    /// - Parameter body: Returns the number of bytes it transferred.
    /// - Returns: Whatever `body` returned.
    @discardableResult
    public func withHostBuffer(
        at index: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> Int
    ) throws -> Int {
        try access(index, body)
    }
}
