/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func localGet(runtime: Runtime, stack: inout Stack, locals: UnsafeMutablePointer<Value>, index: LocalIndex) {
        let value = locals[Int(index)]
        stack.push(value: value)
    }
    mutating func localSet(runtime: Runtime, stack: inout Stack, locals: UnsafeMutablePointer<Value>, index: LocalIndex) {
        let value = stack.popValue()
        locals[Int(index)] = value
    }
    mutating func localTee(runtime: Runtime, stack: inout Stack, locals: UnsafeMutablePointer<Value>, index: LocalIndex) {
        let value = stack.topValue
        locals[Int(index)] = value
    }
    mutating func globalGet(runtime: Runtime, stack: inout Stack, index: GlobalIndex) throws {
        let address = Int(currentModule(store: runtime.store, stack: &stack).globalAddresses[Int(index)])
        let globals = runtime.store.globals
        let value = globals[address].value
        stack.push(value: value)
    }

    mutating func globalSet(runtime: Runtime, stack: inout Stack, index: GlobalIndex) throws {
        let address = Int(currentModule(store: runtime.store, stack: &stack).globalAddresses[Int(index)])
        try doGlobalSet(stack: &stack, address: address, &runtime.store.globals)
    }
    mutating func doGlobalSet(stack: inout Stack, address: GlobalAddress, _ globals: inout [GlobalInstance]) throws {
        let value = stack.popValue()
        globals[address].value = value
    }
}
