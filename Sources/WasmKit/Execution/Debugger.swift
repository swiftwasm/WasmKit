#if WasmDebuggingSupport

    package struct Debugger: ~Copyable {
        enum Error: Swift.Error {
            case entrypointFunctionNotFound
        }

        let valueStack: Sp
        let execution: Execution
        let store: Store

        private let module: Module
        private let instance: Instance

        /// Addresses of each function in the code section of ``module``
        let functionAddresses: [Int]
        let entrypointFunction: Function

        package init(module: Module, store: Store, imports: Imports) throws(Error) {
            let limit = store.engine.configuration.stackSize / MemoryLayout<StackSlot>.stride
            let instance = try module.instantiate(store: store, imports: imports, isDebuggable: true)

            guard case .function(let entrypointFunction) = instance.exports["_start"] else {
                throw Error.entrypointFunctionNotFound
            }

            self.instance = instance
            self.module = module
            self.functionAddresses = module.functions.map { $0.code.originalAddress }
            self.entrypointFunction = entrypointFunction
            self.valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
            self.store = store
            self.execution = Execution(store: StoreRef(store), stackEnd: valueStack.advanced(by: limit))
        }

        package mutating func stopAtEntrypoint() throws(Error) {
            try self.toggleBreakpoint(address: self.originalAddress(function: entrypointFunction))
        }

        package func originalAddress(function: Function) throws(Error) -> Int {
            precondition(function.handle.isWasm)

            switch function.handle.wasm.code {
            case .debuggable(let wasm, _):
                return wasm.originalAddress
            case .uncompiled:
                try function.handle.wasm.ensureCompiled(store: StoreRef(self.store))
                return try self.originalAddress(function: function)
            case .compiled:
                print(function.handle.wasm.code)
                fatalError()
            }
        }

        package mutating func toggleBreakpoint(address: Int) throws(Error) {
            print("attempt to toggle a breakpoint at \(address)")
        }

        /// Array of addresses in the Wasm binary of executed instructions on the call stack.
        package var currentCallStack: [Int] {
            guard let instance = self.valueStack.currentInstance else { return [] }
            let isDebuggable = instance.isDebuggable
            print("isDebuggable is \(isDebuggable)")

            return Execution.captureBacktrace(sp: self.valueStack, store: self.store).symbols.map {
                instance.iSeqToWasmMapping[$0.address]!
            }
        }

        deinit {
            valueStack.deallocate()
        }
    }

#endif
