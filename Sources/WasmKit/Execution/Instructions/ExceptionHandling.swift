/// > Note:
/// <https://webassembly.github.io/exception-handling/core/exec/instructions.html>
extension Execution {

    /// Throw a new exception with the given tag.
    ///
    /// This instruction reads the tag's parameter values from the stack,
    /// constructs a `WasmKitException`, and throws it as a Swift error.
    @inline(never)
    func throwTag(sp: Sp, pc: Pc, immediate: Instruction.ThrowTagOperand) throws -> (Pc, CodeSlot) {
        let instance = currentInstance(sp: sp)
        let tag = instance.tags[Int(immediate.tagIndex)]
        let tagType = store.value.engine.resolveType(tag.type)
        var payload: [Value] = []
        payload.reserveCapacity(tagType.parameters.count)
        var slotOffset = VReg.zero
        for paramType in tagType.parameters {
            let value = UntypedValue(storage: sp[i64: immediate.payloadBase + slotOffset])
            payload.append(value.cast(to: paramType))
            slotOffset += VReg(slotIndex: paramType.stackSlotCount)
        }
        throw WasmKitException(tag: tag, payload: payload)
    }

    /// Throw the exception referenced by an `exnref` value.
    @inline(never)
    func throwRef(sp: Sp, pc: Pc, immediate: Instruction.ThrowRefOperand) throws -> (Pc, CodeSlot) {
        let ref = UntypedValue(storage: sp[i64: immediate.exnRef])
        if ref.isNullRef {
            throw Trap(.message(.init("null exception reference")))
        }
        throw store.value.allocator.gcHeap.exception(UInt32(truncatingIfNeeded: ref.storage))
    }

    /// Register exception handlers for a `try_table` block.
    ///
    /// `pc` points past the `catchHandlers` instruction at this point.
    /// The `pcOffset` in each `CatchTableEntry` is relative to this `pc`.
    ///
    /// Clauses are pushed last to first so that `handleException`, which searches
    /// from the top, tries them in source order as the spec requires.
    mutating func catchHandlers(sp: Sp, pc: Pc, immediate: Instruction.CatchHandlersOperand) -> (Pc, CodeSlot) {
        for i in (0..<Int(immediate.count)).reversed() {
            let entry = immediate.baseAddress[i]
            let targetPC = pc.advanced(by: Int(entry.pcOffset))
            let handler = ExceptionHandler(
                tag: entry.tag,
                isRef: entry.isRef != 0,
                sp: sp,
                targetPC: targetPC,
                payloadRegBase: entry.payloadRegBase,
                siblingsBelow: Int(immediate.count) - 1 - i
            )
            exceptionHandlers.append(handler)
        }
        return pc.next()
    }

    /// Unregister exception handlers.
    mutating func catchHandlersEnd(sp: Sp, immediate: Instruction.CatchHandlersEndOperand) {
        let count = Int(immediate.count)
        exceptionHandlers.removeLast(count)
    }

    /// Handle an exception by finding a matching handler and dispatching to it.
    ///
    /// On a match, mutates `sp`, `pc`, `md`, and `ms` to the handler's restored values
    /// and returns `true`. Returns `false` if no handler matched.
    mutating func handleException(
        _ exception: WasmKitException,
        sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms
    ) throws -> Bool {
        // Search from the top of the handler stack (most recently registered)
        while let handler = exceptionHandlers.last {
            exceptionHandlers.removeLast()

            let isMatch: Bool
            if let handlerTag = handler.tag {
                // catch / catch_ref: match by tag identity
                isMatch = exception.hasTag(handlerTag)
            } else {
                // catch_all / catch_all_ref: always match
                isMatch = true
            }

            guard isMatch else { continue }

            // The rest of this handler's try_table is exited along with it.
            exceptionHandlers.removeLast(handler.siblingsBelow)

            // Unwind call stack to the handler's frame
            sp = handler.sp
            pc = handler.targetPC

            // Update memory cache for the restored instance
            let restoredInstance = currentInstance(sp: sp)
            CurrentMemory.mayUpdateCurrentInstance(
                instance: restoredInstance,
                from: nil,
                md: &md, ms: &ms
            )

            // Write exception payload to the handler's target stack slots
            if let handlerTag = handler.tag {
                let tagType = store.value.engine.resolveType(handlerTag.type)
                var slotOffset = VReg.zero
                for (i, paramType) in tagType.parameters.enumerated() {
                    sp[i64: handler.payloadRegBase + slotOffset] = UntypedValue(exception.payload[i]).storage
                    slotOffset += VReg(slotIndex: paramType.stackSlotCount)
                }
                // For catch_ref, also write the exnref after the payload
                if handler.isRef {
                    let exnAddr = try storeException(exception, tag: handlerTag)
                    sp[i64: handler.payloadRegBase + slotOffset] = UntypedValue(.ref(.exception(exnAddr))).storage
                }
            } else if handler.isRef {
                // catch_all_ref: write exnref at the base
                let exnAddr = try storeException(exception, tag: nil)
                sp[i64: handler.payloadRegBase] = UntypedValue(.ref(.exception(exnAddr))).storage
            }
            // catch_all without ref: nothing to write

            return true
        }
        return false
    }

    /// Stores an exception in the GC heap and returns it as an `exnref`, the
    /// object's offset. `tag` is the tag the exception was caught by, if any.
    private func storeException(_ exception: WasmKitException, tag: InternalTag?) throws -> ExceptionAddress {
        // A catch_all_ref clause does not name the tag, but the exception's tag
        // identity is the tag entity's address.
        let tag = tag ?? InternalTag(bitPattern: UInt(bitPattern: exception.tagIdentity)).unsafelyUnwrapped
        let object = try store.value.allocator.gcHeap.allocateException(
            exception, tagType: tag.type, resourceLimiter: store.value.resourceLimiter)
        return ExceptionAddress(object)
    }
}
