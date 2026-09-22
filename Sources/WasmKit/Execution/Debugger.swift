#if WasmDebuggingSupport

    /// Debugger state owner, driven by a debugger host. This implementation has no knowledge of the exact
    /// debugger protocol, which allows any protocol implementation or direct API users to be layered on top if needed.
    package struct Debugger: ~Copyable {
        package struct BreakpointState {
            let iseq: Execution.Breakpoint
            /// Wasm address the engine stopped on.
            package let wasmPc: Int
            /// Wasm address reported for this stop.
            package var reportedPc: Int
        }

        package enum State {
            case instantiated
            case stoppedAtBreakpoint(BreakpointState)
            case trapped(TrapState)
            case entrypointReturned([Value])
            case exited(status: UInt32)
        }

        package struct TrapState {
            package let description: String
            /// Wasm addresses of the frames on the call stack, innermost first.
            package let callStack: [Int]
        }

        package enum Error: Swift.Error, @unchecked Sendable {
            case entrypointFunctionNotFound
            case unknownCurrentFunctionAtBreakpoint(UnsafeMutablePointer<UInt64>)
            case noInstructionMappingAvailable(Int)
            case noReverseInstructionMappingAvailable(UnsafeMutablePointer<UInt64>)
            case stackFrameIndexOOB(UInt)
            case stackLocalIndexOOB(UInt)
            case globalIndexOOB(UInt)
            case globalUnsupportedType(UInt)
            case notStoppedAtBreakpoint
            case linearMemoryNotInitialized
            case linearMemoryOOB(address: UInt, length: UInt)
        }

        private let valueStack: Sp
        private var execution: Execution
        private let store: Store

        /// Parsed in-memory representation of a Wasm module instantiated for debugging.
        private let module: Module

        /// Instance of parsed Wasm ``module``.
        private let instance: Instance

        /// Reference to the entrypoint function of the currently debugged module, for use in ``stopAtEntrypoint``.
        /// Currently assumed to be the WASI command `_start` entrypoint.
        private let entrypointFunction: Function

        /// Threading model of the Wasm engine configuration, cached for a potentially hot path.
        private let threadingModel: EngineConfiguration.ThreadingModel

        /// Breakpoints currently present in the bytecode, keyed by resolved Wasm address. The value
        /// carries both what to restore and where, so taking one down never has to resolve again.
        private var armedBreakpoints = [Int: (iseq: Pc, originalHeadSlot: CodeSlot)]()

        /// Breakpoints requested by the host, keyed by resolved address. Multiple requests may share a slot.
        private var hostBreakpoints = [Int: Set<Int>]()

        package var armedBreakpointAddresses: Set<Int> { Set(self.armedBreakpoints.keys) }

        package private(set) var state: State

        /// Pc of the final instruction that a successful program will execute, initialized with `Instruction.endofExecution`
        private var endOfExecution: CodeSlot

        private var md: Md = nil
        private var ms: Ms = 0

        /// Bytes of linear memory the guest can see, zero before a stop has bound any.
        package private(set) var linearMemoryByteCount = 0

        /// Starts of this instance's Wasm functions in the original binary, in ascending order,
        /// paired with their indices. Excludes imported functions: their addresses are offsets
        /// into the defining binary, not this one.
        private let functionAddresses: [(address: Int, instanceFunctionIndex: Int)]

        /// The head slot of the `breakpoint` instruction, which an armed breakpoint puts in the bytecode.
        private let breakpointHeadSlot: CodeSlot

        /// Initializes a new debugger state instance.
        /// - Parameters:
        ///   - module: Wasm module to instantiate.
        ///   - store: Store that instantiates the module.
        ///   - imports: Imports required by `module` for instantiation.
        package init(module: Module, store: Store, imports: Imports) throws {
            let limit = store.engine.configuration.stackSize / MemoryLayout<StackSlot>.stride
            let instance = try module.instantiate(store: store, imports: imports, isDebuggable: true)

            guard case .function(let entrypointFunction) = instance.exports["_start"] else {
                throw Error.entrypointFunctionNotFound
            }

            self.instance = instance
            self.functionAddresses = instance.handle.functions.enumerated().compactMap {
                guard $0.element.isWasm, $0.element.wasm.instance == instance.handle else { return nil }
                switch $0.element.wasm.code {
                case .uncompiled(let wasm), .debuggable(let wasm, _):
                    return (address: wasm.originalBodyAddress, instanceFunctionIndex: $0.offset)
                case .compiled:
                    fatalError()
                }
            }
            self.module = module
            self.entrypointFunction = entrypointFunction
            self.valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
            self.store = store
            self.execution = Execution(
                store: StoreRef(store),
                stackEnd: valueStack.advanced(by: limit)
            )
            self.threadingModel = store.engine.configuration.threadingModel
            self.endOfExecution = Instruction.endOfExecution(.init()).headSlot(threadingModel: threadingModel)
            self.breakpointHeadSlot = Instruction.breakpoint(.init()).headSlot(threadingModel: threadingModel)

            self.state = .instantiated
        }

        /// Sets a breakpoint at the first instruction in the entrypoint function of the module instantiated by
        /// this debugger.
        package mutating func stopAtEntrypoint() throws {
            try self.enableBreakpoint(address: self.originalAddress(function: entrypointFunction))
        }

        /// Finds a Wasm address for the first instruction in a given function.
        /// - Parameter function: the Wasm function to find the first Wasm instruction address for.
        /// - Returns: byte offset of the first Wasm instruction of given function in the module it was parsed from.
        package func originalAddress(function: Function) throws -> Int {
            precondition(function.handle.isWasm)

            switch function.handle.wasm.code {
            case .debuggable(let wasm, _):
                return wasm.originalAddress
            case .uncompiled:
                try function.handle.wasm.ensureCompiled(store: StoreRef(self.store))
                return try self.originalAddress(function: function)
            case .compiled:
                fatalError()
            }
        }

        /// The Wasm function containing `address` and the start of the next function. Uses the
        /// module layout to support breakpoints in functions not yet compiled.
        private func functionContaining(address: Int) -> (function: InternalFunction, upperBound: Int)? {
            let following = self.functionAddresses.partitioningIndex { $0.address > address }
            guard following > self.functionAddresses.startIndex else { return nil }

            let entry = self.functionAddresses[following - 1]
            let upperBound = following < self.functionAddresses.endIndex ? self.functionAddresses[following].address : Int.max
            return (self.instance.handle.functions[entry.instanceFunctionIndex], upperBound)
        }

        private func findIseq(forWasmAddress address: Int) throws -> (iseq: Pc, wasm: Int) {
            if let iseq = self.instance.handle.instructionMapping.iseq(forWasmAddress: address) {
                return (iseq, address)
            }

            // Addresses that didn't emit bytecode slide forward to the next emitting instruction.
            // This requires the containing function to be compiled and bounds the search.
            guard let (function, upperBound) = self.functionContaining(address: address) else {
                throw Error.noInstructionMappingAvailable(address)
            }
            try function.wasm.ensureCompiled(store: StoreRef(self.store))

            guard
                let resolved = self.instance.handle.instructionMapping.findIseq(
                    forWasmAddress: address,
                    before: upperBound
                )
            else {
                throw Error.noInstructionMappingAvailable(address)
            }

            return resolved
        }

        /// Puts a breakpoint into the bytecode at an already resolved Wasm address, preserving the
        /// instruction it replaces. Idempotent, so that arming for one owner cannot record another
        /// owner's breakpoint instruction as the original.
        private mutating func arm(resolved: Int, iseq: Pc) {
            guard self.armedBreakpoints[resolved] == nil else { return }

            self.armedBreakpoints[resolved] = (iseq: iseq, originalHeadSlot: iseq.pointee)
            iseq.pointee = self.breakpointHeadSlot
        }

        /// Takes the breakpoint at an already resolved Wasm address out of the bytecode, restoring
        /// the instruction it replaced. Leaves ``hostBreakpoints`` alone: it is the bytecode half of
        /// a breakpoint, not the request for one.
        private mutating func disarm(resolved: Int) {
            guard let armed = self.armedBreakpoints.removeValue(forKey: resolved) else { return }

            armed.iseq.pointee = armed.originalHeadSlot
        }

        /// Enables a breakpoint at a given Wasm address.
        /// - Parameter address: byte offset of the Wasm instruction that will be replaced with a breakpoint. If no
        /// direct internal bytecode matching instruction is found, the next closest internal bytecode instruction
        /// is replaced with a breakpoint. The original instruction to be restored is preserved in debugger state
        /// represented by `self`.
        /// See also ``Debugger/disableBreakpoint(address:)``.
        @discardableResult
        package mutating func enableBreakpoint(address: Int) throws -> Int {
            let (iseq, wasm) = try self.findIseq(forWasmAddress: address)
            self.hostBreakpoints[wasm, default: []].insert(address)
            self.arm(resolved: wasm, iseq: iseq)
            return wasm
        }

        package mutating func enableBreakpoint(
            module: Module,
            function: Int,
            offsetWithinFunction: Int = 0
        ) throws -> Int {
            try self.enableBreakpoint(address: module.functions[function].code.originalAddress + offsetWithinFunction)
        }

        /// Disables a breakpoint at a given Wasm address. If no breakpoint at a given address was previously set with
        /// `self.enableBreakpoint(address:), this function immediately returns.
        /// - Parameter address: byte offset of the Wasm instruction that was replaced with a breakpoint. The original
        /// instruction is restored from debugger state and replaces the breakpoint instruction.
        /// See also ``Debugger/enableBreakpoint(address:)``.
        package mutating func disableBreakpoint(address: Int) throws {
            // Resolve the same way enableBreakpoint does, so a breakpoint set
            // at an elided address is found under its resolved key.
            let (_, wasm) = try self.findIseq(forWasmAddress: address)
            self.hostBreakpoints[wasm]?.remove(address)

            // Keep armed if other requests share the slot.
            guard self.hostBreakpoints[wasm]?.isEmpty ?? true else { return }

            self.hostBreakpoints[wasm] = nil
            self.disarm(resolved: wasm)
        }

        /// Forgets every breakpoint, so that execution can resume without the debugger observing it
        /// again.
        package mutating func removeAllBreakpoints() {
            self.hostBreakpoints.removeAll()
            for armed in self.armedBreakpoints.values {
                armed.iseq.pointee = armed.originalHeadSlot
            }
            self.armedBreakpoints.removeAll()
        }

        /// Resumes the module instantiated by the debugger stopped at a breakpoint. The lowest-level
        /// resume: the breakpoint at the current program counter is taken out of the bytecode so that
        /// execution can make progress, and it is not put back. Execution continues until the next
        /// breakpoint is triggered or all remaining instructions are executed. If the module is not
        /// stopped at a breakpoint, this function returns immediately.
        package mutating func run() throws {
            switch self.state {
            case .stoppedAtBreakpoint(let breakpoint):
                self.disarm(resolved: breakpoint.wasmPc)
                try self.resume(.runLoop(sp: breakpoint.iseq.sp, pc: breakpoint.iseq.pc))
            case .instantiated:
                try self.resume(.entrypoint)

            case .exited:
                // The guest is gone, so there is nothing to resume.
                return

            case .trapped:
                // The guest trapped, so there is nothing to resume.
                return

            case .entrypointReturned:
                fatalError("Restarting a Wasm module from the debugger is not implemented yet.")
            }
        }

        /// How ``resume(_:)`` runs the guest.
        private enum Resumption {
            /// From the start of the entrypoint.
            case entrypoint
            /// From the head slot `pc` with the threading model's own run loop.
            case runLoop(sp: Sp, pc: Pc)
            /// By a single step off `breakpoint`.
            case singleStep(BreakpointState)
        }

        /// Runs the guest, recording in ``state`` how it stops: at a breakpoint, with a trap, or by
        /// returning from the entrypoint.
        private mutating func resume(_ resumption: Resumption) throws {
            do {
                switch resumption {
                case .entrypoint:
                    // The entrypoint returns to `endOfExecution`, so its frame keeps this address.
                    let result = try self.execution.executeWasm(
                        threadingModel: self.threadingModel,
                        function: self.entrypointFunction.handle,
                        type: self.entrypointFunction.type,
                        arguments: [],
                        sp: self.valueStack,
                        pc: &self.endOfExecution
                    )
                    self.state = .entrypointReturned(result)
                case .runLoop(let sp, let pc):
                    try self.runNative(sp: sp, pc: pc)
                case .singleStep(let breakpoint):
                    try self.singleStep(from: breakpoint)
                }
            } catch let end as Execution.EndOfExecution {
                // The module successfully executed till the "end of execution" instruction.
                let type = self.entrypointFunction.type
                self.state = .entrypointReturned(
                    type.results.enumerated().map { (i, type) in
                        end.sp[VReg(slotIndex: i)].cast(to: type)
                    }
                )
            } catch let breakpoint as Execution.Breakpoint {
                try self.stop(at: breakpoint)
            } catch let trap as Trap {
                let mapping = self.instance.handle.instructionMapping
                self.state = .trapped(
                    .init(
                        description: "Trap: \(trap.reason)",
                        callStack: (trap.backtrace?.symbols ?? []).compactMap {
                            mapping.firstWasm(forIseqAddress: $0.address)
                        }
                    )
                )
            }
        }

        /// Records a stop at the head slot `breakpoint.pc`, whether a breakpoint was hit there or a
        /// step landed there.
        private mutating func stop(at breakpoint: Execution.Breakpoint) throws {
            let pc = breakpoint.pc
            let mapping = self.instance.handle.instructionMapping
            guard let wasmPc = mapping.findWasm(forIseqAddress: pc) else {
                throw Error.noReverseInstructionMappingAvailable(pc)
            }

            self.state = .stoppedAtBreakpoint(
                .init(
                    iseq: breakpoint,
                    wasmPc: wasmPc,
                    reportedPc: self.hostBreakpoints[wasmPc]?.min() ?? mapping.firstWasm(forIseqAddress: pc) ?? wasmPc
                )
            )

            guard let currentFunction = breakpoint.sp.currentFunction else {
                throw Error.unknownCurrentFunctionAtBreakpoint(breakpoint.sp)
            }
            Execution.CurrentMemory.mayUpdateCurrentInstance(
                instance: currentFunction.instance,
                md: &self.md,
                ms: &self.ms
            )
            // ms may include uncommitted guard pages that fault outside the trap guard.
            self.linearMemoryByteCount = currentFunction.instance.memories.first?.byteCount ?? 0
        }

        /// Runs the guest from the head slot `pc` with the threading model's own run loop until it
        /// stops.
        private mutating func runNative(sp: Sp, pc: Pc) throws {
            self.execution.resetError()
            var sp = sp
            var pc = pc
            switch self.threadingModel {
            case .direct:
                try self.execution.runDirectThreaded(sp: sp, pc: pc, md: self.md, ms: self.ms)
            case .token:
                try self.execution.runTokenThreaded(sp: &sp, pc: &pc, md: &self.md, ms: &self.ms)
            }
        }

        /// Steps by a single Wasm instruction in the module instantiated by the debugger stopped at a breakpoint.
        /// The guest runs one internal instruction at a time until it reaches the start of a Wasm instruction,
        /// wherever execution goes: into a callee, back to a caller, past a host call, or to an exception
        /// handler. Breakpoints stay in the bytecode throughout, so a step leaves the host's breakpoints exactly
        /// as it found them.
        /// If the module is not stopped at a breakpoint, this function returns immediately.
        package mutating func step() throws {
            guard case .stoppedAtBreakpoint(let breakpoint) = self.state else {
                return
            }

            // Report any remaining breakpoints sharing this slot before resuming.
            guard !self.reportPendingHostBreakpoint(after: breakpoint) else { return }

            try self.resume(.singleStep(breakpoint))
        }

        /// Reports the next host breakpoint sharing this bytecode slot without resuming execution.
        private mutating func reportPendingHostBreakpoint(after breakpoint: BreakpointState) -> Bool {
            guard
                let pending = self.hostBreakpoints[breakpoint.wasmPc]?
                    .filter({ $0 > breakpoint.reportedPc })
                    .min()
            else { return false }

            var breakpoint = breakpoint
            breakpoint.reportedPc = pending
            self.state = .stoppedAtBreakpoint(breakpoint)
            return true
        }

        /// Resumes the module instantiated by the debugger stopped at a breakpoint. The breakpoint from which
        /// the debugger resumes is preserved. If the module is current not stopped at a breakpoint, this function
        /// returns immediately.
        package mutating func runPreservingCurrentBreakpoint() throws {
            guard case .stoppedAtBreakpoint = self.state else {
                return
            }

            // Stepping runs the instruction under the breakpoint without taking the breakpoint out, and
            // gets execution off its slot.
            try self.step()

            // Landing on a breakpoint the host set is a stop the host is waiting for.
            guard case .stoppedAtBreakpoint(let landed) = self.state,
                self.hostBreakpoints[landed.wasmPc] == nil
            else {
                return
            }

            try self.run()
        }

        /// Records that the guest exited with the given status.
        package mutating func recordExit(status: UInt32) {
            self.state = .exited(status: status)
        }

        package func getLocal(frameIndex: UInt, localIndex: UInt) throws -> UInt64 {
            guard case .stoppedAtBreakpoint(let breakpoint) = self.state else {
                throw Error.notStoppedAtBreakpoint
            }

            var i = 0
            for frame in Execution.CallStack(sp: breakpoint.iseq.sp) {
                guard frameIndex == i else {
                    i += 1
                    continue
                }

                guard let currentFunction = frame.sp.currentFunction else {
                    throw Debugger.Error.unknownCurrentFunctionAtBreakpoint(frame.sp)
                }

                try currentFunction.ensureCompiled(store: StoreRef(store))

                guard case .debuggable(let wasm, _) = currentFunction.code else {
                    fatalError()
                }

                // Wasm function arguments are also addressed as locals.
                let functionType = store.engine.funcTypeInterner.resolve(currentFunction.type)

                let localsCount = functionType.parameters.count + wasm.locals.count

                guard localIndex < localsCount else {
                    throw Debugger.Error.stackLocalIndexOOB(localIndex)
                }

                if localIndex < functionType.parameters.count {
                    let localIndex = Int(localIndex) - 4
                    return frame.sp[localIndex].storage
                } else {
                    let localIndex = Int(localIndex) - functionType.parameters.count
                    return frame.sp[localIndex].storage
                }
            }

            throw Error.stackFrameIndexOOB(frameIndex)
        }

        /// The global at `index` in the debugged instance's global index space.
        ///
        /// Globals are instance-wide, so a `qWasmGlobal` frame argument carries no
        /// information and is dropped, matching LLDB's `eWasmTagGlobal`.
        package func getGlobal(index: UInt) throws -> UInt64 {
            let globals = self.instance.handle.globals
            guard index < UInt(globals.count) else { throw Error.globalIndexOOB(index) }
            let global = globals[Int(index)]
            switch global.globalType.valueType {
            case .i32, .i64, .f32, .f64, .ref: return global.rawStorage.lo
            case .v128: throw Error.globalUnsupportedType(index)  // 128-bit can't fit a single reply
            }
        }

        package func readLinearMemory<T>(address: UInt, length: UInt, reader: (UnsafeRawBufferPointer) -> T) throws(Error) -> T {
            let range = try self.linearMemoryRange(address: address, length: length)
            let memory = UnsafeRawBufferPointer(start: self.md, count: self.linearMemoryByteCount)

            return reader(UnsafeRawBufferPointer(rebasing: memory[range]))
        }

        package mutating func writeLinearMemory(address: UInt, bytes: some Collection<UInt8>) throws(Error) {
            let range = try self.linearMemoryRange(address: address, length: UInt(bytes.count))
            let memory = UnsafeMutableRawBufferPointer(start: self.md, count: self.linearMemoryByteCount)

            UnsafeMutableRawBufferPointer(rebasing: memory[range]).copyBytes(from: bytes)
        }

        private func linearMemoryRange(address: UInt, length: UInt) throws(Error) -> Range<Int> {
            guard self.md != nil, self.linearMemoryByteCount > 0 else {
                throw Error.linearMemoryNotInitialized
            }

            let (upperBound, overflowed) = address.addingReportingOverflow(length)
            guard !overflowed, upperBound <= UInt(self.linearMemoryByteCount) else {
                throw Error.linearMemoryOOB(address: address, length: length)
            }

            return Int(address)..<Int(upperBound)
        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [Int] { self.callStack(atRunStart: false) }

        /// ``currentCallStack`` with frames moved to the start of their instruction run.
        package var reportedCallStack: [Int] { self.callStack(atRunStart: true) }

        /// Wasm addresses of the frames on the stack, innermost first. Frames with no reverse
        /// mapping are dropped.
        private func callStack(atRunStart: Bool) -> [Int] {
            // Trap call stacks already use run-start addresses.
            if case .trapped(let trap) = self.state {
                return trap.callStack
            }

            guard case .stoppedAtBreakpoint(let breakpoint) = self.state else {
                return []
            }

            let mapping = self.instance.handle.instructionMapping
            var result = [atRunStart ? breakpoint.reportedPc : breakpoint.wasmPc]
            for frame in Execution.CallStack(sp: breakpoint.iseq.sp) {
                let wasm = atRunStart ? mapping.firstWasm(forIseqAddress: frame.pc) : mapping.findWasm(forIseqAddress: frame.pc)
                guard let wasm else { continue }
                result.append(wasm)
            }

            return result
        }

        /// Runs the guest one internal instruction at a time from `breakpoint`, following wherever
        /// execution goes, until the next instruction to run is at a stop point: the first head slot of
        /// a Wasm instruction. Records the stop there.
        ///
        /// Breakpoints are never taken out. The first instruction runs from the head slot its
        /// breakpoint replaced, and no later one is at a stop point, where breakpoints go.
        private mutating func singleStep(from breakpoint: BreakpointState) throws {
            var sp = breakpoint.iseq.sp
            var pc = breakpoint.iseq.pc.advanced(by: 1)
            // If the breakpoint was externally removed (e.g. via disableBreakpoint while stopped), the
            // original instruction has already been restored, so read it directly. Bound with `if let`:
            // `armedBreakpoints[key]?.originalHeadSlot` in a mutating method reads a stale value for a
            // missing key at -Onone (Swift 6.3.2).
            var head: CodeSlot
            if let armed = self.armedBreakpoints[breakpoint.wasmPc] {
                head = armed.originalHeadSlot
            } else {
                head = breakpoint.iseq.pc.pointee
            }
            var isFirst = true
            repeat {
                head = try self.execution.stepInstruction(
                    head: head, threadingModel: self.threadingModel,
                    sp: &sp, pc: &pc, md: &self.md, ms: &self.ms
                )
                if isFirst {
                    self.restoreBreakpointIfOverwritten(at: breakpoint.wasmPc)
                    isFirst = false
                }
                if let function = sp.currentFunction, function.instance != self.instance.handle {
                    guard let back = try self.runOutsideInstance(sp: sp, pc: pc) else { return }
                    (sp, pc, head) = back
                }
            } while !self.isAtStopPoint(head: head, readBefore: pc)

            try self.stop(at: Execution.Breakpoint(sp: sp, pc: pc.advanced(by: -1)))
        }

        /// Whether the instruction about to run, whose head slot `head` was read just before `pc`,
        /// is at a stop point.
        private func isAtStopPoint(head: CodeSlot, readBefore pc: Pc) -> Bool {
            let slot = pc.advanced(by: -1)
            // A `_return` leaving the instance hands over to `returnCrossInstance` without moving
            // `pc`, so the slot is only where the next instruction is if it holds `head`.
            return slot.pointee == head && self.instance.handle.instructionMapping.isStopPoint(slot)
        }

        /// Puts back the breakpoint at `resolved` if the instruction under it overwrote it:
        /// `compilingCall` rewrites its own head slot to `internalCall` the first time it runs.
        private mutating func restoreBreakpointIfOverwritten(at resolved: Int) {
            guard let armed = self.armedBreakpoints[resolved], armed.iseq.pointee != self.breakpointHeadSlot else {
                return
            }

            self.armedBreakpoints[resolved] = (iseq: armed.iseq, originalHeadSlot: armed.iseq.pointee)
            armed.iseq.pointee = self.breakpointHeadSlot
        }

        /// Runs code of another instance, which a single step can't: it was not compiled for
        /// debugging, so it has no stop points and may use direct-only instructions. `pc` points just
        /// past the head slot of the instruction about to run, as in ``singleStep(from:)``.
        ///
        /// When the frame it runs in returns into the debugged instance, whose return address and
        /// caller the frame holds, this hands back where stepping resumes. Otherwise the guest runs
        /// until it stops and this returns `nil`.
        private mutating func runOutsideInstance(sp: Sp, pc: Pc) throws -> (sp: Sp, pc: Pc, head: CodeSlot)? {
            guard let returnPC = sp.returnPC, let callerSp = sp.previousSP,
                self.instance.handle.instructionMapping.findWasm(forIseqAddress: returnPC) != nil
            else {
                // The frame doesn't return into this instance, so the step becomes a continue.
                try self.runNative(sp: sp, pc: pc.advanced(by: -1))
                return nil
            }

            let savedHead = returnPC.pointee
            returnPC.pointee = self.breakpointHeadSlot
            defer { returnPC.pointee = savedHead }

            var sp = sp
            var pc = pc.advanced(by: -1)
            while true {
                do {
                    try self.runNative(sp: sp, pc: pc)
                    return nil
                } catch let hit as Execution.Breakpoint where hit.pc == returnPC {
                    // The run loop switched back to this instance's memory without telling us.
                    Execution.CurrentMemory.mayUpdateCurrentInstance(instance: self.instance.handle, md: &self.md, ms: &self.ms)
                    // Back in the frame that made the call, or at a host breakpoint on the way.
                    if hit.sp == callerSp || savedHead == self.breakpointHeadSlot {
                        return (hit.sp, returnPC.advanced(by: 1), savedHead)
                    }
                    // A deeper frame returned to the same address: run past it and keep waiting.
                    sp = hit.sp
                    var next = returnPC.advanced(by: 1)
                    _ = try self.execution.stepInstruction(
                        head: savedHead, threadingModel: self.threadingModel,
                        sp: &sp, pc: &next, md: &self.md, ms: &self.ms
                    )
                    pc = next.advanced(by: -1)
                }
            }
        }

        deinit {
            self.valueStack.deallocate()
        }
    }

#endif
