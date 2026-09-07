/// Fused `i64.eqz` + conditional branch handlers.
///
/// `brIf`/`brIfNot` test `sp[i32: condition]`, i.e. only the low 32 bits of the
/// condition slot. That is fine for an `i32.eqz` result (which the translator
/// folds into a plain `brIfNot`/`brIf` on the input) but wrong for a 64-bit
/// zero test: `0x1_0000_0000` has a zero low half and a non-zero value. These
/// two opcodes therefore read the whole 64-bit slot.
///
/// They live in their own file rather than in `Control.swift` only to keep the
/// diff of this change out of that file.
extension Execution {
    /// `i64.eqz x` followed by `br_if`: branch when `x == 0`.
    @inline(__always)
    mutating func brIfI64Eqz(sp: Sp, pc: Pc, immediate: Instruction.BrIfOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` in Control.swift for why this must stay a real
        // branch and not be if-converted into a `csel`.
        guard _fastPath(sp[i64: immediate.condition] == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }

    /// `i64.eqz x` followed by `br_if_not`: branch when `x != 0`.
    @inline(__always)
    mutating func brIfI64Nez(sp: Sp, pc: Pc, immediate: Instruction.BrIfOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` in Control.swift for the rationale.
        guard _fastPath(sp[i64: immediate.condition] != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
