/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func globalGet(sp: Sp, globalGetOperand: Instruction.GlobalGetOperand) {
        globalGetOperand.global.withValue{
            sp[VReg(globalGetOperand.reg)] = $0.rawValue
        }
    }
    mutating func globalSet(sp: Sp, globalSetOperand: Instruction.GlobalSetOperand) {
        let value = sp[VReg(globalSetOperand.reg)]
        globalSetOperand.global.withValue{ $0.rawValue = value }
    }

    mutating func copyStack(sp: Sp, copyStackOperand: Instruction.CopyStackOperand) {
        sp[copyStackOperand.dest] = sp[copyStackOperand.source]
    }
    mutating func copyR0ToStack(sp: Sp, r0: R0, dest: VReg) {
        preconditionFailure()
    }
}
