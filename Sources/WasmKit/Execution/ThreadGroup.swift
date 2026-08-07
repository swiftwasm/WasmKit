#if os(macOS) || os(Linux)

    import Synchronization

    /// A shared termination flag for cooperative cancellation across threads.
    ///
    /// Every `Store` in a wasi-threads group holds the same instance. Cancellation takes effect
    /// wherever the interpreter checks the flag, at function-call boundaries and around
    /// `memory.atomic.wait`, which throw `Trap(.threadTerminated)` to unwind the executing thread.
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
    package final class ThreadGroup: Sendable {
        package let module: Module

        /// Each child thread builds its own `Engine` from this configuration.
        let engineConfiguration: EngineConfiguration

        /// Shared with every child `Engine`; see ``Engine/funcTypeInterner``.
        let funcTypeInterner: Interner<FunctionType>

        /// Indexed by the module's memory index; `nil` where that memory is not shared.
        package let sharedMemories: [SharedMemoryStorage?]

        package let terminationFlag: TerminationFlag

        /// Next thread ID to allocate. TID 0 is reserved for the main thread by the wasi-threads spec.
        let nextTID: Atomic<Int32>

        let exitCode: Mutex<Int32?>

        /// Threads this group owns, to be joined by ``joinAllThreads()`` or detached by `deinit`.
        let spawnedThreads: Mutex<[PlatformThreadHandle]>

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
            self.spawnedThreads = Mutex([])
        }

        deinit {
            assert(
                spawnedThreads.withLock({ $0.count }) == 0,
                "ThreadGroup deallocated with unjoined threads")

            // Detach rather than join the leftovers: joining would block deallocation on guest code.
            spawnedThreads.withLock { handles in
                for handle in handles {
                    PlatformThread.detach(handle)
                }
                handles.removeAll()
            }
        }

        /// Allocate a unique thread ID. Returns a positive integer in `[1, 2^29)`.
        package func allocateTID() -> Int32 {
            let tid = nextTID.wrappingAdd(1, ordering: .relaxed).oldValue
            precondition(tid >= 1 && tid < (1 << 29), "TID overflow")
            return tid
        }

        package func makeChildEngine() -> Engine {
            Engine(configuration: engineConfiguration, funcTypeInterner: funcTypeInterner)
        }

        /// Wake every waiter so it observes the termination flag and unwinds.
        private func unparkAllWaiters() {
            for shared in sharedMemories { shared?.parkingLot.unparkAll() }
        }

        package func signalTrap() {
            terminationFlag.signal()
            unparkAllWaiters()
        }

        /// Signal all threads to terminate with an exit code (from `proc_exit`).
        ///
        /// With concurrent callers the last write wins: wasi-threads lets `proc_exit` from any
        /// thread end the group, and makes the exact code best-effort.
        package func signalExit(code: Int32) {
            exitCode.withLock { $0 = code }
            terminationFlag.signal()
            unparkAllWaiters()
        }

        package func isTerminated() -> Bool {
            terminationFlag.isSignaled()
        }

        package func registerThread(_ thread: consuming PlatformThread) {
            // Consumed outside `withLock`: a `~Copyable` value cannot be consumed inside a closure.
            let handle = thread.release()
            spawnedThreads.withLock { $0.append(handle) }
        }

        /// Join every registered thread, throwing the first error but joining the rest.
        ///
        /// Joins outside the lock: a thread that calls `registerThread` from its body would
        /// otherwise deadlock.
        package func joinAllThreads() throws(PlatformThreadError) {
            // Swap instead of returning the array: `inout sending` state cannot escape `withLock`.
            var toJoin: [PlatformThreadHandle] = []
            spawnedThreads.withLock { swap(&toJoin, &$0) }

            var firstError: PlatformThreadError?
            for handle in toJoin {
                do throws(PlatformThreadError) {
                    try PlatformThread.join(handle)
                } catch {
                    if firstError == nil { firstError = error }
                }
            }
            if let firstError { throw firstError }
        }
    }

#endif
