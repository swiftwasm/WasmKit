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
        func breakpoints() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(trivialModuleWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            try debugger.stopAtEntrypoint()
            #expect(debugger.breakpoints.count == 1)

            #expect(try debugger.run() == nil)

            var expectedPc = try #require(debugger.breakpoints.keys.first)
            #expect(debugger.currentCallStack == [expectedPc])

            try debugger.step()
            #expect(try debugger.breakpoints.count == 1)
            expectedPc = try #require(debugger.breakpoints.keys.first)
            #expect(debugger.currentCallStack == [expectedPc])

            #expect(try debugger.run() == [.i32(42)])
        }

        @Test
        func binarySearch() throws {
            #expect([Int]().binarySearch(nextClosestTo: 42) == nil)

            #expect([1].binarySearch(nextClosestTo: 1) == 1)
            #expect([1].binarySearch(nextClosestTo: 8) == nil)

            #expect([9, 15, 37].binarySearch(nextClosestTo: 28) == 37)
            #expect([9, 15, 37].binarySearch(nextClosestTo: 0) == 9)
            #expect([9, 15, 37].binarySearch(nextClosestTo: 42) == nil)

            #expect([106, 110, 111].binarySearch(nextClosestTo: 107) == 110)
        }
    }

#endif
