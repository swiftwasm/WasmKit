import _CWasmKit

/// Storage allocation that reports failure instead of aborting the process.
///
/// The standard library has no failable form: `UnsafeMutableRawPointer.allocate`
/// and `Array(repeating:count:)` crash when the allocator returns null. A guest
/// chooses its own memory and table sizes, so those allocations have to be
/// something an embedder can catch.
enum FailableAllocation {
    /// Zero-filled storage, or `nil` if the allocator cannot satisfy the request.
    static func allocateZeroed(byteCount: Int) -> UnsafeMutableRawPointer? {
        wasmkit_alloc_zeroed(byteCount)
    }

    /// Releases storage from ``allocateZeroed(byteCount:)``.
    static func deallocate(_ pointer: UnsafeMutableRawPointer?) {
        wasmkit_free(pointer)
    }
}
