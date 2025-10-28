#if WasmDebuggingSupport
    /// User-facing debugger state driven by a debugger host. This implementation has no knowledge of the exact
    /// debugger protocol, which allows any protocol implementation or direct API users to be layered on top if needed.
    package struct Debugger: ~Copyable {
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

        private var currentBreakpoint: (iseq: Execution.Breakpoint, wasmPc: Int)?

        private var pc = Pc.allocate(capacity: 1)

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
            self.module = module
            self.entrypointFunction = entrypointFunction
            self.valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
            self.store = store
            self.execution = Execution(store: StoreRef(store), stackEnd: valueStack.advanced(by: limit))
            self.threadingModel = store.engine.configuration.threadingModel
            self.pc.pointee = Instruction.endOfExecution.headSlot(threadingModel: threadingModel)
        }

        /// Sets a breakpoint at the first instruction in the entrypoint function of the module instantiated by
        /// this debugger.
        package mutating func stopAtEntrypoint() throws {
            try self.enableBreakpoint(address: self.originalAddress(function: entrypointFunction))
        }

        /// Finds a Wasm address for the first instruction in a given function.
        /// - Parameter function: the Wasm function to find the first Wasm instruction address for.
        /// - Returns: byte offset of the first Wasm instruction of given function in the module it was parsed from.
        private func originalAddress(function: Function) throws -> Int {
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

        /// Enables a breakpoint at a given Wasm address.
        /// - Parameter address: byte offset of the Wasm instruction that will be replaced with a breakpoint. If no
        /// direct internal bytecode matching instruction is found, the next closest internal bytecode instruction
        /// is replaced with a breakpoint. The original instruction to be restored is preserved in debugger state
        /// represented by `self`.
        /// See also ``Debugger/disableBreakpoint(address:)``.
        package mutating func enableBreakpoint(address: Int) throws(Error) {
            guard self.breakpoints[address] == nil else {
                return
            }

            guard let (iseq, wasm) = try self.instance.handle.instructionMapping.findIseq(forWasmAddress: address) else {
                throw Error.noInstructionMappingAvailable(address)
            }

            self.breakpoints[wasm] = iseq.pointee
            iseq.pointee = Instruction.breakpoint.headSlot(threadingModel: self.threadingModel)
        }

        /// Disables a breakpoint at a given Wasm address. If no breakpoint at a given address was previously set with
        /// `self.enableBreakpoint(address:), this function immediately returns.
        /// - Parameter address: byte offset of the Wasm instruction that was replaced with a breakpoint. The original
        /// instruction is restored from debugger state and replaces the breakpoint instruction.
        /// See also ``Debugger/enableBreakpoint(address:)``.
        package mutating func disableBreakpoint(address: Int) throws(Error) {
            guard let oldCodeSlot = self.breakpoints[address] else {
                return
            }

            guard let (iseq, wasm) = try self.instance.handle.instructionMapping.findIseq(forWasmAddress: address) else {
                throw Error.noInstructionMappingAvailable(address)
            }

            self.breakpoints[wasm] = nil
            iseq.pointee = oldCodeSlot
        }

        /// Resumes the module instantiated by the debugger stopped at a breakpoint. The breakpoint is disabled
        /// and execution is resumed until the next breakpoint is triggered or all remaining instructions are
        /// executed. If the module is not stopped at a breakpoint, this function returns immediately.
        /// - Returns: `[Value]` result of `entrypointFunction` if current instance ran to completion,
        /// `nil` if it stopped at a breakpoint.
        package mutating func run() throws -> [Value]? {
            do {
                if let currentBreakpoint {
                    // Remove the breakpoint before resuming
                    try self.disableBreakpoint(address: currentBreakpoint.wasmPc)
                    self.execution.resetError()

                    var sp = currentBreakpoint.iseq.sp
                    var pc = currentBreakpoint.iseq.pc
                    var md: Md = nil
                    var ms: Ms = 0

                    guard let currentFunction = sp.currentFunction else {
                        throw Error.unknownCurrentFunctionForResumedBreakpoint(sp)
                    }

                    Execution.CurrentMemory.mayUpdateCurrentInstance(
                        instance: currentFunction.instance,
                        from: self.instance.handle,
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
                    }

                    let type = self.store.engine.funcTypeInterner.resolve(currentFunction.type)
                    return type.results.enumerated().map { (i, type) in
                        sp[VReg(i)].cast(to: type)
                    }
                } else {
                    return try self.execution.executeWasm(
                        threadingModel: self.threadingModel,
                        function: self.entrypointFunction.handle,
                        type: self.entrypointFunction.type,
                        arguments: [],
                        sp: self.valueStack,
                        pc: self.pc
                    )
                }
            } catch let breakpoint as Execution.Breakpoint {
                let pc = breakpoint.pc
                guard let wasmPc = self.instance.handle.instructionMapping.findWasm(forIseqAddress: pc) else {
                    throw Error.noReverseInstructionMappingAvailable(pc)
                }

                self.currentBreakpoint = (breakpoint, wasmPc)
                return nil
            }
        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [Int] {
            guard let currentBreakpoint else {
                return []
            }

            var result = Execution.captureBacktrace(sp: currentBreakpoint.iseq.sp, store: self.store).symbols.compactMap {
                return self.instance.handle.instructionMapping.findWasm(forIseqAddress: $0.address)
            }
            result.append(currentBreakpoint.wasmPc)

            return result
        }

        deinit {
            self.valueStack.deallocate()
            self.pc.deallocate()
        }
    }

#endif
