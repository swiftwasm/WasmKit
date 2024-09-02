/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension ExecutionState {
    @inline(__always)
    mutating func const32(sp: Sp, const32Operand: Instruction.Const32Operand) {
        sp[const32Operand.result] = UntypedValue(storage32: const32Operand.value)
    }
    @inline(__always)
    mutating func const64(sp: Sp, pc: Pc, const64Operand: Instruction.Const64Operand) -> Pc {
        sp[VReg(const64Operand.result)] = const64Operand.value
        return pc
    }
}
