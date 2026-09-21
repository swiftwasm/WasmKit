#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import Darwin
#elseif canImport(Musl)
    import Musl
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Android)
    import Android
#endif

/// Storage allocation that reports failure instead of aborting the process.
///
/// `UnsafeMutableBufferPointer.allocate` and `Array(repeating:count:)` trap when
/// the host cannot satisfy the request, and both are reached with a size the
/// *guest* chooses -- a module may declare any memory or table size the
/// validator permits. Without a failable path, `(module (table 0xffffffff funcref))`
/// takes the host process down, which is not something an embedder can catch.
enum FailableAllocation {
    /// Whether the host can currently satisfy an allocation of `byteCount`.
    ///
    /// Used to pre-flight allocations that have to go through a construct which
    /// cannot report failure, such as `Array(repeating:count:)`.
    static func canAllocate(byteCount: Int) -> Bool {
        guard byteCount > 0 else { return true }
        #if canImport(Darwin) || canImport(Musl) || canImport(Glibc) || canImport(Android)
            guard let probe = malloc(byteCount) else { return false }
            free(probe)
            return true
        #else
            // No libc to ask; assume the allocation is satisfiable and keep the
            // previous behaviour.
            return true
        #endif
    }

    /// Allocates zero-initialized storage, or returns `nil` if the host cannot.
    static func allocateZeroed(byteCount: Int) -> UnsafeMutableRawPointer? {
        // Always request at least one byte, so the result is a pointer that
        // ``deallocate(_:)`` can release even for an empty memory.
        let byteCount = max(byteCount, 1)
        #if canImport(Darwin) || canImport(Musl) || canImport(Glibc) || canImport(Android)
            return calloc(byteCount, 1)
        #else
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: MemoryLayout<UInt64>.alignment)
            buffer.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
            return buffer
        #endif
    }
}

extension FailableAllocation {
    /// Releases storage obtained from ``allocateZeroed(byteCount:)``.
    static func deallocate(_ pointer: UnsafeMutablePointer<UInt8>?) {
        guard let pointer else { return }
        #if canImport(Darwin) || canImport(Musl) || canImport(Glibc) || canImport(Android)
            free(UnsafeMutableRawPointer(pointer))
        #else
            UnsafeMutableRawPointer(pointer).deallocate()
        #endif
    }
}
