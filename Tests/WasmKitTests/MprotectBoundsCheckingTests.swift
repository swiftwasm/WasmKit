#if os(macOS) || os(Linux)

    import Testing
    @testable import WasmKit
    import WAT

    private let boundsCheckingModesUnderTest: [EngineConfiguration.MemoryBoundsChecking] =
        Engine.isAddressSanitizerEnabled ? [.software] : [.mprotect, .software]

    @Suite
    struct MprotectBoundsCheckingTests {
        @Test(arguments: boundsCheckingModesUnderTest)
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
        func trapGuardReservationSizeReflectsMode() throws {
            guard !Engine.isAddressSanitizerEnabled else { return }
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
