#if WasmDebuggingSupport

    package struct Debugger: ~Copyable {
        let valueStack: Sp
        let execution: Execution
        let store: Store

        package init(store: Store) {
            let limit = store.engine.configuration.stackSize / MemoryLayout<StackSlot>.stride
            self.valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
            self.store = store
            self.execution = Execution(store: StoreRef(store), stackEnd: valueStack.advanced(by: limit))
        }

        package func toggleBreakpoint() {

        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [UInt64] {
            return Execution.captureBacktrace(sp: self.valueStack, store: self.store).symbols.map {
                switch $0.debuggingAddress {
                case .iseq: fatalError()
                case .wasm(let pc): return pc
                }
            }
        }

        deinit {
            valueStack.deallocate()
        }
    }

#endif
