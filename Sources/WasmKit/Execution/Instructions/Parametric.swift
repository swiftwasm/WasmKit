/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension ExecutionState {
    mutating func select(context: inout StackContext, stack: FrameBase, selectOperand: Instruction.SelectOperand) throws {
        let flag = stack[selectOperand.condition].i32
        let selected = flag != 0 ? selectOperand.onTrue : selectOperand.onFalse
        let value = stack[selected]
        stack[selectOperand.result] = value
    }
}
