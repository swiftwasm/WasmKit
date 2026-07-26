/// A mutual-exclusion wrapper around a piece of state.
///
/// With the `MultiThread` package trait enabled (the default), this is backed
/// by `Synchronization.Mutex`. With the trait disabled -- for single-threaded
/// environments such as bare-metal Embedded Swift targets, where the
/// `Synchronization` module provides no `Mutex` -- it degrades to plain
/// unsynchronized storage with the same non-copyable shape.
#if MultiThread
    import Synchronization

    struct PlatformMutex<State>: ~Copyable, Sendable {
        private let inner: Mutex<State>

        init(_ initial: consuming sending State) {
            self.inner = Mutex(initial)
        }

        borrowing func withLock<Result, E: Error>(
            _ body: (inout sending State) throws(E) -> sending Result
        ) throws(E) -> sending Result {
            try inner.withLock(body)
        }
    }
#else
    /// Single-threaded fallback: disabling the `MultiThread` trait is a promise
    /// that the process never accesses WasmKit state from more than one thread,
    /// so plain storage without a lock is enough.
    struct PlatformMutex<State>: ~Copyable, @unchecked Sendable {
        private var state: State

        init(_ initial: consuming State) {
            self.state = initial
        }

        mutating func withLock<Result, E: Error>(
            _ body: (inout State) throws(E) -> Result
        ) throws(E) -> Result {
            try body(&state)
        }
    }
#endif
