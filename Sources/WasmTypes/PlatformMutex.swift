/// A mutual-exclusion wrapper around a piece of state.
///
/// With the `MultiThread` package trait enabled (the default), this is backed
/// by `Synchronization.Mutex`. With the trait disabled (single-threaded
/// environments such as bare-metal Embedded Swift targets, where the
/// `Synchronization` module provides no `Mutex`), it degrades to plain
/// unsynchronized storage with the same non-copyable shape.
#if MultiThread
    import Synchronization

    package struct PlatformMutex<State>: ~Copyable, Sendable {
        @usableFromInline let inner: Mutex<State>

        @inlinable
        package init(_ initial: consuming sending State) {
            self.inner = Mutex(initial)
        }

        @inlinable
        package borrowing func withLock<Result, E: Error>(
            _ body: (inout sending State) throws(E) -> sending Result
        ) throws(E) -> sending Result {
            try inner.withLock(body)
        }
    }
#else
    /// Single-threaded fallback: disabling the `MultiThread` trait is a promise
    /// that the process never accesses WasmKit or WASI state from more than one
    /// thread, so plain storage without a lock is enough. The state lives behind
    /// a pointer so that `withLock` can mutate it through a `borrowing` self.
    package struct PlatformMutex<State>: ~Copyable, @unchecked Sendable {
        @usableFromInline let storage: UnsafeMutablePointer<State>

        @inlinable
        package init(_ initial: consuming State) {
            storage = .allocate(capacity: 1)
            storage.initialize(to: initial)
        }

        @inlinable
        deinit {
            storage.deinitialize(count: 1)
            storage.deallocate()
        }

        @inlinable
        package borrowing func withLock<Result, E: Error>(
            _ body: (inout State) throws(E) -> Result
        ) throws(E) -> Result {
            try body(&storage.pointee)
        }
    }
#endif
