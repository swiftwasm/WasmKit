import Dispatch
import Foundation
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

// These tests drive real cross-thread park/unpark blocking, so they only apply where
// `AtomicParkingLot` has a pthread-backed implementation. On Windows/WASI it is a stub
// (see AtomicParkingLot.swift), and `swift test` there must not compile this suite.
#if canImport(Darwin) || canImport(Musl) || canImport(Glibc)

    @Suite struct AtomicParkingLotTests {
        #if DEBUG
            /// Deterministic regression for the notify/timeout race: a waiter that `unpark`
            /// dequeues and counts must report `.woken` (0), not `.timedOut` (2).
            ///
            /// Ordering is forced with no reliance on wall-clock timing:
            ///   1. the waiter registers, then blocks in `beforeSleep`;
            ///   2. the notifier `unpark`s — removing and counting the slot — then pauses in the
            ///      seam, before `wake()`, so `woken` stays false and the slot is already absent;
            ///   3. the waiter resumes with a zero timeout, reads `woken == false`, and runs its
            ///      timeout-path registry check against the now-absent slot.
            @Test func timedOutWaiterClaimedByNotifyReportsWoken() {
                let lot = AtomicParkingLot()
                let address: UInt64 = 0x2000

                let registered = DispatchSemaphore(value: 0)
                let proceedWaiter = DispatchSemaphore(value: 0)
                let dequeued = DispatchSemaphore(value: 0)
                let release = DispatchSemaphore(value: 0)

                lot._afterDequeueBeforeWake.withLock {
                    $0 = {
                        dequeued.signal()
                        release.wait()
                    }
                }

                let outcome = Mutex<WaitOutcome?>(nil)
                let notifyCount = Mutex<UInt32>(0)
                let waiterDone = DispatchGroup()
                let notifierDone = DispatchGroup()

                waiterDone.enter()
                Thread.detachNewThread {
                    let result = lot.parkConditionally(
                        address: address,
                        validate: { true },
                        deadline: { ContinuousClock.now },  // relative timeout 0: `wait` reads `woken` immediately
                        beforeSleep: {
                            registered.signal()
                            proceedWaiter.wait()
                        }
                    )
                    outcome.withLock { $0 = result }
                    waiterDone.leave()
                }

                notifierDone.enter()
                Thread.detachNewThread {
                    registered.wait()  // slot is queued
                    let n = lot.unpark(address: address, count: .max)  // removes+counts, then pauses in the seam
                    notifyCount.withLock { $0 = n }
                    notifierDone.leave()
                }

                dequeued.wait()  // unpark removed+counted the slot; paused before wake()
                proceedWaiter.signal()  // waiter resumes: reads woken==false, finds its slot absent
                waiterDone.wait()  // waiter has returned its outcome
                release.signal()  // unpark finishes (wake() is now a no-op on the discarded slot)
                notifierDone.wait()

                #expect(notifyCount.withLock { $0 } == 1, "unpark must count the single dequeued waiter")
                #expect(
                    outcome.withLock { $0 } == .woken,
                    "a waiter that unpark dequeued and counted must report .woken (0), not .timedOut (2)"
                )
            }
        #endif

        /// Contention breadth: across a run using only `unpark`, the sum of `unpark`
        /// return values must equal the number of `parkConditionally` calls returning
        /// `.woken` (exact post-fix; see the plan's Correctness argument). Waiters use a
        /// short positive timeout so they block in `pthread_cond_timedwait`, the
        /// production `memory.atomic.wait` path.
        @Test func notifyCountMatchesObservedWakeupsUnderContention() {
            let lot = AtomicParkingLot()
            let address: UInt64 = 0x1000

            let cores = ProcessInfo.processInfo.activeProcessorCount
            let waiterCount = max(4, cores)
            let notifierCount = max(2, cores / 2)
            let runDuration: Duration = .milliseconds(750)
            let waitTimeout: Duration = .microseconds(200)

            let totals = Mutex<(notify: Int, woken: Int, timedOut: Int)>((0, 0, 0))
            let stop = Atomic<Bool>(false)
            let waiters = DispatchGroup()
            let notifiers = DispatchGroup()
            let stopAt = ContinuousClock.now.advanced(by: runDuration)

            for _ in 0..<waiterCount {
                waiters.enter()
                Thread.detachNewThread {
                    var woken = 0
                    var timedOut = 0
                    while ContinuousClock.now < stopAt {
                        switch lot.parkConditionally(
                            address: address,
                            validate: { true },
                            deadline: { ContinuousClock.now.advanced(by: waitTimeout) }
                        ) {
                        case .woken: woken += 1
                        case .timedOut: timedOut += 1
                        case .mismatch:
                            // Unreachable here: `validate` is constant-true, so the slot is always
                            // appended and the wait runs. `continue` (not `break`) makes the intent
                            // explicit — a bare `break` would exit only the switch, not the loop.
                            continue
                        }
                    }
                    totals.withLock {
                        $0.woken += woken
                        $0.timedOut += timedOut
                    }
                    waiters.leave()
                }
            }

            for _ in 0..<notifierCount {
                notifiers.enter()
                Thread.detachNewThread {
                    var notified = 0
                    while !stop.load(ordering: .acquiring) {
                        notified += Int(lot.unpark(address: address, count: .max))
                        // Yield each iteration so the tight notify loop does not starve the
                        // waiter threads of CPU on low-core hosts: waiters must get scheduled
                        // long enough to actually park for a notify to reach them, which keeps
                        // the `woken > 0` non-vacuity guard robust without lengthening the
                        // waiters' timeout (which would stop exercising the timeout path).
                        sched_yield()
                    }
                    totals.withLock { $0.notify += notified }
                    notifiers.leave()
                }
            }

            waiters.wait()
            stop.store(true, ordering: .releasing)
            notifiers.wait()

            // `waiters.wait()`/`notifiers.wait()` establish happens-before for every per-thread
            // `totals` write, so this final read observes all of them.
            totals.withLock { t in
                #expect(
                    t.notify == t.woken,
                    "notify count (\(t.notify)) must equal observed wakeups (\(t.woken))"
                )
                // Non-vacuity: confirm notifies actually woke some waiters this run (else
                // 0 == 0 is meaningless). This proves notify reached waiters; it does NOT by
                // itself prove the timeout/notify overlap window was hit — that race is what
                // `timedOutWaiterClaimedByNotifyReportsWoken` covers deterministically.
                // A failure here means too little contention: raise runDuration / counts.
                #expect(t.woken > 0, "no waiter was woken by a notify (raise contention/runDuration)")
            }
        }
    }

#endif
