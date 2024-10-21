/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#control-instructions>
extension Execution {
    func unreachable(sp: Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        throw Trap(.unreachable)
    }
    mutating func nop(sp: Sp) {
    }

    mutating func br(sp: Sp, pc: Pc, immediate: Instruction.BrOperand) -> (Pc, CodeSlot) {
        return pc.advanced(by: Int(immediate)).next()
    }
    mutating func brIf(sp: Sp, pc: Pc, immediate: Instruction.BrIfOperand) -> (Pc, CodeSlot) {
        // NOTE: Marked as `_fastPath` to teach the compiler not to use conditional
        // instructions (e.g. csel) to utilize the branch prediction. Typically
        // if-conversion is applied to optimize branches into conditional instructions
        // but it's not always the best choice for performance when the branch is
        // highly predictable:
        //
        // > Use branches when the condition is highly predictable. The cost of
        // > mispredicts will be low, and the code will be executed with optimal
        // > latency.
        // >
        // > Apple Silicon CPU Optimization Guide: 3.0 (Page 105)
        //
        // We prefer branch instructions over conditional instructions to provide
        // the best performance when guest code is highly predictable.
        guard _fastPath(sp[i32: immediate.condition] != 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    mutating func brIfNot(sp: Sp, pc: Pc, immediate: Instruction.BrIfOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for the rationale.
        guard _fastPath(sp[i32: immediate.condition] == 0) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    mutating func brTable(sp: Sp, pc: Pc, immediate: Instruction.BrTableOperand) -> (Pc, CodeSlot) {
        let index = sp[i32: immediate.index]
        let normalizedOffset = min(Int(index), Int(immediate.count - 1))
        let entry = immediate.baseAddress[normalizedOffset]
        return pc.advanced(by: Int(entry.offset)).next()
    }

    @inline(__always)
    mutating func _return(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms) -> (Pc, CodeSlot) {
        var pc = pc
        popFrame(sp: &sp, pc: &pc, md: &md, ms: &ms)
        return pc.next()
    }

    mutating func endOfExecution(sp: inout Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        throw EndOfExecution()
    }

    @inline(__always)
    mutating func call(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, immediate: Instruction.CallOperand) throws -> (Pc, CodeSlot) {
        var pc = pc

        (pc, sp) = try invoke(
            function: immediate.callee,
            callerInstance: currentInstance(sp: sp),
            spAddend: immediate.spAddend,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        return pc.next()
    }

    @inline(__always)
    private mutating func _internalCall(
        sp: inout Sp,
        pc: inout Pc,
        callee: InternalFunction,
        internalCallOperand: Instruction.CallOperand
    ) throws {
        // The callee is known to be a function defined within the same module, so we can
        // skip updating the current instance.
        let (iseq, locals, instance) = internalCallOperand.callee.assumeCompiled()
        sp = try pushFrame(
            iseq: iseq,
            function: instance,
            numberOfNonParameterLocals: locals,
            sp: sp, returnPC: pc,
            spAddend: internalCallOperand.spAddend
        )
        pc = iseq.baseAddress
    }

    @inline(__always)
    mutating func internalCall(sp: inout Sp, pc: Pc, immediate: Instruction.CallOperand) throws -> (Pc, CodeSlot) {
        var pc = pc
        let callee = immediate.callee
        try _internalCall(sp: &sp, pc: &pc, callee: callee, internalCallOperand: immediate)
        return pc.next()
    }

    @inline(__always)
    mutating func compilingCall(sp: inout Sp, pc: Pc, immediate: Instruction.CallOperand) throws -> (Pc, CodeSlot) {
        var pc = pc
        // NOTE: `CompilingCallOperand` consumes 2 slots, discriminator is at -3
        let headSlotPc = pc.advanced(by: -3)
        let callee = immediate.callee
        try callee.wasm.ensureCompiled(store: store)
        let replaced = Instruction.internalCall(immediate)
        headSlotPc.pointee = replaced.headSlot(threadingModel: store.value.engine.configuration.threadingModel)
        try _internalCall(sp: &sp, pc: &pc, callee: callee, internalCallOperand: immediate)
        return pc.next()
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
            throw Trap(.tableOutOfBounds(elementIndex))
        }
        guard case let .function(rawBitPattern?) = table.elements[elementIndex]
        else {
            throw Trap(.indirectCallToNull(elementIndex))
        }
        let function = InternalFunction(bitPattern: rawBitPattern)
        guard function.type == expectedType else {
            throw Trap(
                .typeMismatchCall(
                    actual: store.value.engine.resolveType(function.type),
                    expected: store.value.engine.resolveType(expectedType)
                ))
        }
        return (function, callerInstance)
    }

    @inline(__always)
    mutating func callIndirect(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, immediate: Instruction.CallIndirectOperand) throws -> (Pc, CodeSlot) {
        var pc = pc
        let (function, callerInstance) = try prepareForIndirectCall(
            sp: sp, tableIndex: immediate.tableIndex, expectedType: immediate.type,
            callIndirectOperand: immediate
        )
        (pc, sp) = try invoke(
            function: function,
            callerInstance: callerInstance,
            spAddend: immediate.spAddend,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        return pc.next()
    }

    mutating func onEnter(sp: Sp, immediate: Instruction.OnEnterOperand) {
        let function = currentInstance(sp: sp).functions[Int(immediate)]
        self.store.value.engine.interceptor?.onEnterFunction(
            Function(handle: function, store: store.value)
        )
    }
    mutating func onExit(sp: Sp, immediate: Instruction.OnExitOperand) {
        let function = currentInstance(sp: sp).functions[Int(immediate)]
        self.store.value.engine.interceptor?.onExitFunction(
            Function(handle: function, store: store.value)
        )
    }
}
