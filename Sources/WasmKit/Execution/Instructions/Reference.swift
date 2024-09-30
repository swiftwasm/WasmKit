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
