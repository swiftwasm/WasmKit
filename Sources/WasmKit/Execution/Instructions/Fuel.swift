/// Signals that a fuel charge could not be paid.
///
/// Returned rather than thrown, for the same reason ``MemoryAccessTrap`` is: throwing out of a
/// handler is a call, and a call forces a prologue and epilogue onto the *fast* path. A loop's
/// per-iteration charge runs on that path, so it has to stay straight-line. Direct threading
/// dispatches to the `outOfFuelTrap` pseudo-instruction with a tail call; token threading, which
/// has no handler addresses, raises it from the dispatcher. Either suspends a resumable call, or
/// traps.
struct FuelTrap {
    let store: StoreRef
    /// The frame of the failed charge.
    let sp: Sp
    /// Where the charging handler was. Only ``raise()`` reads it, so it is what the
    /// token-threaded dispatcher sees: just past the checkpoint's immediate.
    let pc: Pc

    /// The head slot of the pseudo-instruction that handles this, for a direct-threaded handler
    /// to return as its "next instruction".
    @inline(__always)
    var directThreadedHeadSlot: CodeSlot {
        Instruction.outOfFuelTrapHeadSlot
    }

    /// Suspends or traps directly, for the token-threaded dispatcher.
    @inline(never)
    func raise() throws -> Never {
        try Execution.suspendOrTrapOutOfFuel(
            store: store, sp: sp, checkpoint: pc - (1 + Instruction.ConsumeFuelOperand.slotCount))
    }
}

extension Execution {
    /// Charges the fuel cost of the region beginning at this instruction.
    ///
    /// The charge is all-or-nothing: when the budget cannot cover it, the remaining fuel is left
    /// as it was, so a caller that tops the budget up can retry the very same charge.
    ///
    /// The cell is read straight from the store without consulting the engine's configuration,
    /// because this instruction is only ever emitted when that configuration asks for metering.
    @inline(__always)
    mutating func consumeFuel(immediate: Instruction.ConsumeFuelOperand, sp: Sp, pc: Pc) -> FuelTrap? {
        let fuel = store.value.remainingFuel.address
        let (remaining, underflow) = fuel.pointee.subtractingReportingOverflow(immediate.raw)
        if _slowPath(underflow) {
            return FuelTrap(store: store, sp: sp, pc: pc)
        }
        fuel.pointee = remaining
        return nil
    }

    /// Suspends a resumable call at the `consumeFuel` that failed, or raises `Trap(.outOfFuel)`.
    ///
    /// A pseudo-instruction: the translator never emits it, and `consumeFuel` reaches it by
    /// returning its head slot as the next instruction. By then the wrapper has stepped `pc` past
    /// the checkpoint's head slot, its immediate and its successor's head slot. Resuming at the
    /// checkpoint retries the charge, which the failure left undeducted.
    mutating func outOfFuelTrap(sp: Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        try Self.suspendOrTrapOutOfFuel(
            store: store, sp: sp, checkpoint: pc - (2 + Instruction.ConsumeFuelOperand.slotCount))
    }

    /// Out of line, so that the dispatcher it is reached from stays small.
    @inline(never)
    fileprivate static func suspendOrTrapOutOfFuel(store: StoreRef, sp: Sp, checkpoint: Pc) throws -> Never {
        guard store.value.isSuspendable else { throw Trap(.outOfFuel) }
        var immediatePC = checkpoint + 1
        let required = Instruction.ConsumeFuelOperand.load(from: &immediatePC).raw
        throw SuspensionSignal(reason: .outOfFuel(required: required), sp: sp, resumePC: checkpoint)
    }

    /// Charges for copying `count` table elements, priced like the bytes they occupy.
    ///
    /// Saturates rather than wrapping: a length whose byte count overflows 64 bits must charge
    /// everything the budget has, never a small wrapped-around amount.
    @inline(__always)
    mutating func chargeElementsCopied(_ count: UInt64) throws {
        try chargeBytesCopied(Self.bytesOfElements(count))
    }

    @inline(__always)
    static func bytesOfElements(_ count: UInt64) -> UInt64 {
        let (bytes, overflow) = count.multipliedReportingOverflow(by: UInt64(MemoryLayout<Reference>.stride))
        return overflow ? .max : bytes
    }

    /// ``reserveBytesCopied(_:sp:pc:for:)`` for `count` table elements.
    @inline(__always)
    mutating func reserveElementsCopied<Operand: InstructionImmediate>(
        _ count: UInt64, sp: Sp, pc: Pc, for operand: Operand.Type
    ) throws {
        try reserveBytesCopied(Self.bytesOfElements(count), sp: sp, pc: pc, for: operand)
    }

    /// Suspends a resumable call before a bulk operation whose ``chargeBytesCopied(_:)`` the
    /// budget cannot cover, so that resuming runs the whole operation again.
    ///
    /// Call this before the operation does anything. Bounds are checked by the operation itself,
    /// so one that is out of bounds can suspend here first, and trap once it is resumed. Outside
    /// a resumable call this does nothing, and the charge after the operation traps as before.
    ///
    /// - Parameters:
    ///   - sp: The frame of the calling instruction.
    ///   - pc: Just past the calling instruction's immediate.
    ///   - operand: The immediate operand type of the calling instruction, which tells how far
    ///     its head slot is behind `pc`.
    @inline(__always)
    mutating func reserveBytesCopied<Operand: InstructionImmediate>(
        _ bytes: UInt64, sp: Sp, pc: Pc, for operand: Operand.Type
    ) throws {
        guard store.value.isFuelMetered else { return }
        if _slowPath(store.value.remainingFuel.value < bytes / 64) {
            try suspendBeforeBulkOperation(required: bytes / 64, sp: sp, pc: pc, for: operand)
        }
    }

    @inline(never)
    private func suspendBeforeBulkOperation<Operand: InstructionImmediate>(
        required: UInt64, sp: Sp, pc: Pc, for operand: Operand.Type
    ) throws {
        guard store.value.isSuspendable else { return }
        throw SuspensionSignal(reason: .outOfFuel(required: required), sp: sp, resumePC: pc - (1 + Operand.slotCount))
    }

    /// Charges one unit of fuel per 64 bytes moved by a bulk memory or table operation.
    ///
    /// Call this after the operation's bounds checks have passed, so that a trapping operation
    /// costs only its operator and not the work it never did. Unlike the region charge above,
    /// this one does consult the configuration: these handlers exist whether or not the engine
    /// meters fuel, and a store given a budget on an unmetered engine must keep it untouched.
    @inline(__always)
    mutating func chargeBytesCopied(_ bytes: UInt64) throws {
        guard store.value.isFuelMetered else { return }
        let fuel = store.value.remainingFuel.address
        let (remaining, underflow) = fuel.pointee.subtractingReportingOverflow(bytes / 64)
        if _slowPath(underflow) {
            throw Trap(.outOfFuel)
        }
        fuel.pointee = remaining
    }
}
