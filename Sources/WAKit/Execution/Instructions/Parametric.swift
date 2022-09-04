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
            let flagValue = try stack.pop(Value.self)
            guard case let .i32(flag) = flagValue else {
                throw Trap.stackValueTypesMismatch(expected: .int(.i32), actual: flagValue.type)
            }
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
