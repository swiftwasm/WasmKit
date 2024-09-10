/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension ExecutionState {
    mutating func select(sp: Sp, selectOperand: Instruction.SelectOperand) {
        let flag = sp[i32: selectOperand.condition]
        let selected = flag != 0 ? selectOperand.onTrue : selectOperand.onFalse
        let value = sp[selected]
        sp[selectOperand.result] = value
    }
}
