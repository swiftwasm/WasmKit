// The 32-bit immediate of an immediate-operand instruction, as an operand:
// an `i32` takes its bit pattern, an `i64` sign-extends it.

extension Instruction.BinaryImmOperand {
    @inline(__always) var i32: UInt32 { UInt32(bitPattern: imm) }
    @inline(__always) var i64: UInt64 { UInt64(bitPattern: Int64(imm)) }
}

extension Instruction.AccBinaryImmOperand {
    @inline(__always) var i32: UInt32 { UInt32(bitPattern: imm) }
    @inline(__always) var i64: UInt64 { UInt64(bitPattern: Int64(imm)) }
}

extension Instruction.BrIfCmpImmOperand {
    @inline(__always) var i32: UInt32 { UInt32(bitPattern: imm) }
    @inline(__always) var i64: UInt64 { UInt64(bitPattern: Int64(imm)) }
}

extension Instruction.SelectCmpImmOperand {
    @inline(__always) var i32: UInt32 { UInt32(bitPattern: imm) }
    @inline(__always) var i64: UInt64 { UInt64(bitPattern: Int64(imm)) }
}
