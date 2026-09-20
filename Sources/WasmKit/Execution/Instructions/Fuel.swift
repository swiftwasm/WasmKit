/// Signals that a fuel charge could not be paid.
///
/// Returned rather than thrown, for the same reason ``MemoryAccessTrap`` is: throwing out of a
/// handler is a call, and a call forces a prologue and epilogue onto the *fast* path. A loop's
/// per-iteration charge runs on that path, so it has to stay straight-line. Direct threading
/// dispatches to the `outOfFuelTrap` pseudo-instruction with a tail call; token threading, which
/// has no handler addresses, throws from the dispatcher.
enum FuelTrap {
    case outOfFuel

    /// The head slot of the pseudo-instruction that raises this trap, for a direct-threaded
    /// handler to return as its "next instruction".
    @inline(__always)
    var directThreadedHeadSlot: CodeSlot {
        Instruction.outOfFuelTrapHeadSlot
    }

    /// Raises this trap directly, for the token-threaded dispatcher.
    @inline(never)
    func raise() throws -> Never {
        throw Trap(.outOfFuel)
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
    mutating func consumeFuel(immediate: Instruction.ConsumeFuelOperand) -> FuelTrap? {
        let fuel = store.value.remainingFuel.address
        let (remaining, underflow) = fuel.pointee.subtractingReportingOverflow(immediate.raw)
        if _slowPath(underflow) {
            return .outOfFuel
        }
        fuel.pointee = remaining
        return nil
    }

    /// Raises `Trap(.outOfFuel)`.
    ///
    /// A pseudo-instruction: the translator never emits it, and `consumeFuel` reaches it by
    /// returning its head slot as the next instruction.
    ///
    /// Records the program counter on the way out. Nothing reads it yet: a resumable call has to
    /// retry the charge that failed, and keeping the position means that change does not have to
    /// disturb this path. Note what the value points at — by the time the trap is dispatched the
    /// interpreter has already stepped `pc` past the checkpoint's immediate and its successor's
    /// head slot, so a resumable API has to walk it back to the `consumeFuel` instruction rather
    /// than use it as is.
    mutating func outOfFuelTrap(sp: Sp, pc: Pc) throws -> (Pc, CodeSlot) {
        store.value.fuelTrapPC = UnsafeRawPointer(pc)
        try FuelTrap.outOfFuel.raise()
    }

    /// Charges for copying `count` table elements, priced like the bytes they occupy.
    ///
    /// Saturates rather than wrapping: a length whose byte count overflows 64 bits must charge
    /// everything the budget has, never a small wrapped-around amount.
    @inline(__always)
    mutating func chargeElementsCopied(_ count: UInt64) throws {
        let (bytes, overflow) = count.multipliedReportingOverflow(by: UInt64(MemoryLayout<Reference>.stride))
        try chargeBytesCopied(overflow ? .max : bytes)
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
