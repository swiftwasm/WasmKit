/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Runtime {
    func execute(variable instruction: VariableInstruction) throws {
        switch instruction {
        case let .localGet(index):
            let currentFrame = try stack.get(current: Frame.self)
            let value = try currentFrame.localGet(index: index)
            stack.push(value)

        case let .localSet(index),
             let .localTee(index):
            let currentFrame = try stack.get(current: Frame.self)
            let value: Value
            if case .localTee = instruction {
                value = try stack.peek(Value.self)
            } else {
                value = try stack.pop(Value.self)
            }
            try currentFrame.localSet(index: index, value: value)

        case let .getGlobal(index):
            let value = try store.getGlobal(index: index)
            stack.push(value)

        case let .setGlobal(index):
            let value = try stack.pop(Value.self)
            try store.setGlobal(index: index, value: value)
        }
    }
}
