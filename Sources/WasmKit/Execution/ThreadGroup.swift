#if os(macOS) || os(Linux)

    import BasicContainers
    import Synchronization

    /// A shared termination flag for cooperative cancellation across threads.
    ///
    /// All `Store`s in a wasi-threads group hold a reference to the same `TerminationFlag`. The interpreter
    /// checks it at function-call boundaries (`invoke`/`tailInvoke`) and around `memory.atomic.wait`, throwing
    /// `Trap(.threadTerminated)` when set so the executing thread unwinds.
    package final class TerminationFlag: Sendable {
        let shouldTerminate: Atomic<Bool>

        package init() {
            self.shouldTerminate = Atomic(false)
        }

        package func signal() {
            shouldTerminate.store(true, ordering: .releasing)
        }

        @inline(__always)
        package func isSignaled() -> Bool {
            shouldTerminate.load(ordering: .acquiring)
        }
    }

    /// Shared state across all threads in a wasi-threads group.
    ///
    /// Created when a module with wasi-threads support is instantiated.
    /// All child threads spawned via `wasi_thread_spawn` join this group.
    ///
    /// This class is `Sendable` because all mutable state is protected by
    /// `Atomic` or `Mutex`, and all immutable state is compiler-verified Sendable.
    /// It is the sole value captured in the `@Sendable` closure at the thread
    /// spawn boundary.
    package final class ThreadGroup: Sendable {
        // MARK: - Immutable shared state (compiler-verified Sendable)

        package let module: Module

        /// Each child thread constructs its own `Engine` from this shared configuration.
        let engineConfiguration: EngineConfiguration

        /// Shared with every child `Engine`. See ``Engine/funcTypeInterner``.
        let funcTypeInterner: Interner<FunctionType>

        /// Shared memory handles, indexed by memory index. `nil` entries
        /// correspond to non-shared memories.
        package let sharedMemories: [SharedMemoryStorage?]

        /// Shared with every participating `Store`; see ``TerminationFlag``.
        package let terminationFlag: TerminationFlag

        // MARK: - Atomic counters

        /// Next thread ID to allocate. Starts at 1 (TID 0 is reserved for
        /// the main thread per the wasi-threads spec).
        let nextTID: Atomic<Int32>

        // MARK: - Mutex-protected mutable state

        let exitCode: Mutex<Int32?>

        let spawnedThreads: Mutex<UniqueArray<PlatformThread>>

        package init(
            module: Module,
            engineConfiguration: EngineConfiguration,
            funcTypeInterner: Interner<FunctionType>,
            sharedMemories: [SharedMemoryStorage?]
        ) {
            self.module = module
            self.engineConfiguration = engineConfiguration
            self.funcTypeInterner = funcTypeInterner
            self.sharedMemories = sharedMemories
            self.terminationFlag = TerminationFlag()
            self.nextTID = Atomic(1)
            self.exitCode = Mutex(nil)
            self.spawnedThreads = Mutex(UniqueArray())
        }

        deinit {
            // Debug-only: catch programming errors where ThreadGroup is dropped
            // without joining its threads. In release, PlatformThread deinits
            // will detach (safety net), which is better than crashing in deinit.
            assert(
                spawnedThreads.withLock({ $0.count }) == 0,
                "ThreadGroup deallocated with unjoined threads")
        }

        // MARK: - TID allocation

        /// Allocate a unique thread ID. Returns a positive integer in `[1, 2^29)`.
        package func allocateTID() -> Int32 {
            let tid = nextTID.wrappingAdd(1, ordering: .relaxed).oldValue
            precondition(tid >= 1 && tid < (1 << 29), "TID overflow")
            return tid
        }

        // MARK: - Child engine construction

        package func makeChildEngine() -> Engine {
            Engine(configuration: engineConfiguration, funcTypeInterner: funcTypeInterner)
        }

        // MARK: - Termination

        /// Wake every thread blocked in `memory.atomic.wait` on any of the group's shared
        /// memories, so they observe the termination flag and unwind. Each shared memory
        /// owns its parking lot (shared across importing threads).
        private func unparkAllWaiters() {
            for shared in sharedMemories { shared?.parkingLot.unparkAll() }
        }

        /// Signal all threads in the group to terminate due to a trap.
        package func signalTrap() {
            terminationFlag.signal()
            unparkAllWaiters()
        }

        /// Signal all threads to terminate with an exit code (from `proc_exit`).
        ///
        /// If multiple threads call this concurrently, the stored exit code is
        /// whichever write acquires the mutex last (effectively arbitrary).
        /// This matches wasi-threads semantics where `proc_exit` from any thread
        /// terminates the group, and the exact code is best-effort.
        package func signalExit(code: Int32) {
            exitCode.withLock { $0 = code }
            terminationFlag.signal()
            unparkAllWaiters()
        }

        package func isTerminated() -> Bool {
            terminationFlag.isSignaled()
        }

        // MARK: - Thread tracking

        /// Register a spawned thread for join-on-terminate.
        /// Consumes the PlatformThread handle; ThreadGroup takes ownership.
        package func registerThread(_ thread: consuming PlatformThread) {
            // Transfer through a pointer: the Swift 6 compiler can't consume
            // ~Copyable captures in closures (can't prove the closure runs once).
            let ptr = UnsafeMutablePointer<PlatformThread>.allocate(capacity: 1)
            ptr.initialize(to: thread)
            spawnedThreads.withLock { threads in
                threads.append(ptr.move())
                ptr.deallocate()
            }
        }

        /// Join all spawned threads. Used during termination cleanup.
        ///
        /// Drains the thread array under the lock, then joins outside the lock
        /// so that threads which call `registerThread` during their body don't
        /// deadlock. Joins every thread even if some fail; throws the first
        /// error encountered.
        package func joinAllThreads() throws(PlatformThreadError) {
            var toJoin = UniqueArray<PlatformThread>()
            spawnedThreads.withLock { swap(&toJoin, &$0) }

            var firstError: PlatformThreadError?
            while toJoin.count > 0 {
                let thread = toJoin.removeLast()
                do throws(PlatformThreadError) {
                    try thread.join()
                } catch {
                    if firstError == nil { firstError = error }
                }
            }
            if let firstError { throw firstError }
        }
    }

#endif
