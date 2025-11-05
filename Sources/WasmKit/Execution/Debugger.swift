#if WasmDebuggingSupport

    /// Debugger state owner, driven by a debugger host. This implementation has no knowledge of the exact
    /// debugger protocol, which allows any protocol implementation or direct API users to be layered on top if needed.
    package struct Debugger: ~Copyable {
        package struct BreakpointState {
            let sp: Sp
            let iseq: Execution.Breakpoint
            package let wasmPc: Int
        }

        package enum State {
            case instantiated
            case stoppedAtBreakpoint(BreakpointState)
            case trapped(String)
            case entrypointReturned([Value])
        }

        package enum Error: Swift.Error, @unchecked Sendable {
            case entrypointFunctionNotFound
            case unknownCurrentFunctionForResumedBreakpoint(UnsafeMutablePointer<UInt64>)
            case noInstructionMappingAvailable(Int)
            case noReverseInstructionMappingAvailable(UnsafeMutablePointer<UInt64>)
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

        private(set) var breakpoints = [Int: CodeSlot]()

        package private(set) var state: State

        /// Pc ofthe final instruction that a successful program will execute, initialized with `Instruction.endofExecution`
        private let endOfExecution = Pc.allocate(capacity: 1)

        /// Addresses of functions in the original Wasm binary, used looking up functions when a breakpoint
        /// is enabled at an arbitrary address if it isn't present in ``InstructionMapping`` yet (i.e. the
        /// was not compiled yet in lazy compilation mode).
        private let functionAddresses: [(address: Int, instanceFunctionIndex: Int)]

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
            self.functionAddresses = instance.handle.functions.enumerated().filter { $0.element.isWasm }.lazy.map {
                switch $0.element.wasm.code {
                case .uncompiled(let wasm), .debuggable(let wasm, _):
                    return (address: wasm.originalAddress, instanceFunctionIndex: $0.offset)
                case .compiled:
                    fatalError()
                }
            }
            self.module = module
            self.entrypointFunction = entrypointFunction
            self.valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
            self.store = store
            self.execution = Execution(store: StoreRef(store), stackEnd: valueStack.advanced(by: limit))
            self.threadingModel = store.engine.configuration.threadingModel
            self.endOfExecution.pointee = Instruction.endOfExecution.headSlot(threadingModel: threadingModel)
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

        private func findIseq(forWasmAddress address: Int) throws -> (iseq: Pc, wasm: Int) {
            if let (iseq, wasm) = self.instance.handle.instructionMapping.findIseq(forWasmAddress: address) {
                return (iseq, wasm)
            }

            let followingIndex = self.functionAddresses.firstIndex(where: { $0.address > address }) ?? self.functionAddresses.endIndex
            let functionIndex = self.functionAddresses[followingIndex - 1].instanceFunctionIndex
            let function = instance.handle.functions[functionIndex]
            try function.wasm.ensureCompiled(store: StoreRef(self.store))

            if let (iseq, wasm) = self.instance.handle.instructionMapping.findIseq(forWasmAddress: address) {
                return (iseq, wasm)
            }

            throw Error.noInstructionMappingAvailable(address)
        }

        /// Enables a breakpoint at a given Wasm address.
        /// - Parameter address: byte offset of the Wasm instruction that will be replaced with a breakpoint. If no
        /// direct internal bytecode matching instruction is found, the next closest internal bytecode instruction
        /// is replaced with a breakpoint. The original instruction to be restored is preserved in debugger state
        /// represented by `self`.
        /// See also ``Debugger/disableBreakpoint(address:)``.
        @discardableResult
        package mutating func enableBreakpoint(address: Int) throws -> Int {
            guard self.breakpoints[address] == nil else {
                return address
            }

            let (iseq, wasm) = try self.findIseq(forWasmAddress: address)
            self.breakpoints[wasm] = iseq.pointee
            iseq.pointee = Instruction.breakpoint.headSlot(threadingModel: self.threadingModel)
            return wasm
        }

        /// Disables a breakpoint at a given Wasm address. If no breakpoint at a given address was previously set with
        /// `self.enableBreakpoint(address:), this function immediately returns.
        /// - Parameter address: byte offset of the Wasm instruction that was replaced with a breakpoint. The original
        /// instruction is restored from debugger state and replaces the breakpoint instruction.
        /// See also ``Debugger/enableBreakpoint(address:)``.
        package mutating func disableBreakpoint(address: Int) throws {
            guard let oldCodeSlot = self.breakpoints[address] else {
                return
            }

            let (iseq, wasm) = try self.findIseq(forWasmAddress: address)

            self.breakpoints[wasm] = nil
            iseq.pointee = oldCodeSlot
        }

        /// Resumes the module instantiated by the debugger stopped at a breakpoint. The breakpoint is disabled
        /// and execution is resumed until the next breakpoint is triggered or all remaining instructions are
        /// executed. If the module is not stopped at a breakpoint, this function returns immediately.
        package mutating func run() throws {
            do {
                switch self.state {
                case .stoppedAtBreakpoint(let breakpoint):
                    // Remove the breakpoint before resuming
                    try self.disableBreakpoint(address: breakpoint.wasmPc)
                    self.execution.resetError()

                    let iseq = breakpoint.iseq
                    var sp = iseq.sp
                    var pc = iseq.pc
                    var md: Md = nil
                    var ms: Ms = 0

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
                    } catch is Execution.EndOfExecution {
                        // The module successfully executed till the "end of execution" instruction.
                        let type = self.store.engine.funcTypeInterner.resolve(currentFunction.type)
                        self.state = .entrypointReturned(
                            type.results.enumerated().map { (i, type) in
                                sp[VReg(i)].cast(to: type)
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
                        pc: self.endOfExecution
                    )
                    self.state = .entrypointReturned(result)

                case .trapped, .entrypointReturned:
                    fatalError("Restarting a Wasm module from the debugger is not implemented yet.")
                }
            } catch let breakpoint as Execution.Breakpoint {
                let pc = breakpoint.pc
                guard let wasmPc = self.instance.handle.instructionMapping.findWasm(forIseqAddress: pc) else {
                    throw Error.noReverseInstructionMappingAvailable(pc)
                }

                self.state = .stoppedAtBreakpoint(.init(sp: breakpoint.sp, iseq: breakpoint, wasmPc: wasmPc))
            }
        }

        /// Steps by a single Wasm instruction in the module instantiated by the debugger stopped at a breakpoint.
        /// The current breakpoint is disabled and new breakpoints are put on the next instruction (or instructions in case
        /// of multiple possible execution branches). After breakpoints setup, execution is resumed until suspension.
        /// If the module is not stopped at a breakpoint, this function returns immediately.
        package mutating func step() throws {
            guard case .stoppedAtBreakpoint(let breakpoint) = self.state else {
                return
            }

            // TODO: analyze actual instruction branching to set the breakpoint correctly.
            try self.enableBreakpoint(address: breakpoint.wasmPc + 1)
            try self.run()
        }

        package func getLocal(frameIndex: Int, localIndex: Int) -> Address {

        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [Int] {
            guard case .stoppedAtBreakpoint(let breakpoint) = self.state else {
                return []
            }

            var result = [breakpoint.wasmPc]
            result.append(
                contentsOf: Execution.captureBacktrace(sp: breakpoint.iseq.sp, store: self.store).symbols.compactMap {
                    return self.instance.handle.instructionMapping.findWasm(forIseqAddress: $0.address)
                })

            return result
        }

        deinit {
            self.valueStack.deallocate()
            self.endOfExecution.deallocate()
        }
    }

#endif
