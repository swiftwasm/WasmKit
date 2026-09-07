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

    /// Returns to the caller.
    ///
    /// This handler covers only the case where the caller runs in the same
    /// instance as the frame being popped, which is every return inside a module
    /// and therefore almost every return. `md`/`ms` still describe the right
    /// memory, so the whole instruction is: load the two saved slots, check the
    /// flag the call recorded in the saved PC, dispatch.
    ///
    /// The cross-instance case is handed off to ``returnCrossInstance`` instead of
    /// being handled here, so that this handler contains no call at all. A single
    /// call instruction anywhere in it (`bl` on arm64, `call` on x86-64) -- and
    /// switching `md`/`ms` needs one, for `wasmkit_trap_guard_set_current_memory`
    /// -- would cost a stack frame's worth of prologue and epilogue on *every*
    /// return. As it stands the handler is 6 instructions on arm64 and 8 on
    /// x86-64, with no frame, ending in an indirect branch to the next handler.
    @inline(__always)
    mutating func _return(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms) -> (Pc, CodeSlot) {
        let oldSp = sp
        let rawReturnPC = oldSp.rawReturnPC
        guard _fastPath(rawReturnPC & Sp.returnPCNeedsMemoryRestore == 0) else {
            // Re-dispatch with `sp`/`pc` untouched; `returnCrossInstance` pops.
            // The slot is read through the engine: loads only, no call.
            return (pc, store.value.engine.crossInstanceReturnSlot)
        }
        sp = oldSp.previousSP.unsafelyUnwrapped
        // The flag bit is clear, so the slot is the return `Pc` as it stands.
        let pc = Pc(bitPattern: UInt(rawReturnPC)).unsafelyUnwrapped
        return pc.next()
    }

    /// Returns to a caller in a different instance, switching `md`/`ms` back.
    ///
    /// Never emitted by the translator: ``_return`` dispatches here when the frame
    /// it is about to pop was entered across an instance boundary, so `sp` and `pc`
    /// are still exactly what that `_return` was given.
    @inline(__always)
    mutating func returnCrossInstance(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms) -> (Pc, CodeSlot) {
        var pc = pc
        popFrameRestoringCurrentMemory(sp: &sp, pc: &pc, md: &md, ms: &ms)
        return pc.next()
    }

    mutating func endOfExecution(sp: inout Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        throw EndOfExecution(sp: sp)
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
        // skip updating the current instance -- and, by recording that in the frame,
        // the matching `_return` can skip checking for it too.
        let (iseq, instance) = internalCallOperand.callee.assumeCompiled()
        sp = try pushFrame(
            iseq: iseq,
            function: instance,
            sp: sp, returnPC: pc,
            spAddend: internalCallOperand.spAddend,
            needsMemoryRestoreOnReturn: false
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

    /// Loads a `call_indirect` table entry, or `0` when the index is out of
    /// bounds.
    ///
    /// The table's address is baked into the immediate, so this is two loads off
    /// that address (`rawElements` and `count`, independent of each other) plus
    /// the element load -- no instance chase, no `Array` bounds-check machinery,
    /// and no reference counting, because the elements are plain 64-bit words in
    /// the ``UntypedValue`` encoding.
    ///
    /// `0` doubles as the out-of-bounds sentinel: it is not a representable
    /// reference, since a null one has bit 63 set and a non-null one is an entity
    /// address. So one signed comparison on the result covers both "out of
    /// bounds" and "null", which is what keeps the fast handler's prologue-free
    /// resolution down to five instructions.
    @inline(__always)
    private func loadIndirectCallee(sp: Sp, table: InternalTable, address: VReg) -> UInt64 {
        let index = sp[address].asAddressOffset()
        return table.withValue { table -> UInt64 in
            guard _fastPath(index < UInt64(bitPattern: Int64(table.count))) else { return 0 }
            return table.rawElements[Int(bitPattern: UInt(index))]
        }
    }

    /// Builds the trap for a `call_indirect` whose table entry could not be used.
    @inline(never)
    private func indirectCallResolutionTrap(table: InternalTable, index: UInt64) -> Error {
        let elementIndex = Int(truncatingIfNeeded: index)
        guard index < UInt64(bitPattern: Int64(table.count)) else {
            return Trap(.tableOutOfBounds(elementIndex))
        }
        return Trap(.indirectCallToNull(elementIndex))
    }

    @inline(never)
    private func indirectCallTypeMismatchTrap(actual: InternedFuncType, expected: InternedFuncType) -> Error {
        Trap(
            .typeMismatchCall(
                actual: store.value.engine.resolveType(actual),
                expected: store.value.engine.resolveType(expected)
            ))
    }

    /// Resolves a `call_indirect` table entry the way `returnCallIndirect` needs
    /// it: throwing, since that handler has a stack frame anyway.
    @inline(__always)
    private func resolveIndirectCallee(
        sp: Sp, table: InternalTable, address: VReg
    ) throws -> InternalFunction {
        let raw = loadIndirectCallee(sp: sp, table: table, address: address)
        guard _fastPath(Int64(bitPattern: raw) > 0) else {
            throw indirectCallResolutionTrap(
                table: table, index: sp[address].asAddressOffset()
            )
        }
        return InternalFunction(bitPattern: Int(bitPattern: UInt(raw)))
    }

    /// `call_indirect`, fast path.
    ///
    /// Every check below bails to ``callIndirectSlow`` rather than handling its
    /// case, so that this handler contains no call and therefore no prologue: a
    /// trap has to build a `Trap` (a type-metadata accessor plus
    /// `swift_allocError`), compiling a callee is a call, entering a host callee
    /// is a call, switching `md`/`ms` is a call, and a frame-init image over
    /// ``Execution/inlineFrameInitLimit`` slots is a `memcpy`. The hand-off costs
    /// one extra dispatch on paths that were already doing far more work.
    ///
    /// `sp` is left untouched and `pc` is rewound to the start of the shared
    /// immediate, so ``callIndirectSlow`` decodes exactly the same operand and
    /// redoes the resolution from scratch -- which is what makes the traps come
    /// out in the order the spec asks for without this handler knowing about them.
    @inline(__always)
    mutating func callIndirect(sp: inout Sp, pc: Pc, immediate: Instruction.CallIndirectOperand) -> (Pc, CodeSlot) {
        // `CallIndirectOperand` occupies 3 slots and `pc` is past all of them.
        // The slot is read through the engine: loads only, no call.
        let handOff = (pc.advanced(by: -3), store.value.engine.callIndirectSlowSlot)

        let raw = loadIndirectCallee(sp: sp, table: immediate.table, address: immediate.index)
        // Out of bounds (0) or null (bit 63) in one signed compare.
        guard _fastPath(Int64(bitPattern: raw) > 0) else { return handOff }
        // Bit 0 tags a host function, whose entity is not a `WasmFunctionEntity`.
        guard _fastPath(raw & 0b1 == 0) else { return handOff }
        let callee = EntityHandle<WasmFunctionEntity>(bitPattern: UInt(raw)).unsafelyUnwrapped
        guard _fastPath(callee.type == immediate.type) else { return handOff }
        // One load of the code state and a branch, instead of a call into
        // `ensureCompiled` on every indirect call.
        guard let iseq = callee.compiledIseq else { return handOff }
        // Same instance: no `md`/`ms` update, and the saved-PC flag stays clear so
        // the matching `_return` keeps its fast path too.
        guard _fastPath(callee.instance == immediate.callerInstance) else { return handOff }
        guard
            let newSp = pushFrameWithoutCalling(
                iseq: iseq, function: callee,
                sp: sp, returnPC: pc, spAddend: immediate.spAddend
            )
        else { return handOff }
        sp = newSp
        return iseq.baseAddress.next()
    }

    /// `call_indirect`, everything ``callIndirect`` declined to do.
    ///
    /// Never emitted by the translator. It receives the `sp` its `callIndirect`
    /// was given and a `pc` rewound to the shared immediate, so it can resolve
    /// from scratch.
    @inline(__always)
    mutating func callIndirectSlow(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, immediate: Instruction.CallIndirectOperand) throws -> (Pc, CodeSlot) {
        let function = try resolveIndirectCallee(sp: sp, table: immediate.table, address: immediate.index)
        guard function.isWasm else {
            // A host callee runs in place and leaves `sp`, `pc`, `md` and `ms`
            // alone. `Execution.invokeHostFunction` is the `self`-free form on
            // purpose: a method taking `Execution` by reference makes the
            // optimizer materialise a 48-byte copy of it on the native stack.
            guard function.type == immediate.type else {
                throw indirectCallTypeMismatchTrap(actual: function.type, expected: immediate.type)
            }
            try Execution.invokeHostFunction(
                store: store, function: function.host, sp: sp, spAddend: immediate.spAddend
            )
            return pc.next()
        }
        let callee = function.wasm
        guard callee.type == immediate.type else {
            throw indirectCallTypeMismatchTrap(actual: callee.type, expected: immediate.type)
        }
        let iseq: InstructionSequence
        if let compiled = callee.compiledIseq {
            iseq = compiled
        } else {
            iseq = try callee.ensureCompiled(store: store)
        }
        let calleeInstance = callee.instance
        let switchesInstance = calleeInstance != immediate.callerInstance
        sp = try pushFrame(
            iseq: iseq,
            function: callee,
            sp: sp, returnPC: pc,
            spAddend: immediate.spAddend,
            needsMemoryRestoreOnReturn: switchesInstance
        )
        if switchesInstance {
            Execution.CurrentMemory.mayUpdateCurrentInstance(instance: calleeInstance, md: &md, ms: &ms)
        }
        return iseq.baseAddress.next()
    }

    mutating func returnCall(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, immediate: Instruction.ReturnCallOperand) throws -> (Pc, CodeSlot) {
        var pc = pc
        (pc, sp) = try tailInvoke(
            function: immediate.callee,
            callerInstance: currentInstance(sp: sp),
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        return pc.next()
    }

    mutating func returnCallIndirect(sp: inout Sp, pc: Pc, md: inout Md, ms: inout Ms, immediate: Instruction.ReturnCallIndirectOperand) throws -> (Pc, CodeSlot) {
        var pc = pc
        // Resolution is inlined the same way as `callIndirect`'s; the entry itself
        // stays in `tailInvoke`, which has to reuse the current frame and is far
        // rarer than a plain indirect call.
        let function = try resolveIndirectCallee(sp: sp, table: immediate.table, address: immediate.index)
        guard _fastPath(function.type == immediate.type) else {
            throw indirectCallTypeMismatchTrap(actual: function.type, expected: immediate.type)
        }
        (pc, sp) = try tailInvoke(
            function: function,
            callerInstance: immediate.callerInstance,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        return pc.next()
    }

    mutating func resizeFrameHeader(sp: inout Sp, immediate: Instruction.ResizeFrameHeaderOperand) throws {
        // The params/results space are resized by `delta` slots and the rest of the
        // frame is copied to the new location. See the following diagram for the
        // layout of the frame before and after the resize operation:
        //
        //
        //              |--------BEFORE-------|   |--------AFTER--------|
        //              |  Params  | Results  |   |  Params  | Results  |
        //              |  ...     |   ...    |   |  ...     |   ...    |
        // Old Header ->|---------------------|\  |  ...     |   ...    |              -+
        //              |         Sp          | \ |  ...     |   ...    |               | delta
        //              |---------------------|  \|---------------------|<- New Header -+  -+
        //              |         Pc          |   |         Sp          |                   |
        //              |---------------------|   |---------------------|                   |
        //              |     Current Func    | C |         Pc          |                   |
        //     Old Sp ->|---------------------| O |---------------------|                   |
        //              |       Locals        | P |     Current Func    |                   |
        //              |        ...          | Y |---------------------|<- New Sp          |
        //              |---------------------|   |       Locals        |                   | sizeToCopy
        //              |        Consts       |   |        ...          |                   |
        //              |        ...          |   |---------------------|                   |
        //              |---------------------|   |        Consts       |                   |
        //              |     Value Stack     |   |        ...          |                   |
        //              |        ...          |   |---------------------|                   |
        //              |---------------------|\  |     Value Stack     |                   |
        //                                      \ |        ...          |                   |
        //                                       \|---------------------|                  -+
        let newSp = sp.advanced(by: Int(immediate.delta))
        try checkStackBoundary(newSp)
        let oldFrameHeader = sp.advanced(by: -FrameHeaderLayout.numberOfSavingSlots)
        let newFrameHeader = newSp.advanced(by: -FrameHeaderLayout.numberOfSavingSlots)
        newFrameHeader.update(from: oldFrameHeader, count: Int(immediate.sizeToCopy))
        sp = newSp
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

    mutating func breakpoint(sp: inout Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        throw Breakpoint(
            sp: sp,
            // Throw `pc` value before the breakpoint was triggered to allow resumption in same place
            pc: pc - 1
        )
    }
}

// MARK: - Fused integer compare + branch
//
// These are the fused form of an integer comparison immediately followed by
// `br_if`/`br_if_not`. The translator emits one of these instead of writing the
// comparison result into a stack slot and reloading it in `brIf`, which removes
// one dispatch, one store and one load per loop back-edge.
//
// Only integers are fused: the complement of an integer comparison is another
// integer comparison (Eq<->Ne, LtS<->GeS, LtU<->GeU, GtS<->LeS, GtU<->LeU), so
// `br_if_not` needs no dedicated opcodes. Float comparisons have no complement
// because of NaN, so they are left unfused.
extension Execution {
    /// Fused `i32.eq` + `br_if`.
    @inline(__always)
    mutating func brIfI32Eq(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] == sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ne` + `br_if`.
    @inline(__always)
    mutating func brIfI32Ne(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] != sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.lt_s` + `br_if`.
    @inline(__always)
    mutating func brIfI32LtS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed < sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.lt_u` + `br_if`.
    @inline(__always)
    mutating func brIfI32LtU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] < sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.gt_s` + `br_if`.
    @inline(__always)
    mutating func brIfI32GtS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed > sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.gt_u` + `br_if`.
    @inline(__always)
    mutating func brIfI32GtU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] > sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.le_s` + `br_if`.
    @inline(__always)
    mutating func brIfI32LeS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed <= sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.le_u` + `br_if`.
    @inline(__always)
    mutating func brIfI32LeU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] <= sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ge_s` + `br_if`.
    @inline(__always)
    mutating func brIfI32GeS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs].signed >= sp[i32: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i32.ge_u` + `br_if`.
    @inline(__always)
    mutating func brIfI32GeU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i32: immediate.lhs] >= sp[i32: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.eq` + `br_if`.
    @inline(__always)
    mutating func brIfI64Eq(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] == sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ne` + `br_if`.
    @inline(__always)
    mutating func brIfI64Ne(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] != sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.lt_s` + `br_if`.
    @inline(__always)
    mutating func brIfI64LtS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed < sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.lt_u` + `br_if`.
    @inline(__always)
    mutating func brIfI64LtU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] < sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.gt_s` + `br_if`.
    @inline(__always)
    mutating func brIfI64GtS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed > sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.gt_u` + `br_if`.
    @inline(__always)
    mutating func brIfI64GtU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] > sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.le_s` + `br_if`.
    @inline(__always)
    mutating func brIfI64LeS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed <= sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.le_u` + `br_if`.
    @inline(__always)
    mutating func brIfI64LeU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] <= sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ge_s` + `br_if`.
    @inline(__always)
    mutating func brIfI64GeS(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs].signed >= sp[i64: immediate.rhs].signed) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
    /// Fused `i64.ge_u` + `br_if`.
    @inline(__always)
    mutating func brIfI64GeU(sp: Sp, pc: Pc, immediate: Instruction.BrIfCmpOperand) -> (Pc, CodeSlot) {
        // NOTE: See `brIf` for why this must stay a real branch (not a `csel`).
        guard _fastPath(sp[i64: immediate.lhs] >= sp[i64: immediate.rhs]) else {
            return pc.next()
        }
        return pc.advanced(by: Int(immediate.offset)).next()
    }
}
