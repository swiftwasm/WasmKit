#if WasmDebuggingSupport

    extension [Int] {
        func binarySearch(nextClosestTo value: Int) -> Int? {
            switch self.count {
            case 0:
                return nil
            default:
                var slice = self[0..<self.count]
                while slice.count > 1 {
                    let middle = (slice.endIndex - slice.startIndex) / 2
                    if slice[middle] < value {
                        // Not found anything in the lower half, assigning higher half to `slice`.
                        slice = slice[(middle + 1)..<slice.endIndex]
                    } else {
                        // Not found anything in the higher half, assigning lower half to `slice`.
                        slice = slice[slice.startIndex..<middle]
                    }
                }

                return self[slice.startIndex]
            }
        }
    }

    extension Instance {
        func findIseq(forWasmAddress address: Int) throws(Debugger.Error) -> (iseq: Pc, wasm: Int) {
            // Look in the main mapping
            if let iseq = handle.wasmToIseqMapping[address] {
                return (iseq, address)
            }

            // If nothing found, find the closest Wasm address using binary search
            guard let nextAddress = handle.wasmMappings.binarySearch(nextClosestTo: address),
                // Look in the main mapping again with the next closest address if binary search produced anything
                let iseq = handle.wasmToIseqMapping[nextAddress]
            else {
                throw Debugger.Error.noInstructionMappingAvailable(address)
            }

            return (iseq, nextAddress)
        }
    }

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
        private let entrypointFunction: Function

        /// Threading model of the Wasm engine configuration cached for a potentially hot path.
        private let threadingModel: EngineConfiguration.ThreadingModel

        private(set) var breakpoints = [Int: CodeSlot]()

        private var currentBreakpoint: (iseq: Execution.Breakpoint, wasmPc: Int)?

        private var pc = Pc.allocate(capacity: 1)

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

        package mutating func stopAtEntrypoint() throws {
            try self.enableBreakpoint(address: self.originalAddress(function: entrypointFunction))
        }

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

        package mutating func enableBreakpoint(address: Int) throws(Error) {
            guard self.breakpoints[address] == nil else {
                return
            }

            let (iseq, wasm) = try self.instance.findIseq(forWasmAddress: address)

            self.breakpoints[wasm] = iseq.pointee
            iseq.pointee = Instruction.breakpoint.headSlot(threadingModel: self.threadingModel)
        }

        package mutating func disableBreakpoint(address: Int) throws(Error) {
            guard let oldCodeSlot = self.breakpoints[address] else {
                return
            }

            let (iseq, wasm) = try self.instance.findIseq(forWasmAddress: address)

            self.breakpoints[wasm] = nil
            iseq.pointee = oldCodeSlot
        }

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
                guard let wasmPc = self.instance.handle.iseqToWasmMapping[pc] else {
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
                return self.instance.handle.iseqToWasmMapping[$0.address]
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
