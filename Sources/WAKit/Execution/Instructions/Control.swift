/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension InstructionFactory {
    var unreachable: Instruction {
        return makeInstruction { _, _, _ in throw Trap.unreachable }
    }

    var nop: Instruction {
        return makeInstruction { pc, _, _ in .jump(pc + 1) }
    }

    func block(type: ResultType, expression: Expression) -> [Instruction] {
        let count = expression.instructions.count
        let block = makeInstruction { pc, _, stack in
            let start = pc + 1
            let end = pc + count
            let label = Label(arity: type.count, continuation: start + count, range: start ... end)
            stack.push(label)
            return .jump(start)
        }
        return [block] + expression.instructions
    }

    func loop(type: ResultType, expression: Expression) -> [Instruction] {
        let count = expression.instructions.count
        let loop = makeInstruction { pc, _, stack in
            let start = pc + 1
            let end = pc + count
            let label = Label(arity: type.count, continuation: pc, range: start ... end)
            stack.push(label)
            return .jump(start)
        }
        return [loop] + expression.instructions
    }

    func `if`(type: ResultType, then: Expression, else: Expression) -> [Instruction] {
        let thenCount = then.instructions.count
        let elseCount = `else`.instructions.count
        let instructions = then.instructions + `else`.instructions
        let `if` = makeInstruction { pc, _, stack in
            let isTrue = try stack.pop(Value.self).i32 != 0

            if !isTrue, elseCount == 0 {
                return .jump(pc + thenCount + 1)
            }

            let start = pc + 1 + (isTrue ? 0 : thenCount)
            let end = start + (isTrue ? thenCount - 1 : elseCount - 1)
            let label = Label(arity: type.count, continuation: pc + instructions.count + 1, range: start ... end)
            stack.push(label)
            return .jump(start)
        }
        return [`if`] + instructions
    }

    var `else`: Instruction {
        return makeInstruction { _, _, _ in throw Trap.unreachable }
    }

    var end: Instruction {
        return makeInstruction { _, _, _ in throw Trap.unreachable }
    }

    func br(_ labelIndex: LabelIndex) -> Instruction {
        return makeInstruction { _, _, stack in
            let label = try stack.get(Label.self, index: Int(labelIndex))
            let values = try stack.pop(Value.self, count: label.arity)
            for _ in 0 ... labelIndex {
                while stack.peek() is Value {
                    _ = stack.pop()
                }
                try stack.pop(Label.self)
            }
            for value in values {
                stack.push(value)
            }

            return .jump(label.continuation)
        }
    }

    func brIf(_ labelIndex: LabelIndex) -> Instruction {
        return makeInstruction { pc, _, stack in
            guard try stack.pop(Value.self).i32 != 0 else {
                return .jump(pc + 1)
            }

            let label = try stack.get(Label.self, index: Int(labelIndex))
            let values = try stack.pop(Value.self, count: label.arity)
            for _ in 0 ... labelIndex {
                while stack.peek() is Value {
                    _ = stack.pop()
                }
                try stack.pop(Label.self)
            }
            for value in values {
                stack.push(value)
            }

            return .jump(label.continuation)
        }
    }

    func brTable(_ labelIndices: [LabelIndex], default defaultLabelIndex: LabelIndex) -> Instruction {
        return makeInstruction { _, _, stack in
            let value = try stack.pop(Value.self).i32
            let labelIndex: LabelIndex
            if labelIndices.indices.contains(Int(value)) {
                labelIndex = labelIndices[Int(value)]
            } else {
                labelIndex = defaultLabelIndex
            }

            let label = try stack.get(Label.self, index: Int(labelIndex))
            let values = try stack.pop(Value.self, count: label.arity)
            for _ in 0 ... labelIndex {
                while stack.peek() is Value {
                    _ = stack.pop()
                }
                try stack.pop(Label.self)
            }
            for value in values {
                stack.push(value)
            }

            return .jump(label.continuation)
        }
    }

    var `return`: Instruction {
        return makeInstruction { _, _, _ in
            throw Trap.unimplemented(#function)
        }
    }

    func call(_ functionIndex: UInt32) -> Instruction {
        return makeInstruction { _, _, stack in
            let frame = try stack.get(current: Frame.self)
            let functionAddress = frame.module.functionAddresses[Int(functionIndex)]
            return .invoke(functionAddress)
        }
    }

    func callIndirect(_ typeIndex: UInt32) -> Instruction {
        return makeInstruction { _, store, stack in
            let frame = try stack.get(current: Frame.self)
            let module = frame.module
            let tableAddresses = module.tableAddresses[0]
            let tableInstance = store.tables[tableAddresses]
            let expectedType = module.types[Int(typeIndex)]
            let value = try Int(stack.pop(Value.self).i32)
            guard let functionAddress = tableInstance.elements[value] else {
                throw Trap.tableUninitialized
            }
            let function = store.functions[functionAddress]
            guard function.type == expectedType else {
                throw Trap.callIndirectFunctionTypeMismatch(actual: function.type, expected: expectedType)
            }
            return .invoke(functionAddress)
        }
    }
}
