#if WASMKIT_MPROTECT_BOUND_CHECKING && !os(WASI)

    import Testing
    @testable import WasmKit
    import WAT

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
    }

#endif
