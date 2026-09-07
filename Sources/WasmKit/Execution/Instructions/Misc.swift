/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Execution {
    /// `global.get` on a global whose value fits a single 64-bit stack slot.
    ///
    /// The global's shape is fixed by its type, so the translator picks this
    /// handler for every non-`v128` global and the handler is a plain slot copy:
    /// no tag test and no type load. See `globalGetV128` for the wide form.
    mutating func globalGet(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue {
            sp[immediate.reg] = UntypedValue(storage: $0.rawStorage.lo)
        }
    }
    mutating func globalSet(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue {
            $0.rawStorage.lo = sp[immediate.reg].storage
        }
    }
    mutating func globalGetV128(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue {
            let raw = $0.rawStorage
            sp[immediate.reg] = UntypedValue(storage: raw.lo)
            sp[immediate.regHi] = UntypedValue(storage: raw.hi)
        }
    }
    mutating func globalSetV128(sp: Sp, immediate: Instruction.GlobalAndVRegOperand) {
        immediate.global.withValue {
            $0.rawStorage = V128Storage(lo: sp[immediate.reg].storage, hi: sp[immediate.regHi].storage)
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
        case .exnRef:
            value = .ref(.exception(nil))
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
