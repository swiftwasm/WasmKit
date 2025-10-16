package struct DebuggerExecution: ~Copyable {
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

    package func captureBacktrace() -> Backtrace {
        return Execution.captureBacktrace(sp: self.valueStack, store: self.store)
    }

    deinit {
        valueStack.deallocate()
    }
}
