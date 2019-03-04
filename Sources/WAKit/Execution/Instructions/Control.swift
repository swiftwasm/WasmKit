/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension Runtime {
    func execute(control instruction: ControlInstruction) throws {
        switch instruction {
        case .unreachable:
            throw Trap.unreachable
        case .nop:
            return
        case let .block(type, expression):
            let label = Label(arity: type.count, instrucions: [])
            stack.push(label)
            try execute(expression.instructions)

        case let .loop(type, expression):
            let label = Label(arity: type.count, instrucions: [instruction])
            stack.push(label)
            try execute(expression.instructions)

        default:
            throw Trap.unimplemented()
        }
    }
}
