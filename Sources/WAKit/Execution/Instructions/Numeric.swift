/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions>

extension InstructionFactory {
    func const<V: RawRepresentableValue>(_ value: V) -> Instruction {
        return makeInstruction { pc, _, stack in
            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func operate<V: RawRepresentableValue>(_ type: V.Type, _ operate: @escaping (V.RawValue) -> V.RawValue) -> Instruction {
        return makeInstruction { pc, _, stack in
            let value = try stack.pop(type)
            let result = V(operate(value.rawValue))
            stack.push(result)
            return .jump(pc + 1)
        }
    }

    func operate<V: RawRepresentableValue>(_ type: V.Type, _ operate: @escaping (V.RawValue, V.RawValue) -> V.RawValue) -> Instruction {
        return makeInstruction { pc, _, stack in
            let value2 = try stack.pop(type)
            let value1 = try stack.pop(type)
            let result = V(operate(value1.rawValue, value2.rawValue))
            stack.push(result)
            return .jump(pc + 1)
        }
    }

    func operate<V: RawRepresentableValue>(_ type: V.Type, _ operate: @escaping (V.RawValue, V.RawValue) -> Bool, _ value2: V? = nil) -> Instruction {
        return makeInstruction { pc, _, stack in
            let value2 = try value2 ?? stack.pop(type)
            let value1 = try stack.pop(type)
            let result = operate(value1.rawValue, value2.rawValue) ? I32(1) : I32(0)
            stack.push(result)
            return .jump(pc + 1)
        }
    }

    func operate<V: RawRepresentableValue>(signed type: V.Type, _ operate: @escaping (V.RawValue.Signed, V.RawValue.Signed) -> Bool) -> Instruction where V.RawValue: RawUnsignedInteger {
        return makeInstruction { pc, _, stack in
            let value2 = try stack.pop(type)
            let value1 = try stack.pop(type)
            let result = operate(value1.signed, value2.signed) ? I32(1) : I32(0)
            stack.push(result)
            return .jump(pc + 1)
        }
    }
}
