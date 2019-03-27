/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension InstructionFactory {
    var drop: Instruction {
        return makeInstruction { pc, _, stack in
            _ = try stack.pop(Value.self)
            return .jump(pc)
        }
    }

    var select: Instruction {
        return makeInstruction { pc, _, stack in
            let flag = try stack.pop(I32.self)
            let value2 = try stack.pop(Value.self)
            let value1 = try stack.pop(Value.self)
            if flag != 0 {
                stack.push(value1)
            } else {
                stack.push(value2)
            }
            return .jump(pc)
        }
    }
}
