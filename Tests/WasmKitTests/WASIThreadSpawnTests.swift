#if os(macOS) || os(Linux)

    import Testing
    import WAT
    import WasmKitWASI

    @testable import WasmKit

    private let sharedMemorySupported = SharedMemoryStorage.isSupported(
        engineConfiguration: Engine(configuration: .init(features: [.threads])).configuration,
        isMemory64: false
    )

    @Suite(.enabled(if: sharedMemorySupported)) struct WASIThreadSpawnTests {
        private func makeEngine() -> Engine {
            Engine(configuration: .init(features: [.threads]))
        }

        @Test func basicThreadSpawn() throws {
            // Canonical wasi-threads pattern: parent spawns child, child writes
            // tid and arg to shared memory, parent spin-reads and verifies.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        ;; Store tid at offset 4
                        i32.const 4
                        local.get $tid
                        i32.atomic.store
                        ;; Store arg at offset 8
                        i32.const 8
                        local.get $arg
                        i32.atomic.store
                        ;; Signal parent: store 1 at offset 0
                        i32.const 0
                        i32.const 1
                        i32.atomic.store
                      )
                      (func (export "_start") (local $tid i32)
                        ;; Spawn thread with arg 12345
                        i32.const 12345
                        call $thread_spawn
                        local.set $tid
                        ;; Check TID > 0
                        local.get $tid
                        i32.const 0
                        i32.le_s
                        if unreachable end
                        ;; Spin-wait for child signal at offset 0
                        block $done
                          loop $retry
                            i32.const 0
                            i32.atomic.load
                            i32.eqz
                            br_if $retry
                          end
                        end
                        ;; Verify child received correct tid
                        i32.const 4
                        i32.atomic.load
                        local.get $tid
                        i32.ne
                        if unreachable end
                        ;; Verify child received correct arg
                        i32.const 8
                        i32.atomic.load
                        i32.const 12345
                        i32.ne
                        if unreachable end
                        ;; All checks passed
                        i32.const 0
                        call $proc_exit
                        unreachable
                      )
                    )
                    """),
                features: [.threads]
            )

            let engine = makeEngine()
            let store = Store(engine: engine)
            let bridge = try WASIBridgeToHost()
            var imports = Imports()
            bridge.link(to: &imports, store: store)
            let threadGroup = try bridge.linkThreads(
                to: &imports, store: store, module: module
            )
            let instance = try module.instantiate(store: store, imports: imports)
            let exitCode = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(exitCode == 0)
        }

        @Test func missingThreadStartTrapsGroup() throws {
            // Module without wasi_thread_start: child signals trap.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func (export "_start")
                        i32.const 0
                        call $thread_spawn
                        drop
                      )
                    )
                    """),
                features: [.threads]
            )

            let engine = makeEngine()
            let store = Store(engine: engine)
            let bridge = try WASIBridgeToHost()
            var imports = Imports()
            bridge.link(to: &imports, store: store)
            let threadGroup = try bridge.linkThreads(
                to: &imports, store: store, module: module
            )
            let instance = try module.instantiate(store: store, imports: imports)
            _ = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(threadGroup.isTerminated())
        }

        @Test func childTrapSignalsGroup() throws {
            // Child's wasi_thread_start traps: group is signaled.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        unreachable
                      )
                      (func (export "_start")
                        i32.const 0
                        call $thread_spawn
                        drop
                      )
                    )
                    """),
                features: [.threads]
            )

            let engine = makeEngine()
            let store = Store(engine: engine)
            let bridge = try WASIBridgeToHost()
            var imports = Imports()
            bridge.link(to: &imports, store: store)
            let threadGroup = try bridge.linkThreads(
                to: &imports, store: store, module: module
            )
            let instance = try module.instantiate(store: store, imports: imports)
            _ = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(threadGroup.isTerminated())
        }

        @Test func childTerminatesBlockedParent() throws {
            // Cooperative termination via parking lot wakeup: parent blocks on
            // memory.atomic.wait32 with a 1-second safety timeout; child traps.
            // signalTrap calls unparkAll, waking the parent's wait; the wait's
            // post-park termination check then throws Trap(.threadTerminated), so
            // proc_exit is never reached. The timeout bounds runtime if unpark fails.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        unreachable
                      )
                      (func (export "_start")
                        ;; Spawn the child
                        i32.const 0
                        call $thread_spawn
                        drop
                        ;; Wait on address 0 for value to change from 0.
                        ;; 1 second safety timeout (1_000_000_000 ns).
                        i32.const 0              ;; address
                        i32.const 0              ;; expected value (matches initial zero)
                        i64.const 1000000000     ;; 1 second timeout
                        memory.atomic.wait32
                        drop
                        ;; Unreached: the wait above throws Trap(.threadTerminated)
                        ;; once the child's signalTrap unparks it.
                        i32.const 0
                        call $proc_exit
                        unreachable
                      )
                    )
                    """),
                features: [.threads]
            )

            let engine = makeEngine()
            let store = Store(engine: engine)
            let bridge = try WASIBridgeToHost()
            var imports = Imports()
            bridge.link(to: &imports, store: store)
            let threadGroup = try bridge.linkThreads(
                to: &imports, store: store, module: module
            )
            let instance = try module.instantiate(store: store, imports: imports)
            #expect(throws: Trap.self) {
                _ = try bridge.start(instance)
            }
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(threadGroup.isTerminated())
        }

        #if DEBUG
            @Test func infiniteWaitObservesTerminationDuringRegistrationRace() throws {
                // _start parks on address 0 (holds 0, expected 0) with a bounded 500ms timeout, then ends.
                // A hook fires termination in the pre-lock-to-lock window, so the wait must observe it and
                // unwind rather than park to the timeout.
                let module = try parseWasm(
                    bytes: wat2wasm(
                        """
                        (module
                          (memory (export "memory") (import "foo" "bar") 1 1 shared)
                          (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                          (func (export "_start")
                            i32.const 0          ;; address
                            i32.const 0          ;; expected (matches initial zero, so it would park)
                            i64.const 500000000  ;; 500ms bound; the fix must unwind before this elapses
                            memory.atomic.wait32
                            drop                 ;; reached only on the no-throw (pre-fix) path
                          )
                        )
                        """),
                    features: [.threads]
                )

                let engine = makeEngine()
                let store = Store(engine: engine)
                let bridge = try WASIBridgeToHost()
                var imports = Imports()
                bridge.link(to: &imports, store: store)
                let threadGroup = try bridge.linkThreads(to: &imports, store: store, module: module)

                // Deterministically create the terminate-before-register ordering: when the guest is between
                // parkConditionally's pre-lock validate and taking the registry lock, terminate the group.
                threadGroup.sharedMemories[0]?.parkingLot._beforeRegistryLock.withLock {
                    $0 = { threadGroup.signalTrap() }
                }

                let instance = try module.instantiate(store: store, imports: imports)
                // The fix must unwind the wait immediately via the under-lock termination check in `validate`.
                // Without that check the guest would instead park to the 500ms bound and only then throw at the
                // post-park check, so the tight elapsed bound (not merely the throw) is what guards the race fix.
                let clock = ContinuousClock()
                let started = clock.now
                #expect(throws: Trap.self) {
                    _ = try bridge.start(instance)
                }
                #expect(clock.now - started < .milliseconds(250))
                try threadGroup.joinAllThreads()
                try bridge.close()
            }
        #endif
    }

#endif
