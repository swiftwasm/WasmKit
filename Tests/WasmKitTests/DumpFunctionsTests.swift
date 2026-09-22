#if Disassembler

    import Testing
    import WAT
    import WasmParser

    @_spi(OnlyForCLI) @testable import WasmKit

    @Suite
    struct DumpFunctionsTests {
        /// The dump reads each instruction's first slot, which holds a handler address under direct
        /// threading and an opcode under token threading.
        @Test(arguments: testedThreadingModels)
        func dumpsUnderEveryThreadingModel(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module
                      (memory 1)
                      (func (export "f") (param i32) (result i32)
                        (block $b
                          (br_if $b (i32.lt_s (local.get 0) (i32.const 10)))
                          (i32.store (local.get 0) (i32.add (local.get 0) (i32.const 1))))
                        (i32.load (local.get 0))))
                    """
                )
            )
            let store = Store(engine: Engine(configuration: EngineConfiguration(threadingModel: threadingModel)))
            let instance = try module.instantiate(store: store)

            var out = ""
            try instance.dumpFunctions(to: &out, module: module)
            // Direct-only forms print under their case names (`i32StoreAcc(...)`), so match loosely.
            let listing = out.lowercased()
            #expect(listing.contains("load"))
            #expect(listing.contains("store"))
            #expect(listing.contains("return"))
        }
    }

#endif
