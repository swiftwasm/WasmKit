#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

import Synchronization
import WASI
import WasmKit

/// Manages wasi-threads thread spawning for a module instance.
///
/// Implements the `thread-spawn` function from the `wasi-threads` proposal.
/// Each call to `spawnThread` re-instantiates the module (sharing memories and tables
/// via the same `Imports`), then spawns an OS thread that calls
/// `wasi_thread_start(tid, start_arg)` on the child instance.
///
/// Use two-phase initialization to break the circular dependency between
/// the thread manager and imports:
/// ```swift
/// let threadManager = WASIThreadManager(module: module)
/// // ... register thread-spawn using threadManager ...
/// threadManager.setImports(imports)
/// ```
public final class WASIThreadManager {
    /// The parsed module, needed to re-instantiate for each child thread.
    private let module: Module
    /// The imports used when instantiating children (set after construction).
    private var imports: Imports?
    /// Atomic thread ID counter.
    private let nextTID = Mutex<UInt32>(1)
    /// Active child threads (for join/cleanup).
    private let activeThreads = Mutex<[UInt32: pthread_t]>([:])

    public init(module: Module) {
        self.module = module
    }

    /// Set the complete imports (including thread-spawn) for child instantiation.
    /// Must be called before any thread is spawned.
    public func setImports(_ imports: Imports) {
        self.imports = imports
    }

    /// Implements the `thread-spawn` WASI function.
    ///
    /// The overall flow:
    /// 1. Allocate a unique TID.
    /// 2. Re-instantiate the module with the same `Imports`. Because `Imports`
    ///    holds references to the parent's shared memory and tables, the child
    ///    instance automatically shares them (instance-per-thread model).
    /// 3. Resolve the `wasi_thread_start` export on the child instance.
    /// 4. Spawn a POSIX thread that invokes `wasi_thread_start(tid, start_arg)`.
    ///    The thread is immediately detached — we don't join on it. The
    ///    wasi-threads spec says a thread finishes when `wasi_thread_start`
    ///    returns; there's no join primitive. We keep the pthread_t handle in
    ///    `activeThreads` only for bookkeeping (e.g. future `proc_exit`
    ///    termination support).
    ///
    /// - Parameters:
    ///   - store: The store for allocating new instances.
    ///   - startArg: The opaque argument to pass to `wasi_thread_start`.
    /// - Returns: Positive TID on success, negative error code on failure.
    func spawnThread(store: Store, startArg: UInt32) -> Int32 {
        guard let imports else {
            return -1 // imports not yet configured
        }

        let tid = nextTID.withLock { tid -> UInt32 in
            let current = tid
            tid += 1
            return current
        }
        // The return type is s32; TID must be positive.
        guard tid <= UInt32(Int32.max) else { return -1 }

        let childInstance: Instance
        do {
            childInstance = try module.instantiate(store: store, imports: imports)
        } catch {
            return -1
        }

        guard let threadStart = childInstance.exports[function: "wasi_thread_start"] else {
            return -1
        }

        // Heap-allocate the closure so we can pass it through pthread_create's
        // `void *` argument. The spawned thread takes ownership and deallocates.
        let closurePtr = UnsafeMutablePointer<() -> Void>.allocate(capacity: 1)
        closurePtr.initialize(to: { [weak self] in
            do {
                _ = try threadStart.invoke([.i32(tid), .i32(startArg)])
            } catch is WASIExitCode {
                // proc_exit called — should terminate all threads
                // TODO: implement global termination signal
            } catch {
                // Trap — should terminate all threads
                // TODO: implement global termination signal
            }
            self?.activeThreads.withLock { _ = $0.removeValue(forKey: tid) }
        })

        var threadHandle = pthread_t()
        let err = pthread_create(&threadHandle, nil, { arg -> UnsafeMutableRawPointer? in
            // Take ownership of the heap-allocated closure and run it.
            let ptr = arg!.assumingMemoryBound(to: (() -> Void).self)
            let body = ptr.move()
            ptr.deallocate()
            body()
            return nil
        }, closurePtr)

        guard err == 0 else {
            closurePtr.deinitialize(count: 1)
            closurePtr.deallocate()
            return -1
        }

        activeThreads.withLock { $0[tid] = threadHandle }
        // Detach immediately: the wasi-threads spec has no join primitive.
        // The thread cleans itself up when wasi_thread_start returns.
        pthread_detach(threadHandle)

        return Int32(tid)
    }
}
