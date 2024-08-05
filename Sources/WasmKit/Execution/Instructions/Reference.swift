/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#reference-instructions>
extension ExecutionState {
    mutating func refNull(runtime: Runtime, context: inout StackContext, stack: FrameBase, refNullOperand: Instruction.RefNullOperand) {
        let value: Value
        switch refNullOperand.type {
        case .externRef:
            value = .ref(.extern(nil))
        case .funcRef:
            value = .ref(.function(nil))
        }
        stack[refNullOperand.result] = value
    }
    mutating func refIsNull(runtime: Runtime, context: inout StackContext, stack: FrameBase, refIsNullOperand: Instruction.RefIsNullOperand) {
        let value = stack[refIsNullOperand.value]

        let result: Value
        switch value {
        case .ref(.extern(nil)), .ref(.function(nil)):
            result = .i32(1)
        case .ref(.extern(_)), .ref(.function(_)):
            result = .i32(0)
        default:
            fatalError("Invalid type \(value.type) for `\(#function)` implementation")
        }
        stack[refIsNullOperand.result] = result
    }
    mutating func refFunc(runtime: Runtime, context: inout StackContext, stack: FrameBase, refFuncOperand: Instruction.RefFuncOperand) {
        let module = runtime.store.module(address: context.currentFrame.module)
        let functionAddress = module.functionAddresses[Int(refFuncOperand.index)]
        stack[refFuncOperand.result] = .ref(.function(functionAddress))
    }
}
