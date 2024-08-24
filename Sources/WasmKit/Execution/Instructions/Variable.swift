/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func globalGet(context: inout StackContext, sp: Sp, globalGetOperand: Instruction.GlobalGetOperand) throws {
        globalGetOperand.global.withValue{
            sp[globalGetOperand.result] = $0.rawValue
        }
    }
    mutating func globalSet(context: inout StackContext, sp: Sp, globalSetOperand: Instruction.GlobalSetOperand) throws {
        let value = sp[globalSetOperand.value]
        globalSetOperand.global.withValue{ $0.rawValue = value }
    }

    mutating func copyStack(context: inout StackContext, sp: Sp, copyStackOperand: Instruction.CopyStackOperand) {
        sp[copyStackOperand.dest] = sp[copyStackOperand.source]
    }
}
