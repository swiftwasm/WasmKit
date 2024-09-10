/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension ExecutionState {
    func unreachable(sp: Sp, pc: Pc) throws -> Pc {
        throw Trap.unreachable
    }
    mutating func nop(sp: Sp) {
    }

    mutating func br(sp: Sp, pc: Pc, offset: Int32) -> Pc {
        return pc.advanced(by: Int(offset))
    }
    mutating func brIf(sp: Sp, pc: Pc, brIfOperand: Instruction.BrIfOperand) -> Pc {
        guard sp[i32: brIfOperand.condition] != 0 else {
            return pc
        }
        return pc.advanced(by: Int(brIfOperand.offset))
    }
    mutating func brIfNot(sp: Sp, pc: Pc, brIfOperand: Instruction.BrIfOperand) -> Pc {
        guard sp[i32: brIfOperand.condition] == 0 else {
            return pc
        }
        return pc.advanced(by: Int(brIfOperand.offset))
    }
    mutating func brTable(sp: Sp, pc: Pc, brTable: Instruction.BrTable) -> Pc {
        let index = sp[i32: brTable.index]
        let normalizedOffset = min(Int(index), Int(brTable.count - 1))
        let entry = brTable.baseAddress[normalizedOffset]
        return pc.advanced(by: Int(entry.offset))
    }

    @inline(__always)
    mutating func _return(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms) -> Pc {
        var pc = pc
        popFrame(sp: &sp, pc: &pc, md: &md, ms: &ms)
        return pc
    }

    mutating func endOfExecution(sp: inout Sp, pc: Pc) throws -> Pc {
        throw EndOfExecution()
    }

    @inline(__always)
    mutating func call(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, callOperand: Instruction.CallOperand) throws -> Pc {
        var pc = pc

        (pc, sp) = try invoke(
            function: callOperand.callee,
            callerInstance: currentInstance(sp: sp),
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
        let (iseq, locals, instance) = internalCallOperand.callee.assumeCompiled()
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
        let callee = internalCallOperand.callee
        try _internalCall(sp: &sp, pc: &pc, callee: callee, internalCallOperand: internalCallOperand)
        return pc
    }

    @inline(__always)
    mutating func compilingCall(sp: inout Sp, pc: Pc, compilingCallOperand: Instruction.CompilingCallOperand) throws -> Pc {
        var pc = pc
        // NOTE: `CompilingCallOperand` consumes 2 slots, discriminator is at -3
        let discriminatorPc = pc.advanced(by: -3)
        let callee = compilingCallOperand.callee
        try callee.ensureCompiled(runtime: runtime)
        let replaced = Instruction.internalCall(compilingCallOperand)
        switch runtime.value.configuration.threadingModel {
        case .direct:
            discriminatorPc.pointee = replaced.handler
        case .token:
            discriminatorPc.pointee = UInt64(replaced.rawIndex)
        }
        try _internalCall(sp: &sp, pc: &pc, callee: callee, internalCallOperand: compilingCallOperand)
        return pc
    }

    @inline(never)
    private func prepareForIndirectCall(
        sp: Sp, tableIndex: TableIndex, expectedType: InternedFuncType,
        callIndirectOperand: Instruction.CallIndirectOperand
    ) throws -> (InternalFunction, InternalInstance) {
        let callerInstance = currentInstance(sp: sp)
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
        let (function, callerInstance) = try prepareForIndirectCall(
            sp: sp, tableIndex: callIndirectOperand.tableIndex, expectedType: callIndirectOperand.type,
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
        let function = currentInstance(sp: sp).functions[Int(onEnterOperand)]
        self.runtime.value.interceptor?.onEnterFunction(
            Function(handle: function, allocator: self.runtime.store.allocator),
            store: self.runtime.store
        )
    }
    mutating func onExit(sp: Sp, onExitOperand: Instruction.OnExitOperand) {
        let function = currentInstance(sp: sp).functions[Int(onExitOperand)]
        self.runtime.value.interceptor?.onExitFunction(
            Function(handle: function, allocator: self.runtime.store.allocator),
            store: self.runtime.store
        )
    }
}
