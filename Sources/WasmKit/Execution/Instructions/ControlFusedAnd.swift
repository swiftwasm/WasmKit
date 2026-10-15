/// Fused bit-test + conditional branch handlers: `i32.and`/`i64.and` followed by
/// a branch on the result.
///
/// Both polarities are separate opcodes, since the complement of a bit test is
/// the same test with the branch inverted. The 64-bit forms are needed because
/// the 32-bit ones only look at the low half of the slot.
extension Execution {
    /// Fused `i32.and` + `br_if`: branch when `(lhs & rhs) != 0`.
    @inline(__always)
    mutating func brIfI32And(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` in Control.swift for the rationale.
        guard _fastPath(sp[i32: immediate.lhs] & sp[i32: immediate.rhs] != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }

    /// Fused `i32.and` + `br_if_not`: branch when `(lhs & rhs) == 0`.
    @inline(__always)
    mutating func brIfNotI32And(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` in Control.swift for the rationale.
        guard _fastPath(sp[i32: immediate.lhs] & sp[i32: immediate.rhs] == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }

    /// Fused `i64.and` + `br_if`: branch when `(lhs & rhs) != 0`.
    @inline(__always)
    mutating func brIfI64And(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` in Control.swift for the rationale.
        guard _fastPath(sp[i64: immediate.lhs] & sp[i64: immediate.rhs] != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }

    /// Fused `i64.and` + `br_if_not`: branch when `(lhs & rhs) == 0`.
    @inline(__always)
    mutating func brIfNotI64And(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` in Control.swift for the rationale.
        guard _fastPath(sp[i64: immediate.lhs] & sp[i64: immediate.rhs] == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
