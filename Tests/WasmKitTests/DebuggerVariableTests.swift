#if WasmDebuggingSupport

    import Testing
    import WAT
    import WasmParser

    @testable import WasmKit

    /// Locks in the `getLocal` path LLDB drives through `qWasmLocal`: after a step-in, both the
    /// callee's own locals and the parent caller frame's local must still read their correct values.
    private let localsAcrossFramesWAT = """
        (module
          (func $callee (param $a i32) (result i32) (local $x i32)
            (local.set $x (i32.const 99))
            (i32.add (local.get $a) (local.get $x)))
          (func (export "_start") (result i32) (local $c i32)
            (i32.const 7) (local.set $c)
            (call $callee (i32.const 10))))
        """

    /// A local's slot depends on the whole signature and on the width of every local before it.
    private let mixedWidthFrameWAT = """
        (module
          (func $callee (param $a i32) (param $b i64) (param $c i32) (result i32)
            (local $x v128) (local $y i32)
            (local.set $y (i32.const 55))
            (i32.add (local.get $a) (local.get $c)))
          (func (export "_start") (result i32)
            (call $callee (i32.const 11) (i64.const 22) (i32.const 33))))
        """

    @Suite
    struct DebuggerVariableTests {
        @Test
        func localValuesSurviveStepIntoAcrossFrames() throws {
            let store = Store(engine: Engine())
            let module = try parseWasm(bytes: try wat2wasm(localsAcrossFramesWAT))
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let startBase = module.functions[1].code.originalAddress
            // _start body: i32.const 7 (2) + local.set (2) + i32.const 10 (2) + call (2)
            let callSite = startBase + 6
            _ = try debugger.enableBreakpoint(address: callSite)
            try debugger.run()

            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 0) == 7, "caller local $c")

            try debugger.step()

            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 0) == 10, "callee param $a")
            #expect(try debugger.getLocal(frameIndex: 1, localIndex: 0) == 7, "caller local $c from parent frame")

            // $x is uninitialised until its local.set runs, so step past it before reading.
            try debugger.step()
            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 1) == 99, "callee local $x after local.set")
        }

        @Test
        func localValuesReadPastMixedWidthParametersAndLocals() throws {
            let store = Store(engine: Engine())
            let module = try parseWasm(bytes: try wat2wasm(mixedWidthFrameWAT))
            var debugger = try Debugger(module: module, store: store, imports: [:])

            _ = try debugger.enableBreakpoint(module: module, function: 0)
            try debugger.run()
            // $y is uninitialised until its local.set runs, so step past it before reading.
            try debugger.step()
            try debugger.step()

            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 0) == 11, "param $a")
            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 1) == 22, "param $b")
            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 2) == 33, "param $c")
            #expect(try debugger.getLocal(frameIndex: 0, localIndex: 4) == 55, "local $y past the v128 $x")
        }
    }

#endif
