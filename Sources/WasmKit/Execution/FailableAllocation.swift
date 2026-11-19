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

    /// Resizes storage from ``allocateZeroed(byteCount:)`` to `byteCount` bytes,
    /// keeping its contents, or answers `nil` and leaves it as it was (also
    /// where there is no C library to do it with). Bytes past the old size are
    /// not zeroed.
    static func reallocate(_ pointer: UnsafeMutableRawPointer, byteCount: Int) -> UnsafeMutableRawPointer? {
        wasmkit_realloc(pointer, byteCount)
    }

    /// Releases storage from ``allocateZeroed(byteCount:)``.
    static func deallocate(_ pointer: UnsafeMutableRawPointer?) {
        wasmkit_free(pointer)
    }
}
