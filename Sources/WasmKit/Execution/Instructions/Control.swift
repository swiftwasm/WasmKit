/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(context: inout StackContext, sp: Sp) throws {
        throw Trap.unreachable
    }
    mutating func nop(context: inout StackContext, sp: Sp) throws {
        programCounter += 1
    }

    mutating func ifThen(context: inout StackContext, sp: Sp, ifOperand: Instruction.IfOperand) {
        let isTrue = sp[ifOperand.condition].i32 != 0
        if isTrue {
            programCounter += 1
        } else {
            programCounter += ifOperand.elseOrEndRef.relativeOffset
        }
    }

    private mutating func branch(offset: Int32) throws {
        programCounter += Int(offset)
    }
    mutating func br(context: inout StackContext, sp: Sp, offset: Int32) throws {
        try branch(offset: offset)
    }
    mutating func brIf(context: inout StackContext, sp: Sp, brIfOperand: Instruction.BrIfOperand) throws {
        guard sp[brIfOperand.condition].i32 != 0 else {
            programCounter += 1
            return
        }
        try branch(offset: brIfOperand.offset)
    }
    mutating func brIfNot(context: inout StackContext, sp: Sp, brIfOperand: Instruction.BrIfOperand) throws {
        guard sp[brIfOperand.condition].i32 == 0 else {
            programCounter += 1
            return
        }
        try branch(offset: brIfOperand.offset)
    }
    mutating func brTable(context: inout StackContext, sp: Sp, brTableOperand: Instruction.BrTableOperand) throws {
        let brTable = brTableOperand.table
        let index = sp[brTableOperand.index].i32
        let normalizedOffset = min(Int(index), Int(brTable.count - 1))
        let entry = brTable.baseAddress[normalizedOffset]

        try branch(offset: entry.offset)
    }
    mutating func `return`(context: inout StackContext, sp: Sp, md: inout Md, ms: inout Ms, returnOperand: Instruction.ReturnOperand) throws {
        try self.endOfFunction(context: &context, sp: sp, md: &md, ms: &ms, returnOperand: returnOperand)
    }

    mutating func endOfFunction(context: inout StackContext, sp: Sp, md: inout Md, ms: inout Ms, returnOperand: Instruction.ReturnOperand) throws {
        try self.endOfFunction(context: &context, currentFrame: context.currentFrame, returnOperand: returnOperand, md: &md, ms: &ms)
    }

    mutating func endOfExecution(context: inout StackContext, sp: Sp) throws {
        reachedEndOfExecution = true
    }

    private mutating func endOfFunction(context: inout StackContext, currentFrame: Frame, returnOperand: Instruction.ReturnOperand, md: inout Md, ms: inout Ms) throws {
        // When reached at "end" of function
        let lastInstanceAddr = context.popFrame()
        programCounter = currentFrame.returnPC
        CurrentMemory.mayUpdateCurrentInstance(instance: currentFrame.instance, from: lastInstanceAddr, md: &md, ms: &ms)
    }

    mutating func call(context: inout StackContext, sp: Sp, md: inout Md, ms: inout Ms, callOperand: Instruction.CallOperand) throws {
        let function = callOperand.callee

        try invoke(
            function: function,
            stack: &context,
            callerInstance: context.currentFrame.instance,
            callLike: callOperand.callLike,
            md: &md, ms: &ms
        )
    }

    mutating func internalCall(context: inout StackContext, sp: Sp, internalCallOperand: Instruction.InternalCallOperand) throws {
        // The callee is known to be a function defined within the same module, so we can
        // skip updating the current instance.
        let (iseq, locals, instance) = internalCallOperand.callee.assumeCompiled()
        try context.pushFrame(
            iseq: iseq,
            instance: instance,
            numberOfNonParameterLocals: locals,
            returnPC: programCounter.advanced(by: 1),
            spAddend: internalCallOperand.callLike.spAddend
        )
        self.programCounter = iseq.baseAddress
    }

    mutating func compilingCall(context: inout StackContext, sp: Sp, compilingCallOperand: Instruction.CompilingCallOperand) throws {
        try compilingCallOperand.callee.ensureCompiled(executionState: &self)
        programCounter.pointee = .internalCall(compilingCallOperand)
        try internalCall(context: &context, sp: sp, internalCallOperand: compilingCallOperand)
    }

    mutating func callIndirect(context: inout StackContext, sp: Sp, md: inout Md, ms: inout Ms, callIndirectOperand: Instruction.CallIndirectOperand) throws {
        let callerInstance = context.currentFrame.instance
        let table = callerInstance.tables[Int(callIndirectOperand.tableIndex)]
        let expectedType = callIndirectOperand.type
        let value = sp[callIndirectOperand.index].asAddressOffset(table.limits.isMemory64)
        let elementIndex = Int(value)
        guard elementIndex < table.elements.count else {
            throw Trap.undefinedElement
        }
        guard case let .function(rawBitPattern?) = table.elements[elementIndex]
        else {
            throw Trap.tableUninitialized(elementIndex)
        }
        let function = InternalFunction(bitPattern: rawBitPattern)
        guard function.type == expectedType else {
            throw Trap.callIndirectFunctionTypeMismatch(
                actual: runtime.value.resolveType(function.type),
                expected: runtime.value.resolveType(expectedType)
            )
        }

        try invoke(
            function: function,
            stack: &context,
            callerInstance: callerInstance,
            callLike: callIndirectOperand.callLike,
            md: &md, ms: &ms
        )
    }

    mutating func onEnter(context: inout StackContext, sp: Sp, onEnterOperand: Instruction.OnEnterOperand) {
        let function = context.currentInstance.functions[Int(onEnterOperand)]
        self.runtime.value.interceptor?.onEnterFunction(
            Function(handle: function, allocator: self.runtime.store.allocator),
            store: self.runtime.store
        )
    }
    mutating func onExit(context: inout StackContext, sp: Sp, onExitOperand: Instruction.OnExitOperand) {
        let function = context.currentInstance.functions[Int(onExitOperand)]
        self.runtime.value.interceptor?.onExitFunction(
            Function(handle: function, allocator: self.runtime.store.allocator),
            store: self.runtime.store
        )
    }
}
