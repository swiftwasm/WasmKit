#if os(macOS) || os(Linux)

    import Synchronization
    import Testing

    @testable import WasmKit

    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Glibc)
        import Glibc
    #endif

    @Suite struct PlatformThreadTests {
        @Test func spawnAndJoin_setsAtomicFlag() throws {
            let flag = Atomic<Bool>(false)
            let thread = try PlatformThread.spawn(stackSize: 0) {
                flag.store(true, ordering: .releasing)
            }
            try thread.join()
            #expect(flag.load(ordering: .acquiring) == true)
        }

        @Test func spawnWithCustomStackSize_completesSuccessfully() throws {
            let flag = Atomic<Bool>(false)
            let thread = try PlatformThread.spawn(stackSize: 1024 * 1024) {
                flag.store(true, ordering: .releasing)
            }
            try thread.join()
            #expect(flag.load(ordering: .acquiring) == true)
        }

        @Test func multipleThreads_allComplete() throws {
            let counter = Atomic<Int>(0)

            let t1 = try PlatformThread.spawn(stackSize: 0) { counter.wrappingAdd(1, ordering: .relaxed) }
            let t2 = try PlatformThread.spawn(stackSize: 0) { counter.wrappingAdd(1, ordering: .relaxed) }
            let t3 = try PlatformThread.spawn(stackSize: 0) { counter.wrappingAdd(1, ordering: .relaxed) }
            let t4 = try PlatformThread.spawn(stackSize: 0) { counter.wrappingAdd(1, ordering: .relaxed) }

            try t1.join()
            try t2.join()
            try t3.join()
            try t4.join()

            #expect(counter.load(ordering: .acquiring) == 4)
        }

        @Test func joinWaitsForCompletion() throws {
            let result = Atomic<Int>(0)
            let thread = try PlatformThread.spawn(stackSize: 0) {
                usleep(50_000)  // 50ms; ensures join() must actually block
                result.store(42, ordering: .releasing)
            }
            #expect(result.load(ordering: .acquiring) == 0)  // not yet set
            try thread.join()
            #expect(result.load(ordering: .acquiring) == 42)  // set after join returns
        }

        @Test func spawnWithTooSmallStackSize_throws() {
            // 1024 bytes is below PTHREAD_STACK_MIN on all platforms.
            #expect(throws: PlatformThreadError.self) {
                _ = try PlatformThread.spawn(stackSize: 1024) {}
            }
        }

        @Test func dropWithoutJoin_detachesThread() throws {
            let flag = Atomic<Bool>(false)
            do {
                _ = try PlatformThread.spawn(stackSize: 0) {
                    flag.store(true, ordering: .releasing)
                }
                // PlatformThread dropped here; deinit detaches
            }
            // Spin-wait with timeout; detached threads can't be joined.
            let deadline = ContinuousClock.now.advanced(by: .seconds(2))
            while !flag.load(ordering: .acquiring) {
                if ContinuousClock.now >= deadline {
                    Issue.record("Detached thread did not complete within 2s timeout")
                    return
                }
            }
        }
    }

#endif
