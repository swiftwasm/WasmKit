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
/// A buffer is checked against guest memory when it is resolved, because a
/// read into an earlier buffer can rewrite a later iovec.
@_spi(WASIPlatform) public struct GuestBuffers {
    /// The number of buffers in the vector.
    public let count: Int

    private let access: (Int, (UnsafeMutableRawBufferPointer) throws -> Int) throws -> Int

    /// Throws `EFAULT` if the iovec array does not lie inside `memory`.
    init<M: GuestMemory>(iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>, memory: M) throws {
        try iovs.checkBounds(in: memory)
        self.count = Int(iovs.count)
        self.access = { index, body in
            let iovec = iovs.read(at: UInt32(index), in: memory)
            try memory.checkBounds(iovec.buffer, count: UInt64(iovec.length))
            return try iovec.withHostBufferPointer(in: memory) { try body($0) }
        }
    }

    /// Calls `body` with the host buffer backing the buffer at `index`.
    ///
    /// - Parameter body: Returns the number of bytes it transferred.
    /// - Returns: Whatever `body` returned.
    /// - Throws: `EFAULT` if the buffer does not lie inside guest memory, or
    ///   whatever `body` throws.
    @discardableResult
    public func withHostBuffer(
        at index: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> Int
    ) throws -> Int {
        try access(index, body)
    }
}
