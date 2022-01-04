/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension InstructionFactory {
    func localGet(_ index: UInt32) -> Instruction {
        return makeInstruction { pc, _, stack in
            let currentFrame = try stack.get(current: Frame.self)
            let value = try currentFrame.localGet(index: index)
            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func localSet(_ index: UInt32) -> Instruction {
        return makeInstruction { pc, _, stack in
            let currentFrame = try stack.get(current: Frame.self)
            let value = try stack.pop(Value.self)
            try currentFrame.localSet(index: index, value: value)
            return .jump(pc + 1)
        }
    }

    func localTee(_ index: UInt32) -> Instruction {
        return makeInstruction { pc, _, stack in
            let currentFrame = try stack.get(current: Frame.self)
            let value = try stack.peek(Value.self)
            try currentFrame.localSet(index: index, value: value)
            return .jump(pc + 1)
        }
    }

    func globalGet(_ index: UInt32) -> Instruction {
        return makeInstruction { pc, store, stack in
            let value = try store.getGlobal(index: index)
            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func globalSet(_ index: UInt32) -> Instruction {
        return makeInstruction { pc, _, stack in
            let currentFrame = try stack.get(current: Frame.self)
            let value = try currentFrame.localGet(index: index)
            stack.push(value)
            return .jump(pc + 1)
        }
    }
}
