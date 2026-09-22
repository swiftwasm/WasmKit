#if WasmDebuggingSupport

    import Testing
    import WAT
    import WasmParser

    @testable import WasmKit

    @Suite
    struct DebuggerGlobalTests {
        @Test(arguments: testedThreadingModels)
        func getGlobalReadsInitializedValue(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let store = Store(engine: Engine(configuration: EngineConfiguration(threadingModel: threadingModel)))
            let module = try parseWasm(
                bytes: try wat2wasm(
                    """
                    (module (global $g (mut i32) (i32.const 1))
                      (func (export "_start") (result i32) (global.get $g)))
                    """))
            var debugger = try Debugger(module: module, store: store, imports: [:])
            try debugger.stopAtEntrypoint()
            try debugger.run()
            #expect(try debugger.getGlobal(index: 0) == 1)
        }
    }

#endif
