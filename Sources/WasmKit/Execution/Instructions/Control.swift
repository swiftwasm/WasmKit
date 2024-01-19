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
    mutating func block(runtime: Runtime, expression: Expression, type: ResultType) throws {
        let (paramSize, resultSize) = type.arity(typeSection: { getTypeSection(store: runtime.store) })
        let values = stack.popValues(count: paramSize)
        enter(expression, continuation: programCounter + 1, arity: resultSize)
        stack.push(values: values)
    }
    mutating func loop(runtime: Runtime, expression: Expression, type: ResultType) throws {
        let (paramSize, _) = type.arity(typeSection: { getTypeSection(store: runtime.store) })
        let values = stack.popValues(count: paramSize)
        enter(expression, continuation: programCounter, arity: paramSize)
        stack.push(values: values)
    }
    mutating func `if`(runtime: Runtime, thenExpr: Expression, elseExpr: Expression, type: ResultType) throws {
        let isTrue = try stack.popValue().i32 != 0

        let expression: Expression
        if isTrue {
            expression = thenExpr
        } else {
            expression = elseExpr
        }

        if !expression.instructions.isEmpty {
            try block(runtime: runtime, expression: expression, type: type)
        } else {
            programCounter += 1
        }
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
    mutating func brTable(runtime: Runtime, labelIndices: [LabelIndex], defaultIndex: LabelIndex) throws {
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
        let lastLabel = stack.exit(frame: currentFrame)
        if let lastLabel {
            programCounter = lastLabel.continuation
        }
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
