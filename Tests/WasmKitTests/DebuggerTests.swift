#if WasmDebuggingSupport

    import Testing
    import WAT
    @testable import WasmKit

    private let trivialModuleWAT = """
        (module
            (func (export "_start") (result i32) (local $x i32)
                (i32.const 42)
                (i32.const 0)
                (i32.eqz)
                (drop)
                (local.set $x)
                (local.get $x)
            )
        )
        """

    @Suite
    struct DebuggerTests {
        @Test
        func stopAtEntrypoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(trivialModuleWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            try debugger.stopAtEntrypoint()
            #expect(debugger.breakpoints.count == 1)

            #expect(try debugger.run() == nil)

            let expectedPc = try #require(debugger.breakpoints.keys.first)
            #expect(debugger.currentCallStack == [expectedPc])
        }

        @Test
        func binarySearch() throws {
            #expect([Int]().binarySearch(nextClosestTo: 42) == nil)

            var result = try #require([1].binarySearch(nextClosestTo: 8))
            #expect(result == 1)

            result = try #require([9, 15, 37].binarySearch(nextClosestTo: 28))
            #expect(result == 37)

            result = try #require([9, 15, 37].binarySearch(nextClosestTo: 0))
            #expect(result == 9)
        }
    }

#endif
