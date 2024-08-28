/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(sp: Sp, pc: inout Pc) throws {
        throw Trap.unreachable
    }
    mutating func nop(sp: Sp, pc: inout Pc) throws {
        nextInstruction(&pc)
    }

    mutating func ifThen(sp: Sp, pc: inout Pc, ifOperand: Instruction.IfOperand) {
        let isTrue = sp[ifOperand.condition].i32 != 0
        if isTrue {
            nextInstruction(&pc)
        } else {
            nextInstruction(&pc, count: Int(ifOperand.elseOrEndOffset))
        }
    }

    mutating func br(sp: Sp, pc: inout Pc, offset: Int32) throws {
        nextInstruction(&pc, count: Int(offset))
    }
    mutating func brIf(sp: Sp, pc: inout Pc, brIfOperand: Instruction.BrIfOperand) throws {
        guard sp[brIfOperand.condition].i32 != 0 else {
            nextInstruction(&pc)
            return
        }
        nextInstruction(&pc, count: Int(brIfOperand.offset))
    }
    mutating func brIfNot(sp: Sp, pc: inout Pc, brIfOperand: Instruction.BrIfOperand) throws {
        guard sp[brIfOperand.condition].i32 == 0 else {
            nextInstruction(&pc)
            return
        }
        nextInstruction(&pc, count: Int(brIfOperand.offset))
    }
    mutating func brTable(sp: Sp, pc: inout Pc, brTableOperand: Instruction.BrTableOperand) throws {
        let brTable = brTableOperand.table
        let index = sp[brTableOperand.index].i32
        let normalizedOffset = min(Int(index), Int(brTable.count - 1))
        let entry = brTable.baseAddress[normalizedOffset]

        nextInstruction(&pc, count: Int(entry.offset))
    }

    mutating func `return`(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) throws {
        popFrame(sp: &sp, pc: &pc, md: &md, ms: &ms)
    }

    mutating func endOfExecution(sp: inout Sp, pc: inout Pc) throws {
        throw EndOfExecution()
    }

    private mutating func endOfFunction(currentFrame: Frame, sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) throws {
        // When reached at "end" of function
        popFrame(sp: &sp, pc: &pc, md: &md, ms: &ms)
    }

    @inline(__always)
    mutating func call(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms, callOperand: Instruction.CallOperand) throws {
        let function = callOperand.callee

        (pc, sp) = try invoke(
            function: function,
            callerInstance: currentFrame.instance,
            callLike: callOperand.callLike,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
    }

    @inline(__always)
    mutating func internalCall(sp: inout Sp, pc: inout Pc, internalCallOperand: Instruction.InternalCallOperand) throws {
        // The callee is known to be a function defined within the same module, so we can
        // skip updating the current instance.
        let (iseq, locals, instance) = internalCallOperand.callee.assumeCompiled()
        sp = try pushFrame(
            iseq: iseq,
            instance: instance,
            numberOfNonParameterLocals: locals,
            sp: sp, returnPC: pc.advancedPc(by: 1),
            spAddend: internalCallOperand.callLike.spAddend
        )
        pc = iseq.baseAddress
    }

    @inline(__always)
    mutating func compilingCall(sp: inout Sp, pc: inout Pc, compilingCallOperand: Instruction.CompilingCallOperand) throws {
        try compilingCallOperand.callee.ensureCompiled(runtime: runtime)
        pc.assumingMemoryBound(to: Instruction.self).pointee = .internalCall(compilingCallOperand)
        try internalCall(sp: &sp, pc: &pc, internalCallOperand: compilingCallOperand)
    }

    @inline(never)
    private func prepareForIndirectCall(
        sp: Sp, callIndirectOperand: Instruction.CallIndirectOperand
    ) throws -> (InternalFunction, InternalInstance) {
        let callerInstance = currentFrame.instance
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
        return (function, callerInstance)
    }

    @inline(__always)
    mutating func callIndirect(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms, callIndirectOperand: Instruction.CallIndirectOperand) throws {
        let (function, callerInstance) = try prepareForIndirectCall(
            sp: sp,
            callIndirectOperand: callIndirectOperand
        )
        (pc, sp) = try invoke(
            function: function,
            callerInstance: callerInstance,
            callLike: callIndirectOperand.callLike,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
    }

    mutating func onEnter(sp: Sp, onEnterOperand: Instruction.OnEnterOperand) {
        let function = currentInstance.functions[Int(onEnterOperand)]
        self.runtime.value.interceptor?.onEnterFunction(
            Function(handle: function, allocator: self.runtime.store.allocator),
            store: self.runtime.store
        )
    }
    mutating func onExit(sp: Sp, onExitOperand: Instruction.OnExitOperand) {
        let function = currentInstance.functions[Int(onExitOperand)]
        self.runtime.value.interceptor?.onExitFunction(
            Function(handle: function, allocator: self.runtime.store.allocator),
            store: self.runtime.store
        )
    }
}
