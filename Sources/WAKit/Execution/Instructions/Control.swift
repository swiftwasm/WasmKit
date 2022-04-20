/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension InstructionFactory {
    var unreachable: Instruction {
        return makeInstruction(
            implementation: { _, _, _ in throw Trap.unreachable },
            validator: { validator, _, _ in validator.unreachable() }
        )
    }

    var nop: Instruction {
        return makeInstruction(
            implementation: { pc, _, _ in .jump(pc + 1) },
            validator: { _, _, _ in }
        )
    }

    func block(type: ResultType, expression: Expression) -> [Instruction] {
        let count = expression.instructions.count
        let block = makeInstruction(implementation: { pc, _, stack in
            let start = pc + 1
            let end = pc + count
            let label = Label(arity: type.count, continuation: start + count, range: start ... end)
            stack.push(label)
            return .jump(start)
        }, validator: { validator, instr, _ in
            // TODO: Update to consume incoming types
            try validator.popValues([])
            validator.pushControlFrame(opcode: instr.code, input: [], output: type)
        })
        return [block] + expression.instructions
    }

    func loop(type: ResultType, expression: Expression) -> [Instruction] {
        let count = expression.instructions.count
        let loop = makeInstruction(implementation: { pc, _, stack in
            let start = pc + 1
            let end = pc + count
            let label = Label(arity: type.count, continuation: pc, range: start ... end)
            stack.push(label)
            return .jump(start)
        }, validator: { validator, instr, _ in
            try validator.popValues([])
            validator.pushControlFrame(opcode: instr.code, input: [], output: type)
        })
        return [loop] + expression.instructions
    }

    func `if`(type: ResultType, then: Expression, else: Expression) -> [Instruction] {
        let thenCount = then.instructions.count
        let elseCount = `else`.instructions.count
        let instructions = then.instructions + `else`.instructions
        let `if` = makeInstruction(implementation: { pc, _, stack in
            let isTrue = try stack.pop(I32.self) != 0

            if !isTrue, elseCount == 0 {
                return .jump(pc + thenCount + 1)
            }

            let start = pc + 1 + (isTrue ? 0 : thenCount)
            let end = start + (isTrue ? thenCount - 1 : elseCount - 1)
            let label = Label(arity: type.count, continuation: pc + instructions.count + 1, range: start ... end)
            stack.push(label)
            return .jump(start)
        }, validator: { validator, _, _ in
            try validator.popValue(I32.self)
            try validator.popValues([])
            validator.pushValues(type)
        })
        return [`if`] + instructions
    }

    var `else`: Instruction {
        return makeInstruction(
            implementation: { _, _, _ in throw Trap.unreachable },
            validator: { validator, instr, _ in
                let frame = try validator.popControlFrame()
                guard frame.opcode == .if else {
                    throw ValidationError(diagnostic: "else found outside of an `if` block")
                }
                validator.pushControlFrame(opcode: instr.code, input: frame.startTypes, output: frame.endTypes)
            }
        )
    }

    var end: Instruction {
        return makeInstruction(
            implementation: { _, _, _ in throw Trap.unreachable },
            validator: { validator, _, _ in
                let frame = try validator.popControlFrame()
                validator.pushValues(frame.endTypes)
            }
        )
    }

    func br(_ labelIndex: LabelIndex) -> Instruction {
        return makeInstruction(
            implementation: { _, _, stack in
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
            },
            validator: { validator, _, _ in
                guard labelIndex < validator.controlStack.count else {
                    throw ValidationError(diagnostic: "unknown label: branch depth too large")
                }
                let frame = validator.controlStack[Int(labelIndex)]
                try validator.popValues(validator.labelTypes(frame: frame))
                validator.unreachable()
            }
        )
    }

    func brIf(_ labelIndex: LabelIndex) -> Instruction {
        return makeInstruction(
            implementation: { pc, _, stack in
                guard try stack.pop(I32.self) != 0 else {
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
            },
            validator: { validator, _, _ in
                guard labelIndex < validator.controlStack.count else {
                    throw ValidationError(diagnostic: "unknown label: branch depth too large")
                }
                let frame = validator.controlStack[Int(labelIndex)]
                try validator.popValue(I32.self)
                try validator.popValues(validator.labelTypes(frame: frame))
                validator.pushValues(validator.labelTypes(frame: frame))
            }
        )
    }

    func brTable(_ labelIndices: [LabelIndex], default defaultLabelIndex: LabelIndex) -> Instruction {
        return makeInstruction(
            implementation: { _, _, stack in
                let value = try stack.pop(I32.self)
                let labelIndex: LabelIndex
                if labelIndices.indices.contains(Int(value.rawValue)) {
                    labelIndex = labelIndices[Int(value.rawValue)]
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
            },
            validator: { validator, _, _ in
                try validator.popValue(I32.self)
                guard defaultLabelIndex < validator.controlStack.count else {
                    throw ValidationError(diagnostic: "unknown label: branch depth too large")
                }
                let frame = validator.controlStack[Int(defaultLabelIndex)]
                let defaultType = validator.labelTypes(frame: frame)
                for labelIndex in labelIndices {
                    let frame = validator.controlStack[Int(labelIndex)]
                    let labelType = validator.labelTypes(frame: frame)
                    guard labelIndex < validator.controlStack.count else {
                        throw ValidationError(diagnostic: "unknown label: branch depth too large")
                    }
                    guard labelType.count == defaultType.count else {
                        throw ValidationError(diagnostic: "type mismatch: br_table target labels have different number of types")
                    }
                    try validator.pushValues(validator.popValues(labelType))
                }
                try validator.popValues(defaultType)
                validator.unreachable()
            }
        )
    }

    var `return`: Instruction {
        return makeInstruction(
            implementation: { _, _, _ in
                throw Trap.unimplemented(#function)
            },
            validator: { validator, _, _ in
                try validator.popValues(validator.controlStack.last!.endTypes)
                validator.unreachable()
            }
        )
    }

    func call(_ functionIndex: UInt32) -> Instruction {
        return makeInstruction(
            implementation: { _, _, stack in
                let frame = try stack.get(current: Frame.self)
                let functionAddress = frame.module.functionAddresses[Int(functionIndex)]
                return .invoke(functionAddress)
            },
            validator: { validator, _, context in
                let functionType = context.functionType(index: functionIndex)
                try validator.popValues(functionType.parameters.reversed())
                validator.pushValues(functionType.results)
            }
        )
    }

    func callIndirect(_ typeIndex: UInt32) -> Instruction {
        return makeInstruction(
            implementation: { _, store, stack in
                let frame = try stack.get(current: Frame.self)
                let module = frame.module
                let tableAddresses = module.tableAddresses[0]
                let tableInstance = store.tables[tableAddresses]
                let expectedType = module.types[Int(typeIndex)]
                let value = try Int(stack.pop(I32.self).rawValue)
                guard let functionAddress = tableInstance.elements[value] else {
                    throw Trap.tableUninitialized
                }
                let function = store.functions[functionAddress]
                guard function.type == expectedType else {
                    throw Trap.callIndirectFunctionTypeMismatch(actual: function.type, expected: expectedType)
                }
                return .invoke(functionAddress)
            },
            validator: { validator, _, context in
                let functionType = context.type(index: typeIndex)
                try validator.popValues(functionType.parameters.reversed())
                validator.pushValues(functionType.results)
            }
        )
    }
}
