/// Synchronization primitives for atomic memory wait and notify operations.
///
/// Provides thread-safe waiting and notification mechanisms for shared memory
/// operations. Uses pthread condition variables for OS-level blocking.
///
/// API design inspired by WebKit's ParkingLot:
/// https://github.com/WebKit/WebKit/blob/main/Source/WTF/wtf/ParkingLot.h

import Synchronization

#if canImport(Darwin)
    import Darwin
#elseif canImport(Musl)
    import Musl
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Android)
    import Android
#elseif canImport(WASILibc)
    import WASILibc
    import wasi_pthread
#endif

// `memory.atomic.wait`/`notify` need an OS primitive to block and wake a thread.
// pthread provides it on Darwin, Linux (Glibc/Musl), Android (Bionic), and WASI
// (wasi-libc's `wasi_pthread`). Windows has no pthread here, so the parking lot is
// excluded there; the wait/notify instructions handle its absence directly.
#if !os(Windows)

/// Per-wait blocking context wrapping a pthread condvar + mutex pair.
///
/// A class because the same slot is referenced simultaneously from the
/// registry (where `unpark` finds it) and the parked thread (blocking in
/// `wait()`). `woken` is only accessed under `pthread_mutex_lock(mutex)`.
final class BlockingSlot: @unchecked Sendable {
    private let mutex: UnsafeMutablePointer<pthread_mutex_t>
    private let cond: UnsafeMutablePointer<pthread_cond_t>
    private var woken: Bool

    init() {
        mutex = .allocate(capacity: 1)
        mutex.initialize(to: pthread_mutex_t())
        pthread_mutex_init(mutex, nil)

        cond = .allocate(capacity: 1)
        cond.initialize(to: pthread_cond_t())
        #if canImport(Darwin) || canImport(WASILibc)
            // Darwin has no `pthread_condattr_setclock`; wasi-libc's `CLOCK_MONOTONIC`
            // is a time64 clock object (not an importable constant). Both use the
            // default clock, so the timed wait below reads `CLOCK_REALTIME` to match.
            pthread_cond_init(cond, nil)
        #else
            var attr = pthread_condattr_t()
            pthread_condattr_init(&attr)
            pthread_condattr_setclock(&attr, CLOCK_MONOTONIC)
            pthread_cond_init(cond, &attr)
            pthread_condattr_destroy(&attr)
        #endif

        woken = false
    }

    deinit {
        pthread_cond_destroy(cond)
        cond.deinitialize(count: 1)
        cond.deallocate()

        pthread_mutex_destroy(mutex)
        mutex.deinitialize(count: 1)
        mutex.deallocate()
    }

    /// Block until woken or timeout expires.
    /// - Parameter timeoutNs: relative timeout in nanoseconds.
    ///   `< 0` = wait indefinitely, `0` = return immediately, `> 0` = timed wait.
    /// - Returns: `true` if woken by `wake()`, `false` if timed out.
    func wait(timeoutNs: Int64) -> Bool {
        pthread_mutex_lock(mutex)
        defer { pthread_mutex_unlock(mutex) }

        if timeoutNs == 0 {
            return woken
        }

        if timeoutNs < 0 {
            while !woken {
                pthread_cond_wait(cond, mutex)
            }
            return true
        }

        var deadline = timespec()
        #if canImport(Darwin)
            clock_gettime(CLOCK_REALTIME, &deadline)
        #elseif canImport(WASILibc)
            // wasi-libc's `CLOCK_REALTIME` is a time64 clock object, not an importable
            // constant, so seed the (default-clock) deadline from `gettimeofday`.
            var now = timeval()
            gettimeofday(&now, nil)
            deadline.tv_sec = now.tv_sec
            deadline.tv_nsec = Int(now.tv_usec) * 1000
        #else
            clock_gettime(CLOCK_MONOTONIC, &deadline)
        #endif
        let extraSec = timeoutNs / 1_000_000_000
        let extraNsec = timeoutNs % 1_000_000_000
        deadline.tv_sec += time_t(extraSec)
        deadline.tv_nsec += Int(extraNsec)
        if deadline.tv_nsec >= 1_000_000_000 {
            deadline.tv_sec += 1
            deadline.tv_nsec -= 1_000_000_000
        }

        while !woken {
            let rc = pthread_cond_timedwait(cond, mutex, &deadline)
            if rc == ETIMEDOUT { break }
        }
        return woken
    }

    /// Wake the thread blocked on this slot.
    func wake() {
        pthread_mutex_lock(mutex)
        woken = true
        pthread_cond_signal(cond)
        pthread_mutex_unlock(mutex)
    }
}

/// Manages waiting threads for atomic memory operations.
package final class AtomicParkingLot: Sendable {
    private let registry: Mutex<[UInt64: [BlockingSlot]]>

    #if DEBUG
        /// Test-only hook fired inside `unpark` after the slots are removed and counted
        /// (registry lock released) and before `wake()` runs, used to deterministically
        /// exercise the timeout/notify race. Never set outside tests; compiled out of release.
        let _afterDequeueBeforeWake = Mutex<(@Sendable () -> Void)?>(nil)
    #endif

    init() {
        self.registry = Mutex([:])
    }

    /// Parks the calling thread until woken, timed out, or validation fails.
    ///
    /// Validation runs twice: once before acquiring the registry lock (quick
    /// path) and once while holding it (definitive check). If either returns
    /// false, returns `.mismatch` without blocking.
    /// - Parameters:
    ///   - address: Memory address to park on
    ///   - validate: Closure that checks if the wait condition is still valid
    ///   - deadline: Optional deadline after which to timeout
    ///   - beforeSleep: Optional callback invoked after the thread is queued
    ///     in the registry but before it blocks. Callers can use this to
    ///     signal readiness, knowing that a subsequent `unpark` on the same
    ///     address will find this thread.
    func parkConditionally(
        address: UInt64,
        validate: () -> Bool,
        deadline: (() -> ContinuousClock.Instant)?,
        beforeSleep: (() -> Void)? = nil
    ) -> WaitOutcome {
        if !validate() {
            return .mismatch
        }

        let slot = BlockingSlot()

        let shouldBlock = registry.withLock { reg -> Bool in
            if !validate() {
                return false
            }
            reg[address, default: []].append(slot)
            return true
        }

        if !shouldBlock {
            return .mismatch
        }

        beforeSleep?()

        let timeoutNs: Int64
        if let deadline = deadline?() {
            let remaining = deadline - ContinuousClock.now
            let (seconds, attoseconds) = remaining.components
            let ns = seconds * 1_000_000_000 + attoseconds / 1_000_000_000
            timeoutNs = max(ns, 0)
        } else {
            timeoutNs = -1
        }

        let wasWoken = slot.wait(timeoutNs: timeoutNs)

        if !wasWoken {
            // `slot.wait` reported a timeout, but the pthread `woken` flag and registry
            // membership are two views of one wakeup. The registry — mutated only under
            // `registry`'s lock — is authoritative: `unpark` removes a slot from the
            // registry (under the lock) before it calls `wake()` (outside the lock). So if
            // our slot is still queued here we genuinely timed out; if it is already gone,
            // a concurrent `unpark` claimed and counted us in the gap between our timeout
            // and its `wake()`, and we report `.woken` to keep `unpark`'s returned count
            // equal to the wakeups waiters observe. Each slot is appended exactly once, so
            // `firstIndex` finds the unique entry. This relies on `unpark` being the only
            // dequeuer; `unparkAll`, when wired for termination, must revisit it (see Risks).
            let genuinelyTimedOut = registry.withLock { reg -> Bool in
                guard var slots = reg[address],
                    let index = slots.firstIndex(where: { $0 === slot })
                else {
                    return false
                }
                slots.remove(at: index)
                setOrRemove(slots, for: address, in: &reg)
                return true
            }
            return genuinelyTimedOut ? .timedOut : .woken
        }

        return .woken
    }

    /// Stores the waiter list for `address`, or removes the key entirely when the list
    /// is empty so empty buckets do not accumulate.
    private func setOrRemove(
        _ slots: [BlockingSlot], for address: UInt64, in reg: inout [UInt64: [BlockingSlot]]
    ) {
        if slots.isEmpty {
            reg.removeValue(forKey: address)
        } else {
            reg[address] = slots
        }
    }

    /// Unparks up to `count` threads from the queue at `address`.
    func unpark(address: UInt64, count: UInt32) -> UInt32 {
        if count == 0 { return 0 }

        let toWake: [BlockingSlot] = registry.withLock { reg in
            guard var slots = reg[address], !slots.isEmpty else {
                return []
            }
            let wakeCount = min(Int(count), slots.count)
            let result = Array(slots.prefix(wakeCount))
            slots.removeFirst(wakeCount)
            setOrRemove(slots, for: address, in: &reg)
            return result
        }

        #if DEBUG
            _afterDequeueBeforeWake.withLock { $0 }?()
        #endif

        for slot in toWake {
            slot.wake()
        }
        return UInt32(toWake.count)
    }

    /// Wake all parked threads across all addresses.
    func unparkAll() {
        let allSlots: [[BlockingSlot]] = registry.withLock { reg in
            let result = Array(reg.values)
            reg.removeAll()
            return result
        }
        for slots in allSlots {
            for slot in slots {
                slot.wake()
            }
        }
    }
}

#endif

/// Result of a wait operation
enum WaitOutcome: Equatable {
    case woken  // 0 - successfully woken by notify
    case mismatch  // 1 - value didn't match expected
    case timedOut  // 2 - deadline expired
}
