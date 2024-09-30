/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension Execution {
    mutating func select(sp: Sp, immediate: Instruction.SelectOperand) {
        let flag = sp[i32: immediate.condition]
        let selected = flag != 0 ? immediate.onTrue : immediate.onFalse
        let value = sp[selected]
        sp[immediate.result] = value
    }
}
