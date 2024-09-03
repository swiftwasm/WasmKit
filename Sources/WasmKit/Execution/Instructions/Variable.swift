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
    mutating func copyX0ToStackI32(sp: Sp, x0: X0, dest: VReg) {
        sp[dest] = .i32(UInt32(x0 & 0xffffffff))
    }
    mutating func copyX0ToStackI64(sp: Sp, x0: X0, dest: VReg) {
        sp[dest] = .i64(UInt64(x0))
    }
    mutating func copyD0ToStackF32(sp: Sp, d0: D0, dest: VReg) {
        sp[dest] = .f32(Float(d0))
    }
    mutating func copyD0ToStackF64(sp: Sp, d0: D0, dest: VReg) {
        sp[dest] = .f64(d0)
    }
}
