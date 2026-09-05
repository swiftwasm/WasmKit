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
            case trapped(String)
            case entrypointReturned([Value])
            case exited(status: UInt32)
        }

        package enum Error: Swift.Error, @unchecked Sendable {
            case entrypointFunctionNotFound
            case unknownCurrentFunctionForResumedBreakpoint(UnsafeMutablePointer<UInt64>)
            case noInstructionMappingAvailable(Int)
            case noReverseInstructionMappingAvailable(UnsafeMutablePointer<UInt64>)
            case stackFrameIndexOOB(UInt)
            case stackLocalIndexOOB(UInt)
            case globalIndexOOB(UInt)
            case globalUnsupportedType(UInt)
            case notStoppedAtBreakpoint
            case linearMemoryNotInitialized
            case linearMemoryOOB(Range<Int>)
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

        /// Resolved Wasm addresses armed to bound the single-instruction step in progress. Every
        /// address execution can reach from the current one has to be armed, and all of them come
        /// down again once the step lands, except where the host wants a breakpoint too.
        private var stepBreakpoints = Set<Int>()

        package var armedBreakpointAddresses: Set<Int> { Set(self.armedBreakpoints.keys) }

        package private(set) var state: State

        /// Pc of the final instruction that a successful program will execute, initialized with `Instruction.endofExecution`
        private var endOfExecution: CodeSlot

        private var md: Md = nil
        private var ms: Ms = 0

        /// Starts of this instance's Wasm functions in the original binary, in ascending order,
        /// paired with their indices. Excludes imported functions: their addresses are offsets
        /// into the defining binary, not this one.
        private let functionAddresses: [(address: Int, instanceFunctionIndex: Int)]

        /// Reverse map from a head code slot to its opcode ID, used for resolving
        /// which control-flow instruction is at a breakpoint site.
        /// For token threading the head slot is the opcode ID itself; for direct
        /// threading it is a function pointer that we map back.
        private let headSlotToOpcodeID: [CodeSlot: OpcodeID]

        private static let callFamilyOpcodes: Set<OpcodeID> = [
            Instruction.call(.init(rawCallee: UInt64(0), spAddend: VReg(0))).opcodeID,
            Instruction.compilingCall(.init(rawCallee: UInt64(0), spAddend: VReg(0))).opcodeID,
            Instruction.internalCall(.init(rawCallee: UInt64(0), spAddend: VReg(0))).opcodeID,
            Instruction.callIndirect(.init(tableIndex: UInt32(0), rawType: UInt32(0), index: VReg(0), spAddend: VReg(0))).opcodeID,
            Instruction.returnCall(.init(rawCallee: UInt64(0))).opcodeID,
            Instruction.returnCallIndirect(.init(tableIndex: UInt32(0), rawType: UInt32(0), index: VReg(0))).opcodeID,
        ]

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
            self.endOfExecution = Instruction.endOfExecution.headSlot(threadingModel: threadingModel)

            self.headSlotToOpcodeID = Instruction.buildControlHeadSlotMap(
                threadingModel: self.threadingModel
            )

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
            iseq.pointee = Instruction.breakpoint.headSlot(threadingModel: self.threadingModel)
        }

        /// Takes the breakpoint at an already resolved Wasm address out of the bytecode, restoring
        /// the instruction it replaced. Leaves ``hostBreakpoints`` and ``stepBreakpoints`` alone: it
        /// is the bytecode half of a breakpoint, not the request for one.
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
            guard !self.stepBreakpoints.contains(wasm) else { return }

            self.disarm(resolved: wasm)
        }

        /// Forgets every breakpoint, so that execution can resume without the debugger observing it
        /// again.
        package mutating func removeAllBreakpoints() {
            self.hostBreakpoints.removeAll()
            self.stepBreakpoints.removeAll()
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
            do {
                switch self.state {
                case .stoppedAtBreakpoint(let breakpoint):
                    self.disarm(resolved: breakpoint.wasmPc)
                    self.execution.resetError()

                    let iseq = breakpoint.iseq
                    var sp = iseq.sp
                    var pc = iseq.pc

                    guard let currentFunction = sp.currentFunction else {
                        throw Error.unknownCurrentFunctionForResumedBreakpoint(sp)
                    }

                    Execution.CurrentMemory.mayUpdateCurrentInstance(
                        instance: currentFunction.instance,
                        md: &md,
                        ms: &ms
                    )

                    do {
                        switch self.threadingModel {
                        case .direct:
                            try self.execution.runDirectThreaded(sp: sp, pc: pc, md: md, ms: ms)
                        case .token:
                            try self.execution.runTokenThreaded(sp: &sp, pc: &pc, md: &md, ms: &ms)
                        }
                    } catch let end as Execution.EndOfExecution {
                        // The module successfully executed till the "end of execution" instruction.
                        let type = self.entrypointFunction.type
                        self.state = .entrypointReturned(
                            type.results.enumerated().map { (i, type) in
                                end.sp[VReg(i)].cast(to: type)
                            }
                        )
                    }
                case .instantiated:
                    let result = try self.execution.executeWasm(
                        threadingModel: self.threadingModel,
                        function: self.entrypointFunction.handle,
                        type: self.entrypointFunction.type,
                        arguments: [],
                        sp: self.valueStack,
                        pc: &self.endOfExecution
                    )
                    self.state = .entrypointReturned(result)

                case .exited:
                    // The guest is gone, so there is nothing to resume.
                    return

                case .trapped, .entrypointReturned:
                    fatalError("Restarting a Wasm module from the debugger is not implemented yet.")
                }
            } catch let breakpoint as Execution.Breakpoint {
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
            }
        }

        /// Steps by a single Wasm instruction in the module instantiated by the debugger stopped at a breakpoint.
        /// The current breakpoint is disabled and new breakpoints are put on the next instruction (or instructions in case
        /// of multiple possible execution branches). After breakpoints setup, execution is resumed until suspension.
        /// Every breakpoint the step needed comes down again once it lands, and the breakpoint it stepped off
        /// goes back in, so a step leaves the host's breakpoints exactly as it found them.
        /// If the module is not stopped at a breakpoint, this function returns immediately.
        package mutating func step() throws {
            guard case .stoppedAtBreakpoint(let breakpoint) = self.state else {
                return
            }

            // Report any remaining breakpoints sharing this slot before resuming.
            guard !self.reportPendingHostBreakpoint(after: breakpoint) else { return }

            // Clear step-specific breakpoints even if execution fails.
            defer { self.clearStepBreakpoints() }

            try self.setNextInstructionBreakpoints(breakpoint: breakpoint)
            try self.run()
            self.clearStepBreakpoints()
            // Re-arm directly to avoid recording the resolved address as a new host request.
            if self.hostBreakpoints[breakpoint.wasmPc] != nil {
                self.arm(resolved: breakpoint.wasmPc, iseq: breakpoint.iseq.pc)
            }
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

            // A bounded single step is what gets execution out of the slot the resumed-from breakpoint
            // occupies, which is the precondition for putting that breakpoint back.
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
                    throw Debugger.Error.unknownCurrentFunctionForResumedBreakpoint(frame.sp)
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
            switch globals[Int(index)].storage {
            case .scalar(let untyped): return untyped.storage
            case .v128: throw Error.globalUnsupportedType(index)  // 128-bit can't fit a single reply
            }
        }

        package func readLinearMemory<T>(address: UInt, length: UInt, reader: (UnsafeRawBufferPointer) -> T) throws(Error) -> T {
            guard let md, ms > 0 else {
                throw Error.linearMemoryNotInitialized
            }

            let upperBound = address + length
            let range = Int(address)..<Int(upperBound)

            guard address + length < ms else {
                throw Error.linearMemoryOOB(range)
            }

            let memory = UnsafeRawBufferPointer(start: md, count: ms)

            return reader(UnsafeRawBufferPointer(rebasing: memory[range]))
        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [Int] { self.callStack(atRunStart: false) }

        /// ``currentCallStack`` with frames moved to the start of their instruction run.
        package var reportedCallStack: [Int] { self.callStack(atRunStart: true) }

        /// Wasm addresses of the frames on the stack, innermost first. Frames with no reverse
        /// mapping are dropped.
        private func callStack(atRunStart: Bool) -> [Int] {
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

        /// Arms a breakpoint that only exists to bound the step in progress.
        private mutating func armStepBreakpoint(address: Int) throws {
            let (iseq, wasm) = try self.findIseq(forWasmAddress: address)
            self.stepBreakpoints.insert(wasm)
            self.arm(resolved: wasm, iseq: iseq)
        }

        /// Takes down the breakpoints that bounded a step that has landed. Only one of them is where
        /// execution went, and none of them are the host's, so leaving any behind stops the program at
        /// an address nothing asked about.
        private mutating func clearStepBreakpoints() {
            let armedForStep = self.stepBreakpoints
            self.stepBreakpoints.removeAll()
            for resolved in armedForStep where self.hostBreakpoints[resolved] == nil {
                self.disarm(resolved: resolved)
            }
        }

        /// Analyzes the control-flow instruction at the given breakpoint and sets breakpoints
        /// at all possible next instruction locations.
        private mutating func setNextInstructionBreakpoints(breakpoint: BreakpointState) throws {
            // If the breakpoint was externally removed (e.g. via disableBreakpoint
            // while stopped), the original instruction has already been restored at the
            // iseq PC, so read it directly.
            let savedHead = self.armedBreakpoints[breakpoint.wasmPc]?.originalHeadSlot ?? breakpoint.iseq.pc.pointee
            let operandPc = breakpoint.iseq.pc.advanced(by: 1)
            let sp = breakpoint.iseq.sp

            if let opcodeID = headSlotToOpcodeID[savedHead],
                let targets = Instruction.predictNextPcs(
                    opcodeID: opcodeID, operandPc: operandPc, sp: sp,
                    predictor: &self
                )
            {
                // Control instruction with predicted targets.
                // Empty targets means terminal (unreachable, endOfExecution) — no breakpoints to set.
                for pc in targets {
                    if let wasmAddr = self.instance.handle.instructionMapping.findWasm(forIseqAddress: pc) {
                        try self.armStepBreakpoint(address: wasmAddr)
                    }
                }
                return
            }

            // The head slot is non-control because a call with args maps its wasm address to a
            // prep slot, not the call.
            if let calleeEntry = self.stepInTargetIfCall(breakpoint: breakpoint) {
                try self.armStepBreakpoint(address: calleeEntry)
                return
            }

            // Non-control instruction: fall back to next Wasm address
            try self.armStepBreakpoint(address: breakpoint.wasmPc + 1)
        }

        /// The call is the last iseq emit for its wasm address (prep slots come first), so `lastIseq`
        /// points at the real call head, never an operand. Callee resolution, including the
        /// indirect-call runtime table index, is left to the existing `predictNext_*` predictors, which
        /// also compile the callee. Their iseq base may be an elided instruction with no reverse wasm
        /// mapping, so it is mapped through the callee function's originalAddress; enableBreakpoint then
        /// forward-resolves that to the first emitted instruction.
        private mutating func stepInTargetIfCall(breakpoint: BreakpointState) -> Int? {
            let mapping = self.instance.handle.instructionMapping
            guard let headPc = mapping.lastIseq(forWasmAddress: breakpoint.wasmPc),
                // Equal means the breakpoint already sits on the head; the control-head path handled it.
                headPc != breakpoint.iseq.pc,
                let opcodeID = headSlotToOpcodeID[headPc.pointee],
                Self.callFamilyOpcodes.contains(opcodeID),
                let targets = Instruction.predictNextPcs(
                    opcodeID: opcodeID, operandPc: headPc.advanced(by: 1), sp: breakpoint.iseq.sp,
                    predictor: &self
                ),
                // Empty for a host/imported or unresolvable callee.
                let calleeIseq = targets.first
            else { return nil }

            return self.wasmOrigin(ofIseqBase: calleeIseq)
        }

        private func wasmOrigin(ofIseqBase base: Pc) -> Int? {
            for entry in self.functionAddresses {
                let iseq: InstructionSequence
                switch self.instance.handle.functions[entry.instanceFunctionIndex].wasm.code {
                case .debuggable(_, let compiled), .compiled(let compiled): iseq = compiled
                case .uncompiled: continue
                }
                if iseq.instructions.baseAddress == base { return entry.address }
            }
            return nil
        }

        deinit {
            self.valueStack.deallocate()
        }
    }

    extension Debugger: NextInstructionPredictor {
        mutating func predictNext_br(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let offset = Instruction.BrOperand.load(from: &pc)
            return [pc.advanced(by: Int(offset))]
        }

        mutating func predictNext_brIf(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.BrIfOperand.load(from: &pc)
            // Both fall-through (pc after operand) and branch target are possible
            return [pc, pc.advanced(by: Int(op.offset))]
        }

        mutating func predictNext_brIfNot(operandPc: Pc, sp: Sp) -> [Pc] {
            predictNext_brIf(operandPc: operandPc, sp: sp)
        }

        mutating func predictNext_brTable(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.BrTableOperand.load(from: &pc)
            return (0..<Int(op.count)).map { pc.advanced(by: Int(op.baseAddress[$0].offset)) }
        }

        /// Resolves the entry PC of a call target, compiling it if needed.
        ///
        /// Returns `nil` when there is nothing to step into: a host function, or
        /// a callee whose compilation fails. `call` is emitted for host
        /// functions and for wasm functions in another instance, so neither
        /// "is wasm" nor "is compiled" can be assumed here.
        private mutating func calleeEntryPc(_ callee: InternalFunction) -> Pc? {
            guard callee.isWasm else { return nil }
            _ = try? callee.wasm.ensureCompiled(store: StoreRef(self.store))
            guard let iseq = callee.compiledIseq() else { return nil }
            return iseq.instructions.baseAddress
        }

        mutating func predictNext_call(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.CallOperand.load(from: &pc)
            guard let entry = calleeEntryPc(op.callee) else { return [] }
            return [entry]
        }

        mutating func predictNext_compilingCall(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.CallOperand.load(from: &pc)
            guard let entry = calleeEntryPc(op.callee) else { return [] }
            return [entry]
        }

        mutating func predictNext_internalCall(operandPc: Pc, sp: Sp) -> [Pc] {
            predictNext_call(operandPc: operandPc, sp: sp)
        }

        mutating func predictNext__return(operandPc: Pc, sp: Sp) -> [Pc] {
            // returnPC is stored at sp[-2]
            let returnPc = Pc(bitPattern: UInt(sp.advanced(by: -2).pointee))
            return returnPc.map { [$0] } ?? []
        }

        /// Resolves a callee function from a table and returns its iseq base address.
        /// Returns `nil` if the callee is a host function or the resolution fails.
        private mutating func resolveIndirectCallee(
            tableIndex: UInt32, index: VReg, sp: Sp
        ) -> Pc? {
            let callerInstance = self.instance.handle
            let table = callerInstance.tables[Int(tableIndex)]
            let value = sp[index].asAddressOffset(table.limits.isMemory64)
            let elementIndex = Int(value)
            guard elementIndex < table.elements.count,
                case .function(let rawBitPattern?) = table.elements[elementIndex]
            else { return nil }
            let function = InternalFunction(bitPattern: rawBitPattern)
            return calleeEntryPc(function)
        }

        mutating func predictNext_callIndirect(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.CallIndirectOperand.load(from: &pc)
            guard let target = resolveIndirectCallee(tableIndex: op.tableIndex, index: op.index, sp: sp) else {
                return []
            }
            return [target]
        }

        mutating func predictNext_returnCall(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.ReturnCallOperand.load(from: &pc)
            let callee = op.callee
            guard let entry = calleeEntryPc(callee) else { return [] }
            return [entry]
        }

        mutating func predictNext_returnCallIndirect(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            let op = Instruction.ReturnCallIndirectOperand.load(from: &pc)
            guard let target = resolveIndirectCallee(tableIndex: op.tableIndex, index: op.index, sp: sp) else {
                return []
            }
            return [target]
        }

        // Terminal instructions — no successor exists
        mutating func predictNext_unreachable(operandPc: Pc, sp: Sp) -> [Pc] { [] }
        mutating func predictNext_endOfExecution(operandPc: Pc, sp: Sp) -> [Pc] { [] }
        mutating func predictNext_breakpoint(operandPc: Pc, sp: Sp) -> [Pc] { [] }

        // Exception-handling instructions — destination depends on which handler
        // catches at runtime, so static prediction is not possible.
        mutating func predictNext_throwTag(operandPc: Pc, sp: Sp) -> [Pc] { [] }
        mutating func predictNext_throwRef(operandPc: Pc, sp: Sp) -> [Pc] { [] }

        // `catchHandlers` registers exception handlers and falls through to the
        // immediately-following instruction.
        mutating func predictNext_catchHandlers(operandPc: Pc, sp: Sp) -> [Pc] {
            var pc = operandPc
            _ = Instruction.CatchHandlersOperand.load(from: &pc)
            return [pc]
        }
    }

#endif
