/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#reference-instructions>
extension ExecutionState {
    mutating func refNull(sp: Sp, refNullOperand: Instruction.RefNullOperand) {
        let value: Value
        switch refNullOperand.type {
        case .externRef:
            value = .ref(.extern(nil))
        case .funcRef:
            value = .ref(.function(nil))
        }
        sp[refNullOperand.result] = UntypedValue(value)
    }
    mutating func refIsNull(sp: Sp, refIsNullOperand: Instruction.RefIsNullOperand) {
        let value = sp[refIsNullOperand.value]

        let result: Value
        if value.isNullRef {
            result = .i32(1)
        } else {
            result = .i32(0)
        }
        sp[refIsNullOperand.result] = UntypedValue(result)
    }
    mutating func refFunc(sp: Sp, refFuncOperand: Instruction.RefFuncOperand) {
        let function = currentInstance(sp: sp).functions[Int(refFuncOperand.index)]
        sp[refFuncOperand.result] = UntypedValue(.ref(.function(from: function)))
    }
}
