/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(runtime: Runtime, stack: inout Stack) throws {
        throw Trap.unreachable
    }
    mutating func nop(runtime: Runtime, stack: inout Stack) throws {
        programCounter += 1
    }
    private func getTypeSection(store: Store, stack: inout Stack) -> [FunctionType] {
        store.module(address: stack.currentFrame.module).types
    }

    typealias BlockType = Instruction.BlockType

    mutating func block(runtime: Runtime, stack: inout Stack, endRef: ExpressionRef, type: BlockType) {
        enter(
            jumpTo: programCounter + 1,
            continuation: programCounter + endRef.relativeOffset,
            stack: &stack,
            arity: Int(type.results),
            pushPopValues: Int(type.parameters)
        )
    }
    mutating func loop(runtime: Runtime, stack: inout Stack, type: BlockType) {
        let paramSize = Int(type.parameters)
        enter(jumpTo: programCounter + 1, continuation: programCounter, stack: &stack, arity: paramSize, pushPopValues: paramSize)
    }

    mutating func ifThen(runtime: Runtime, stack: inout Stack, endRef: ExpressionRef, type: BlockType) {
        let isTrue = stack.popValue().i32 != 0
        if isTrue {
            enter(
                jumpTo: programCounter + 1,
                continuation: programCounter.advanced(by: endRef.relativeOffset),
                stack: &stack,
                arity: Int(type.results),
                pushPopValues: Int(type.parameters)
            )
        } else {
            programCounter += endRef.relativeOffset
        }
    }

    mutating func ifThenElse(runtime: Runtime, stack: inout Stack, elseRef: ExpressionRef, endRef: ExpressionRef, type: BlockType) {
        let isTrue = stack.popValue().i32 != 0
        let addendToPC: Int
        if isTrue {
            addendToPC = 1
        } else {
            addendToPC = elseRef.relativeOffset
        }
        enter(
            jumpTo: programCounter + addendToPC,
            continuation: programCounter + endRef.relativeOffset,
            stack: &stack,
            arity: Int(type.results),
            pushPopValues: Int(type.parameters)
        )
    }
    mutating func end(runtime: Runtime, stack: inout Stack) {
        if stack.currentLabel != nil {
            stack.exitLabel()
        }
        programCounter += 1
    }
    mutating func `else`(runtime: Runtime, stack: inout Stack) {
        let label = stack.currentLabel!
        stack.exitLabel()
        programCounter = label.continuation // if-then-else's continuation points the "end"
    }

    private mutating func labelBranch(labelIndex: Int, stack: inout Stack, runtime: Runtime) throws {
        if stack.numberOfLabelsInCurrentFrame() == labelIndex {
            try self.return(runtime: runtime, stack: &stack)
            return
        }
        let label = stack.getLabel(index: Int(labelIndex))
        let values = stack.popValues(count: label.arity)

        stack.unwindLabels(upto: labelIndex)

        stack.push(values: values)
        programCounter = label.continuation
    }
    private mutating func branch(labelIndex: LabelIndex, stack: inout Stack, offset: Int32, copyCount: UInt32, popCount: UInt32) throws {
        if popCount > 0 { // TODO: Maybe worth to have a special instruction for popCount=0?
            stack.copyValues(copyCount: Int(copyCount), popCount: Int(popCount))
        }
        stack.popLabels(upto: Int(labelIndex))
        programCounter += Int(offset)
    }
    mutating func br(runtime: Runtime, stack: inout Stack, labelIndex: LabelIndex, offset: Int32, copyCount: UInt32, popCount: UInt32) throws {
        try branch(labelIndex: labelIndex, stack: &stack, offset: offset, copyCount: copyCount, popCount: popCount)
    }
    mutating func legacyBr(runtime: Runtime, stack: inout Stack, labelIndex: LabelIndex) throws {
        try labelBranch(labelIndex: Int(labelIndex), stack: &stack, runtime: runtime)
    }

    mutating func brIf(runtime: Runtime, stack: inout Stack, labelIndex: LabelIndex, offset: Int32, copyCount: UInt32, popCount: UInt32) throws {
        guard stack.popValue().i32 != 0 else {
            programCounter += 1
            return
        }
        try branch(labelIndex: labelIndex, stack: &stack, offset: offset, copyCount: copyCount, popCount: popCount)
    }
    mutating func legacyBrIf(runtime: Runtime, stack: inout Stack, labelIndex: LabelIndex) throws {
        guard stack.popValue().i32 != 0 else {
            programCounter += 1
            return
        }
        try labelBranch(labelIndex: Int(labelIndex), stack: &stack, runtime: runtime)
    }
    mutating func brTable(runtime: Runtime, stack: inout Stack, brTable: Instruction.BrTable) throws {
        let labelIndices = brTable.labelIndices
        let defaultIndex = brTable.defaultIndex
        let value = stack.popValue().i32
        let labelIndex: LabelIndex
        if labelIndices.indices.contains(Int(value)) {
            labelIndex = labelIndices[Int(value)]
        } else {
            labelIndex = defaultIndex
        }

        try labelBranch(labelIndex: Int(labelIndex), stack: &stack, runtime: runtime)
    }
    mutating func `return`(runtime: Runtime, stack: inout Stack) throws {
        let currentFrame = stack.currentFrame!
        stack.exit(frame: currentFrame)
        try endOfFunction(runtime: runtime, stack: &stack, currentFrame: currentFrame)
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
