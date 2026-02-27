#if WasmDebuggingSupport

    import Testing
    import WAT
    import WasmParser

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

    private let manyLocalsWAT = """
        (module
            (func (export "_start") (result i32) (local $x i32)
                (i32.const 42)
                (i32.const 0)
                (i32.eqz)
                (drop)
                (local.set $x)
                (local.get $x)
                (call $f)
                (call $g)
            )

            (func $f (param $a i32) (result i32)
                (local.get $a)
            )

            (func $g (param $a i32) (result i32) (local $x i32)
                (i32.const 24)
                (local.set $x)
                (local.get $a)
            )
        )
        """

    private let factorialWAT = """
        (module
          (func (export "_start") (result i64)
            (i64.const 3)
            (call $factorial)
          )

          (func $factorial (param $arg i64) (result i64)
            (if (result i64)
              (i64.eqz (local.get $arg))
              (then (i64.const 1))
              (else
                (i64.mul
                  (local.get $arg)
                  (call $factorial
                    (i64.sub
                      (local.get $arg)
                      (i64.const 1)
                    ))))))
        )
        """

    private let loopWAT = """
        (module
          (func (export "_start") (result i32) (local $i i32)
            (local.set $i (i32.const 3))
            (block $break (loop $continue
              (local.set $i (i32.sub (local.get $i) (i32.const 1)))
              (br_if $continue (local.get $i))
            ))
            (local.get $i)
          )
        )
        """

    /// Loop with unconditional `br` back to header.
    private let brLoopWAT = """
        (module
          (func (export "_start") (result i32) (local $i i32)
            (local.set $i (i32.const 2))
            (block $break (loop $continue
              (local.set $i (i32.sub (local.get $i) (i32.const 1)))
              (br_if $break (i32.eqz (local.get $i)))
              (br $continue)
            ))
            (local.get $i)
          )
        )
        """

    /// Loop with `br_table` branching back to header.
    private let brTableLoopWAT = """
        (module
          (func (export "_start") (result i32) (local $i i32)
            (local.set $i (i32.const 2))
            (block $break (loop $continue
              (local.set $i (i32.sub (local.get $i) (i32.const 1)))
              (br_table $break $continue (local.get $i))
            ))
            (local.get $i)
          )
        )
        """

    /// Simple two-function module for testing step-into on `call`.
    private let callWAT = """
        (module
          (func (export "_start") (result i32)
            (i32.const 10)
            (call $add_one)
          )
          (func $add_one (param i32) (result i32)
            (i32.add (local.get 0) (i32.const 1))
          )
        )
        """

    /// Module with indirect call through a table.
    private let callIndirectWAT = """
        (module
          (type $i32_to_i32 (func (param i32) (result i32)))
          (func (export "_start") (result i32)
            (i32.const 10)
            (call_indirect (type $i32_to_i32) (i32.const 0))
          )
          (func $add_one (type $i32_to_i32) (param i32) (result i32)
            (i32.add (local.get 0) (i32.const 1))
          )
          (table 1 funcref)
          (elem (i32.const 0) func $add_one)
        )
        """

    /// Recursive function: each call invokes $recurse which calls itself.
    private let recursiveCallWAT = """
        (module
          (func (export "_start") (result i32)
            (call $recurse (i32.const 3))
          )
          (func $recurse (param $n i32) (result i32)
            (if (result i32) (i32.eqz (local.get $n))
              (then (local.get $n))
              (else (call $recurse (i32.sub (local.get $n) (i32.const 1))))
            )
          )
        )
        """

    /// Indirect-recursive function: $ping calls $pong indirectly, $pong calls $ping indirectly.
    private let indirectRecursiveCallWAT = """
        (module
          (type $i32_to_i32 (func (param i32) (result i32)))
          (func (export "_start") (result i32)
            (call_indirect (type $i32_to_i32) (i32.const 2) (i32.const 0))
          )
          (func $ping (type $i32_to_i32) (param i32) (result i32)
            (if (result i32) (i32.eqz (local.get 0))
              (then (i32.const 0))
              (else
                (call_indirect (type $i32_to_i32)
                  (i32.sub (local.get 0) (i32.const 1))
                  (i32.const 1)))
            )
          )
          (func $pong (type $i32_to_i32) (param i32) (result i32)
            (if (result i32) (i32.eqz (local.get 0))
              (then (i32.const 0))
              (else
                (call_indirect (type $i32_to_i32)
                  (i32.sub (local.get 0) (i32.const 1))
                  (i32.const 0)))
            )
          )
          (table 2 funcref)
          (elem (i32.const 0) func $ping $pong)
        )
        """

    /// Loop that calls a helper function on each iteration.
    private let callInLoopWAT = """
        (module
          (func (export "_start") (result i32) (local $i i32)
            (local.set $i (i32.const 3))
            (block $break (loop $continue
              (local.set $i (call $decrement (local.get $i)))
              (br_if $continue (local.get $i))
            ))
            (local.get $i)
          )
          (func $decrement (param $n i32) (result i32)
            (i32.sub (local.get $n) (i32.const 1))
          )
        )
        """

    /// Loop that calls a helper function indirectly on each iteration.
    private let callIndirectInLoopWAT = """
        (module
          (type $i32_to_i32 (func (param i32) (result i32)))
          (func (export "_start") (result i32) (local $i i32)
            (local.set $i (i32.const 3))
            (block $break (loop $continue
              (local.set $i
                (call_indirect (type $i32_to_i32) (local.get $i) (i32.const 0)))
              (br_if $continue (local.get $i))
            ))
            (local.get $i)
          )
          (func $decrement (type $i32_to_i32) (param i32) (result i32)
            (i32.sub (local.get 0) (i32.const 1))
          )
          (table 1 funcref)
          (elem (i32.const 0) func $decrement)
        )
        """

    /// Self-recursive function via call_indirect (calls itself through a table).
    private let recursiveCallIndirectSelfWAT = """
        (module
          (type $i32_to_i32 (func (param i32) (result i32)))
          (func (export "_start") (result i32)
            (call $recurse (i32.const 3))
          )
          (func $recurse (type $i32_to_i32) (param i32) (result i32)
            (if (result i32) (i32.eqz (local.get 0))
              (then (i32.const 0))
              (else
                (call_indirect (type $i32_to_i32)
                  (i32.sub (local.get 0) (i32.const 1))
                  (i32.const 0)))
            )
          )
          (table 1 funcref)
          (elem (i32.const 0) func $recurse)
        )
        """

    /// Tail-recursive countdown using `return_call`.
    private let returnCallRecursiveWAT = """
        (module
          (func (export "_start") (result i32)
            (call $countdown (i32.const 3))
          )
          (func $countdown (param i32) (result i32)
            (if (i32.eqz (local.get 0))
              (then (return (i32.const 0)))
            )
            (return_call $countdown (i32.sub (local.get 0) (i32.const 1)))
          )
        )
        """

    /// Module for testing step on `return_call` (tail call).
    private let returnCallWAT = """
        (module
          (func (export "_start") (result i32)
            (return_call $f)
          )
          (func $f (result i32)
            (i32.const 42)
          )
        )
        """

    /// Asserts the debugger is stopped at a breakpoint, returning the wasm PC.
    @discardableResult
    private func requireBreakpoint(
        _ debugger: borrowing Debugger,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Int {
        guard case .stoppedAtBreakpoint(let bp) = debugger.state else {
            try #require(Bool(false), "Expected stoppedAtBreakpoint, got \(debugger.state)", sourceLocation: sourceLocation)
            fatalError()
        }
        return bp.wasmPc
    }

    /// Asserts the debugger's entrypoint has returned, returning the result values.
    @discardableResult
    private func requireReturned(
        _ debugger: borrowing Debugger,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> [Value] {
        guard case .entrypointReturned(let values) = debugger.state else {
            try #require(Bool(false), "Expected entrypointReturned, got \(debugger.state)", sourceLocation: sourceLocation)
            fatalError()
        }
        return values
    }

    @Suite
    struct DebuggerTests {

        // MARK: - Basics

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
            let values = try requireReturned(debugger)
            #expect(values == [.i32(42)])
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
        func getLocal() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(manyLocalsWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            _ = try debugger.enableBreakpoint(
                module: module,
                function: 2,
                // i32.const 2 bytes + local.set 4 bytes
                offsetWithinFunction: 6
            )

            try debugger.run()
            let firstLocal = try debugger.getLocal(frameIndex: 0, localIndex: 0)
            #expect(firstLocal == 42)
            let secondLocal = try debugger.getLocal(frameIndex: 0, localIndex: 1)
            #expect(secondLocal == 24)
        }

        // MARK: - step()

        /// Verifies that `step` on a `br_if` that branches back to a loop header
        /// resumes inside the loop body, not at naive pc+1 (which would land after
        /// the loop).
        @Test
        func stepFollowsBrIf() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(loopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            // _start expression body layout:
            //   offset  0: i32.const 3 (2 bytes)
            //   offset  2: local.set 0 (2 bytes)
            //   offset  4: block (2 bytes)
            //   offset  6: loop (2 bytes)
            //   offset  8: local.get 0 (2 bytes)   <- loop body starts here in Wasm bytecode
            //   offset 10: i32.const 1 (2 bytes)
            //   offset 12: i32.sub (1 byte)         <- first iseq instruction of loop body
            //   offset 13: local.set 0 (2 bytes)
            //   offset 15: local.get 0 (2 bytes)
            //   offset 17: br_if 0 (2 bytes)        <- breakpoint here
            //   offset 19: end (loop/block)
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 17)
            let loopEndAddress = base + 19

            // First iteration: $i starts at 3, decremented to 2. br_if condition is
            // nonzero, so the branch back to $continue is taken.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Stepping from br_if (with a taken branch) should land inside the loop
            // body, not at or past the loop end.
            try debugger.step()
            let wasmPc = try requireBreakpoint(debugger)

            #expect(
                wasmPc >= base + 8 && wasmPc < loopEndAddress,
                "step on a taken br_if should resume inside the loop body (offset 8..<19), got offset \(wasmPc - base)"
            )
        }

        /// Verifies that `step` on an unconditional `br` back to a loop header
        /// resumes inside the loop body, not past the loop.
        @Test
        func stepFollowsBr() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(brLoopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            // _start expression body layout:
            //   offset  0: i32.const 2       (2 bytes)
            //   offset  2: local.set 0       (2 bytes)
            //   offset  4: block $break      (2 bytes)
            //   offset  6: loop $continue    (2 bytes)
            //   offset  8: local.get 0       (2 bytes)
            //   offset 10: i32.const 1       (2 bytes)
            //   offset 12: i32.sub           (1 byte)
            //   offset 13: local.set 0       (2 bytes)
            //   offset 15: local.get 0       (2 bytes)
            //   offset 17: i32.eqz           (1 byte)
            //   offset 18: br_if 1           (2 bytes)   $break
            //   offset 20: br 0              (2 bytes)   $continue <- breakpoint
            //   offset 22: end (loop)        (1 byte)
            //   offset 23: end (block)       (1 byte)
            //   offset 24: local.get 0       (2 bytes)
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 20)

            // First iteration: $i=2, decremented to 1, eqz is false,
            // br_if not taken, br $continue is reached.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            try debugger.step()
            let wasmPc = try requireBreakpoint(debugger)

            #expect(
                wasmPc >= base + 8 && wasmPc < base + 22,
                "step on br $continue should resume inside the loop body (offset 8..<22), got offset \(wasmPc - base)"
            )
        }

        /// Verifies that `step` on a `br_table` that branches back to a loop header
        /// resumes inside the loop body.
        @Test
        func stepFollowsBrTable() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(brTableLoopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            // _start expression body layout:
            //   offset  0: i32.const 2       (2 bytes)
            //   offset  2: local.set 0       (2 bytes)
            //   offset  4: block $break      (2 bytes)
            //   offset  6: loop $continue    (2 bytes)
            //   offset  8: local.get 0       (2 bytes)
            //   offset 10: i32.const 1       (2 bytes)
            //   offset 12: i32.sub           (1 byte)
            //   offset 13: local.set 0       (2 bytes)
            //   offset 15: local.get 0       (2 bytes)
            //   offset 17: br_table          (4 bytes: 0x0E, count=1, depth 1, depth 0)
            //   offset 21: end (loop)        (1 byte)
            //   offset 22: end (block)       (1 byte)
            //   offset 23: local.get 0       (2 bytes)
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 17)

            // First iteration: $i=2, decremented to 1. br_table index=1,
            // which is >= count(1), so default target ($continue) is taken.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            try debugger.step()
            let wasmPc = try requireBreakpoint(debugger)

            #expect(
                wasmPc >= base + 8 && wasmPc < base + 21,
                "step on br_table should resume inside the loop body (offset 8..<21), got offset \(wasmPc - base)"
            )
        }

        /// Verifies that `step` on a `call` instruction correctly steps over the call
        /// and stops at the next instruction in the caller.
        @Test
        func stepStepsOverCall() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(callWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let startBase = module.functions[0].code.originalAddress
            // _start body: i32.const 10 (2) + call 1 (2) + end (1)
            let breakpointAddress = try debugger.enableBreakpoint(address: startBase + 2)

            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            try debugger.step()
            let wasmPc = try requireBreakpoint(debugger)

            #expect(
                wasmPc > breakpointAddress,
                "step on call should advance past the call site (offset 2), got offset \(wasmPc - startBase)"
            )
        }

        /// Verifies that `step` on a `call_indirect` instruction correctly steps over
        /// the indirect call and stops at the next instruction in the caller.
        @Test
        func stepStepsOverCallIndirect() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(callIndirectWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let startBase = module.functions[0].code.originalAddress
            // _start body: i32.const 10 (2) + i32.const 0 (2) + call_indirect (3) + end (1)
            let breakpointAddress = try debugger.enableBreakpoint(address: startBase + 4)

            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            try debugger.step()
            let wasmPc = try requireBreakpoint(debugger)

            #expect(
                wasmPc > breakpointAddress,
                "step on call_indirect should advance past the call site (offset 4), got offset \(wasmPc - startBase)"
            )
        }

        /// Verifies that `step` on a `return_call` (tail call) lands at the
        /// tail-called function's first instruction, not running to completion.
        @Test
        func stepFollowsReturnCall() throws {
            let features: WasmFeatureSet = [.tailCall]
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(returnCallWAT, features: features)
            let module = try parseWasm(bytes: bytes, features: features)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let startBase = module.functions[0].code.originalAddress
            let startEnd = module.functions[0].code.expression.endIndex

            // _start body: return_call 1 (2 bytes) + end (1 byte)
            try debugger.stopAtEntrypoint()

            try debugger.run()
            try requireBreakpoint(debugger)

            try debugger.step()
            let wasmPc = try requireBreakpoint(debugger)

            // Step should land outside the caller's code range (inside the callee).
            #expect(
                wasmPc < startBase || wasmPc >= startEnd,
                "step on return_call should leave the caller (range \(startBase)..<\(startEnd)), got \(wasmPc)"
            )
        }

        /// Verifies that stepping over a `call` to a recursive function works:
        /// step completes (lands at a breakpoint) rather than running to completion.
        @Test
        func stepThroughRecursiveCall() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(recursiveCallWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let startBase = module.functions[0].code.originalAddress
            // _start body: i32.const 3 (2) + call $recurse (2) + end (1)
            let breakpointAddress = try debugger.enableBreakpoint(address: startBase + 2)

            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            try debugger.step()
            try requireBreakpoint(debugger)

            // Continue to completion to verify the recursion produces the right result.
            try debugger.run()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// Verifies that stepping through indirect-recursive calls ($ping <-> $pong
        /// via call_indirect) works correctly.
        @Test
        func stepThroughIndirectRecursiveCall() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(indirectRecursiveCallWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            // _start body: i32.const 2 (2) + i32.const 0 (2) + call_indirect (3) + end (1)
            let startBase = module.functions[0].code.originalAddress
            let breakpointAddress = try debugger.enableBreakpoint(address: startBase + 4)

            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            try debugger.step()
            try requireBreakpoint(debugger)

            // Continue to completion to verify the module produces the right result.
            try debugger.run()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        // MARK: - runPreservingCurrentBreakpoint()

        @Test
        func runPreservingFactorialBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(factorialWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let breakpointAddress = try debugger.enableBreakpoint(
                module: module,
                function: 1,
                // if 1 byte + i64.const 2 bytes + i64.eqz 1 byte + local.set 4 bytes
                offsetWithinFunction: 8
            )

            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)
            var local = try debugger.getLocal(frameIndex: 0, localIndex: 0)
            #expect(local == 3)
            try debugger.runPreservingCurrentBreakpoint()

            #expect(try requireBreakpoint(debugger) == breakpointAddress)
            local = try debugger.getLocal(frameIndex: 0, localIndex: 0)
            #expect(local == 2)
            try debugger.runPreservingCurrentBreakpoint()

            #expect(try requireBreakpoint(debugger) == breakpointAddress)
            local = try debugger.getLocal(frameIndex: 0, localIndex: 0)
            #expect(local == 1)
            try debugger.runPreservingCurrentBreakpoint()

            let values = try requireReturned(debugger)
            #expect(values == [.i64(6)])
        }

        /// `runPreservingCurrentBreakpoint` on a `br_if` inside a loop re-hits the
        /// breakpoint on each iteration. The loop runs 3 iterations ($i: 3->2->1->0).
        @Test
        func runPreservingBrIfBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(loopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 17)  // br_if

            // First hit: $i decremented from 3 to 2.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Second hit: $i decremented from 2 to 1.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Third hit: $i decremented from 1 to 0. br_if not taken, loop exits.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // After the third hit, $i is 0. Resuming runs to completion.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a `br` inside a loop. With $i starting
        /// at 2, the br breakpoint is hit once, then br_if $break exits the loop.
        @Test
        func runPreservingBrBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(brLoopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 20)  // br $continue

            // First hit: $i=2 -> 1, eqz false, br_if not taken, br reached.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // After resuming, $i=1 -> 0, eqz true, br_if $break is taken.
            // The br $continue is never reached, so execution completes.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a `br_table` inside a loop.
        /// First hit: $i=1 (default -> $continue). Second hit: $i=0 (target[0] -> $break).
        @Test
        func runPreservingBrTableBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(brTableLoopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 17)  // br_table

            // First hit: $i=2 -> 1. br_table index=1, default -> $continue.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Second hit: $i=1 -> 0. br_table index=0, target[0] -> $break.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // br_table took $break, loop exits.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a `call` inside a loop. The breakpoint
        /// on `call $decrement` is re-hit on each of the 3 iterations.
        @Test
        func runPreservingCallBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(callInLoopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            // _start body layout:
            //   offset  0: i32.const 3       (2)
            //   offset  2: local.set $i      (2)
            //   offset  4: block $break      (2)
            //   offset  6: loop $continue    (2)
            //   offset  8: local.get $i      (2)
            //   offset 10: call $decrement   (2) <- breakpoint
            //   offset 12: local.set $i      (2)
            //   offset 14: local.get $i      (2)
            //   offset 16: br_if $continue   (2)
            //   offset 18: end (loop)
            //   offset 19: end (block)
            //   offset 20: local.get $i      (2)
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 10)  // call $decrement

            // Hit 1: calling $decrement with $i=3.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 2: $i decremented to 2, loop continued.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 3: $i decremented to 1, loop continued.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // $i becomes 0, br_if not taken, loop exits.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a `call_indirect` inside a loop.
        /// The breakpoint on `call_indirect` is re-hit on each of the 3 iterations.
        @Test
        func runPreservingCallIndirectInLoopBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(callIndirectInLoopWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let base = module.functions[0].code.originalAddress
            // _start body layout:
            //   offset  0: i32.const 3            (2)
            //   offset  2: local.set $i           (2)
            //   offset  4: block $break           (2)
            //   offset  6: loop $continue         (2)
            //   offset  8: local.get $i           (2)
            //   offset 10: i32.const 0            (2)   [table index]
            //   offset 12: call_indirect type=0   (3)   <- breakpoint
            //   offset 15: local.set $i           (2)
            //   offset 17: local.get $i           (2)
            //   offset 19: br_if $continue        (2)
            //   offset 21: end (loop)
            //   offset 22: end (block)
            //   offset 23: local.get $i           (2)
            let breakpointAddress = try debugger.enableBreakpoint(address: base + 12)  // call_indirect

            // Hit 1: calling $decrement with $i=3.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 2: $i decremented to 2, loop continued.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 3: $i decremented to 1, loop continued.
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // $i becomes 0, br_if not taken, loop exits.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a `call` inside a recursive function.
        /// The breakpoint on `call $recurse` is re-hit for each recursive invocation
        /// ($recurse(3) -> $recurse(2) -> $recurse(1)), then $recurse(0) takes the
        /// base case and returns.
        @Test
        func runPreservingRecursiveCallBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(recursiveCallWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let recurseBase = module.functions[1].code.originalAddress
            // $recurse body layout:
            //   offset  0: local.get $n          (2)
            //   offset  2: i32.eqz              (1)
            //   offset  3: if (result i32)       (2)
            //   offset  5: local.get $n          (2)   [then]
            //   offset  7: else                  (1)
            //   offset  8: local.get $n          (2)   [else]
            //   offset 10: i32.const 1           (2)
            //   offset 12: i32.sub              (1)
            //   offset 13: call $recurse         (2)   <- breakpoint
            //   offset 15: end                   (1)
            let breakpointAddress = try debugger.enableBreakpoint(address: recurseBase + 13)  // call $recurse

            // Hit 1: $recurse(3) about to call $recurse(2).
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 2: $recurse(2) about to call $recurse(1).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 3: $recurse(1) about to call $recurse(0).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // $recurse(0) takes the base case, returns up the stack.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a `call_indirect` inside a self-recursive
        /// function. The breakpoint is re-hit for each recursive invocation through the table.
        @Test
        func runPreservingRecursiveCallIndirectBreakpoint() throws {
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(recursiveCallIndirectSelfWAT)
            let module = try parseWasm(bytes: bytes)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let recurseBase = module.functions[1].code.originalAddress
            // $recurse body layout:
            //   offset  0: local.get 0           (2)
            //   offset  2: i32.eqz              (1)
            //   offset  3: if (result i32)       (2)
            //   offset  5: i32.const 0           (2)   [then]
            //   offset  7: else                  (1)
            //   offset  8: local.get 0           (2)   [else]
            //   offset 10: i32.const 1           (2)
            //   offset 12: i32.sub              (1)
            //   offset 13: i32.const 0           (2)   [table index]
            //   offset 15: call_indirect type=0  (3)   <- breakpoint
            //   offset 18: end                   (1)
            let breakpointAddress = try debugger.enableBreakpoint(address: recurseBase + 15)  // call_indirect

            // Hit 1: $recurse(3) about to call_indirect $recurse(2).
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 2: $recurse(2) about to call_indirect $recurse(1).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 3: $recurse(1) about to call_indirect $recurse(0).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // $recurse(0) takes the base case, returns up the stack.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }

        /// `runPreservingCurrentBreakpoint` on a tail-recursive function using
        /// `return_call`. The breakpoint at $countdown's entry is re-hit for each
        /// tail call: _start calls $countdown(3), which tail-calls $countdown(2),
        /// $countdown(1), then $countdown(0) returns.
        @Test
        func runPreservingRecursiveReturnCallBreakpoint() throws {
            let features: WasmFeatureSet = [.tailCall]
            let store = Store(engine: Engine())
            let bytes = try wat2wasm(returnCallRecursiveWAT, features: features)
            let module = try parseWasm(bytes: bytes, features: features)
            var debugger = try Debugger(module: module, store: store, imports: [:])

            let countdownBase = module.functions[1].code.originalAddress
            let breakpointAddress = try debugger.enableBreakpoint(address: countdownBase)

            // Hit 1: $countdown(3) entered from _start's call.
            try debugger.run()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 2: return_call to $countdown(2).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 3: return_call to $countdown(1).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // Hit 4: return_call to $countdown(0).
            try debugger.runPreservingCurrentBreakpoint()
            #expect(try requireBreakpoint(debugger) == breakpointAddress)

            // $countdown(0) takes the base case, returns.
            try debugger.runPreservingCurrentBreakpoint()
            let values = try requireReturned(debugger)
            #expect(values == [.i32(0)])
        }
    }

#endif
