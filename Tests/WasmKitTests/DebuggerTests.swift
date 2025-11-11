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

    private let multiFunctionWAT = """
        (module
            (func (export "_start") (result i32) (local $x i32)
                (i32.const 42)
                (i32.const 0)
                (i32.eqz)
                (drop)
                (local.set $x)
                (local.get $x)
                (call $f)
            )

            (func $f (param $a i32) (result i32)
                (local.get $a)
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

            try debugger.run()
            let firstExpectedPc = try #require(debugger.breakpoints.keys.first)
            #expect(debugger.currentCallStack == [firstExpectedPc])

            try debugger.step()
            #expect(debugger.breakpoints.count == 1)
            let secondExpectedPc = try #require(debugger.breakpoints.keys.first)
            #expect(debugger.currentCallStack == [secondExpectedPc])

            #expect(firstExpectedPc < secondExpectedPc)

            try debugger.run()
            guard case .entrypointReturned(let values) = debugger.state, values == [.i32(42)] else {
                Issue.record("Unexpected debugger state after `debugger.run()` call")
                return
            }
        }

        /// Ensures that breakpoints and call stacks work across multiple function calls.
        @Test
        func lazyFunctionsCompilation() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(multiFunctionWAT)
            let module = try parseWasm(bytes: bytes)

            #expect(module.functions.count == 2)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let breakpointAddress = try debugger.enableBreakpoint(
                address: module.functions[1].code.originalAddress
            )
            try debugger.run()

            #expect(debugger.currentCallStack.count == 2)
            #expect(debugger.currentCallStack.first == breakpointAddress)
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
            #expect([106, 110, 111, 113, 119, 120, 122, 128, 136].binarySearch(nextClosestTo: 121) == 122)
        }

        @Test
        func localAddress() {
            let localOffset = UInt64(0xC000_0000_0000_0000)

            #expect(Debugger.LocalAddress(raw: 0, offset: localOffset) == nil)
            #expect(Debugger.LocalAddress(raw: 0xABCDEF, offset: localOffset) == nil)
            #expect(Debugger.LocalAddress(raw: 0xC000_0000_0000_ABCD, offset: localOffset) == Debugger.LocalAddress(frameIndex: 0, localIndex: 0xABCD))
            #expect(Debugger.LocalAddress(raw: 0xC000_0000_0000_ABCD, offset: localOffset) == Debugger.LocalAddress(frameIndex: 0, localIndex: 0xABCD))
        }
    }

#endif
