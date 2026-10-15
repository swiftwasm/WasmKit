// Fused compare-against-a-constant and bit-test-against-a-constant branches.
extension Execution {
    /// Fused `i32.eq` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32EqImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] == immediate.i32) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ne` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32NeImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] != immediate.i32) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.lt_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32LtSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed < immediate.i32.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.lt_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32LtUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] < immediate.i32) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.gt_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32GtSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed > immediate.i32.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.gt_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32GtUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] > immediate.i32) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.le_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32LeSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed <= immediate.i32.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.le_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32LeUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] <= immediate.i32) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ge_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32GeSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed >= immediate.i32.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ge_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI32GeUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] >= immediate.i32) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Branch when `(i32 lhs & imm) != 0`.
    @inline(__always)
    mutating func brIfI32AndImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] & immediate.i32 != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Branch when `(i32 lhs & imm) == 0`.
    @inline(__always)
    mutating func brIfNotI32AndImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] & immediate.i32 == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.eq` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64EqImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] == immediate.i64) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ne` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64NeImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] != immediate.i64) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.lt_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64LtSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed < immediate.i64.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.lt_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64LtUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] < immediate.i64) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.gt_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64GtSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed > immediate.i64.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.gt_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64GtUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] > immediate.i64) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.le_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64LeSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed <= immediate.i64.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.le_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64LeUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] <= immediate.i64) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ge_s` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64GeSImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed >= immediate.i64.signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ge_u` against a constant + `br_if`.
    @inline(__always)
    mutating func brIfI64GeUImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] >= immediate.i64) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Branch when `(i64 lhs & imm) != 0`.
    @inline(__always)
    mutating func brIfI64AndImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] & immediate.i64 != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Branch when `(i64 lhs & imm) == 0`.
    @inline(__always)
    mutating func brIfNotI64AndImm(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpImmOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] & immediate.i64 == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
