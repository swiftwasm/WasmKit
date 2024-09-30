/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension Execution {
    @inline(__always)
    mutating func const32(sp: Sp, immediate: Instruction.Const32Operand) {
        sp[immediate.result] = UntypedValue(storage32: immediate.value)
    }
    @inline(__always)
    mutating func const64(sp: Sp, immediate: Instruction.Const64Operand) {
        sp[immediate.result] = immediate.value
    }
}
