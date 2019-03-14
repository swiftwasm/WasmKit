/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension Runtime {
    func execute(control instruction: ControlInstruction) throws -> ExecutionResult {
        switch instruction {
        case .unreachable:
            throw Trap.unreachable

        case .nop:
            break

        case let .block(type, expression):
            let label = Label(arity: type.count, continuation: [])
            try enterBlock(instructions: expression.instructions, label: label)

        case let .loop(_, expression):
            let label = Label(arity: 0, continuation: [instruction])
            try enterBlock(instructions: expression.instructions, label: label)

        case let .br(labelIndex):
            let label = try stack.get(Label.self, index: Int(labelIndex))
            let values = try (0 ..< label.arity).map { _ in try stack.pop(Value.self) }
            for _ in 0 ... labelIndex {
                while stack.peek() is Value {
                    _ = stack.pop()
                }
                try stack.pop(Label.self)
            }
            for value in values {
                stack.push(value)
            }
            return .break(labelIndex)

        case let .brIf(labelIndex):
            let value = try stack.pop(I32.self)
            if value != 0 {
                return try execute(control: .br(labelIndex))
            }

        case let .call(functionIndex):
            let frame = try stack.get(current: Frame.self)
            let functionAddress = frame.module.functionAddresses[Int(functionIndex)]
            try invoke(functionAddress: functionAddress)

        default:
            throw Trap.unimplemented("\(instruction)")
        }

        return .continue
    }
}
