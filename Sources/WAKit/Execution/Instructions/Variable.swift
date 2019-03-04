/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Runtime {
    func execute(variable instruction: VariableInstruction) throws {
        switch instruction {
        case let .getLocal(index):
            let currentFrame = try stack.getCurrent(Frame.self)
            let value = try currentFrame.getLocal(index: index)
            stack.push(value)

        case let .setLocal(index),
             let .teeLocal(index):
            let currentFrame = try stack.getCurrent(Frame.self)
            let value: Value
            if case .teeLocal = instruction {
                value = try stack.peek(Value.self)
            } else {
                value = try stack.pop(Value.self)
            }
            try currentFrame.setLocal(index: index, value: value)

        case let .getGlobal(index):
            let value = try store.getGlobal(index: index)
            stack.push(value)

        case let .setGlobal(index):
            let value = try stack.pop(Value.self)
            try store.setGlobal(index: index, value: value)
        }
    }
}
