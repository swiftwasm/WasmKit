import Synchronization
import WasmParser
@preconcurrency import _CWasmKit

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif os(Windows)
    import WinSDK
#endif

/// Thread-safe backing store for a WebAssembly shared linear memory.
///
/// The storage pre-reserves `maxPageCount * pageSize` bytes of virtual address
/// space using `mmap(PROT_NONE)` (POSIX) or `VirtualAlloc(MEM_RESERVE)` (Windows).
/// Only the initially committed pages are made accessible; growth commits
/// additional pages via `mprotect` / `VirtualAlloc(MEM_COMMIT)`.
///
/// The base pointer never changes, so existing references remain valid.
///
/// ## Thread Safety
///
/// - `basePointer` is stable for the lifetime of the object.
/// - `currentByteCount` is an `Atomic<Int>` read/written with acquire/release
///   for the Ms staleness reload path.
/// - The C-level `wasmkit_shared_memory_guard_t` holds a spinlock (`atomic_flag`)
///   that serializes grow with the signal handler. The signal handler acquires
///   this spinlock when a fault lands in our reservation, checks the committed
///   size, and either retries (grow in progress) or traps (genuine OOB).
///
/// ## Deregistration Invariant
///
/// The guard is unregistered from the global registry before deallocation.
/// We rely on the invariant that shared memory is not deallocated while any
/// thread is actively executing wasm on that memory.
struct SharedMemoryStorage: ~Copyable {
    /// The stable base pointer. Never changes after init.
    let basePointer: UnsafeMutableRawPointer

    /// The current committed size in bytes (Swift-side atomic for Ms staleness reload).
    let currentByteCount: Atomic<Int>

    /// The maximum allowed byte count (maxPages * pageSize).
    let maxByteCount: Int

    /// The total reservation size in bytes.
    /// On mprotect platforms this covers the full wasm32 address space + offset guard;
    /// otherwise it equals `maxByteCount`.
    let reservationSize: Int

    /// The memory type this storage was created from.
    let memoryType: MemoryType

    /// C-level guard struct registered with the signal handler.
    /// Owns the spinlock and the canonical `current_byte_count` for the signal handler.
    let guardPtr: UnsafeMutablePointer<wasmkit_shared_memory_guard_t>

    /// The page size in bytes (64 KiB per Wasm spec).
    static let pageSize = 65536

    init(memoryType: MemoryType, engineConfiguration: EngineConfiguration, resourceLimiter: any ResourceLimiter) throws(Trap) {
        let initialBytes = Int(memoryType.min) * Self.pageSize
        let maxPages = memoryType.max ?? UInt64(MemoryEntity.maxPageCount(isMemory64: memoryType.isMemory64))
        let (maxBytes, overflow) = Int(clamping: maxPages).multipliedReportingOverflow(by: Self.pageSize)
        if overflow {
            throw Trap(.mmapFailed(reserveBytes: Int.max))
        }
        do {
            guard try resourceLimiter.limitMemoryGrowth(to: initialBytes) else {
                throw Trap(.initialMemorySizeExceedsLimit(byteSize: initialBytes))
            }
        } catch let trap as Trap {
            throw trap
        } catch {
            throw Trap(.initialMemorySizeExceedsLimit(byteSize: initialBytes))
        }

        // Compute reservation size: on mprotect platforms with wasm32, reserve the full
        // 4 GiB + offset guard region so unchecked instructions fault within our mmap.
        let reservationSize = Self.computeReservationSize(
            maxBytes: maxBytes, memoryType: memoryType, engineConfiguration: engineConfiguration)

        let base = try Self.reserveAndCommit(reserveBytes: reservationSize, commitBytes: initialBytes)

        // Allocate and register the C-level guard struct for signal handler coordination.
        // Must happen before assigning any self. properties — ~Copyable types require
        // consistent initialization state through all code paths.
        let gp = UnsafeMutablePointer<wasmkit_shared_memory_guard_t>.allocate(capacity: 1)
        wasmkit_shared_memory_guard_init(gp, base, reservationSize, initialBytes)
        guard wasmkit_shared_memory_guard_register(gp) == 0 else {
            gp.deallocate()
            Self.releaseReservation(base, byteCount: reservationSize)
            throw Trap(.sharedMemoryGuardRegistryFull)
        }

        self.basePointer = base
        self.maxByteCount = maxBytes
        self.reservationSize = reservationSize
        self.memoryType = memoryType
        self.currentByteCount = Atomic(initialBytes)
        self.guardPtr = gp
    }

    deinit {
        wasmkit_shared_memory_guard_unregister(guardPtr)
        guardPtr.deallocate()
        Self.releaseReservation(basePointer, byteCount: reservationSize)
    }

    /// Grow by `deltaPages`. Returns the old page count, or -1 on failure.
    /// Thread-safe: serialized by the C-level spinlock (same lock the signal handler acquires).
    func grow(by deltaPages: Int, resourceLimiter: any ResourceLimiter) throws(Trap) -> Int {
        // Block SIGSEGV/SIGBUS before acquiring the spinlock to prevent self-deadlock
        // if a signal arrives while the lock is held (e.g., from a stray pointer during grow).
        #if os(macOS) || os(Linux)
            wasmkit_shared_memory_guard_lock_for_grow(guardPtr)
            defer { wasmkit_shared_memory_guard_unlock_for_grow(guardPtr) }
        #else
            wasmkit_shared_memory_guard_lock(guardPtr)
            defer { wasmkit_shared_memory_guard_unlock(guardPtr) }
        #endif

        let oldBytes = Int(wasmkit_shared_memory_guard_get_size(guardPtr))
        let oldPages = oldBytes / Self.pageSize

        // Overflow-checked arithmetic
        let (deltaBytes, mulOverflow) = deltaPages.multipliedReportingOverflow(by: Self.pageSize)
        guard !mulOverflow else { return -1 }
        let (newBytes, addOverflow) = oldBytes.addingReportingOverflow(deltaBytes)
        guard !addOverflow else { return -1 }
        guard newBytes <= maxByteCount else { return -1 }

        do {
            guard try resourceLimiter.limitMemoryGrowth(to: newBytes) else { return -1 }
        } catch {
            return -1
        }

        if deltaBytes > 0 {
            #if os(Windows)
                guard
                    VirtualAlloc(
                        basePointer.advanced(by: oldBytes), deltaBytes,
                        DWORD(MEM_COMMIT), DWORD(PAGE_READWRITE)
                    ) != nil
                else { return -1 }
            #else
                guard
                    mprotect(
                        basePointer.advanced(by: oldBytes), deltaBytes,
                        PROT_READ | PROT_WRITE
                    ) == 0
                else { return -1 }
            #endif
        }

        // Two-phase size update:
        // 1. C guard size (under spinlock): the signal handler reads this value after
        //    acquiring the per-guard spinlock. Updated first so the signal handler sees
        //    the new size only after mprotect has committed the pages.
        wasmkit_shared_memory_guard_set_size(guardPtr, newBytes)
        // 2. Swift-side atomic: checked instructions read this via `reloadSharedMemorySize`.
        //    Updated second. There is a brief window where the Swift value < C value;
        //    this is conservative (safe) — the checked path will see the old (smaller) size,
        //    fail the fast-path bounds check, then reload from the C guard via the slow path.
        currentByteCount.store(newBytes, ordering: .releasing)

        return oldPages
    }

    private static func computeReservationSize(
        maxBytes: Int, memoryType: MemoryType, engineConfiguration: EngineConfiguration
    ) -> Int {
        #if os(macOS) || os(Linux)
            if !memoryType.isMemory64, engineConfiguration.memoryBoundsChecking != .software {
                return MprotectLinearMemory.wasm32ReservationSize(
                    offsetGuardSize: engineConfiguration.memoryOffsetGuardSize)
            }
            return maxBytes
        #else
            return maxBytes
        #endif
    }

    // MARK: - Platform Memory Management

    /// Reserve `reserveBytes` of virtual address space (PROT_NONE / PAGE_NOACCESS),
    /// then commit the first `commitBytes` as read-write.
    private static func reserveAndCommit(
        reserveBytes: Int, commitBytes: Int
    ) throws(Trap) -> UnsafeMutableRawPointer {
        guard reserveBytes > 0 else {
            // Zero-size reservation: return a non-nil sentinel.
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
            return ptr
        }
        #if os(Windows)
            guard let base = VirtualAlloc(nil, reserveBytes, DWORD(MEM_RESERVE), DWORD(PAGE_NOACCESS)) else {
                throw Trap(.mmapFailed(reserveBytes: reserveBytes))
            }
            if commitBytes > 0 {
                guard VirtualAlloc(base, commitBytes, DWORD(MEM_COMMIT), DWORD(PAGE_READWRITE)) != nil else {
                    VirtualFree(base, 0, DWORD(MEM_RELEASE))
                    throw Trap(.mmapFailed(reserveBytes: reserveBytes))
                }
            }
            return base
        #else
            // POSIX: Reserve entire range as PROT_NONE, then commit initial pages.
            #if os(Linux)
                let mapAnon = MAP_ANONYMOUS
            #else
                let mapAnon = MAP_ANON
            #endif
            let base = mmap(nil, reserveBytes, PROT_NONE, MAP_PRIVATE | mapAnon, -1, 0)
            guard base != MAP_FAILED else {
                throw Trap(.mmapFailed(reserveBytes: reserveBytes))
            }
            if commitBytes > 0 {
                guard mprotect(base, commitBytes, PROT_READ | PROT_WRITE) == 0 else {
                    munmap(base, reserveBytes)
                    throw Trap(.mmapFailed(reserveBytes: reserveBytes))
                }
            }
            return base!
        #endif
    }

    private static func releaseReservation(_ base: UnsafeMutableRawPointer, byteCount: Int) {
        guard byteCount > 0 else {
            base.deallocate()
            return
        }
        #if os(Windows)
            VirtualFree(base, 0, DWORD(MEM_RELEASE))
        #else
            munmap(base, byteCount)
        #endif
    }
}
