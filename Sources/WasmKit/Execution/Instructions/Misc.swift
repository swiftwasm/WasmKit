/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Execution {
    mutating func globalGet(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue {
            switch $0.storage {
            case .scalar(let raw):
                sp[immediate.reg] = raw
            case .v128(let v):
                sp[immediate.reg] = UntypedValue(storage: v.lo)
                let regHi = LLVReg(storage: immediate.reg.value + Int64(MemoryLayout<StackSlot>.size))
                sp[regHi] = UntypedValue(storage: v.hi)
            }
        }
    }
    mutating func globalSet(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue {
            switch $0.globalType.valueType {
            case .v128:
                let lo = sp[immediate.reg].i64
                let regHi = LLVReg(storage: immediate.reg.value + Int64(MemoryLayout<StackSlot>.size))
                let hi = sp[regHi].i64
                $0.storage = .v128(V128Storage(lo: lo, hi: hi))
            case .i32, .i64, .f32, .f64, .ref:
                let value = sp[immediate.reg]
                $0.storage = .scalar(value)
            }
        }
    }

    mutating func copyStack(sp: Sp, immediate: Instruction.CopyStackOperand) {
        sp[immediate.dest] = sp[immediate.source]
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#reference-instructions>
extension Execution {
    mutating func refNull(sp: Sp, immediate: Instruction.RefNullOperand) {
        let value: Value
        switch immediate.type {
        case .externRef:
            value = .ref(.extern(nil))
        case .funcRef:
            value = .ref(.function(nil))
        }
        sp[immediate.result] = UntypedValue(value)
    }
    mutating func refIsNull(sp: Sp, immediate: Instruction.RefIsNullOperand) {
        let value = sp[immediate.value]

        let result: Value
        if value.isNullRef {
            result = .i32(1)
        } else {
            result = .i32(0)
        }
        sp[immediate.result] = UntypedValue(result)
    }
    mutating func refFunc(sp: Sp, immediate: Instruction.RefFuncOperand) {
        let function = currentInstance(sp: sp).functions[Int(immediate.index)]
        sp[immediate.result] = UntypedValue(.ref(.function(from: function)))
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension Execution {
    @inline(__always)
    mutating func const32(sp: Sp, immediate: Instruction.Const32Operand) {
        sp[immediate.result] = UntypedValue(storage32: immediate.value)
    }
    @inline(__always)
    mutating func const64(sp: Sp, immediate: Instruction.Const64Operand) {
        sp[immediate.result] = immediate.value
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension Execution {
    mutating func select(sp: Sp, immediate: Instruction.SelectOperand) {
        let flag = sp[i32: immediate.condition]
        let selected = flag != 0 ? immediate.onTrue : immediate.onFalse
        let value = sp[selected]
        sp[immediate.result] = value
    }
}
