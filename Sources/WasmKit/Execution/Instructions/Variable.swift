/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Execution {
    mutating func globalGet(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue{
            sp[immediate.reg] = $0.rawValue
        }
    }
    mutating func globalSet(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        let value = sp[immediate.reg]
        immediate.global.withValue{ $0.rawValue = value }
    }

    mutating func copyStack(sp: Sp, immediate: Instruction.CopyStackOperand) {
        sp[immediate.dest] = sp[immediate.source]
    }
}
