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
        func findIseq(forWasmAddress address: Int) throws(Debugger.Error) -> Pc {
            // Look in the main mapping first
            guard
                let iseq = handle.wasmToIseqMapping[address]
                    // If nothing found, find the closest Wasm address using binary search
                    ?? handle.wasmMappings.binarySearch(nextClosestTo: address)
                    // Look in the main mapping again with the next closest address if binary search produced anything
                    .flatMap({ handle.wasmToIseqMapping[$0] })
            else {
                throw Debugger.Error.noInstructionMappingAvailable(address)
            }

            return iseq
        }
    }

    package struct Debugger: ~Copyable {
        package enum Error: Swift.Error {
            case entrypointFunctionNotFound
            case noInstructionMappingAvailable(Int)
        }

        private let valueStack: Sp
        private let execution: Execution
        private let store: Store

        /// Parsed in-memory representation of a Wasm module instantiated for debugging.
        private let module: Module

        /// Instance of parsed Wasm ``module``.
        private let instance: Instance

        /// Reference to the entrypoint function of the currently debugged module, for use in ``stopAtEntrypoint``.
        private let entrypointFunction: Function

        /// Threading model of the Wasm engine configuration cached for a potentially hot path.
        private let threadingModel: EngineConfiguration.ThreadingModel

        private var breakpoints = [Int: CodeSlot]()

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

            let iseq = try self.instance.findIseq(forWasmAddress: address)

            self.breakpoints[address] = iseq.pointee
            iseq.pointee = Instruction.breakpoint.headSlot(threadingModel: self.threadingModel)
        }

        package mutating func disableBreakpoint(address: Int) throws(Error) {
            print("attempt to toggle a breakpoint at \(address)")

            guard let oldCodeSlot = self.breakpoints[address] else {
                print("breakpoint at \(address) already disabled")
                return
            }

            let iseq = try self.instance.findIseq(forWasmAddress: address)

            self.breakpoints[address] = nil
            iseq.pointee = oldCodeSlot
        }

        package func run() throws {
            try self.entrypointFunction()
        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [Int] {
            let isDebuggable = self.instance.handle.isDebuggable
            print("isDebuggable is \(isDebuggable)")

            return Execution.captureBacktrace(sp: self.valueStack, store: self.store).symbols.map {
                self.instance.handle.iseqToWasmMapping[$0.address]!
            }
        }

        deinit {
            valueStack.deallocate()
        }
    }

#endif
