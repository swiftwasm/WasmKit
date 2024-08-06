/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func globalGet(context: inout StackContext, stack: FrameBase, globalGetOperand: Instruction.GlobalGetOperand) throws {
        let value = globalGetOperand.global.withValue{ $0.value }
        stack[globalGetOperand.result] = UntypedValue(value)
    }
    mutating func globalSet(context: inout StackContext, stack: FrameBase, globalSetOperand: Instruction.GlobalSetOperand) throws {
        let value = stack[globalSetOperand.value]
        globalSetOperand.global.withValue{ $0.assign(value) }
    }

    mutating func copyStack(context: inout StackContext, stack: FrameBase, copyStackOperand: Instruction.CopyStackOperand) {
        stack[copyStackOperand.dest] = stack[copyStackOperand.source]
    }
}
