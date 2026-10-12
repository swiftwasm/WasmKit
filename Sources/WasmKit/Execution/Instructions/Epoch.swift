import _CWasmKit

/// Signals that the engine's epoch reached the store's deadline.
///
/// Returned rather than thrown, like ``FuelTrap``: `checkEpoch` runs at every loop header, so its
/// fast path has to stay straight-line. Direct threading dispatches to the `epochDeadlineTrap`
/// pseudo-instruction with a tail call; token threading raises it from the dispatcher.
struct EpochTrap {
    let store: StoreRef
    /// The frame of the check.
    let sp: Sp
    /// Where the checking handler was. Only ``raise()`` reads it, so it is what the
    /// token-threaded dispatcher sees: just past the check's head slot.
    let pc: Pc

    /// The head slot of the pseudo-instruction that handles this, for a direct-threaded handler
    /// to return as its "next instruction".
    @inline(__always)
    var directThreadedHeadSlot: CodeSlot {
        Instruction.epochDeadlineTrapHeadSlot
    }

    /// Suspends or traps directly, for the token-threaded dispatcher.
    @inline(never)
    func raise() throws -> Never {
        try Execution.suspendOrTrapAtEpochDeadline(store: store, sp: sp, checkpoint: pc - 1)
    }
}

extension Execution {
    /// Compares the engine's epoch with the store's deadline.
    ///
    /// Reads the store without consulting the engine's configuration, because this instruction
    /// is only ever emitted when that configuration asks for epoch interruption.
    @inline(__always)
    mutating func checkEpoch(sp: Sp, pc: Pc) -> EpochTrap? {
        let store = store.value
        if _slowPath(wasmkit_epoch_load(store.epochCounter) >= store.epochDeadline.value) {
            return EpochTrap(store: self.store, sp: sp, pc: pc)
        }
        return nil
    }

    /// Suspends a resumable call at the `checkEpoch` that reached the deadline, or raises
    /// `Trap(.epochDeadlineReached)`.
    ///
    /// A pseudo-instruction reached like `outOfFuelTrap`. By then the wrapper has stepped `pc`
    /// past the check's head slot and its successor's. Resuming at the check runs it again.
    mutating func epochDeadlineTrap(sp: Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        try Self.suspendOrTrapAtEpochDeadline(store: store, sp: sp, checkpoint: pc - 2)
    }

    /// Out of line, so that the dispatcher it is reached from stays small.
    @inline(never)
    fileprivate static func suspendOrTrapAtEpochDeadline(store: StoreRef, sp: Sp, checkpoint: Pc) throws -> Never {
        guard store.value.isSuspendable else { throw Trap(.epochDeadlineReached) }
        throw SuspensionSignal(reason: .epochDeadlineReached, sp: sp, resumePC: checkpoint)
    }
}
