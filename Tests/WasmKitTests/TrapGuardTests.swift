import Testing
import WAT
import WasmParser

@testable import WasmKit

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#endif

/// The trap guard turns a fault in a guard page into a trap. Its `sigsetjmp` saves no signal
/// mask, and a fault comes back through the kernel's return from the signal rather than a jump
/// out of the handler; these check that the thread is left as it was: the same signal mask, off
/// its alternate signal stack, which can still be replaced, and ready for the next fault.
@Suite
struct TrapGuardTests {
    #if (os(macOS) || os(Linux)) && (arch(arm64) || arch(x86_64))
        /// A shared memory's accesses are bounds-checked by its guard pages: an access past the
        /// committed pages faults, and the trap guard turns the fault into a trap. Only the
        /// direct-threaded loop runs guest code under the trap guard.
        struct GuardedFixture {
            let store: Store
            let instance: Instance

            init(host: ((Store) -> Function)? = nil) throws {
                let features: WasmFeatureSet = [.threads]
                store = Store(
                    engine: Engine(configuration: .init(threadingModel: .direct, features: features, memoryBoundsChecking: .mprotect)))
                let memory = try WasmKit.Memory(store: store, type: MemoryType(min: 1, max: 2, shared: true))
                let host = host?(store) ?? Function(store: store, parameters: [], results: []) { _, _ in [] }
                instance = try parseWasm(
                    bytes: wat2wasm(
                        """
                        (module
                          (import "env" "mem" (memory 1 2 shared))
                          (import "env" "host" (func $host))
                          (func (export "load") (param i32) (result i32) (i32.load (local.get 0)))
                          (func (export "hostThenLoad") (param i32) (result i32)
                            (call $host) (i32.load (local.get 0)))
                        )
                        """, features: features),
                    features: features
                ).instantiate(store: store, imports: ["env": ["mem": memory, "host": host]])
            }

            func callAsFunction(_ name: String) throws -> Function {
                try #require(instance.exports[function: name])
            }
        }

        static let guardPagesAvailable =
            !Engine.isAddressSanitizerEnabled
            && SharedMemoryStorage.isSupported(
                engineConfiguration: Engine(configuration: .init(features: [.threads], memoryBoundsChecking: .mprotect)).configuration,
                isMemory64: false)

        @Test(.enabled(if: TrapGuardTests.guardPagesAvailable))
        func outOfBoundsAccessesTrapAndTheNextCallRuns() throws {
            let fixture = try GuardedFixture()
            var stack = ExecutionStack(engine: fixture.store.engine)
            let before = currentSignalMask()
            for _ in 0..<10 {
                for address: UInt32 in [65536, 65536 * 2 - 4, 0xFFFF_FFF0] {
                    expectGuardedTrap { _ = try fixture("load").invoke([.i32(address)], on: &stack) }
                    guard maskIsUnchanged(since: before) else { return }
                    #expect(try fixture("load").invoke([.i32(0)], on: &stack) == [.i32(0)])
                }
            }
        }

        /// Were SIGSEGV left blocked, the next fault in a guard page could not be delivered: the
        /// process would hang or be killed, which is why each check comes before the next fault.
        @Test(.enabled(if: TrapGuardTests.guardPagesAvailable))
        func signalMaskIsUnchangedByGuardedTraps() throws {
            let fixture = try GuardedFixture()
            var stack = ExecutionStack(engine: fixture.store.engine)
            try withBlockedSignals([SIGUSR1, SIGUSR2]) {
                let before = currentSignalMask()
                #expect(isBlocked(SIGUSR1, in: before))
                #expect(isBlocked(SIGSEGV, in: before) == false)
                for _ in 0..<20 {
                    expectGuardedTrap { _ = try fixture("load").invoke([.i32(65536)], on: &stack) }
                    guard maskIsUnchanged(since: before) else { return }
                }
                let loaded = try fixture("load").invoke([.i32(8)], on: &stack)
                #expect(loaded == [.i32(0)])
            }
        }

        /// With an alternate signal stack installed (as crash reporters install one), the handler
        /// runs on it, and after the trap the thread is off it again: the next fault is handled
        /// on it too, and it can be replaced. Jumping out of the handler with a `siglongjmp` that
        /// restores no mask leaves a Darwin thread marked as still on it, so that later signals
        /// are delivered on the faulting stack and `sigaltstack` refuses to replace it.
        @Test(.enabled(if: TrapGuardTests.guardPagesAvailable))
        func alternateSignalStackIsLeftAfterGuardedTraps() throws {
            let fixture = try GuardedFixture()
            var stack = ExecutionStack(engine: fixture.store.engine)
            let size = 1 << 16
            let first = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 16)
            let second = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 16)
            defer {
                first.deallocate()
                second.deallocate()
            }
            var previous = stack_t()
            var installed = stack_t()
            installed.ss_sp = first
            installed.ss_size = size
            #expect(sigaltstack(&installed, &previous) == 0)
            defer {
                // Off the stacks above before they are freed; `previous` disables it if none was set.
                var restore = previous
                if restore.ss_sp == nil { restore.ss_flags = numericCast(SS_DISABLE) }
                sigaltstack(&restore, nil)
            }

            for _ in 0..<5 {
                expectGuardedTrap { _ = try fixture("load").invoke([.i32(65536)], on: &stack) }
                #expect(isOnAlternateSignalStack() == false)
                guard !isOnAlternateSignalStack() else { return }
            }
            var replacement = stack_t()
            replacement.ss_sp = second
            replacement.ss_size = size
            #expect(sigaltstack(&replacement, nil) == 0)
            expectGuardedTrap { _ = try fixture("load").invoke([.i32(65536)], on: &stack) }
            #expect(isOnAlternateSignalStack() == false)
            #expect(try fixture("load").invoke([.i32(0)], on: &stack) == [.i32(0)])
        }

        /// A guarded trap in a call the host makes from inside a guarded call, caught there, then
        /// one in the outer call: each trap guard catches its own fault, the outer one is restored
        /// when the inner call ends, and the mask is unchanged after both.
        @Test(.enabled(if: TrapGuardTests.guardPagesAvailable))
        func nestedGuardedTrapsEachReachTheirOwnGuard() throws {
            var load: Function?
            var innerTraps = 0
            let fixture = try GuardedFixture { store in
                Function(store: store, parameters: [], results: []) { _, _ in
                    var stack = ExecutionStack(engine: store.engine)
                    do {
                        _ = try load!.invoke([.i32(65536)], on: &stack)
                    } catch let trap as Trap where trap.reason.description == TrapReason.memoryOutOfBounds.description {
                        innerTraps += 1
                    }
                    return []
                }
            }
            load = try fixture("load")
            var stack = ExecutionStack(engine: fixture.store.engine)
            try withBlockedSignals([SIGUSR1]) {
                let before = currentSignalMask()
                for round in 1...10 {
                    // The inner call traps and the host catches it; the outer call goes on.
                    let loaded = try fixture("hostThenLoad").invoke([.i32(0)], on: &stack)
                    #expect(loaded == [.i32(0)])
                    guard maskIsUnchanged(since: before) else { return }
                    // The inner call traps; then the outer call does.
                    expectGuardedTrap { _ = try fixture("hostThenLoad").invoke([.i32(65536)], on: &stack) }
                    #expect(innerTraps == 2 * round)
                    guard maskIsUnchanged(since: before) else { return }
                }
            }
        }

        // MARK: - Helpers

        /// Expects a memory-out-of-bounds trap raised by the trap guard (a fault in a guard page),
        /// not by a software bounds check.
        func expectGuardedTrap(sourceLocation: SourceLocation = #_sourceLocation, _ body: () throws -> Void) {
            do {
                try body()
                Issue.record("expected a trap, but no error was thrown", sourceLocation: sourceLocation)
            } catch let trap as Trap {
                #expect(trap.reason.description == TrapReason.memoryOutOfBounds.description, sourceLocation: sourceLocation)
                // Only the trap guard's path leaves the innermost frame unknown.
                #expect(trap.backtrace != nil, sourceLocation: sourceLocation)
                #expect(trap.backtrace?.innermostSp == nil, sourceLocation: sourceLocation)
            } catch {
                Issue.record("expected a trap, but caught: \(error)", sourceLocation: sourceLocation)
            }
        }

        private func isOnAlternateSignalStack() -> Bool {
            var current = stack_t()
            sigaltstack(nil, &current)
            return Int(current.ss_flags) & Int(SS_ONSTACK) != 0
        }

        /// Whether this thread's signal mask is still `before`. If it isn't, records the issue and
        /// puts `before` back, so that the test can stop without the next fault hanging the run.
        private func maskIsUnchanged(since before: sigset_t, sourceLocation: SourceLocation = #_sourceLocation) -> Bool {
            let after = currentSignalMask()
            guard signalMasksAreEqual(before, after) else {
                Issue.record(
                    "a guarded trap changed the signal mask (SIGSEGV blocked: \(isBlocked(SIGSEGV, in: after)), SIGBUS blocked: \(isBlocked(SIGBUS, in: after)))",
                    sourceLocation: sourceLocation)
                var before = before
                pthread_sigmask(SIG_SETMASK, &before, nil)
                return false
            }
            return true
        }

        private func currentSignalMask() -> sigset_t {
            var mask = sigset_t()
            sigemptyset(&mask)
            pthread_sigmask(SIG_SETMASK, nil, &mask)
            return mask
        }

        private func signalMasksAreEqual(_ a: sigset_t, _ b: sigset_t) -> Bool {
            withUnsafeBytes(of: a) { a in withUnsafeBytes(of: b) { b in a.elementsEqual(b) } }
        }

        private func isBlocked(_ signal: Int32, in mask: sigset_t) -> Bool {
            var mask = mask
            return sigismember(&mask, signal) == 1
        }

        /// Runs `body` with `signals` blocked on this thread, then puts the mask back.
        private func withBlockedSignals(_ signals: [Int32], _ body: () throws -> Void) throws {
            var block = sigset_t()
            sigemptyset(&block)
            for signal in signals { sigaddset(&block, signal) }
            var original = sigset_t()
            sigemptyset(&original)
            #expect(pthread_sigmask(SIG_BLOCK, &block, &original) == 0)
            defer { pthread_sigmask(SIG_SETMASK, &original, nil) }
            try body()
        }
    #endif
}
