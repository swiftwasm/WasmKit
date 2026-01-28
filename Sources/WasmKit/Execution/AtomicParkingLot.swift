/// Synchronization primitives for atomic memory wait and notify operations.
///
/// Provides thread-safe waiting and notification mechanisms for shared memory
/// operations. The current implementation uses a simple mutex-protected queue
/// with busy-waiting, but the interface is designed to allow future
/// optimizations with more efficient blocking mechanisms.
///
/// API design inspired by WebKit's ParkingLot:
/// https://github.com/WebKit/WebKit/blob/main/Source/WTF/wtf/ParkingLot.h

import Synchronization

/// Represents a thread waiting on a memory address
final class WaitingThread: @unchecked Sendable {
    let isWoken: Atomic<Bool>

    init() {
        self.isWoken = Atomic(false)
    }
}

/// Manages waiting threads for atomic memory operations.
final class AtomicParkingLot {
    /// Synchronized map from memory address to waiting threads
    private let lock: Mutex<[UInt64: [WaitingThread]]>

    init() {
        self.lock = Mutex([:])
    }

    /// Parks the thread in a queue associated with the given address.
    ///
    /// The parking only succeeds if the validation function returns true while
    /// the queue lock is held. If validation returns false, it will return
    /// `.mismatch` without doing anything else.
    ///
    /// If validation returns true, it will enqueue the thread, unlock the
    /// parking queue lock, and then sleep so long as the thread continues to be
    /// on the queue and the timeout hasn't fired. Returns `.woken` if we
    /// actually got unparked, `.timedOut` if the timeout was hit, or `.mismatch`
    /// if validation failed.
    ///
    /// - Parameters:
    ///   - address: Memory address to park on (cannot be null conceptually)
    ///   - validate: Closure that checks if the wait condition is still valid
    ///   - deadline: Optional deadline after which to timeout
    ///   - threadState: Thread-local state for this wait operation
    /// - Returns: Result indicating woken, mismatch, or timeout
    func parkConditionally(
        address: UInt64,
        validate: () -> Bool,
        deadline: (() -> ContinuousClock.Instant)?,
        threadState: inout ThreadWaitState
    ) -> WaitOutcome {
        // Quick check before acquiring lock
        if !validate() {
            return WaitOutcome.mismatch
        }

        // Initialize thread state if needed
        let thread = threadState.thread ?? WaitingThread()
        threadState.thread = thread
        thread.isWoken.store(false, ordering: .relaxed)

        // Register this thread as waiting
        let shouldBlock = lock.withLock { registry -> Bool in
            // Re-check condition while holding lock
            if !validate() {
                thread.isWoken.store(true, ordering: .relaxed)
                return false
            }

            // Add to waiting list for this address
            registry[address, default: []].append(thread)
            return true
        }

        // Exit early if condition no longer holds
        if !shouldBlock || thread.isWoken.load(ordering: .acquiring) {
            return WaitOutcome.mismatch
        }

        // Wait for wake signal with timeout handling
        let deadlineTime = deadline?()
        var expired = false
        var spinCount = 1

        while !thread.isWoken.load(ordering: .acquiring) {
            if let deadlineTime = deadlineTime {
                let currentTime = ContinuousClock.now
                if currentTime >= deadlineTime {
                    expired = true
                    break
                }
            }

            // Progressive backoff to reduce CPU spinning
            for _ in 0..<spinCount {
                _ = spinCount & 1
            }
            spinCount = min(spinCount * 2, 1024)
        }

        // Clean up if we timed out
        if expired {
            lock.withLock { registry in
                if var threads = registry[address] {
                    threads.removeAll { $0 === thread }
                    if threads.isEmpty {
                        registry.removeValue(forKey: address)
                    } else {
                        registry[address] = threads
                    }
                }
            }
            return WaitOutcome.timedOut
        }

        return WaitOutcome.woken
    }

    /// Unparks up to `count` threads from the queue associated with the given address.
    ///
    /// - Parameters:
    ///   - address: Memory address to unpark threads for (cannot be null conceptually)
    ///   - count: Maximum number of threads to unpark
    /// - Returns: Number of threads actually unparked
    func unpark(address: UInt64, count: UInt32) -> UInt32 {
        if count == 0 {
            return 0
        }

        var wokenCount: UInt32 = 0

        lock.withLock { registry in
            guard var threads = registry[address], !threads.isEmpty else {
                return
            }

            let wakeCount = min(Int(count), threads.count)
            let toWake = Array(threads.prefix(wakeCount))
            threads.removeFirst(wakeCount)

            if threads.isEmpty {
                registry.removeValue(forKey: address)
            } else {
                registry[address] = threads
            }

            // Signal waiting threads
            for thread in toWake {
                thread.isWoken.store(true, ordering: .releasing)
            }

            wokenCount = UInt32(wakeCount)
        }

        return wokenCount
    }
}

/// Per-thread state for wait operations
struct ThreadWaitState {
    var thread: WaitingThread?

    init() {
        self.thread = nil
    }
}

/// Result of a wait operation
enum WaitOutcome {
    case woken  // 0 - successfully woken by notify
    case mismatch  // 1 - value didn't match expected
    case timedOut  // 2 - deadline expired
}
