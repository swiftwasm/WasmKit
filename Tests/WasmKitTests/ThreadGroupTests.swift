#if os(macOS) || os(Linux)

    import Synchronization
    import Testing
    import WAT

    @testable import WasmKit

    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Glibc)
        import Glibc
    #endif

    @Suite struct ThreadGroupTests {
        private func makeTestThreadGroup() throws -> ThreadGroup {
            let module = try parseWasm(bytes: wat2wasm("(module)"))
            let config = EngineConfiguration()
            let interner = Interner<FunctionType>()
            return ThreadGroup(
                module: module,
                engineConfiguration: config,
                funcTypeInterner: interner,
                sharedMemories: []
            )
        }

        @Test func allocateTID_startsAtOne() throws {
            let group = try makeTestThreadGroup()
            #expect(group.allocateTID() == 1)
        }

        @Test func allocateTID_monotonicallyIncreasing() throws {
            let group = try makeTestThreadGroup()
            let tids = (0..<5).map { _ in group.allocateTID() }
            #expect(tids == [1, 2, 3, 4, 5])
        }

        @Test func allocateTID_concurrent_noDuplicates() throws {
            let group = try makeTestThreadGroup()
            let collected = Mutex<Set<Int32>>(Set())
            let threadCount = 100

            for _ in 0..<threadCount {
                let thread = try PlatformThread.spawn(stackSize: 0) {
                    let tid = group.allocateTID()
                    collected.withLock { _ = $0.insert(tid) }
                }
                group.registerThread(thread)
            }

            try group.joinAllThreads()

            let uniqueCount = collected.withLock { $0.count }
            #expect(uniqueCount == threadCount)
            let maxTID = collected.withLock { $0.max()! }
            #expect(maxTID == Int32(threadCount))
        }

        @Test func makeChildEngine_sharesInterner() throws {
            let group = try makeTestThreadGroup()
            let funcType = FunctionType(parameters: [.i32], results: [.i64])
            let interned = group.funcTypeInterner.intern(funcType)

            let childEngine = group.makeChildEngine()
            let resolved = childEngine.funcTypeInterner.resolve(interned)
            #expect(resolved == funcType)
        }

        @Test func makeChildEngine_sharesConfiguration() throws {
            let module = try parseWasm(bytes: wat2wasm("(module)"))
            let config = EngineConfiguration(compilationMode: .eager, stackSize: 1024 * 1024)
            let interner = Interner<FunctionType>()
            let group = ThreadGroup(
                module: module,
                engineConfiguration: config,
                funcTypeInterner: interner,
                sharedMemories: []
            )

            let childEngine = group.makeChildEngine()
            #expect(childEngine.configuration.compilationMode == .eager)
            #expect(childEngine.configuration.stackSize == 1024 * 1024)
        }

        @Test func signalTrap_visibleFromOtherThread() throws {
            let group = try makeTestThreadGroup()
            let seen = Atomic<Bool>(false)

            let thread = try PlatformThread.spawn(stackSize: 0) {
                while !group.isTerminated() {}
                seen.store(true, ordering: .releasing)
            }

            usleep(10_000)  // let thread start spinning
            group.signalTrap()
            try thread.join()
            #expect(seen.load(ordering: .acquiring) == true)
        }

        @Test func signalExit_visibleFromOtherThread() throws {
            let group = try makeTestThreadGroup()
            let observedCode = Mutex<Int32?>(nil)

            let thread = try PlatformThread.spawn(stackSize: 0) {
                while !group.isTerminated() {}
                observedCode.withLock { $0 = group.exitCode.withLock { $0 } }
            }

            usleep(10_000)
            group.signalExit(code: 42)
            try thread.join()
            #expect(observedCode.withLock { $0 } == 42)
        }

        @Test func initialState_correctDefaults() throws {
            let group = try makeTestThreadGroup()
            #expect(group.isTerminated() == false)
            #expect(group.exitCode.withLock { $0 } == nil)
            #expect(group.spawnedThreads.withLock { $0.count } == 0)
        }

        @Test func registerThread_fromSpawnedThread() throws {
            let group = try makeTestThreadGroup()
            let innerDone = Atomic<Bool>(false)

            let outer = try PlatformThread.spawn(stackSize: 0) {
                let inner = try! PlatformThread.spawn(stackSize: 0) {
                    innerDone.store(true, ordering: .releasing)
                }
                group.registerThread(inner)
            }
            group.registerThread(outer)

            try group.joinAllThreads()  // joins outer, which registers inner during its body
            try group.joinAllThreads()  // joins inner (registered during the first cycle)
            #expect(innerDone.load(ordering: .acquiring) == true)
        }

        @Test func joinAllThreads_waitsForRunningThreads() throws {
            let group = try makeTestThreadGroup()
            let counter = Atomic<Int>(0)

            for _ in 0..<4 {
                let thread = try PlatformThread.spawn(stackSize: 0) {
                    usleep(50_000)  // 50ms of work
                    counter.wrappingAdd(1, ordering: .relaxed)
                }
                group.registerThread(thread)
            }

            try group.joinAllThreads()
            #expect(counter.load(ordering: .acquiring) == 4)
        }

        @Test func joinAllThreads_calledTwice_isIdempotent() throws {
            let group = try makeTestThreadGroup()
            let thread = try PlatformThread.spawn(stackSize: 0) {}
            group.registerThread(thread)

            try group.joinAllThreads()
            try group.joinAllThreads()  // empty array, no error
            #expect(group.spawnedThreads.withLock { $0.count } == 0)
        }

        @Test func registerThread_consumesAndTracksHandle() throws {
            let group = try makeTestThreadGroup()
            let flag = Atomic<Bool>(false)

            let thread = try PlatformThread.spawn(stackSize: 0) {
                flag.store(true, ordering: .releasing)
            }
            group.registerThread(thread)

            #expect(group.spawnedThreads.withLock { $0.count } == 1)
            try group.joinAllThreads()
            #expect(flag.load(ordering: .acquiring) == true)
            #expect(group.spawnedThreads.withLock { $0.count } == 0)
        }
    }

#endif
