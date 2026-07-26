#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(Windows)
    import WinSDK
#endif

/// A reserved region of system virtual address space with page-granular commit.
///
/// Reserves `reservationBytes` of address space up front with no access
/// (`mmap(PROT_NONE)` / `VirtualAlloc(MEM_RESERVE)`), so the `base` pointer never moves,
/// then commits pages on demand as read-write.
struct SystemVirtualMemory {
    /// The stable base of the reservation. Never changes after `init`.
    let base: UnsafeMutableRawPointer

    /// The total number of bytes reserved.
    let reservationBytes: Int

    /// Reserve `reservationBytes` of address space and commit the first `commitBytes` as
    /// read-write. Returns `nil` if the OS reservation or the initial commit fails.
    ///
    /// A zero `reservationBytes` yields a valid, non-null sentinel with nothing mapped.
    init?(reservationBytes: Int, commitBytes: Int) {
        precondition(reservationBytes >= 0)
        precondition(commitBytes >= 0)
        guard commitBytes <= reservationBytes else { return nil }

        // Zero-size reservation: hand back a non-null sentinel so `base` is always valid.
        guard reservationBytes > 0 else {
            self.base = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 16)
            self.reservationBytes = 0
            return
        }

        guard let base = Self.reserve(reservationBytes) else { return nil }
        if commitBytes > 0, !Self.commit(base, offset: 0, byteCount: commitBytes) {
            Self.release(base, reservationBytes: reservationBytes)
            return nil
        }
        self.base = base
        self.reservationBytes = reservationBytes
    }

    /// Commit `[offset, offset + byteCount)` within the reservation as read-write.
    /// A zero `byteCount` is a successful no-op. Returns `false` if the OS commit fails.
    func commit(offset: Int, byteCount: Int) -> Bool {
        precondition(offset >= 0 && byteCount >= 0)
        precondition(offset + byteCount <= reservationBytes)
        guard byteCount > 0 else { return true }
        return Self.commit(base, offset: offset, byteCount: byteCount)
    }

    /// Release the entire reservation.
    func deallocate() {
        Self.release(base, reservationBytes: reservationBytes)
    }

    // MARK: - Platform primitives

    private static func reserve(_ reservationBytes: Int) -> UnsafeMutableRawPointer? {
        #if os(WASI)
            // WASI has no reserve-without-commit primitive
            return nil
        #elseif os(Windows)
            return VirtualAlloc(nil, SIZE_T(reservationBytes), DWORD(MEM_RESERVE), DWORD(PAGE_NOACCESS))
        #else
            #if os(Linux)
                let mapAnon = MAP_ANONYMOUS
            #else
                let mapAnon = MAP_ANON
            #endif
            let base = mmap(nil, reservationBytes, PROT_NONE, MAP_PRIVATE | mapAnon, -1, 0)
            // `MAP_FAILED` is `(void *)-1`; compare that sentinel directly rather than the
            // macro, which Bionic defines as a C++ `reinterpret_cast` Swift cannot import.
            guard base != UnsafeMutableRawPointer(bitPattern: -1) else { return nil }
            return base
        #endif
    }

    private static func commit(_ base: UnsafeMutableRawPointer, offset: Int, byteCount: Int) -> Bool {
        #if os(WASI)
            // WASI does not support commit-without-reserve; use a full allocation instead
            return false
        #elseif os(Windows)
            return VirtualAlloc(
                base.advanced(by: offset), SIZE_T(byteCount),
                DWORD(MEM_COMMIT), DWORD(PAGE_READWRITE)
            ) != nil
        #else
            return mprotect(base.advanced(by: offset), byteCount, PROT_READ | PROT_WRITE) == 0
        #endif
    }

    private static func release(_ base: UnsafeMutableRawPointer, reservationBytes: Int) {
        guard reservationBytes > 0 else {
            base.deallocate()
            return
        }
        #if os(WASI)
            // Unsupported; WASI has no reserve-without-commit primitive, so this type is never used there.
        #elseif os(Windows)
            VirtualFree(base, 0, DWORD(MEM_RELEASE))
        #else
            munmap(base, reservationBytes)
        #endif
    }
}
