#if WasmDebuggingSupport

    import Testing
    import WAT
    import WasmParser

    @testable import WasmKit

    /// Callee starts with an elided `local.get`, so its resolved entry differs from originalAddress.
    private let stepInCallWAT = """
        (module
          (func $callee (param i32) (result i32) (local $x i32)
            (local.get $x) (drop)
            (i32.add (local.get 0) (i32.const 1)))
          (func (export "_start") (result i32)
            (i32.const 10)
            (call $callee)))
        """

    private let stepInReturnCallWAT = """
        (module
          (func $callee (param i32) (result i32) (local $x i32)
            (local.get $x) (drop)
            (i32.add (local.get 0) (local.get 0)))
          (func (export "_start") (result i32)
            (i32.const 21)
            (return_call $callee)))
        """

    private let stepInCallIndirectWAT = """
        (module
          (type $t (func (param i32) (result i32)))
          (func $callee (type $t) (param i32) (result i32) (local $x i32)
            (local.get $x) (drop)
            (i32.add (local.get 0) (i32.const 1)))
          (func (export "_start") (result i32)
            (i32.const 10)
            (call_indirect (type $t) (i32.const 0)))
          (table 1 funcref)
          (elem (i32.const 0) func $callee))
        """

    /// Zero-argument call: no prep slots, so the breakpoint sits directly on the call head and the
    /// existing control-head path handles it. Guards that the elided-callee cold path still steps in
    /// (findWasm on the callee's iseq base is not the step-over fallback).
    private let stepInZeroArgCallWAT = """
        (module
          (func $callee (result i32) (local $x i32)
            (local.get $x) (drop)
            (i32.const 42))
          (func (export "_start") (result i32)
            (call $callee)))
        """

    @Suite
    struct DebuggerStepIntoTests {
        private func requireStopped(_ debugger: borrowing Debugger) throws -> Int {
            guard case .stoppedAtBreakpoint(let bp) = debugger.state else {
                Issue.record("expected stoppedAtBreakpoint, got \(debugger.state)")
                throw CancellationError()
            }
            return bp.wasmPc
        }

        /// Steps at the call site and asserts the landing is inside the callee. The callee is defined
        /// before `_start`, so its whole body is below `startBase`; a step-over would stay at or above
        /// the call site. The callee is deliberately NOT compiled beforehand, exercising the cold path
        /// where the predictor must compile it and its elided first instruction has no reverse mapping.
        private func assertStepsInto(_ wat: String, callOffset: Int, features: WasmFeatureSet = []) throws {
            let store = Store(engine: Engine())
            let module = try parseWasm(bytes: try wat2wasm(wat, features: features), features: features)
            var debugger = try Debugger(module: module, store: store, imports: [:])
            let calleeOrigin = module.functions[0].code.originalAddress
            let startBase = module.functions[1].code.originalAddress
            let bp = try debugger.enableBreakpoint(address: startBase + callOffset)

            try debugger.run()
            #expect(try requireStopped(debugger) == bp)

            try debugger.step()
            let landing = try requireStopped(debugger)
            #expect(
                landing >= calleeOrigin && landing < startBase,
                "step should land inside the callee [\(calleeOrigin), \(startBase)), got \(landing)")
            #expect(landing != bp + 1, "must not be a step-over")
        }

        @Test func stepIntoCall() throws {
            // _start body: i32.const 10 (2) + call (2) + end
            try assertStepsInto(stepInCallWAT, callOffset: 2)
        }

        @Test func stepIntoReturnCall() throws {
            // _start body: i32.const 21 (2) + return_call (2) + end
            try assertStepsInto(stepInReturnCallWAT, callOffset: 2, features: [.tailCall])
        }

        @Test func stepIntoCallIndirect() throws {
            // _start body: i32.const 10 (2) + i32.const 0 (2) + call_indirect (3) + end
            try assertStepsInto(stepInCallIndirectWAT, callOffset: 4)
        }

        @Test func stepIntoZeroArgCall() throws {
            // _start body: call (2) + end; the call head is the first (only) slot for its wasm address.
            try assertStepsInto(stepInZeroArgCallWAT, callOffset: 0)
        }
    }

#endif
