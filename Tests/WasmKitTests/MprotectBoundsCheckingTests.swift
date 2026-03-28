#if os(macOS) || os(Linux)

    import CWasmKitTestSupport
    import Testing
    @testable import WasmKit
    import WAT

    private let previousSignalHandlerExitCode: Int32 = 99

    @Suite
    struct MprotectBoundsCheckingTests {
        @Test(arguments: [
            EngineConfiguration.MemoryBoundsChecking.mprotect,
            EngineConfiguration.MemoryBoundsChecking.software,
        ])
        func outOfBoundsTrapsWithBothModes(mode: EngineConfiguration.MemoryBoundsChecking) throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory 1)
                        (func (export "oob") (result i32)
                            (i32.load (i32.const 0x10000))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: mode))
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store)
            let oob = try #require(instance.exports[function: "oob"])
            #expect(throws: Trap.self) { try oob() }
        }

        @Test
        func mprotectGuardPageTraps() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory (export "memory") 1)
                        (func (export "store_at") (param i32)
                            (i32.store8 (local.get 0) (i32.const 42))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store)
            let storeAt = try #require(instance.exports[function: "store_at"])

            // Last valid byte of 1 page (64KB - 1)
            try storeAt([.i32(0xFFFF)])

            // One byte past end — should trap
            #expect(throws: Trap.self) { try storeAt([.i32(0x10000)]) }
        }

        @Test
        func trapGuardReservationSizeReflectsMode() throws {
            let wat = """
                (module (memory (export "memory") 1))
                """

            // With mprotect
            do {
                let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
                let store = Store(engine: engine)
                let module = try parseWasm(bytes: wat2wasm(wat))
                let instance = try module.instantiate(store: store)
                let memory = try #require(instance.exports[memory: "memory"])
                let reservationSize = memory.handle.withValue { $0.trapGuardReservationSize }
                #expect(reservationSize > 0)
            }

            // With software
            do {
                let engine = Engine(configuration: .init(memoryBoundsChecking: .software))
                let store = Store(engine: engine)
                let module = try parseWasm(bytes: wat2wasm(wat))
                let instance = try module.instantiate(store: store)
                let memory = try #require(instance.exports[memory: "memory"])
                let reservationSize = memory.handle.withValue { $0.trapGuardReservationSize }
                #expect(reservationSize == 0)
            }
        }

        @Test
        func growThenAccessNewPages() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory (export "memory") 1)
                        (func (export "store_at") (param i32)
                            (i32.store8 (local.get 0) (i32.const 42))
                        )
                        (func (export "grow") (param i32) (result i32)
                            (memory.grow (local.get 0))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store)
            let storeAt = try #require(instance.exports[function: "store_at"])
            let grow = try #require(instance.exports[function: "grow"])

            // Page 2 (offset 0x10000) is not yet accessible — should trap
            #expect(throws: Trap.self) { try storeAt([.i32(0x10000)]) }

            // Grow by 1 page (now 2 pages total)
            let oldPages = try grow([.i32(1)])
            #expect(oldPages[0] == .i32(1))

            // Page 2 is now accessible — should succeed
            try storeAt([.i32(0x10000)])

            // Page 3 (offset 0x20000) is still not accessible — should trap
            #expect(throws: Trap.self) { try storeAt([.i32(0x20000)]) }
        }

        @Test
        func repeatedOobTrapsDoNotLeak() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory 1)
                        (func (export "oob") (result i32)
                            (i32.load (i32.const 0x10000))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store)
            let oob = try #require(instance.exports[function: "oob"])

            // 1000 repeated OOB traps — surfaces resource leaks from siglongjmp if any
            for _ in 0..<1000 {
                #expect(throws: Trap.self) { try oob() }
            }
        }

        // Exit tests require Swift 6.2 or later
        // https://github.com/swiftlang/swift-evolution/blob/main/proposals/testing/0008-exit-tests.md
        #if compiler(>=6.2)
        @Test
        func preservesPreviousSignalHandlerOutsideGuardRanges() async {
            await #expect(processExitsWith: .exitCode(previousSignalHandlerExitCode)) {
                if wasmkit_test_signal_handler_chains_to_previous_handler() == 1 {
                    wasmkit_test_exit_with_code(previousSignalHandlerExitCode)
                }
                wasmkit_test_exit_with_code(3)
            }
        }
        #endif

        @Test
        func reentrantExecutionRestoresOuterTrapGuard() throws {
            let voidSignature = WasmTypes.FunctionType(parameters: [], results: [])
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (import "env" "reenter" (func $reenter))
                        (memory 1)
                        (func (export "outer")
                            (call $reenter)
                            (drop (i32.load (i32.const 0x10000)))
                        )
                        (func (export "inner")
                            (i32.store8 (i32.const 0) (i32.const 42))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)

            var instance: Instance?
            let imports: Imports = [
                "env": [
                    "reenter": Function(store: store, type: voidSignature) { _, _ in
                        let inner = try #require(instance?.exports[function: "inner"])
                        try inner()
                        return []
                    }
                ]
            ]

            instance = try module.instantiate(store: store, imports: imports)
            let outer = try #require(instance?.exports[function: "outer"])
            #expect(throws: Trap.self) { try outer() }
        }

        @Test
        func crossInstanceCallFromMemorylessEntryStillInstallsTrapGuard() throws {
            let calleeModule = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory 1)
                        (func (export "oob")
                            (drop (i32.load (i32.const 0x10000)))
                        )
                    )
                    """))
            let callerModule = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (import "env" "oob" (func $oob))
                        (func (export "start")
                            (call $oob)
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)

            let calleeInstance = try calleeModule.instantiate(store: store)
            let importedOob = try #require(calleeInstance.exports[function: "oob"])
            let callerInstance = try callerModule.instantiate(
                store: store,
                imports: [
                    "env": ["oob": importedOob]
                ])

            let start = try #require(callerInstance.exports[function: "start"])
            #expect(throws: Trap.self) { try start() }
        }

        @Test
        func i64LoadAtPageBoundary() throws {
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory 1)
                        (func (export "load_i64") (param i32) (result i64)
                            (i64.load (local.get 0))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store)
            let loadI64 = try #require(instance.exports[function: "load_i64"])

            // Last valid 8-byte-aligned position in a 1-page memory (65536 - 8 = 0xFFF8)
            let result = try loadI64([.i32(0xFFF8)])
            #expect(result[0] == .i64(0))

            // Partial overlap with guard region — should trap
            #expect(throws: Trap.self) { try loadI64([.i32(0xFFFF)]) }
        }

        @Test
        func largeOffsetUsesCheckedPath() throws {
            // offset=0x20000 exceeds the default 64KB guard, so the translator should
            // fall back to the checked (software) path. This must still trap correctly
            // for a 1-page memory.
            let module = try parseWasm(
                bytes: wat2wasm(
                    """
                    (module
                        (memory 1)
                        (func (export "big_offset") (result i32)
                            (i32.load offset=0x20000 (i32.const 0))
                        )
                    )
                    """))
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            let store = Store(engine: engine)
            let instance = try module.instantiate(store: store)
            let bigOffset = try #require(instance.exports[function: "big_offset"])
            #expect(throws: Trap.self) { try bigOffset() }
        }
    }

#endif
