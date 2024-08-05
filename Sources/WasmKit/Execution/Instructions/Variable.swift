/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func globalGet(runtime: Runtime, context: inout StackContext, stack: FrameBase, globalGetOperand: Instruction.GlobalGetOperand) throws {
        let address = Int(currentModule(store: runtime.store, stack: &context).globalAddresses[Int(globalGetOperand.index)])
        let globals = runtime.store.globals
        let value = globals[address].value
        stack[globalGetOperand.result] = value
    }
    mutating func globalSet(runtime: Runtime, context: inout StackContext, stack: FrameBase, globalSetOperand: Instruction.GlobalSetOperand) throws {
        let address = Int(currentModule(store: runtime.store, stack: &context).globalAddresses[Int(globalSetOperand.index)])
        let value = stack[globalSetOperand.value]
        runtime.store.globals[address].value = value
    }

    mutating func copyStack(runtime: Runtime, context: inout StackContext, stack: FrameBase, copyStackOperand: Instruction.CopyStackOperand) {
        stack[copyStackOperand.dest] = stack[copyStackOperand.source]
    }
}
