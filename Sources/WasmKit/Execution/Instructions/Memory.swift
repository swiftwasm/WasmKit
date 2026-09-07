import WasmParser
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
import _CWasmKit

/// A trap raised by a memory access, returned by the load/store and atomic helpers
/// instead of being thrown.
///
/// Throwing out of a handler body is a `bl` to the error-allocating function, which forces
/// a prologue and epilogue onto the handler -- that is, onto the *fast* path of every load
/// and store. Returning the trap lets each threading model raise it in its own way:
/// direct threading dispatches to a trap pseudo-instruction with a tail call, and token
/// threading (which has no handler addresses) throws from the dispatcher.
enum MemoryAccessTrap {
    case outOfBounds
    case unalignedAtomic

    /// The head slot of the pseudo-instruction that raises this trap, for a
    /// direct-threaded handler to return as its "next instruction".
    @inline(__always)
    var directThreadedHeadSlot: CodeSlot {
        switch self {
        case .outOfBounds: return Instruction.memoryOutOfBoundsTrapHeadSlot
        case .unalignedAtomic: return Instruction.unalignedAtomicTrapHeadSlot
        }
    }

    /// Raises this trap directly, for the token-threaded dispatcher.
    @inline(never)
    func raise() throws -> Never {
        switch self {
        case .outOfBounds: throw Trap(.memoryOutOfBounds)
        case .unalignedAtomic: throw Trap(.unalignedAtomic)
        }
    }
}

extension Execution {
    @inline(never) func throwOutOfBoundsMemoryAccess() throws -> Never {
        throw Trap(.memoryOutOfBounds)
    }
    @inline(never) func throwUnalignedAtomicAccess() throws -> Never {
        throw Trap(.unalignedAtomic)
    }

    /// Raises `Trap(.memoryOutOfBounds)`.
    ///
    /// A pseudo-instruction: the translator never emits it. The memory load/store and
    /// atomic handlers reach it by *returning its head slot* as the next instruction
    /// instead of throwing, which turns their trapping path into a tail call with no
    /// live state. Throwing out of those handlers would be a `bl` and would force a
    /// prologue/epilogue onto the fast path of every load and store.
    mutating func memoryOutOfBoundsTrap(sp: Sp) throws {
        try throwOutOfBoundsMemoryAccess()
    }

    /// Raises `Trap(.unalignedAtomic)`. A pseudo-instruction; see ``memoryOutOfBoundsTrap(sp:)``.
    mutating func unalignedAtomicTrap(sp: Sp) throws {
        try throwUnalignedAtomicAccess()
    }

    /// The linear-memory address of an access: the guest index plus the static offset,
    /// wrapping. ``isInBounds(address:offset:length:ms:)`` rejects a wrapped address.
    @inline(__always)
    static func memoryAddress(offset: UInt64, index: UInt64) -> UInt64 {
        index &+ offset
    }

    /// Whether `length` bytes at `address` lie inside the current memory, where `address`
    /// is `index &+ offset`.
    ///
    /// Three unsigned compares of already-computed values, which arm64 fuses into
    /// `cmp` + `ccmp` + `ccmp` + one conditional branch:
    ///
    /// - `remaining <= ms` rejects `address > ms`, i.e. a borrow out of `ms &- address`;
    ///   written first so that the subtraction itself sets the flags the chain starts from.
    /// - `address >= offset` rejects a wrapped `index &+ offset`. Only a 64-bit memory can
    ///   wrap (a 32-bit memory has a zero-extended 32-bit index and a 32-bit offset), and
    ///   a wrapped address is small, so without this a huge offset would read valid memory.
    /// - `remaining >= length` is the access-width check.
    ///
    /// Phrased in terms of `remaining` rather than `address + length <= ms` so that no
    /// step of the check can overflow and need a flag of its own.
    @inline(__always)
    static func isInBounds(address: UInt64, offset: UInt64, length: UInt64, ms: Ms) -> Bool {
        let ms = UInt64(ms)
        let remaining = ms &- address
        return remaining <= ms && address >= offset && remaining >= length
    }

    /// Whether `length` bytes at `address` lie inside the current memory, for a 32-bit
    /// memory.
    ///
    /// `address` is a zero-extended 32-bit guest index plus a `UInt32` offset, so it
    /// cannot have wrapped and the guard ``isInBounds(address:offset:length:ms:)`` needs
    /// is unnecessary here. Two compares: `subs` + `ccmp` + one conditional branch.
    @inline(__always)
    static func isInBounds32(address: UInt64, length: UInt64, ms: Ms) -> Bool {
        let ms = UInt64(ms)
        let remaining = ms &- address
        return remaining <= ms && remaining >= length
    }

    /// The byte offset from `md` to use for an access already checked by ``isInBounds``.
    ///
    /// Valid only after the check: `address <= ms`, which is the byte size of a live
    /// allocation and therefore fits in `Int`. Written without a trapping conversion so
    /// that no `brk` remains reachable from the fast path.
    @inline(__always)
    static func checkedByteOffset(_ address: UInt64) -> Int {
        Int(bitPattern: UInt(truncatingIfNeeded: address))
    }

    /// `[type].load[bitWidth]`
    ///
    /// Returns `nil` on success, or the trap to raise when the access is out of bounds.
    mutating func memoryLoad<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand, loadAs _: T.Type = T.self, castToValue: (T) -> UntypedValue
    ) -> MemoryAccessTrap? {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[loadOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: loadOperand.offset, index: i)
        if _slowPath(!Execution.isInBounds(address: address, offset: loadOperand.offset, length: length, ms: ms)) {
            return .outOfBounds
        }
        let loaded = md.unsafelyUnwrapped.loadUnaligned(fromByteOffset: Execution.checkedByteOffset(address), as: T.self)
        sp[loadOperand.result] = castToValue(loaded)
        return nil
    }

    /// `[type].load[bitWidth]` on a 32-bit memory whose static offset fits in `UInt32`.
    ///
    /// The index is an `i32`, whose slot is always zero-extended (see
    /// ``UntypedValue/asAddressOffset()``), so `index + offset` fits in 34 bits and the
    /// wrap guard that ``isInBounds(address:offset:length:ms:)`` needs is unnecessary
    /// here. Were that invariant ever broken the access would still be memory-safe: the
    /// bounds check is on the wrapped address, so it can only reach bytes of this memory.
    ///
    /// Returns `nil` on success, or the trap to raise when the access is out of bounds.
    mutating func memoryLoadNarrow<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, loadOperand: Instruction.LoadOperandNarrow, loadAs _: T.Type = T.self, castToValue: (T) -> UntypedValue
    ) -> MemoryAccessTrap? {
        let length = UInt64(T.bitWidth) / 8
        let address = sp[loadOperand.pointer].asAddressOffset() &+ UInt64(loadOperand.offset)
        if _slowPath(!Execution.isInBounds32(address: address, length: length, ms: ms)) {
            return .outOfBounds
        }
        let loaded = md.unsafelyUnwrapped.loadUnaligned(fromByteOffset: Execution.checkedByteOffset(address), as: T.self)
        sp[loadOperand.result] = castToValue(loaded)
        return nil
    }

    /// `[type].store[bitWidth]` on a 32-bit memory whose static offset fits in `UInt32`.
    /// See ``memoryLoadNarrow(sp:md:ms:loadOperand:loadAs:castToValue:)``.
    ///
    /// Returns `nil` on success, or the trap to raise when the access is out of bounds.
    mutating func memoryStoreNarrow<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, storeOperand: Instruction.StoreOperandNarrow, castFromValue: (UntypedValue) -> T
    ) -> MemoryAccessTrap? {
        let value = sp[storeOperand.value]
        let length = UInt64(T.bitWidth) / 8
        let address = sp[storeOperand.pointer].asAddressOffset() &+ UInt64(storeOperand.offset)
        if _slowPath(!Execution.isInBounds32(address: address, length: length, ms: ms)) {
            return .outOfBounds
        }
        let toStore = castFromValue(value)
        md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
            .bindMemory(to: T.self, capacity: 1).pointee = toStore.littleEndian
        return nil
    }

    /// `[type].store[bitWidth]`
    ///
    /// Returns `nil` on success, or the trap to raise when the access is out of bounds.
    mutating func memoryStore<T: FixedWidthInteger>(sp: Sp, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand, castFromValue: (UntypedValue) -> T) -> MemoryAccessTrap? {
        let value = sp[storeOperand.value]
        let length = UInt64(T.bitWidth) / 8
        let i = sp[storeOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: storeOperand.offset, index: i)
        if _slowPath(!Execution.isInBounds(address: address, offset: storeOperand.offset, length: length, ms: ms)) {
            return .outOfBounds
        }
        let toStore = castFromValue(value)
        md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
            .bindMemory(to: T.self, capacity: 1).pointee = toStore.littleEndian
        return nil
    }
    mutating func memorySize(sp: Sp, immediate: Instruction.MemorySizeOperand) {
        let memory = currentInstance(sp: sp).memories[Int(immediate.memoryIndex)]

        memory.withValue { memory in
            let pageCount = memory.byteCount / MemoryEntity.pageSize
            let value: Value = memory.limit.isMemory64 ? .i64(UInt64(pageCount)) : .i32(UInt32(pageCount))
            sp[immediate.result] = UntypedValue(value)
        }
    }

    mutating func memoryGrow(sp: Sp, md: inout Md, ms: inout Ms, immediate: Instruction.MemoryGrowOperand) throws {
        let memory = currentInstance(sp: sp).memories[Int(immediate.memory)]
        try memory.withValue { memory in
            let isMemory64 = memory.limit.isMemory64

            let value = sp[immediate.delta]
            let pageCount: UInt64 = isMemory64 ? value.i64 : UInt64(value.i32)
            let oldPageCount = try memory.grow(by: Int(pageCount), resourceLimiter: store.value.resourceLimiter)
            CurrentMemory.assign(md: &md, ms: &ms, memory: &memory)
            sp[immediate.result] = UntypedValue(oldPageCount)
        }
    }
    mutating func memoryInit(sp: Sp, immediate: Instruction.MemoryInitOperand) throws {
        let instance = currentInstance(sp: sp)
        let memory = instance.memories[0]
        try memory.withValue { memory in
            let segment = instance.dataSegments[Int(immediate.segmentIndex)]

            let size = sp[immediate.size].i32
            let source = sp[immediate.sourceOffset].i32
            let destination = sp[immediate.destOffset].asAddressOffset(memory.limit.isMemory64)
            try memory.initialize(segment, from: source, to: destination, count: size)
        }
    }
    mutating func memoryDataDrop(sp: Sp, immediate: Instruction.MemoryDataDropOperand) {
        let segment = currentInstance(sp: sp).dataSegments[Int(immediate.segmentIndex)]
        segment.withValue { $0.drop() }
    }
    mutating func memoryCopy(sp: Sp, immediate: Instruction.MemoryCopyOperand) throws {
        let memory = currentInstance(sp: sp).memories[0]
        try memory.withValue { memory in
            let isMemory64 = memory.limit.isMemory64
            let size = sp[immediate.size].asAddressOffset(isMemory64)
            let source = sp[immediate.sourceOffset].asAddressOffset(isMemory64)
            let destination = sp[immediate.destOffset].asAddressOffset(isMemory64)
            try memory.copy(from: source, to: destination, count: size)
        }
    }
    mutating func memoryFill(sp: Sp, immediate: Instruction.MemoryFillOperand) throws {
        let memory = currentInstance(sp: sp).memories[0]
        try memory.withValue { memoryInstance in
            let isMemory64 = memoryInstance.limit.isMemory64
            let copyCounter = Int(sp[immediate.size].asAddressOffset(isMemory64))
            let value = sp[immediate.value].i32
            let destinationIndex = Int(sp[immediate.destOffset].asAddressOffset(isMemory64))

            guard !destinationIndex.addingReportingOverflow(copyCounter).overflow else {
                throw Trap(.memoryOutOfBounds)
            }
            try memoryInstance.fill(offset: destinationIndex, value: UInt8(truncatingIfNeeded: value), count: copyCounter)
        }
    }

    // MARK: - Atomic Operations

    /// Atomic load operation
    ///
    /// Returns `nil` on success, or the trap to raise when the access is unaligned or
    /// out of bounds.
    mutating func atomicLoad<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand, loadAs _: T.Type = T.self, castToValue: (T) -> UntypedValue
    ) -> MemoryAccessTrap? {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[loadOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: loadOperand.offset, index: i)
        // Atomic operations must be naturally aligned
        if _slowPath(address % length != 0) {
            return .unalignedAtomic
        }
        if _slowPath(!Execution.isInBounds(address: address, offset: loadOperand.offset, length: length, ms: ms)) {
            return .outOfBounds
        }
        let rawPtr = md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
        let loaded: T
        switch T.bitWidth {
        case 8: loaded = T(wasmkit_atomic_load_8(rawPtr))
        case 16: loaded = T(wasmkit_atomic_load_16(rawPtr))
        case 32: loaded = T(wasmkit_atomic_load_32(rawPtr))
        case 64: loaded = T(wasmkit_atomic_load_64(rawPtr))
        default: fatalError()
        }
        sp[loadOperand.result] = castToValue(loaded)
        return nil
    }

    /// Atomic store operation
    ///
    /// Returns `nil` on success, or the trap to raise when the access is unaligned or
    /// out of bounds.
    mutating func atomicStore<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand, castFromValue: (UntypedValue) -> T
    ) -> MemoryAccessTrap? {
        let value = sp[storeOperand.value]
        let length = UInt64(T.bitWidth) / 8
        let i = sp[storeOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: storeOperand.offset, index: i)
        // Atomic operations must be naturally aligned
        if _slowPath(address % length != 0) {
            return .unalignedAtomic
        }
        if _slowPath(!Execution.isInBounds(address: address, offset: storeOperand.offset, length: length, ms: ms)) {
            return .outOfBounds
        }
        let toStore = castFromValue(value)
        let rawPtr = md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
        switch T.bitWidth {
        case 8: wasmkit_atomic_store_8(rawPtr, UInt8(truncatingIfNeeded: toStore))
        case 16: wasmkit_atomic_store_16(rawPtr, UInt16(truncatingIfNeeded: toStore))
        case 32: wasmkit_atomic_store_32(rawPtr, UInt32(truncatingIfNeeded: toStore))
        case 64: wasmkit_atomic_store_64(rawPtr, UInt64(truncatingIfNeeded: toStore))
        default: fatalError()
        }
        return nil
    }

    // MARK: - Atomic RMW Operations

    /// Atomic read-modify-write operation with RmwOperand
    ///
    /// Returns `nil` on success, or the trap to raise when the access is unaligned or
    /// out of bounds.
    mutating func atomicRmw<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, rmwOperand: Instruction.RmwOperand,
        loadAs _: T.Type = T.self,
        atomicOp: (UnsafeMutableRawPointer, T) -> T,
        castFromValue: (UntypedValue) -> T,
        castToValue: (T) -> UntypedValue
    ) -> MemoryAccessTrap? {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[rmwOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: rmwOperand.offset, index: i)
        // Atomic operations must be naturally aligned
        if _slowPath(address % length != 0) {
            return .unalignedAtomic
        }
        if _slowPath(!Execution.isInBounds(address: address, offset: rmwOperand.offset, length: length, ms: ms)) {
            return .outOfBounds
        }
        let rawPtr = md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
        let value = castFromValue(sp[rmwOperand.value])
        let oldValue = atomicOp(rawPtr, value)
        sp[rmwOperand.result] = castToValue(oldValue)
        return nil
    }

    /// Atomic compare-and-exchange operation with CmpxchgOperand
    ///
    /// Returns `nil` on success, or the trap to raise when the access is unaligned or
    /// out of bounds.
    mutating func atomicCmpxchg<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, cmpxchgOperand: Instruction.CmpxchgOperand,
        loadAs _: T.Type = T.self,
        atomicCmpxchg: (UnsafeMutableRawPointer, T, T) -> T,
        castFromValue: (UntypedValue) -> T,
        castToValue: (T) -> UntypedValue
    ) -> MemoryAccessTrap? {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[cmpxchgOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: cmpxchgOperand.offset, index: i)
        // Atomic operations must be naturally aligned
        if _slowPath(address % length != 0) {
            return .unalignedAtomic
        }
        if _slowPath(!Execution.isInBounds(address: address, offset: cmpxchgOperand.offset, length: length, ms: ms)) {
            return .outOfBounds
        }
        let rawPtr = md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
        let expectedValue = castFromValue(sp[cmpxchgOperand.expected])
        let replacementValue = castFromValue(sp[cmpxchgOperand.replacement])
        let resultValue = atomicCmpxchg(rawPtr, expectedValue, replacementValue)
        sp[cmpxchgOperand.result] = castToValue(resultValue)
        return nil
    }

    // MARK: - Atomic Wait/Notify

    /// The parking lot for `atomic.wait`/`notify` on the current default memory: the
    /// shared memory's own lot (shared by all importing threads) when shared.
    func atomicParkingLot(sp: Sp) -> AtomicParkingLot? {
        if let memory = currentInstance(sp: sp).memories.first,
            let lot = memory.withValue({ $0.sharedParkingLot })
        {
            return lot
        }
        return nil
    }

    /// Atomic wait32 - wait for a value to change at an address
    mutating func atomicWait32(sp: Sp, md: Md, ms: Ms, waitOperand: Instruction.AtomicWaitOperand) throws {
        let i = sp[waitOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: waitOperand.offset, index: i)
        // Atomic operations must be naturally aligned (4 bytes for i32)
        if address % 4 != 0 {
            try throwUnalignedAtomicAccess()
        }
        if _fastPath(Execution.isInBounds(address: address, offset: waitOperand.offset, length: 4, ms: ms)) {
            // `atomic.wait` is only valid on a shared memory.
            guard let parkingLot = atomicParkingLot(sp: sp) else {
                throw Trap(.message(.atomicWaitOnUnsharedMemory))
            }
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
            let currentValue = wasmkit_atomic_load_32(rawPtr)
            let expectedValue = sp[waitOperand.expected].i32

            // Check if value matches expected
            if currentValue != expectedValue {
                // Value doesn't match, return "not equal" (1)
                sp[waitOperand.result] = .i32(1)
                return
            }

            // Value matches - wait for notification or timeout.
            // Per the threads spec: timeout is a signed i64 in nanoseconds.
            //   timeout < 0: never expires (wait indefinitely)
            //   timeout >= 0: expires after `timeout` nanoseconds
            let timeout = sp[waitOperand.timeout].i64
            let timeoutSigned = Int64(bitPattern: timeout)
            let deadline: ParkingDeadline? =
                timeoutSigned < 0 ? nil : ParkingDeadline(afterNanoseconds: timeoutSigned)

            let result = parkingLot.parkConditionally(
                address: UInt64(address),
                validate: {
                    // Re-check the value atomically
                    let currentValue = wasmkit_atomic_load_32(rawPtr)
                    return currentValue == expectedValue
                },
                deadline: deadline
            )

            let resultValue: Int32
            switch result {
            case .woken: resultValue = 0
            case .mismatch: resultValue = 1
            case .timedOut: resultValue = 2
            }
            sp[waitOperand.result] = .i32(UInt32(bitPattern: resultValue))
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    /// Atomic wait64 - wait for a value to change at an address
    mutating func atomicWait64(sp: Sp, md: Md, ms: Ms, waitOperand: Instruction.AtomicWaitOperand) throws {
        let i = sp[waitOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: waitOperand.offset, index: i)
        // Atomic operations must be naturally aligned (8 bytes for i64)
        if address % 8 != 0 {
            try throwUnalignedAtomicAccess()
        }
        if _fastPath(Execution.isInBounds(address: address, offset: waitOperand.offset, length: 8, ms: ms)) {
            // `atomic.wait` is only valid on a shared memory.
            guard let parkingLot = atomicParkingLot(sp: sp) else {
                throw Trap(.message(.atomicWaitOnUnsharedMemory))
            }
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Execution.checkedByteOffset(address))
            let currentValue = wasmkit_atomic_load_64(rawPtr)
            let expectedValue = sp[waitOperand.expected].i64

            // Check if value matches expected
            if currentValue != expectedValue {
                // Value doesn't match, return "not equal" (1)
                sp[waitOperand.result] = .i32(1)
                return
            }

            // Value matches - wait for notification or timeout.
            // Per the threads spec: timeout is a signed i64 in nanoseconds.
            //   timeout < 0: never expires (wait indefinitely)
            //   timeout >= 0: expires after `timeout` nanoseconds
            let timeout = sp[waitOperand.timeout].i64
            let timeoutSigned = Int64(bitPattern: timeout)
            let deadline: ParkingDeadline? =
                timeoutSigned < 0 ? nil : ParkingDeadline(afterNanoseconds: timeoutSigned)

            let result = parkingLot.parkConditionally(
                address: UInt64(address),
                validate: {
                    // Re-check the value atomically
                    let currentValue = wasmkit_atomic_load_64(rawPtr)
                    return currentValue == expectedValue
                },
                deadline: deadline
            )

            let resultValue: Int32
            switch result {
            case .woken: resultValue = 0
            case .mismatch: resultValue = 1
            case .timedOut: resultValue = 2
            }
            sp[waitOperand.result] = .i32(UInt32(bitPattern: resultValue))
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    /// Atomic notify - notify waiting threads
    mutating func atomicNotify(sp: Sp, md: Md, ms: Ms, notifyOperand: Instruction.AtomicNotifyOperand) throws {
        let i = sp[notifyOperand.pointer].asAddressOffset()
        let address = Execution.memoryAddress(offset: notifyOperand.offset, index: i)
        if _fastPath(Execution.isInBounds(address: address, offset: notifyOperand.offset, length: 4, ms: ms)) {
            // A non-shared memory can have no waiters, so nothing is woken.
            guard let parkingLot = atomicParkingLot(sp: sp) else {
                sp[notifyOperand.result] = .i32(0)
                return
            }
            let count = sp[notifyOperand.count].i32
            let wokenCount = parkingLot.unpark(address: UInt64(address), count: UInt32(bitPattern: Int32(truncatingIfNeeded: count)))
            sp[notifyOperand.result] = .i32(wokenCount)
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    /// Atomic fence - sequential consistency barrier
    mutating func atomicFence(sp: Sp) {
        wasmkit_atomic_fence()
    }
}
