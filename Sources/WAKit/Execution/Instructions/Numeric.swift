/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions>

extension InstructionFactory {
    func const(_ value: Value) -> Instruction {
        makeInstruction { pc, _, stack in
            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func numeric(intUnary instruction: NumericInstruction.IntUnary) -> Instruction {
        makeInstruction { pc, _, stack in
            let value = try stack.pop(Value.self)

            stack.push(instruction(value))
            return .jump(pc + 1)
        }
    }

    func numeric(floatUnary instruction: NumericInstruction.FloatUnary) -> Instruction {
        makeInstruction { pc, _, stack in
            let value = try stack.pop(Value.self)

            stack.push(instruction(value))
            return .jump(pc + 1)
        }
    }

    func numeric(binary instruction: NumericInstruction.Binary) -> Instruction {
        makeInstruction { pc, _, stack in
            let value2 = try stack.pop(Value.self)
            let value1 = try stack.pop(Value.self)

            stack.push(instruction(value1, value2))
            return .jump(pc + 1)
        }
    }

    func numeric(intBinary instruction: NumericInstruction.IntBinary) -> Instruction {
        makeInstruction { pc, _, stack in
            let value2 = try stack.pop(Value.self)
            let value1 = try stack.pop(Value.self)

            try stack.push(instruction(value1.type, value1, value2))
            return .jump(pc + 1)
        }
    }

    func numeric(floatBinary instruction: NumericInstruction.FloatBinary) -> Instruction {
        makeInstruction { pc, _, stack in
            let value2 = try stack.pop(Value.self)
            let value1 = try stack.pop(Value.self)

            try stack.push(instruction(value1, value2))
            return .jump(pc + 1)
        }
    }

    func numeric(conversion instruction: NumericInstruction.Conversion) -> Instruction {
        makeInstruction { pc, _, stack in
            let value = try stack.pop(Value.self)

            try stack.push(instruction(value))
            return .jump(pc + 1)
        }
    }
}
