/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(runtime: Runtime, context: inout StackContext, stack: FrameBase) throws {
        throw Trap.unreachable
    }
    mutating func nop(runtime: Runtime, context: inout StackContext, stack: FrameBase) throws {
        programCounter += 1
    }

    mutating func ifThen(runtime: Runtime, context: inout StackContext, stack: FrameBase, ifOperand: Instruction.IfOperand) {
        let isTrue = stack[ifOperand.condition].i32 != 0
        if isTrue {
            programCounter += 1
        } else {
            programCounter += ifOperand.elseOrEndRef.relativeOffset
        }
    }

    mutating func `else`(runtime: Runtime, context: inout StackContext, stack: FrameBase, endRef: ExpressionRef) {
        programCounter += endRef.relativeOffset  // if-then-else's continuation points the "end"
    }
    private mutating func branch(context: inout StackContext, offset: Int32) throws {
        programCounter += Int(offset)
    }
    mutating func br(runtime: Runtime, context: inout StackContext, stack: FrameBase, offset: Int32) throws {
        try branch(context: &context, offset: offset)
    }
    mutating func brIf(runtime: Runtime, context: inout StackContext, stack: FrameBase, brIfOperand: Instruction.BrIfOperand) throws {
        guard stack[brIfOperand.condition].i32 != 0 else {
            programCounter += 1
            return
        }
        try branch(context: &context, offset: brIfOperand.offset)
    }
    mutating func brIfNot(runtime: Runtime, context: inout StackContext, stack: FrameBase, brIfOperand: Instruction.BrIfOperand) throws {
        guard stack[brIfOperand.condition].i32 == 0 else {
            programCounter += 1
            return
        }
        try branch(context: &context, offset: brIfOperand.offset)
    }
    mutating func brTable(runtime: Runtime, context: inout StackContext, stack: FrameBase, brTableOperand: Instruction.BrTableOperand) throws {
        let brTable = brTableOperand.table
        let index = stack[brTableOperand.index].i32
        let normalizedOffset = min(Int(index), brTable.buffer.count - 1)
        let entry = brTable.buffer[normalizedOffset]

        try branch(
            context: &context,
            offset: entry.offset
        )
    }
    mutating func `return`(runtime: Runtime, context: inout StackContext, stack: FrameBase, returnOperand: Instruction.ReturnOperand) throws {
        try self.endOfFunction(runtime: runtime, context: &context, stack: stack, returnOperand: returnOperand)
    }

    mutating func endOfFunction(runtime: Runtime, context: inout StackContext, stack: FrameBase, returnOperand: Instruction.ReturnOperand) throws {
        try self.endOfFunction(runtime: runtime, context: &context, currentFrame: context.currentFrame, returnOperand: returnOperand)
    }

    mutating func endOfExecution(runtime: Runtime, context: inout StackContext, stack: FrameBase) throws {
        reachedEndOfExecution = true
    }

    private mutating func endOfFunction(runtime: Runtime, context: inout StackContext, currentFrame: Frame, returnOperand: Instruction.ReturnOperand) throws {
        // When reached at "end" of function
        #if DEBUG
            if let address = currentFrame.address {
                runtime.interceptor?.onExitFunction(address, store: runtime.store)
            }
        #endif
        let lastInstanceAddr = context.popFrame()
        programCounter = currentFrame.returnPC
        mayUpdateCurrentInstance(instanceAddr: currentFrame.module, store: runtime.store, from: lastInstanceAddr)
    }

    @inline(__always)
    mutating func call(runtime: Runtime, context: inout StackContext, stack: FrameBase, callOperand: Instruction.CallOperand) throws {
        let functionAddresses = runtime.store.module(address: context.currentFrame.module).functionAddresses
        let functionIndex = callOperand.index

        guard functionAddresses.indices.contains(Int(functionIndex)) else {
            throw Trap.invalidFunctionIndex(functionIndex)
        }

        try invoke(
            functionAddress: functionAddresses[Int(
                functionIndex
            )],
            runtime: runtime,
            stack: &context,
            callerModule: context.currentFrame.module,
            callLike: callOperand.callLike
        )
    }

    @inline(__always)
    mutating func callIndirect(runtime: Runtime, context: inout StackContext, stack: FrameBase, callIndirectOperand: Instruction.CallIndirectOperand) throws {
        let callerModuleAddr = context.currentFrame.module
        let moduleInstance = runtime.store.module(address: callerModuleAddr)
        let tableAddresses = moduleInstance.tableAddresses[Int(callIndirectOperand.tableIndex)]
        let tableInstance = runtime.store.tables[tableAddresses]
        let expectedType = moduleInstance.types[Int(callIndirectOperand.typeIndex)]
        let value = stack[callIndirectOperand.index].asAddressOffset(tableInstance.limits.isMemory64)
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

        try invoke(
            functionAddress: functionAddress,
            runtime: runtime,
            stack: &context,
            callerModule: callerModuleAddr,
            callLike: callIndirectOperand.callLike
        )
    }
}
