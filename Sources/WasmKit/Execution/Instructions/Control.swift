/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(runtime: Runtime) throws {
        throw Trap.unreachable
    }
    mutating func nop(runtime: Runtime) throws {
        programCounter += 1
    }
    private func getTypeSection(store: Store) -> [FunctionType] {
        store.module(address: stack.currentFrame.module).types
    }
    mutating func block(runtime: Runtime, endRef: ExpressionRef, type: ResultType) throws {
        let (paramSize, resultSize) = type.arity(typeSection: { getTypeSection(store: runtime.store) })
        enter(jumpTo: programCounter + 1, continuation: programCounter + endRef.relativeOffset, arity: resultSize, pushPopValues: paramSize)
    }
    mutating func loop(runtime: Runtime, type: ResultType) throws {
        let (paramSize, _) = type.arity(typeSection: { getTypeSection(store: runtime.store) })
        enter(jumpTo: programCounter + 1, continuation: programCounter, arity: paramSize, pushPopValues: paramSize)
    }

    mutating func ifThen(runtime: Runtime, endRef: ExpressionRef, type: ResultType) throws {
        let isTrue = try stack.popValue().i32 != 0
        let (paramSize, resultSize) = type.arity(typeSection: { getTypeSection(store: runtime.store) })
        if isTrue {
            enter(
                jumpTo: programCounter + 1,
                continuation: programCounter + endRef.relativeOffset,
                arity: resultSize,
                pushPopValues: paramSize
            )
        } else {
            programCounter += endRef.relativeOffset
        }
    }

    mutating func ifThenElse(runtime: Runtime, elseRef: ExpressionRef, endRef: ExpressionRef, type: ResultType) throws {
        let isTrue = try stack.popValue().i32 != 0
        let (paramSize, resultSize) = type.arity(typeSection: { getTypeSection(store: runtime.store) })
        let addendToPC: Int
        if isTrue {
            addendToPC = 1
        } else {
            addendToPC = elseRef.relativeOffset
        }
        enter(
            jumpTo: programCounter + addendToPC,
            continuation: programCounter + endRef.relativeOffset,
            arity: resultSize,
            pushPopValues: paramSize
        )
    }
    mutating func end(runtime: Runtime) throws {
        if let currentLabel = self.stack.currentLabel {
            stack.exit(label: currentLabel)
        }
        programCounter += 1
    }
    mutating func `else`(runtime: Runtime) throws {
        let label = self.stack.currentLabel!
        stack.exit(label: label)
        programCounter = label.continuation // if-then-else's continuation points the "end"
    }
    mutating func br(runtime: Runtime, labelIndex: LabelIndex) throws {
        try branch(labelIndex: Int(labelIndex))
    }
    mutating func brIf(runtime: Runtime, labelIndex: LabelIndex) throws {
        guard try stack.popValue().i32 != 0 else {
            programCounter += 1
            return
        }
        try br(runtime: runtime, labelIndex: labelIndex)
    }
    mutating func brTable(runtime: Runtime, brTable: Instruction.BrTable) throws {
        let labelIndices = brTable.labelIndices
        let defaultIndex = brTable.defaultIndex
        let value = try stack.popValue().i32
        let labelIndex: LabelIndex
        if labelIndices.indices.contains(Int(value)) {
            labelIndex = labelIndices[Int(value)]
        } else {
            labelIndex = defaultIndex
        }

        try branch(labelIndex: Int(labelIndex))
    }
    mutating func `return`(runtime: Runtime) throws {
        let currentFrame = stack.currentFrame!
        _ = stack.exit(frame: currentFrame)
        programCounter = currentFrame.iseq.instructions.count
    }
    mutating func call(runtime: Runtime, functionIndex: UInt32) throws {
        let functionAddresses = runtime.store.module(address: stack.currentFrame.module).functionAddresses

        guard functionAddresses.indices.contains(Int(functionIndex)) else {
            throw Trap.invalidFunctionIndex(functionIndex)
        }

        try invoke(functionAddress: functionAddresses[Int(functionIndex)], runtime: runtime)
    }

    mutating func callIndirect(runtime: Runtime, tableIndex: TableIndex, typeIndex: TypeIndex) throws {
        let moduleInstance = runtime.store.module(address: stack.currentFrame.module)
        let tableAddresses = moduleInstance.tableAddresses[Int(tableIndex)]
        let tableInstance = runtime.store.tables[tableAddresses]
        let expectedType = moduleInstance.types[Int(typeIndex)]
        let value = try stack.popValue().i32
        let elementIndex = Int(value)
        guard elementIndex < tableInstance.elements.count else {
            throw Trap.undefinedElement
        }
        guard case let .function(functionAddress?) = tableInstance.elements[elementIndex]
        else {
            throw Trap.tableUninitialized(ElementIndex(elementIndex))
        }
        let function = runtime.store.functions[functionAddress]
        guard function.type == expectedType else {
            throw Trap.callIndirectFunctionTypeMismatch(actual: function.type, expected: expectedType)
        }

        try invoke(functionAddress: functionAddress, runtime: runtime)
    }
}
