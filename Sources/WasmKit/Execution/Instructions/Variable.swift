/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func globalGet(runtime: Runtime, context: inout StackContext, stack: FrameBase, globalGetOperand: Instruction.GlobalGetOperand) throws {
        let value = currentGlobalCache.get(index: globalGetOperand.index, runtime: runtime, context: &context)
        stack[globalGetOperand.result] = UntypedValue(value)
    }
    mutating func globalSet(runtime: Runtime, context: inout StackContext, stack: FrameBase, globalSetOperand: Instruction.GlobalSetOperand) throws {
        let value = stack[globalSetOperand.value]
        currentGlobalCache.set(index: globalSetOperand.index, value: value, runtime: runtime, context: &context)
    }

    mutating func copyStack(runtime: Runtime, context: inout StackContext, stack: FrameBase, copyStackOperand: Instruction.CopyStackOperand) {
        stack[copyStackOperand.dest] = stack[copyStackOperand.source]
    }
}
