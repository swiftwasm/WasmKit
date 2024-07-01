/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(runtime: Runtime, stack: inout Stack) throws {
        throw Trap.unreachable
    }
    mutating func nop(runtime: Runtime, stack: inout Stack) throws {
        programCounter += 1
    }

    mutating func ifThen(runtime: Runtime, stack: inout Stack, elseOrEndRef: ExpressionRef) {
        let isTrue = stack.popValue().i32 != 0
        if isTrue {
            programCounter += 1
        } else {
            programCounter += elseOrEndRef.relativeOffset
        }
    }

    mutating func end(runtime: Runtime, stack: inout Stack) {
        fatalError()
    }
    mutating func `else`(runtime: Runtime, stack: inout Stack, endRef: ExpressionRef) {
        programCounter += endRef.relativeOffset // if-then-else's continuation points the "end"
    }
    private mutating func branch(stack: inout Stack, offset: Int32, copyCount: UInt32, popCount: UInt32) throws {
        if popCount > 0 { // TODO: Maybe worth to have a special instruction for popCount=0?
            stack.copyValues(copyCount: Int(copyCount), popCount: Int(popCount))
        }
        programCounter += Int(offset)
    }
    mutating func br(runtime: Runtime, stack: inout Stack, offset: Int32, copyCount: UInt32, popCount: UInt32) throws {
        try branch(stack: &stack, offset: offset, copyCount: copyCount, popCount: popCount)
    }
    mutating func brIf(runtime: Runtime, stack: inout Stack, offset: Int32, copyCount: UInt32, popCount: UInt32) throws {
        guard stack.popValue().i32 != 0 else {
            programCounter += 1
            return
        }
        try branch(stack: &stack, offset: offset, copyCount: copyCount, popCount: popCount)
    }
    mutating func brTable(runtime: Runtime, stack: inout Stack, brTable: Instruction.BrTable) throws {
        let index = stack.popValue().i32
        let normalizedOffset = min(Int(index), brTable.buffer.count - 1)
        let entry = brTable.buffer[normalizedOffset]

        try branch(
            stack: &stack,
            offset: entry.offset,
            copyCount: UInt32(entry.copyCount), popCount: UInt32(entry.popCount)
        )
    }
    mutating func `return`(runtime: Runtime, stack: inout Stack) throws {
        try self.endOfFunction(runtime: runtime, stack: &stack)
    }

    mutating func endOfFunction(runtime: Runtime, stack: inout Stack) throws {
        try self.endOfFunction(runtime: runtime, stack: &stack, currentFrame: stack.currentFrame)
    }

    mutating func endOfExecution(runtime: Runtime, stack: inout Stack) throws {
        reachedEndOfExecution = true
    }

    private mutating func endOfFunction(runtime: Runtime, stack: inout Stack, currentFrame: Frame) throws {
        // When reached at "end" of function
        #if DEBUG
        if let address = currentFrame.address {
            runtime.interceptor?.onExitFunction(address, store: runtime.store)
        }
        #endif
        let values = stack.popValues(count: currentFrame.arity)
        stack.popFrame()
        stack.push(values: values)
        programCounter = currentFrame.returnPC
    }

    mutating func call(runtime: Runtime, stack: inout Stack, functionIndex: UInt32) throws {
        let functionAddresses = runtime.store.module(address: stack.currentFrame.module).functionAddresses

        guard functionAddresses.indices.contains(Int(functionIndex)) else {
            throw Trap.invalidFunctionIndex(functionIndex)
        }

        try invoke(functionAddress: functionAddresses[Int(functionIndex)], runtime: runtime, stack: &stack)
    }

    mutating func callIndirect(runtime: Runtime, stack: inout Stack, tableIndex: TableIndex, typeIndex: TypeIndex) throws {
        let moduleInstance = runtime.store.module(address: stack.currentFrame.module)
        let tableAddresses = moduleInstance.tableAddresses[Int(tableIndex)]
        let tableInstance = runtime.store.tables[tableAddresses]
        let expectedType = moduleInstance.types[Int(typeIndex)]
        let value = stack.popValue().i32
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

        try invoke(functionAddress: functionAddress, runtime: runtime, stack: &stack)
    }
}
