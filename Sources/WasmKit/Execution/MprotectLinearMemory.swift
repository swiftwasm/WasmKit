#if os(macOS) || os(Linux)

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        import Darwin
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Glibc)
        import Glibc
    #endif

    struct MprotectLinearMemory {
        static func wasm32ReservationSize(offsetGuardSize: Int) -> Int {
            let pageSize = Int(getpagesize())
            let guardSize = max(0, offsetGuardSize)
            let alignedGuardSize = (guardSize + pageSize - 1) / pageSize * pageSize
            return (1 << 32) + alignedGuardSize
        }

        private var vm: SystemVirtualMemory
        private(set) var committedSize: Int

        var baseAddress: UnsafeMutableRawPointer { vm.base }
        var reservationSize: Int { vm.reservationBytes }

        init(committedSize: Int, reservationSize: Int) throws {
            precondition(committedSize >= 0)
            precondition(reservationSize > 0)

            #if arch(x86_64) || arch(arm64)
                guard let vm = SystemVirtualMemory(reservationBytes: reservationSize, commitBytes: committedSize) else {
                    throw Trap(.initialMemorySizeExceedsLimit(byteSize: committedSize))
                }
                self.vm = vm
                self.committedSize = committedSize
            #else
                throw Trap(.initialMemorySizeExceedsLimit(byteSize: committedSize))
            #endif
        }

        mutating func grow(to newCommittedSize: Int) throws {
            precondition(newCommittedSize >= committedSize)
            guard newCommittedSize <= reservationSize else {
                throw Trap(.memoryOutOfBounds)
            }
            let delta = newCommittedSize - committedSize
            guard delta > 0 else { return }

            guard vm.commit(offset: committedSize, byteCount: delta) else {
                throw Trap(.memoryOutOfBounds)
            }
            committedSize = newCommittedSize
        }

        func makeBufferPointer() -> UnsafeBufferPointer<UInt8> {
            UnsafeBufferPointer(start: vm.base.assumingMemoryBound(to: UInt8.self), count: committedSize)
        }

        func deallocate() {
            vm.deallocate()
        }
    }

#endif
