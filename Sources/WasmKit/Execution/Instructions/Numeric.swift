/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension ExecutionState {
    @inline(__always)
    mutating func constI32(sp: Sp, x0: inout X0, const32Operand: Instruction.Const32Operand) {
        writePReg(&x0, const32Operand.value)
    }
    @inline(__always)
    mutating func constI64(sp: Sp, x0: inout X0, const64Operand: Instruction.Const64Operand) {
        writePReg(&x0, const64Operand.value)
    }
    @inline(__always)
    mutating func constF32(sp: Sp, d0: inout D0, const32Operand: Instruction.Const32Operand) {
        writePReg(&d0, Float32(bitPattern: const32Operand.value))
    }
    @inline(__always)
    mutating func constF64(sp: Sp, d0: inout D0, const64Operand: Instruction.Const64Operand) {
        writePReg(&d0, Float64(bitPattern: const64Operand.value))
    }
}
