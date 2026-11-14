import Testing
import WAT

@testable import WasmKit

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

        // With mprotect. The engine downgrades the request where guard pages are
        // unavailable, and a memory must be guard-page backed exactly when it did not:
        // this is what catches the C and Swift platform conditions drifting apart.
        do {
            let engine = Engine(configuration: .init(memoryBoundsChecking: .mprotect))
            #if (os(macOS) || os(iOS) || os(Linux) || os(Android)) && (arch(x86_64) || arch(arm64))
                if engine.configuration.threadingModel == .direct {
                    #expect(engine.configuration.memoryBoundsChecking == .mprotect)
                }
            #endif
            let store = Store(engine: engine)
            let module = try parseWasm(bytes: wat2wasm(wat))
            let instance = try module.instantiate(store: store)
            let memory = try #require(instance.exports[memory: "memory"])
            let reservationSize = memory.handle.withValue { $0.trapGuardReservationSize }
            #expect((reservationSize > 0) == (engine.configuration.memoryBoundsChecking == .mprotect))
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
