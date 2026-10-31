/// > Note:
/// <https://github.com/WebAssembly/wide-arithmetic/blob/main/proposals/wide-arithmetic/Overview.md>
///
/// Each handler reads every operand before it writes a result, so a result may
/// share a register with an operand. The high half is written first. When the
/// translator relinks both results into the same local, the local ends up with
/// the low half, as the two `local.set`s it replaces would leave it.
extension Execution {
    @inline(__always)
    mutating func i64Add128(sp: Sp, immediate: Instruction.Binary128Operand) {
        let lhsLow = sp[i64: immediate.lhsLow]
        let lhsHigh = sp[i64: immediate.lhsHigh]
        let rhsLow = sp[i64: immediate.rhsLow]
        let rhsHigh = sp[i64: immediate.rhsHigh]
        let (low, carry) = lhsLow.addingReportingOverflow(rhsLow)
        sp[i64: immediate.high] = lhsHigh &+ rhsHigh &+ (carry ? 1 : 0)
        sp[i64: immediate.low] = low
    }

    @inline(__always)
    mutating func i64Sub128(sp: Sp, immediate: Instruction.Binary128Operand) {
        let lhsLow = sp[i64: immediate.lhsLow]
        let lhsHigh = sp[i64: immediate.lhsHigh]
        let rhsLow = sp[i64: immediate.rhsLow]
        let rhsHigh = sp[i64: immediate.rhsHigh]
        let (low, borrow) = lhsLow.subtractingReportingOverflow(rhsLow)
        sp[i64: immediate.high] = lhsHigh &- rhsHigh &- (borrow ? 1 : 0)
        sp[i64: immediate.low] = low
    }

    @inline(__always)
    mutating func i64MulWideS(sp: Sp, immediate: Instruction.MulWideOperand) {
        let lhs = Int64(bitPattern: sp[i64: immediate.lhs])
        let rhs = Int64(bitPattern: sp[i64: immediate.rhs])
        let product = lhs.multipliedFullWidth(by: rhs)
        sp[i64: immediate.high] = UInt64(bitPattern: product.high)
        sp[i64: immediate.low] = product.low
    }

    @inline(__always)
    mutating func i64MulWideU(sp: Sp, immediate: Instruction.MulWideOperand) {
        let product = sp[i64: immediate.lhs].multipliedFullWidth(by: sp[i64: immediate.rhs])
        sp[i64: immediate.high] = product.high
        sp[i64: immediate.low] = product.low
    }
}
