/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension ExecutionState {
    mutating func select(runtime: Runtime, context: inout StackContext, stack: FrameBase, selectOperand: Instruction.SelectOperand) throws {
        let flagValue = stack[selectOperand.condition]
        guard case let .i32(flag) = flagValue else {
            throw Trap.stackValueTypesMismatch(expected: .i32, actual: flagValue.type)
        }
        let selected = flag != 0 ? selectOperand.onTrue : selectOperand.onFalse
        let value = stack[selected]
        stack[selectOperand.result] = value
    }
}
