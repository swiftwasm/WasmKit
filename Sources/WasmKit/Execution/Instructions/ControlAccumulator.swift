// Fused compare+branch and branch forms that read the integer accumulator.
extension Execution {
    @inline(__always)
    mutating func i32AddImmBrIf(sp: Sp, pc: Pc, ireg: inout UInt64, immediate: Instruction.I32AddImmBrIfOperand) -> (Pc, CodeSlot) {
        let result = sp[i32: immediate.lhs] &+ UInt32(bitPattern: immediate.imm)
        ireg = UInt64(result)
        // Internal code storage and execution-stack slots are disjoint. Fetch
        // the selected handler before writing the result slot so the compiler
        // need not hoist both branch targets across a possibly aliasing store.
        guard _fastPath(result != 0) else {
            let next = pc.next()
            sp[i32: immediate.result] = result
            return next
        }
        let next = pc.advanced(by: Int(immediate.offset)).next()
        sp[i32: immediate.result] = result
        return next
    }

    /// Fused `i32.eq` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32EqAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) == sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ne` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32NeAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) != sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.lt_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32LtSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg).signed < sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.lt_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32LtUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) < sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.gt_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32GtSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg).signed > sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.gt_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32GtUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) > sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.le_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32LeSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg).signed <= sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.le_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32LeUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) <= sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ge_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32GeSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg).signed >= sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ge_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI32GeUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) >= sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.eq` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64EqAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg == sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ne` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64NeAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg != sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.lt_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64LtSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg.signed < sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.lt_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64LtUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg < sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.gt_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64GtSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg.signed > sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.gt_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64GtUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg > sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.le_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64LeSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg.signed <= sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.le_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64LeUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg <= sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ge_s` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64GeSAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg.signed >= sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ge_u` + `br_if` whose left operand is the accumulator.
    @inline(__always)
    mutating func brIfI64GeUAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(ireg >= sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// `br_if` on a condition in the accumulator.
    @inline(__always)
    mutating func brIfAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// `br_if_not` on a condition in the accumulator.
    @inline(__always)
    mutating func brIfNotAcc(sp: Sp, pc: Pc, ireg: UInt64, immediate: Instruction.BrIfAccOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(UInt32(truncatingIfNeeded: ireg) == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
