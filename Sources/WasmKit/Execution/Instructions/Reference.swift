/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#reference-instructions>
extension ExecutionState {
    mutating func refNull(context: inout StackContext, stack: FrameBase, refNullOperand: Instruction.RefNullOperand) {
        let value: Value
        switch refNullOperand.type {
        case .externRef:
            value = .ref(.extern(nil))
        case .funcRef:
            value = .ref(.function(nil))
        }
        stack[refNullOperand.result] = UntypedValue(value)
    }
    mutating func refIsNull(context: inout StackContext, stack: FrameBase, refIsNullOperand: Instruction.RefIsNullOperand) {
        let value = stack[refIsNullOperand.value]

        let result: Value
        if value.isNullRef {
            result = .i32(1)
        } else {
            result = .i32(0)
        }
        stack[refIsNullOperand.result] = UntypedValue(result)
    }
    mutating func refFunc(context: inout StackContext, stack: FrameBase, refFuncOperand: Instruction.RefFuncOperand) {
        let function = context.currentInstance.functions[Int(refFuncOperand.index)]
        stack[refFuncOperand.result] = UntypedValue(.ref(.function(from: function)))
    }
}
