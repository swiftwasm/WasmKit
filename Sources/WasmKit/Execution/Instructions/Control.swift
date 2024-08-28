/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(sp: Sp, pc: Pc) throws -> Pc {
        throw Trap.unreachable
    }
    mutating func nop(sp: Sp, pc: Pc) throws -> Pc {
        return pc
    }

    mutating func ifThen(sp: Sp, pc: Pc, ifOperand: Instruction.IfOperand) -> Pc {
        guard sp[ifOperand.condition].i32 == 0 else {
            return pc
        }
        return pc.advancedPc(by: Int(ifOperand.elseOrEndOffset))
    }

    mutating func br(sp: Sp, pc: Pc, offset: Int32) throws -> Pc {
        return pc.advancedPc(by: Int(offset))
    }
    mutating func brIf(sp: Sp, pc: Pc, brIfOperand: Instruction.BrIfOperand) throws -> Pc {
        guard sp[brIfOperand.condition].i32 != 0 else {
            return pc
        }
        return pc.advancedPc(by: Int(brIfOperand.offset))
    }
    mutating func brIfNot(sp: Sp, pc: Pc, brIfOperand: Instruction.BrIfOperand) throws -> Pc {
        guard sp[brIfOperand.condition].i32 == 0 else {
            return pc
        }
        return pc.advancedPc(by: Int(brIfOperand.offset))
    }
    mutating func brTable(sp: Sp, pc: Pc, brTableOperand: Instruction.BrTableOperand) throws -> Pc {
        var pc = pc
        let brTable = pc.read(Instruction.BrTable.self)
        let index = sp[brTableOperand.index].i32
        let normalizedOffset = min(Int(index), Int(brTableOperand.count - 1))
        let entry = brTable.baseAddress[normalizedOffset]

        nextInstruction(&pc, count: Int(entry.offset))
        return pc
    }

    mutating func `return`(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms) throws -> Pc {
        var pc = pc
        popFrame(sp: &sp, pc: &pc, md: &md, ms: &ms)
        return pc
    }

    mutating func endOfExecution(sp: inout Sp, pc: Pc) throws -> Pc {
        throw EndOfExecution()
    }

    private mutating func endOfFunction(currentFrame: Frame, sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) throws {
        // When reached at "end" of function
        popFrame(sp: &sp, pc: &pc, md: &md, ms: &ms)
    }

    @inline(__always)
    mutating func call(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, callOperand: Instruction.CallOperand) throws -> Pc {
        var pc = pc
        let function = pc.read(InternalFunction.self)

        (pc, sp) = try invoke(
            function: function,
            callerInstance: currentFrame.instance,
            callLike: callOperand.callLike,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        return pc
    }

    @inline(__always)
    private mutating func _internalCall(
        sp: inout Sp,
        pc: inout Pc,
        callee: InternalFunction,
        internalCallOperand: Instruction.InternalCallOperand
    ) throws {
        // The callee is known to be a function defined within the same module, so we can
        // skip updating the current instance.
        let (iseq, locals, instance) = callee.assumeCompiled()
        sp = try pushFrame(
            iseq: iseq,
            instance: instance,
            numberOfNonParameterLocals: locals,
            sp: sp, returnPC: pc,
            spAddend: internalCallOperand.callLike.spAddend
        )
        pc = iseq.baseAddress
    }

    @inline(__always)
    mutating func internalCall(sp: inout Sp, pc: Pc, internalCallOperand: Instruction.InternalCallOperand) throws -> Pc {
        var pc = pc
        let callee = pc.read(InternalFunction.self)
        try _internalCall(sp: &sp, pc: &pc, callee: callee, internalCallOperand: internalCallOperand)
        return pc
    }

    @inline(__always)
    mutating func compilingCall(sp: inout Sp, pc: Pc, compilingCallOperand: Instruction.CompilingCallOperand) throws -> Pc {
        var pc = pc
        let callPc = pc - MemoryLayout<Instruction>.stride
        let callee = pc.read(InternalFunction.self)
        try callee.ensureCompiled(runtime: runtime)
        callPc.assumingMemoryBound(to: Instruction.self).pointee = .internalCall(compilingCallOperand)
        try _internalCall(sp: &sp, pc: &pc, callee: callee, internalCallOperand: compilingCallOperand)
        return pc
    }

    @inline(never)
    private func prepareForIndirectCall(
        sp: Sp, tableIndex: TableIndex, expectedType: InternedFuncType,
        callIndirectOperand: Instruction.CallIndirectOperand
    ) throws -> (InternalFunction, InternalInstance) {
        let callerInstance = currentFrame.instance
        let table = callerInstance.tables[Int(tableIndex)]
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
    mutating func callIndirect(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, callIndirectOperand: Instruction.CallIndirectOperand) throws -> Pc {
        var pc = pc
        let tableIndex = TableIndex(pc.read(UInt64.self))
        let expectedType = InternedFuncType(id: UInt32((pc.read(UInt64.self))))
        let (function, callerInstance) = try prepareForIndirectCall(
            sp: sp, tableIndex: tableIndex, expectedType: expectedType,
            callIndirectOperand: callIndirectOperand
        )
        (pc, sp) = try invoke(
            function: function,
            callerInstance: callerInstance,
            callLike: callIndirectOperand.callLike,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        return pc
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
