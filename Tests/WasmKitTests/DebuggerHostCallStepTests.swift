#if WasmDebuggingSupport

    import Testing
    import WAT
    import WasmParser

    @testable import WasmKit

    /// Calls an imported host function. The translator emits `call` (not
    /// `compilingCall`) for any callee outside the current instance, which
    /// includes every host function, so stepping here exercises the predictor's
    /// handling of a non-wasm callee.
    private let hostCallWAT = """
        (module
          (import "env" "host" (func $host (param i32) (result i32)))
          (func (export "_start") (result i32)
            (i32.const 7)
            (call $host)))
        """

    @Suite
    struct DebuggerHostCallStepTests {
        /// Stepping over a call to a host function must not read the callee as a
        /// wasm entity. `InternalFunction` is a tagged pointer, so interpreting a
        /// `HostFunctionEntity` as a `WasmFunctionEntity` reads unrelated memory:
        /// it either trips `assumeCompiled()`'s precondition or reads past the
        /// allocation, which AddressSanitizer reports as a heap-buffer-overflow.
        @Test func steppingOverAHostCallDoesNotReadTheCalleeAsWasm() throws {
            let store = Store(engine: Engine())
            let module = try parseWasm(bytes: try wat2wasm(hostCallWAT))

            var imports = Imports()
            imports.define(
                module: "env", name: "host",
                Function(store: store, parameters: [.i32], results: [.i32]) { _, args in
                    [.i32(args[0].i32 &+ 1)]
                })

            var debugger = try Debugger(module: module, store: store, imports: imports)
            let startBase = module.functions[0].code.originalAddress

            // _start body: i32.const 7 (2 bytes) + call
            let bp = try debugger.enableBreakpoint(address: startBase + 2)
            try debugger.run()
            guard case .stoppedAtBreakpoint(let stop) = debugger.state, stop.wasmPc == bp else {
                Issue.record("expected to stop at the call site, got \(debugger.state)")
                return
            }

            // The step itself is what predicts past the host call.
            try debugger.step()
        }
    }

#endif
