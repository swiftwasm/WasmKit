// Shared memory relies on the mprotect guard-page reservation for OOB detection, so it is
// only built where that is available (see `SharedMemoryStorage.isSupported`).
#if os(macOS) || os(Linux)

    import Synchronization
    import WasmParser

    /// Thread-safe backing store for a shared linear memory.
    ///
    /// Backed by the same guard-page reservation as `MprotectLinearMemory`: it reserves the
    /// full wasm32 range plus an offset guard (`mmap(PROT_NONE)`) and commits pages on `grow`
    /// (`mprotect`). Out-of-bounds accesses fault into the guard region and are converted to a
    /// trap by the mprotect trap guard, so there is no per-access software size check and thus
    /// no staleness problem when another thread grows the memory. For this reason shared memory
    /// is only supported under the `.mprotect` bounds-checking mode (wasm32, 64-bit host).
    ///
    /// The base pointer never moves, so other threads' references stay valid across growth and
    /// the base can be register-pinned.
    ///
    /// Reference-counted, with a lifetime independent of any `Store`: each importing
    /// `MemoryEntity` holds a strong reference (its `.shared` storage case), and the
    /// backing is freed in `deinit` once the last importer is released.
    ///
    /// `@unchecked Sendable`: `basePointer` is immutable; `currentByteCount` is atomic
    /// (release after commit, acquire on read); `grow` is serialized by `growLock`.
    package final class SharedMemoryStorage: @unchecked Sendable {
        /// The reserved virtual memory backing this storage. The base never moves.
        let vm: SystemVirtualMemory

        /// The stable base pointer. Never changes after init.
        var basePointer: UnsafeMutableRawPointer { vm.base }

        /// The committed size in bytes (atomic); read by `memory.size` and `grow`.
        let currentByteCount: Atomic<Int>

        /// The maximum allowed byte count (maxPages * pageSize).
        let maxByteCount: Int

        /// Reserved virtual size: the wasm32 range plus the offset guard region. Used as the
        /// `Ms` bound so the software check never rejects a valid (possibly just-grown) address;
        /// the guard pages enforce the real bound via the trap guard.
        var reservationSize: Int { vm.reservationBytes }

        /// Serializes concurrent `grow` calls; reads of `currentByteCount` are lock-free.
        let growLock: Mutex<Void>

        /// `memory.atomic.wait`/`notify` waiters, keyed by in-memory address and shared by
        /// every thread that imports this memory (so a notify on one thread wakes a waiter
        /// parked on another).
        let parkingLot = AtomicParkingLot()

        /// Whether a shared memory can be created under `engineConfiguration` on this platform.
        /// Shared memory relies on mprotect guard-page OOB detection, which is available on wasm32
        /// 64-bit macOS/Linux. Note Swift treats Android as `os(Android)`, not `os(Linux)`, so it is
        /// excluded even though the C side sees `__linux__`.
        static func isSupported(engineConfiguration: EngineConfiguration, isMemory64: Bool) -> Bool {
            #if arch(x86_64) || arch(arm64)
                // `.mprotect` here means the engine really uses it (it is downgraded to `.software`
                // for token threading / ASan / unsupported platforms).
                return engineConfiguration.memoryBoundsChecking == .mprotect && !isMemory64
            #else
                return false
            #endif
        }

        init(
            initialBytes: Int,
            maxBytes: Int,
            isMemory64: Bool,
            engineConfiguration: EngineConfiguration
        ) throws(Trap) {
            guard Self.isSupported(engineConfiguration: engineConfiguration, isMemory64: isMemory64) else {
                throw Trap(.sharedMemoryRequiresMprotect)
            }
            #if arch(x86_64) || arch(arm64)
                // Reserve the wasm32 range plus the offset guard so OOB faults hit the guard
                // region; commit the initial pages.
                let reservationSize = MprotectLinearMemory.wasm32ReservationSize(
                    offsetGuardSize: engineConfiguration.memoryOffsetGuardSize)
                guard let vm = SystemVirtualMemory(reservationBytes: reservationSize, commitBytes: initialBytes) else {
                    throw Trap(.mmapFailed(reserveBytes: reservationSize))
                }

                self.vm = vm
                self.maxByteCount = maxBytes
                self.currentByteCount = Atomic(initialBytes)
                self.growLock = Mutex(())
            #else
                throw Trap(.sharedMemoryRequiresMprotect)
            #endif
        }

        deinit {
            // Runs when the last importer releases its reference; no thread can reach the
            // backing at that point.
            vm.deallocate()
        }

        /// Grow by `deltaPages`. Returns the old page count, or -1 on failure.
        /// Thread-safe: mutation is serialized by `growLock`.
        func grow(by deltaPages: Int, resourceLimiter: any ResourceLimiter) throws(Trap) -> Int {
            growLock.withLock { _ in
                let oldBytes = currentByteCount.load(ordering: .acquiring)
                let oldPages = oldBytes / MemoryEntity.pageSize

                let (deltaBytes, mulOverflow) = deltaPages.multipliedReportingOverflow(by: MemoryEntity.pageSize)
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
                    guard vm.commit(offset: oldBytes, byteCount: deltaBytes) else { return -1 }
                }

                // Publish the size only after committing pages, so a concurrent reader that
                // observes it (acquire) sees pages that are already accessible.
                currentByteCount.store(newBytes, ordering: .releasing)

                return oldPages
            }
        }
    }

#endif
