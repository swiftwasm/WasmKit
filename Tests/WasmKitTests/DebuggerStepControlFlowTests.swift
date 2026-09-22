#if WasmDebuggingSupport

    import Testing
    import WAT
    import WasmParser

    @testable import WasmKit

    /// `br` carrying a value: the value is copied into the block result before the `br`, so the
    /// copy, not the `br`, is the first bytecode slot of the `br`'s Wasm address.
    ///
    ///   +0  i32.const 5      +2  local.set $x    +4  block $outer   +6  block $inner
    ///   +8  local.get $c     +10 br_if $inner    +12 local.get $x   +14 br $outer
    ///   +16 end              +17 i32.const 99    +20 return         +21 end
    ///   +22 i32.const 1      +24 i32.add         +25 end
    private let brWithValueWAT = """
        (module
          (func (export "_start") (result i32) (local $x i32) (local $c i32)
            i32.const 5
            local.set $x
            block $outer (result i32)
              block $inner
                local.get $c
                br_if $inner
                local.get $x
                br $outer
              end
              i32.const 99
              return
            end
            i32.const 1
            i32.add))
        """

    /// `return` of a non-parameter local: the local is copied into the result slot first.
    ///
    ///   $f:     +0 block $b  +2 local.get $c  +4 br_if $b  +6 local.get $c  +8 return
    ///   _start: +0 loop  +2 local.get $sum  +4 local.get $i  +6 call $f  +8 i32.add ...
    private let returnWithValueWAT = """
        (module
          (func $f (param $x i32) (result i32) (local $c i32)
            block $b
              local.get $c
              br_if $b
              local.get $c
              return
            end
            i32.const 99)
          (func (export "_start") (result i32) (local $i i32) (local $sum i32)
            loop $l
              local.get $sum
              local.get $i
              call $f
              i32.add
              local.set $sum
              local.get $i
              i32.const 1
              i32.add
              local.tee $i
              i32.const 3
              i32.lt_s
              br_if $l
            end
            local.get $sum))
        """

    /// `br_if` carrying a value, taken: lowered to a `brIfNot` over a landing pad of copies.
    ///
    ///   +0 i32.const 5  +2 local.set $x  +4 block $b  +6 local.get $x  +8 local.get $x
    ///   +10 br_if $b    +12 i32.const 1  +14 i32.add  +15 end  +16 i32.const 100  +19 i32.add
    private let brIfWithValueWAT = """
        (module
          (func (export "_start") (result i32) (local $x i32)
            i32.const 5
            local.set $x
            block $b (result i32)
              local.get $x
              local.get $x
              br_if $b
              i32.const 1
              i32.add
            end
            i32.const 100
            i32.add))
        """

    /// Host calls whose arguments need, or don't need, copying at the call's address.
    ///
    ///   +0 call $host0 (no args)   +2 i32.const 7   +4 call $host1 (constant arg)
    ///   +6 local.get $x  +8 local.get $x  +10 i32.add  +11 call $host1 (computed arg)
    ///   +13 i32.add  +14 end
    private let hostCallsWAT = """
        (module
          (import "env" "host0" (func $host0))
          (import "env" "host1" (func $host1 (param i32) (result i32)))
          (func (export "_start") (result i32) (local $x i32)
            call $host0
            i32.const 7
            call $host1
            local.get $x
            local.get $x
            i32.add
            call $host1
            i32.add))
        """

    /// `throw` caught by a `try_table` in the same function, three times over.
    ///
    ///   +0 loop  +2 block $h  +4 try_table  +10 throw $e  +12 end  +13 end
    ///   +14 local.get $i  +16 i32.const 1  +18 i32.add  +19 local.tee $i  +21 i32.const 3
    ///   +23 i32.lt_s  +24 br_if $l  +26 end  +27 local.get $i
    private let throwInLoopWAT = """
        (module
          (tag $e)
          (func (export "_start") (result i32) (local $i i32)
            loop $l
              block $h
                try_table (catch $e $h)
                  throw $e
                end
              end
              local.get $i
              i32.const 1
              i32.add
              local.tee $i
              i32.const 3
              i32.lt_s
              br_if $l
            end
            local.get $i))
        """

    /// A zero-argument call, so its `compilingCall` is the first slot of its address, run twice.
    ///
    ///   +0 loop  +2 call $f  +4 drop  +5 local.get $i ...  +17 br_if $l  +19 end
    private let compilingCallInLoopWAT = """
        (module
          (func $f (result i32) (i32.const 1))
          (func (export "_start") (result i32) (local $i i32)
            loop $l
              call $f
              drop
              local.get $i
              i32.const 1
              i32.add
              local.tee $i
              i32.const 2
              i32.lt_s
              br_if $l
            end
            local.get $i))
        """

    /// Calls a Wasm function of another instance, which is not compiled for debugging.
    ///
    ///   +0 i32.const 4  +2 local.set $x  +4 local.get $x  +6 call $triple  +8 i32.const 1  +10 i32.add
    private let crossInstanceCallWAT = """
        (module
          (import "other" "triple" (func $triple (param i32) (result i32)))
          (func (export "_start") (result i32) (local $x i32)
            i32.const 4
            local.set $x
            local.get $x
            call $triple
            i32.const 1
            i32.add))
        """

    private let tripleWAT = """
        (module
          (func (export "triple") (param i32) (result i32)
            (i32.mul (local.get 0) (i32.const 3))))
        """

    @Suite
    struct DebuggerStepControlFlowTests {
        private func stoppedPc(_ debugger: borrowing Debugger, sourceLocation: SourceLocation = #_sourceLocation) throws -> Int {
            guard case .stoppedAtBreakpoint(let bp) = debugger.state else {
                Issue.record("expected stoppedAtBreakpoint, got \(debugger.state)", sourceLocation: sourceLocation)
                throw CancellationError()
            }
            return bp.wasmPc
        }

        private func makeStore(_ threadingModel: EngineConfiguration.ThreadingModel) -> Store {
            Store(engine: Engine(configuration: EngineConfiguration(threadingModel: threadingModel)))
        }

        private func hostImports(_ store: Store) -> Imports {
            var imports = Imports()
            imports.define(module: "env", name: "host0", Function(store: store, parameters: [], results: []) { _, _ in [] })
            imports.define(
                module: "env", name: "host1",
                Function(store: store, parameters: [.i32], results: [.i32]) { _, args in [.i32(args[0].i32 &+ 1)] })
            return imports
        }

        /// Stops at `offset` in function `function`, steps once, and returns where the step landed.
        private func stepFrom(
            _ wat: String, function: Int, offset: Int, threadingModel: EngineConfiguration.ThreadingModel,
            imports: (Store) -> Imports = { _ in [:] },
            sourceLocation: SourceLocation = #_sourceLocation
        ) throws -> (landing: Int, module: Module) {
            let store = makeStore(threadingModel)
            let module = try parseWasm(bytes: try wat2wasm(wat))
            var debugger = try Debugger(module: module, store: store, imports: imports(store))
            let requested = module.functions[function].code.originalAddress + offset
            let bp = try debugger.enableBreakpoint(address: requested)
            #expect(bp == requested, "breakpoint resolved elsewhere; the offsets in the test are wrong", sourceLocation: sourceLocation)

            try debugger.run()
            #expect(try stoppedPc(debugger, sourceLocation: sourceLocation) == bp, sourceLocation: sourceLocation)
            try debugger.step()
            return (try stoppedPc(debugger, sourceLocation: sourceLocation), module)
        }

        @Test(arguments: testedThreadingModels)
        func stepOverBrWithValueLandsAfterTheBlock(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(brWithValueWAT, function: 0, offset: 14, threadingModel: threadingModel)
            let base = module.functions[0].code.originalAddress
            #expect(landing >= base + 22, "expected to land after `end $outer` (+22), got +\(landing - base)")
        }

        @Test(arguments: testedThreadingModels)
        func stepOverReturnWithValueLandsInTheCaller(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(returnWithValueWAT, function: 0, offset: 8, threadingModel: threadingModel)
            let startBase = module.functions[1].code.originalAddress
            #expect(landing >= startBase + 8, "expected to land in _start after the call (+8), got \(landing)")
        }

        @Test(arguments: testedThreadingModels)
        func stepOverTakenBrIfWithValueLandsAfterTheBlock(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(brIfWithValueWAT, function: 0, offset: 10, threadingModel: threadingModel)
            let base = module.functions[0].code.originalAddress
            #expect(landing >= base + 16, "expected to land after `end $b` (+16), got +\(landing - base)")
        }

        @Test(arguments: testedThreadingModels)
        func stepOverZeroArgHostCallStopsAfterIt(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(hostCallsWAT, function: 0, offset: 0, threadingModel: threadingModel, imports: hostImports)
            let base = module.functions[0].code.originalAddress
            #expect(landing > base, "expected to stop after `call $host0`, got +\(landing - base)")
        }

        @Test(arguments: testedThreadingModels)
        func stepOverHostCallWithConstantArgStopsAfterIt(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(hostCallsWAT, function: 0, offset: 4, threadingModel: threadingModel, imports: hostImports)
            let base = module.functions[0].code.originalAddress
            #expect(landing > base + 4, "expected to stop after the first `call $host1`, got +\(landing - base)")
        }

        @Test(arguments: testedThreadingModels)
        func stepOverHostCallWithComputedArgStopsAfterIt(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(hostCallsWAT, function: 0, offset: 11, threadingModel: threadingModel, imports: hostImports)
            let base = module.functions[0].code.originalAddress
            #expect(landing > base + 11, "expected to stop after the second `call $host1`, got +\(landing - base)")
        }

        @Test(arguments: testedThreadingModels)
        func stepOverThrowLandsInTheHandler(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let (landing, module) = try stepFrom(throwInLoopWAT, function: 0, offset: 10, threadingModel: threadingModel)
            let base = module.functions[0].code.originalAddress
            #expect(
                landing >= base + 14 && landing < base + 26,
                "expected to land in the handler continuation (+14..<+26), got +\(landing - base)")
        }

        /// The callee belongs to another instance, so the step runs it with the normal run loop and
        /// stops again once it returns.
        @Test(arguments: testedThreadingModels)
        func stepOverCallIntoAnotherInstanceStopsAfterIt(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let store = makeStore(threadingModel)
            let other = try parseWasm(bytes: try wat2wasm(tripleWAT)).instantiate(store: store)
            var imports = Imports()
            imports.define(module: "other", name: "triple", try #require(other.exports[function: "triple"]))

            let module = try parseWasm(bytes: try wat2wasm(crossInstanceCallWAT))
            var debugger = try Debugger(module: module, store: store, imports: imports)
            let base = module.functions[0].code.originalAddress
            let bp = try debugger.enableBreakpoint(address: base + 6)

            try debugger.run()
            #expect(try stoppedPc(debugger) == bp)
            try debugger.step()
            let landing = try stoppedPc(debugger)
            #expect(landing > base + 6, "expected to stop after `call $triple`, got +\(landing - base)")

            try debugger.run()
            guard case .entrypointReturned(let values) = debugger.state else {
                Issue.record("expected entrypointReturned, got \(debugger.state)")
                return
            }
            #expect(values == [.i32(13)])
        }

        /// Continuing from a breakpoint must hit it again when execution comes back around.
        private func continueHitsAgain(
            _ wat: String, function: Int, offset: Int, threadingModel: EngineConfiguration.ThreadingModel
        ) throws {
            let module = try parseWasm(bytes: try wat2wasm(wat))
            var debugger = try Debugger(module: module, store: makeStore(threadingModel), imports: [:])
            let bp = try debugger.enableBreakpoint(address: module.functions[function].code.originalAddress + offset)

            try debugger.run()
            #expect(try stoppedPc(debugger) == bp)
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try stoppedPc(debugger) == bp, "second iteration should stop at the same breakpoint")
        }

        @Test(arguments: testedThreadingModels)
        func continueFromReturnWithValueHitsItAgain(threadingModel: EngineConfiguration.ThreadingModel) throws {
            try continueHitsAgain(returnWithValueWAT, function: 0, offset: 8, threadingModel: threadingModel)
        }

        @Test(arguments: testedThreadingModels)
        func continueFromThrowHitsItAgain(threadingModel: EngineConfiguration.ThreadingModel) throws {
            try continueHitsAgain(throwInLoopWAT, function: 0, offset: 10, threadingModel: threadingModel)
        }

        /// `compilingCall` rewrites its own head slot the first time it runs, over the breakpoint
        /// the step runs it from; the breakpoint has to survive that.
        @Test(arguments: testedThreadingModels)
        func breakpointOnACompilingCallSurvivesAStep(threadingModel: EngineConfiguration.ThreadingModel) throws {
            let module = try parseWasm(bytes: try wat2wasm(compilingCallInLoopWAT))
            var debugger = try Debugger(module: module, store: makeStore(threadingModel), imports: [:])
            let startBase = module.functions[1].code.originalAddress
            let bp = try debugger.enableBreakpoint(address: startBase + 2)

            try debugger.run()
            #expect(try stoppedPc(debugger) == bp)
            try debugger.step()
            #expect(try stoppedPc(debugger) < startBase, "the step should land in $f")
            #expect(debugger.armedBreakpointAddresses == [bp])

            try debugger.runPreservingCurrentBreakpoint()
            #expect(try stoppedPc(debugger) == bp, "the second iteration should stop at the call again")
        }
    }

#endif
