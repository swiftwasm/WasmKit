/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension ExecutionState {
    mutating func select(sp: Sp, pc: Pc) throws -> Pc {
        var pc = pc
        let selectOperand = pc.read(Instruction.SelectOperand.self)
        let flag = sp[selectOperand.condition].i32
        let selected = flag != 0 ? selectOperand.onTrue : selectOperand.onFalse
        let value = sp[selected]
        sp[selectOperand.result] = value
        return pc
    }
}
