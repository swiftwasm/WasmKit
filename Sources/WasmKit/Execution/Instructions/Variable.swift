/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func localGet(runtime: Runtime, stack: inout Stack, locals: UnsafeMutablePointer<Value>, localGetOperand: Instruction.LocalGetOperand) {
        let value = locals[Int(localGetOperand.index)]
        stack[localGetOperand.result] = value
    }
    mutating func localSet(runtime: Runtime, stack: inout Stack, locals: UnsafeMutablePointer<Value>, localSetOperand: Instruction.LocalSetOperand) {
        let value = stack[localSetOperand.value]
        locals[Int(localSetOperand.index)] = value
    }
    mutating func localTee(runtime: Runtime, stack: inout Stack, locals: UnsafeMutablePointer<Value>, localTeeOperand: Instruction.LocalTeeOperand) {
        let value = stack[localTeeOperand.value]
        locals[Int(localTeeOperand.index)] = value
    }
    mutating func globalGet(runtime: Runtime, stack: inout Stack, globalGetOperand: Instruction.GlobalGetOperand) throws {
        let address = Int(currentModule(store: runtime.store, stack: &stack).globalAddresses[Int(globalGetOperand.index)])
        let globals = runtime.store.globals
        let value = globals[address].value
        stack[globalGetOperand.result] = value
    }
    mutating func globalSet(runtime: Runtime, stack: inout Stack, globalSetOperand: Instruction.GlobalSetOperand) throws {
        let address = Int(currentModule(store: runtime.store, stack: &stack).globalAddresses[Int(globalSetOperand.index)])
        let value = stack[globalSetOperand.value]
        runtime.store.globals[address].value = value
    }

    mutating func copyStack(runtime: Runtime, stack: inout Stack, copyStackOperand: Instruction.CopyStackOperand) {
        stack[copyStackOperand.dest] = stack[copyStackOperand.source]
    }
}
