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
/// `writev` do, so a read into one buffer cannot change where a later one
/// points. A buffer outside guest memory throws the memory's error when it is
/// used, after the buffers before it have been transferred.
@_spi(WASIPlatform) public struct GuestBuffers {
    /// The most iovecs that one call accepts, which is `IOV_MAX` on Linux and
    /// macOS.
    static let maxCount = 1024

    /// The number of buffers in the vector.
    public let count: Int

    private let access: (Int, (UnsafeMutableRawBufferPointer) throws -> Int) throws -> Int

    /// Throws `EINVAL` if there are more than ``maxCount`` iovecs, and the
    /// error of `memory` if the iovec array does not lie inside it.
    ///
    /// The count is checked first, as `readv` and `writev` do, so a guest
    /// cannot make the host copy an iovec array as large as its memory.
    ///
    /// The call reports the bytes it transferred as a ``WASIAbi/Size``, but
    /// buffers may overlap, so even a small memory can describe a larger total.
    /// Only the leading buffers whose lengths fit in a `size` together are
    /// kept, and the call transfers less than asked, as a read or write may.
    /// The first buffer always fits, because an iovec length is a `size`.
    init<M: GuestMemory>(iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>, memory: M) throws {
        guard iovs.count <= Self.maxCount else {
            throw WASIAbi.Errno.EINVAL
        }
        var iovecs = try (0..<iovs.count).map { try iovs.read(at: $0, in: memory) }
        var total: UInt64 = 0
        for (index, iovec) in iovecs.enumerated() {
            total += UInt64(iovec.length)
            if total > UInt64(WASIAbi.Size.max) {
                iovecs.removeSubrange(index...)
                break
            }
        }
        self.count = iovecs.count
        self.access = { index, body in
            try iovecs[index].withHostBufferPointer(in: memory) { try body($0) }
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
