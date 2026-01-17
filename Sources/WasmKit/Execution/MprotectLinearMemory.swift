#if WASMKIT_MPROTECT_BOUND_CHECKING && !os(WASI)

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        import Darwin
    #elseif os(Linux)
        import Glibc
    #endif

    struct MprotectLinearMemory {
        static func wasm32ReservationSize(offsetGuardSize: Int) -> Int {
            let pageSize = Int(getpagesize())
            let guardSize = max(0, offsetGuardSize)
            let alignedGuardSize = (guardSize + pageSize - 1) / pageSize * pageSize
            return (1 << 32) + alignedGuardSize
        }

        private(set) var baseAddress: UnsafeMutableRawPointer
        private(set) var committedSize: Int
        let reservationSize: Int

        init(committedSize: Int, reservationSize: Int) throws {
            precondition(committedSize >= 0)
            precondition(reservationSize > 0)
            self.committedSize = committedSize
            self.reservationSize = reservationSize

            #if arch(x86_64) || arch(arm64)
                #if os(Linux)
                    let mapAnon = MAP_ANONYMOUS
                #else
                    let mapAnon = MAP_ANON
                #endif
                let mapped = mmap(
                    nil,
                    reservationSize,
                    PROT_NONE,
                    MAP_PRIVATE | mapAnon,
                    -1,
                    0
                )
                guard mapped != MAP_FAILED else {
                    throw Trap(.initialMemorySizeExceedsLimit(byteSize: committedSize))
                }
                baseAddress = mapped!
            #else
                throw Trap(.initialMemorySizeExceedsLimit(byteSize: committedSize))
            #endif

            if committedSize > 0 {
                let rc = mprotect(baseAddress, committedSize, PROT_READ | PROT_WRITE)
                if rc != 0 {
                    munmap(baseAddress, reservationSize)
                    throw Trap(.initialMemorySizeExceedsLimit(byteSize: committedSize))
                }
            }
        }

        mutating func grow(to newCommittedSize: Int) throws {
            precondition(newCommittedSize >= committedSize)
            guard newCommittedSize <= reservationSize else {
                throw Trap(.memoryOutOfBounds)
            }
            let delta = newCommittedSize - committedSize
            guard delta > 0 else { return }

            let start = baseAddress.advanced(by: committedSize)
            let rc = mprotect(start, delta, PROT_READ | PROT_WRITE)
            guard rc == 0 else {
                throw Trap(.memoryOutOfBounds)
            }
            committedSize = newCommittedSize
        }

        func makeBufferPointer() -> UnsafeBufferPointer<UInt8> {
            UnsafeBufferPointer(start: baseAddress.assumingMemoryBound(to: UInt8.self), count: committedSize)
        }

        func deallocate() {
            munmap(baseAddress, reservationSize)
        }
    }

#endif
