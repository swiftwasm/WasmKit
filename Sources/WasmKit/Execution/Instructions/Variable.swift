/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Execution {
    mutating func globalGet(sp: Sp, globalGetOperand: Instruction.GlobalGetOperand) {
        globalGetOperand.global.withValue{
            sp[globalGetOperand.reg] = $0.rawValue
        }
    }
    mutating func globalSet(sp: Sp, globalSetOperand: Instruction.GlobalSetOperand) {
        let value = sp[globalSetOperand.reg]
        globalSetOperand.global.withValue{ $0.rawValue = value }
    }

    mutating func copyStack(sp: Sp, copyStackOperand: Instruction.CopyStackOperand) {
        sp[copyStackOperand.dest] = sp[copyStackOperand.source]
    }
}
