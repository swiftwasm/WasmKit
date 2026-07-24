#if os(macOS) || os(Linux)

    import Testing
    import WAT
    import WasmKitWASI

    @testable import WasmKit

    private let sharedMemorySupported = SharedMemoryStorage.isSupported(
        engineConfiguration: Engine(configuration: .init(features: [.threads])).configuration,
        isMemory64: false
    )

    @Suite(.enabled(if: sharedMemorySupported)) struct WASIThreadSafetyTests {
        private func makeEngine() -> Engine {
            Engine(configuration: .init(features: [.threads]))
        }

        @Test func childFdWrite() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func $fd_write (import "wasi_snapshot_preview1" "fd_write")
                        (param i32 i32 i32 i32) (result i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        ;; IOVec at 16: {buf_ptr=32, buf_len=2}
                        (i32.store (i32.const 16) (i32.const 32))
                        (i32.store (i32.const 20) (i32.const 2))
                        ;; "OK" at 32
                        (i32.store8 (i32.const 32) (i32.const 79))
                        (i32.store8 (i32.const 33) (i32.const 75))
                        ;; fd_write(stdout=1, iovs=16, iovs_len=1, nwritten=8)
                        (i32.atomic.store (i32.const 4)
                          (call $fd_write (i32.const 1) (i32.const 16) (i32.const 1) (i32.const 8)))
                        ;; Signal parent
                        (i32.atomic.store (i32.const 0) (i32.const 1))
                      )
                      (func (export "_start") (local $tid i32)
                        (local.set $tid (call $thread_spawn (i32.const 0)))
                        (if (i32.le_s (local.get $tid) (i32.const 0)) (then (unreachable)))
                        (block $done (loop $retry
                          (br_if $retry (i32.eqz (i32.atomic.load (i32.const 0))))
                        ))
                        (if (i32.ne (i32.atomic.load (i32.const 4)) (i32.const 0))
                          (then (call $proc_exit (i32.const 1)) (unreachable)))
                        (if (i32.ne (i32.atomic.load (i32.const 8)) (i32.const 2))
                          (then (call $proc_exit (i32.const 2)) (unreachable)))
                        (call $proc_exit (i32.const 0))
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
            let threadGroup = try bridge.linkThreads(to: &imports, store: store, module: module)
            let instance = try module.instantiate(store: store, imports: imports)
            let exitCode = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(exitCode == 0)
        }

        @Test func childArgsGet() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func $args_sizes_get (import "wasi_snapshot_preview1" "args_sizes_get")
                        (param i32 i32) (result i32))
                      (func $args_get (import "wasi_snapshot_preview1" "args_get")
                        (param i32 i32) (result i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        (if (call $args_sizes_get (i32.const 64) (i32.const 68))
                          (then
                            (i32.atomic.store (i32.const 4) (i32.const 10))
                            (i32.atomic.store (i32.const 0) (i32.const 1))
                            return))
                        (if (i32.ne (i32.load (i32.const 64)) (i32.const 2))
                          (then
                            (i32.atomic.store (i32.const 4) (i32.const 20))
                            (i32.atomic.store (i32.const 0) (i32.const 1))
                            return))
                        (if (call $args_get (i32.const 128) (i32.const 256))
                          (then
                            (i32.atomic.store (i32.const 4) (i32.const 30))
                            (i32.atomic.store (i32.const 0) (i32.const 1))
                            return))
                        ;; argv[1] at offset 132; load first byte of that string
                        (i32.atomic.store (i32.const 4)
                          (i32.load8_u (i32.load (i32.const 132))))
                        (i32.atomic.store (i32.const 0) (i32.const 1))
                      )
                      (func (export "_start") (local $tid i32)
                        (local.set $tid (call $thread_spawn (i32.const 0)))
                        (if (i32.le_s (local.get $tid) (i32.const 0)) (then (unreachable)))
                        (block $done (loop $retry
                          (br_if $retry (i32.eqz (i32.atomic.load (i32.const 0))))
                        ))
                        ;; 'h' = 104
                        (if (i32.ne (i32.atomic.load (i32.const 4)) (i32.const 104))
                          (then (call $proc_exit (i32.const 1)) (unreachable)))
                        (call $proc_exit (i32.const 0))
                        unreachable
                      )
                    )
                    """),
                features: [.threads]
            )

            let engine = makeEngine()
            let store = Store(engine: engine)
            let bridge = try WASIBridgeToHost(args: ["program", "hello"])
            var imports = Imports()
            bridge.link(to: &imports, store: store)
            let threadGroup = try bridge.linkThreads(to: &imports, store: store, module: module)
            let instance = try module.instantiate(store: store, imports: imports)
            let exitCode = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(exitCode == 0)
        }

        @Test func childRandomGet() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func $random_get (import "wasi_snapshot_preview1" "random_get")
                        (param i32 i32) (result i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        (local $i i32)
                        (local $xor i32)
                        (i32.atomic.store (i32.const 4)
                          (call $random_get (i32.const 256) (i32.const 8)))
                        (local.set $xor (i32.const 0))
                        (local.set $i (i32.const 0))
                        (block $break (loop $loop
                          (local.set $xor
                            (i32.or (local.get $xor)
                              (i32.load8_u (i32.add (i32.const 256) (local.get $i)))))
                          (local.set $i (i32.add (local.get $i) (i32.const 1)))
                          (br_if $loop (i32.lt_u (local.get $i) (i32.const 8)))
                        ))
                        (i32.atomic.store (i32.const 8)
                          (i32.ne (local.get $xor) (i32.const 0)))
                        (i32.atomic.store (i32.const 0) (i32.const 1))
                      )
                      (func (export "_start") (local $tid i32)
                        (local.set $tid (call $thread_spawn (i32.const 0)))
                        (if (i32.le_s (local.get $tid) (i32.const 0)) (then (unreachable)))
                        (block $done (loop $retry
                          (br_if $retry (i32.eqz (i32.atomic.load (i32.const 0))))
                        ))
                        (if (i32.ne (i32.atomic.load (i32.const 4)) (i32.const 0))
                          (then (call $proc_exit (i32.const 1)) (unreachable)))
                        (if (i32.eqz (i32.atomic.load (i32.const 8)))
                          (then (call $proc_exit (i32.const 2)) (unreachable)))
                        (call $proc_exit (i32.const 0))
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
            let threadGroup = try bridge.linkThreads(to: &imports, store: store, module: module)
            let instance = try module.instantiate(store: store, imports: imports)
            let exitCode = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(exitCode == 0)
        }

        @Test func childClockTimeGet() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func $clock_time_get (import "wasi_snapshot_preview1" "clock_time_get")
                        (param i32 i64 i32) (result i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        ;; MONOTONIC=1, precision=0, result at 256 (8-byte aligned)
                        (i32.atomic.store (i32.const 4)
                          (call $clock_time_get (i32.const 1) (i64.const 0) (i32.const 256)))
                        (i32.atomic.store (i32.const 8)
                          (i64.ne (i64.load (i32.const 256)) (i64.const 0)))
                        (i32.atomic.store (i32.const 0) (i32.const 1))
                      )
                      (func (export "_start") (local $tid i32)
                        (local.set $tid (call $thread_spawn (i32.const 0)))
                        (if (i32.le_s (local.get $tid) (i32.const 0)) (then (unreachable)))
                        (block $done (loop $retry
                          (br_if $retry (i32.eqz (i32.atomic.load (i32.const 0))))
                        ))
                        (if (i32.ne (i32.atomic.load (i32.const 4)) (i32.const 0))
                          (then (call $proc_exit (i32.const 1)) (unreachable)))
                        (if (i32.eqz (i32.atomic.load (i32.const 8)))
                          (then (call $proc_exit (i32.const 2)) (unreachable)))
                        (call $proc_exit (i32.const 0))
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
            let threadGroup = try bridge.linkThreads(to: &imports, store: store, module: module)
            let instance = try module.instantiate(store: store, imports: imports)
            let exitCode = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(exitCode == 0)
        }

        @Test func concurrentChildFdWrite() throws {
            // Spawn 4 children that all call fd_write concurrently,
            // stressing the mutex-protected FdTable under contention.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                      (memory (export "memory") (import "foo" "bar") 1 1 shared)
                      (func $thread_spawn (import "wasi" "thread-spawn") (param i32) (result i32))
                      (func $proc_exit (import "wasi_snapshot_preview1" "proc_exit") (param i32))
                      (func $fd_write (import "wasi_snapshot_preview1" "fd_write")
                        (param i32 i32 i32 i32) (result i32))
                      (func (export "wasi_thread_start") (param $tid i32) (param $arg i32)
                        (local $base i32)
                        ;; Each child gets its own memory region: base = 256 + arg*64
                        (local.set $base (i32.add (i32.const 256)
                          (i32.mul (local.get $arg) (i32.const 64))))
                        ;; IOVec at base: {buf_ptr = base+16, buf_len = 2}
                        (i32.store (local.get $base)
                          (i32.add (local.get $base) (i32.const 16)))
                        (i32.store (i32.add (local.get $base) (i32.const 4))
                          (i32.const 2))
                        ;; "OK" at base+16
                        (i32.store8 (i32.add (local.get $base) (i32.const 16))
                          (i32.const 79))
                        (i32.store8 (i32.add (local.get $base) (i32.const 17))
                          (i32.const 75))
                        ;; fd_write(stdout=1, iovs=base, iovs_len=1, nwritten=base+32)
                        ;; Store errno at 16 + arg*4
                        (i32.atomic.store
                          (i32.add (i32.const 16) (i32.mul (local.get $arg) (i32.const 4)))
                          (call $fd_write (i32.const 1) (local.get $base) (i32.const 1)
                            (i32.add (local.get $base) (i32.const 32))))
                        ;; Atomically increment completion counter at offset 0
                        (drop (i32.atomic.rmw.add (i32.const 0) (i32.const 1)))
                      )
                      (func (export "_start") (local $i i32)
                        ;; Spawn 4 children with args 0, 1, 2, 3
                        (local.set $i (i32.const 0))
                        (loop $spawn
                          (if (i32.le_s (call $thread_spawn (local.get $i)) (i32.const 0))
                            (then (unreachable)))
                          (local.set $i (i32.add (local.get $i) (i32.const 1)))
                          (br_if $spawn (i32.lt_u (local.get $i) (i32.const 4)))
                        )
                        ;; Spin-wait for all 4 children
                        (loop $retry
                          (br_if $retry
                            (i32.lt_u (i32.atomic.load (i32.const 0)) (i32.const 4)))
                        )
                        ;; Check all fd_write errnos are 0
                        (local.set $i (i32.const 0))
                        (loop $check
                          (if (i32.ne
                                (i32.atomic.load
                                  (i32.add (i32.const 16)
                                    (i32.mul (local.get $i) (i32.const 4))))
                                (i32.const 0))
                            (then (call $proc_exit (i32.const 1)) (unreachable)))
                          (local.set $i (i32.add (local.get $i) (i32.const 1)))
                          (br_if $check (i32.lt_u (local.get $i) (i32.const 4)))
                        )
                        (call $proc_exit (i32.const 0))
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
            let threadGroup = try bridge.linkThreads(to: &imports, store: store, module: module)
            let instance = try module.instantiate(store: store, imports: imports)
            let exitCode = try bridge.start(instance)
            try threadGroup.joinAllThreads()
            try bridge.close()
            #expect(exitCode == 0)
        }
    }

#endif
