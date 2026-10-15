/// Fused float compare + conditional branch handlers.
///
/// These are the float half of the compare+branch fusion that integer
/// comparisons already have. The translator emits one of these instead of writing
/// the comparison result into a stack slot and reloading it in `brIf`, which
/// removes one dispatch, one store and one load per site.
///
/// # Why both polarities are opcodes
///
/// For integers the translator fuses a `br_if_not` by flipping the predicate
/// (`lt_s` -> `ge_s`). That is invalid for floats: when either operand is NaN
/// the comparison is *unordered* and both `a < b` and `a >= b` are false, so
/// `!(a < b)` is not `a >= b`. Every predicate therefore gets its own opcode
/// per branch polarity.
///
/// Only six opcodes per float type are needed for the twelve
/// (predicate, polarity) pairs, because two of the twelve coincide exactly:
///
/// | Wasm predicate | `br_if` (ifTrue) | `br_if_not` (ifFalse) |
/// |---|---|---|
/// | `eq a, b` | `brIf*Eq a, b`    | `brIf*Ne a, b`    |
/// | `ne a, b` | `brIf*Ne a, b`    | `brIf*Eq a, b`    |
/// | `lt a, b` | `brIf*Lt a, b`    | `brIfNot*Lt a, b` |
/// | `gt a, b` | `brIf*Lt b, a`    | `brIfNot*Lt b, a` |
/// | `le a, b` | `brIf*Le a, b`    | `brIfNot*Le a, b` |
/// | `ge a, b` | `brIf*Le b, a`    | `brIfNot*Le b, a` |
///
/// `ne` is the exact complement of `eq` even under NaN (`f64.ne` is defined as
/// `!(a == b)`), and `a > b` is `b < a` bit for bit including the unordered
/// case, so no predicate is ever *complemented* in the NaN-unsafe sense.
///
/// # NaN truth table, and the AArch64 condition codes it maps to
///
/// `fcmp` on unordered operands sets `N=0, Z=0, C=1, V=1`. Reading the table
/// below against those flags gives the condition code each handler must use;
/// the assembly is checked against this (`objdump --disassemble-symbols`):
///
/// | handler | branch taken when | NaN operand | AArch64 cond (branch taken) |
/// |---|---|---|---|
/// | `brIf*Eq`    | `a == b`    | **false** | `EQ` |
/// | `brIf*Ne`    | `a != b`    | **true**  | `NE` |
/// | `brIf*Lt`    | `a < b`     | **false** | `MI` |
/// | `brIf*Le`    | `a <= b`    | **false** | `LS` |
/// | `brIfNot*Lt` | `!(a < b)`  | **true**  | `PL` |
/// | `brIfNot*Le` | `!(a <= b)` | **true**  | `HI` |
///
/// Swift's `<`, `<=`, `==` on `Float`/`Double` are the IEEE-754 ordered
/// comparisons (false when either operand is NaN) and `!=` is their exact
/// negation, which is what Wasm's `f{32,64}.{eq,ne,lt,le}` require, so the
/// bodies below are written as the predicate itself and the compiler picks the
/// condition code.
///
/// Every handler keeps `brIf`'s real-branch shape (`_fastPath`, no `csel`);
/// see `brIf` in `Control.swift` for the rationale.
extension Execution {

    // MARK: f32

    /// Fused `f32.eq` + `br_if`. Not taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF32Eq(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f32: immediate.lhs] == sp[f32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f32.ne` + `br_if`, and the `br_if_not` form of `f32.eq`.
    /// Taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF32Ne(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f32: immediate.lhs] != sp[f32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f32.lt` + `br_if`. Not taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF32Lt(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f32: immediate.lhs] < sp[f32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f32.le` + `br_if`. Not taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF32Le(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f32: immediate.lhs] <= sp[f32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f32.lt` + `br_if_not`. **Taken** when either operand is NaN --
    /// this is `!(a < b)`, which is *not* `a >= b`.
    @inline(__always)
    mutating func brIfNotF32Lt(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(sp[f32: immediate.lhs] < sp[f32: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f32.le` + `br_if_not`. **Taken** when either operand is NaN.
    @inline(__always)
    mutating func brIfNotF32Le(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(sp[f32: immediate.lhs] <= sp[f32: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }

    // MARK: f64

    /// Fused `f64.eq` + `br_if`. Not taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF64Eq(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f64: immediate.lhs] == sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f64.ne` + `br_if`, and the `br_if_not` form of `f64.eq`.
    /// Taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF64Ne(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f64: immediate.lhs] != sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f64.lt` + `br_if`. Not taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF64Lt(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f64: immediate.lhs] < sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f64.le` + `br_if`. Not taken when either operand is NaN.
    @inline(__always)
    mutating func brIfF64Le(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[f64: immediate.lhs] <= sp[f64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f64.lt` + `br_if_not`. **Taken** when either operand is NaN --
    /// this is `!(a < b)`, which is *not* `a >= b`.
    @inline(__always)
    mutating func brIfNotF64Lt(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(sp[f64: immediate.lhs] < sp[f64: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `f64.le` + `br_if_not`. **Taken** when either operand is NaN.
    @inline(__always)
    mutating func brIfNotF64Le(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(!(sp[f64: immediate.lhs] <= sp[f64: immediate.rhs])) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
