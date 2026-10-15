// Fused float compare+branch forms that read the float accumulator.
extension Execution {
    @inline(__always)
    mutating func brIfF64EqAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(freg == sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfF64NeAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(freg != sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfF64LtAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(freg < sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfF64LeAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(freg <= sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfF64GtAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(freg > sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfF64GeAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(freg >= sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfNotF64LtAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(freg < sp[f64: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfNotF64LeAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(freg <= sp[f64: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfNotF64GtAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(freg > sp[f64: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    @inline(__always)
    mutating func brIfNotF64GeAcc(sp: Sp, pc: Pc, freg: Double, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(freg >= sp[f64: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
