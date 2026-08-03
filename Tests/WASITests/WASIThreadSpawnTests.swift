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
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        i32.const 4
                        local.get $tid
                        i32.atomic.store
                        i32.const 8
                        local.get $arg
                        i32.atomic.store
                        ;; Signal the parent at offset 0
                        i32.const 0
                        i32.const 1
                        i32.atomic.store
                      )
                      (func (export "_start") (local $tid i32)
                        i32.const 12345
                        call $thread_spawn
                        local.set $tid
                        local.get $tid
                        i32.const 0
                        i32.le_s
                        if unreachable end
                        ;; Wait for the child's signal
                        block $done
                          loop $retry
                            i32.const 0
                            i32.atomic.load
                            i32.eqz
                            br_if $retry
                          end
                        end
                        i32.const 4
                        i32.atomic.load
                        local.get $tid
                        i32.ne
                        if unreachable end
                        i32.const 8
                        i32.atomic.load
                        i32.const 12345
                        i32.ne
                        if unreachable end
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
            // No `wasi_thread_start` export, so the child must signal a trap.
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

        // Without the MultiThread trait `memory.atomic.wait` returns immediately instead of
        // parking, so there is no blocked parent to terminate.
        #if MultiThread
            @Test func childTerminatesBlockedParent() throws {
                // The child's trap unparks the parent's wait, which then throws
                // Trap(.threadTerminated). The 1-second timeout only bounds runtime if that
                // wakeup never arrives.
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
                            i32.const 0
                            call $thread_spawn
                            drop
                            i32.const 0              ;; address
                            i32.const 0              ;; expected (matches, so it parks)
                            i64.const 1000000000     ;; safety timeout
                            memory.atomic.wait32
                            drop                     ;; unreached: the wait throws instead
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
        #endif

        // `_beforeRegistryLock` exists only on the parking lot's DEBUG blocking implementation,
        // which the MultiThread trait gates.
        #if DEBUG && MultiThread
            @Test func infiniteWaitObservesTerminationDuringRegistrationRace() throws {
                let module = try parseWasm(
                    bytes: wat2wasm(
                        """
                        (module
                          (memory (export "memory") (import "foo" "bar") 1 1 shared)
                          (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                          (func (export "_start")
                            i32.const 0          ;; address
                            i32.const 0          ;; expected (matches, so it parks)
                            i64.const 500000000  ;; bound; the wait must unwind well before this
                            memory.atomic.wait32
                            drop                 ;; unreached once the wait unwinds
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

                // Terminate the group while the guest sits between `parkConditionally`'s pre-lock
                // validate and the registry lock: the window where the signal can be missed.
                threadGroup.sharedMemories[0]?.parkingLot._beforeRegistryLock.withLock {
                    $0 = { threadGroup.signalTrap() }
                }

                let instance = try module.instantiate(store: store, imports: imports)
                // The elapsed bound, not the throw, is the assertion: without the under-lock
                // termination check in `validate` the guest parks the full 500ms and only throws
                // at the post-park check.
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
