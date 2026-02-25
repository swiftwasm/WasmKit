import WasmParser
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
import _CWasmKit

enum AtomicRmwOp { case add, sub, and, or, xor, xchg }

extension Execution {
    @inline(never) func throwOutOfBoundsMemoryAccess() throws -> Never {
        throw Trap(.memoryOutOfBounds)
    }
    @inline(never) func throwUnalignedAtomicAccess() throws -> Never {
        throw Trap(.unalignedAtomic)
    }
    mutating func memoryLoad<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand, loadAs _: T.Type = T.self, castToValue: (T) -> UntypedValue
    ) throws {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[loadOperand.pointer].asAddressOffset()
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length &+ loadOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let address = loadOperand.offset + i
            let loaded = md.unsafelyUnwrapped.loadUnaligned(fromByteOffset: Int(address), as: T.self)
            sp[loadOperand.result] = castToValue(loaded)
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    /// `[type].store[bitWidth]`
    mutating func memoryStore<T: FixedWidthInteger>(sp: Sp, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand, castFromValue: (UntypedValue) -> T) throws {
        let value = sp[storeOperand.value]
        let length = UInt64(T.bitWidth) / 8
        let i = sp[storeOperand.pointer].asAddressOffset()
        let address = storeOperand.offset + i
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length &+ storeOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let toStore = castFromValue(value)
            md.unsafelyUnwrapped.advanced(by: Int(address))
                .bindMemory(to: T.self, capacity: 1).pointee = toStore.littleEndian
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
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
            try memoryInstance.fill(offset: destinationIndex, value: value.littleEndianBytes[0], count: copyCounter)
        }
    }

    // MARK: - Atomic Operations

    /// Atomic load operation
    mutating func atomicLoad<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand, loadAs _: T.Type = T.self, castToValue: (T) -> UntypedValue
    ) throws {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[loadOperand.pointer].asAddressOffset()
        let address = loadOperand.offset + i
        // Atomic operations must be naturally aligned
        if address % length != 0 {
            try throwUnalignedAtomicAccess()
        }
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length &+ loadOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Int(address))
            let loaded: T
            switch T.bitWidth {
            case 8: loaded = T(wasmkit_atomic_load_8(rawPtr))
            case 16: loaded = T(wasmkit_atomic_load_16(rawPtr))
            case 32: loaded = T(wasmkit_atomic_load_32(rawPtr))
            case 64: loaded = T(wasmkit_atomic_load_64(rawPtr))
            default: fatalError()
            }
            sp[loadOperand.result] = castToValue(loaded)
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    /// Atomic store operation
    mutating func atomicStore<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand, castFromValue: (UntypedValue) -> T
    ) throws {
        let value = sp[storeOperand.value]
        let length = UInt64(T.bitWidth) / 8
        let i = sp[storeOperand.pointer].asAddressOffset()
        let address = storeOperand.offset + i
        // Atomic operations must be naturally aligned
        if address % length != 0 {
            try throwUnalignedAtomicAccess()
        }
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length &+ storeOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let toStore = castFromValue(value)
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Int(address))
            switch T.bitWidth {
            case 8: wasmkit_atomic_store_8(rawPtr, UInt8(truncatingIfNeeded: toStore))
            case 16: wasmkit_atomic_store_16(rawPtr, UInt16(truncatingIfNeeded: toStore))
            case 32: wasmkit_atomic_store_32(rawPtr, UInt32(truncatingIfNeeded: toStore))
            case 64: wasmkit_atomic_store_64(rawPtr, UInt64(truncatingIfNeeded: toStore))
            default: fatalError()
            }
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    // MARK: - Atomic RMW Operations

    /// Atomic read-modify-write operation with RmwOperand
    mutating func atomicRmw<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, rmwOperand: Instruction.RmwOperand,
        loadAs _: T.Type = T.self,
        op: AtomicRmwOp,
        castFromValue: (UntypedValue) -> T,
        castToValue: (T) -> UntypedValue
    ) throws {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[rmwOperand.pointer].asAddressOffset()
        let address = rmwOperand.offset + i
        // Atomic operations must be naturally aligned
        if address % length != 0 {
            try throwUnalignedAtomicAccess()
        }
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length &+ rmwOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Int(address))
            let value = castFromValue(sp[rmwOperand.value])
            let oldValue: T
            switch (T.bitWidth, op) {
            case (8, .add): oldValue = T(wasmkit_atomic_rmw_add_8(rawPtr, UInt8(truncatingIfNeeded: value)))
            case (8, .sub): oldValue = T(wasmkit_atomic_rmw_sub_8(rawPtr, UInt8(truncatingIfNeeded: value)))
            case (8, .and): oldValue = T(wasmkit_atomic_rmw_and_8(rawPtr, UInt8(truncatingIfNeeded: value)))
            case (8, .or): oldValue = T(wasmkit_atomic_rmw_or_8(rawPtr, UInt8(truncatingIfNeeded: value)))
            case (8, .xor): oldValue = T(wasmkit_atomic_rmw_xor_8(rawPtr, UInt8(truncatingIfNeeded: value)))
            case (8, .xchg): oldValue = T(wasmkit_atomic_rmw_xchg_8(rawPtr, UInt8(truncatingIfNeeded: value)))
            case (16, .add): oldValue = T(wasmkit_atomic_rmw_add_16(rawPtr, UInt16(truncatingIfNeeded: value)))
            case (16, .sub): oldValue = T(wasmkit_atomic_rmw_sub_16(rawPtr, UInt16(truncatingIfNeeded: value)))
            case (16, .and): oldValue = T(wasmkit_atomic_rmw_and_16(rawPtr, UInt16(truncatingIfNeeded: value)))
            case (16, .or): oldValue = T(wasmkit_atomic_rmw_or_16(rawPtr, UInt16(truncatingIfNeeded: value)))
            case (16, .xor): oldValue = T(wasmkit_atomic_rmw_xor_16(rawPtr, UInt16(truncatingIfNeeded: value)))
            case (16, .xchg): oldValue = T(wasmkit_atomic_rmw_xchg_16(rawPtr, UInt16(truncatingIfNeeded: value)))
            case (32, .add): oldValue = T(wasmkit_atomic_rmw_add_32(rawPtr, UInt32(truncatingIfNeeded: value)))
            case (32, .sub): oldValue = T(wasmkit_atomic_rmw_sub_32(rawPtr, UInt32(truncatingIfNeeded: value)))
            case (32, .and): oldValue = T(wasmkit_atomic_rmw_and_32(rawPtr, UInt32(truncatingIfNeeded: value)))
            case (32, .or): oldValue = T(wasmkit_atomic_rmw_or_32(rawPtr, UInt32(truncatingIfNeeded: value)))
            case (32, .xor): oldValue = T(wasmkit_atomic_rmw_xor_32(rawPtr, UInt32(truncatingIfNeeded: value)))
            case (32, .xchg): oldValue = T(wasmkit_atomic_rmw_xchg_32(rawPtr, UInt32(truncatingIfNeeded: value)))
            case (64, .add): oldValue = T(wasmkit_atomic_rmw_add_64(rawPtr, UInt64(truncatingIfNeeded: value)))
            case (64, .sub): oldValue = T(wasmkit_atomic_rmw_sub_64(rawPtr, UInt64(truncatingIfNeeded: value)))
            case (64, .and): oldValue = T(wasmkit_atomic_rmw_and_64(rawPtr, UInt64(truncatingIfNeeded: value)))
            case (64, .or): oldValue = T(wasmkit_atomic_rmw_or_64(rawPtr, UInt64(truncatingIfNeeded: value)))
            case (64, .xor): oldValue = T(wasmkit_atomic_rmw_xor_64(rawPtr, UInt64(truncatingIfNeeded: value)))
            case (64, .xchg): oldValue = T(wasmkit_atomic_rmw_xchg_64(rawPtr, UInt64(truncatingIfNeeded: value)))
            default: fatalError()
            }
            sp[rmwOperand.result] = castToValue(oldValue)
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    /// Atomic compare-and-exchange operation with CmpxchgOperand
    mutating func atomicCmpxchg<T: FixedWidthInteger>(
        sp: Sp, md: Md, ms: Ms, cmpxchgOperand: Instruction.CmpxchgOperand,
        loadAs _: T.Type = T.self,
        castFromValue: (UntypedValue) -> T,
        castToValue: (T) -> UntypedValue
    ) throws {
        let length = UInt64(T.bitWidth) / 8
        let i = sp[cmpxchgOperand.pointer].asAddressOffset()
        let address = cmpxchgOperand.offset + i
        // Atomic operations must be naturally aligned
        if address % length != 0 {
            try throwUnalignedAtomicAccess()
        }
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length &+ cmpxchgOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Int(address))
            let expectedValue = castFromValue(sp[cmpxchgOperand.expected])
            let replacementValue = castFromValue(sp[cmpxchgOperand.replacement])
            // After the CAS call, `expected` holds the old value from memory
            // (unchanged on success, updated to actual value on failure).
            let resultValue: T
            switch T.bitWidth {
            case 8:
                var expected = UInt8(truncatingIfNeeded: expectedValue)
                _ = wasmkit_atomic_cmpxchg_8(rawPtr, &expected, UInt8(truncatingIfNeeded: replacementValue))
                resultValue = T(expected)
            case 16:
                var expected = UInt16(truncatingIfNeeded: expectedValue)
                _ = wasmkit_atomic_cmpxchg_16(rawPtr, &expected, UInt16(truncatingIfNeeded: replacementValue))
                resultValue = T(expected)
            case 32:
                var expected = UInt32(truncatingIfNeeded: expectedValue)
                _ = wasmkit_atomic_cmpxchg_32(rawPtr, &expected, UInt32(truncatingIfNeeded: replacementValue))
                resultValue = T(expected)
            case 64:
                var expected = UInt64(truncatingIfNeeded: expectedValue)
                _ = wasmkit_atomic_cmpxchg_64(rawPtr, &expected, UInt64(truncatingIfNeeded: replacementValue))
                resultValue = T(expected)
            default: fatalError()
            }
            sp[cmpxchgOperand.result] = castToValue(resultValue)
        } else {
            try throwOutOfBoundsMemoryAccess()
        }
    }

    // MARK: - Atomic Wait/Notify

    /// Atomic wait32 - wait for a value to change at an address
    mutating func atomicWait32(sp: Sp, md: Md, ms: Ms, waitOperand: Instruction.AtomicWaitOperand) throws {
        let i = sp[waitOperand.pointer].asAddressOffset()
        let address = waitOperand.offset + i
        // Atomic operations must be naturally aligned (4 bytes for i32)
        if address % 4 != 0 {
            try throwUnalignedAtomicAccess()
        }
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(4 &+ waitOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Int(address))
            let currentValue = wasmkit_atomic_load_32(rawPtr)
            let expectedValue = sp[waitOperand.expected].i32
            let timeout = sp[waitOperand.timeout].i64

            // Check if value matches expected
            if currentValue != expectedValue {
                // Value doesn't match, return "not equal" (1)
                sp[waitOperand.result] = .i32(1)
                return
            }

            // Value matches - wait for notification or timeout
            let parkingLot = store.value.atomicParkingLot
            let deadline: (() -> ContinuousClock.Instant)?
            if timeout == 0 {
                // Timeout of 0 means wait indefinitely
                deadline = nil
            } else {
                // Convert nanoseconds to Duration and calculate deadline
                let timeoutDuration = Duration.nanoseconds(Int64(timeout))
                let deadlineInstant = ContinuousClock.now.advanced(by: timeoutDuration)
                deadline = { deadlineInstant }
            }

            var threadState = ThreadWaitState()
            let result = parkingLot.parkConditionally(
                address: UInt64(address),
                validate: {
                    // Re-check the value atomically
                    let currentValue = wasmkit_atomic_load_32(rawPtr)
                    return currentValue == expectedValue
                },
                deadline: deadline,
                threadState: &threadState
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
        let address = waitOperand.offset + i
        // Atomic operations must be naturally aligned (8 bytes for i64)
        if address % 8 != 0 {
            try throwUnalignedAtomicAccess()
        }
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(8 &+ waitOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let rawPtr = md.unsafelyUnwrapped.advanced(by: Int(address))
            let currentValue = wasmkit_atomic_load_64(rawPtr)
            let expectedValue = sp[waitOperand.expected].i64
            let timeout = sp[waitOperand.timeout].i64

            // Check if value matches expected
            if currentValue != expectedValue {
                // Value doesn't match, return "not equal" (1)
                sp[waitOperand.result] = .i32(1)
                return
            }

            // Value matches - wait for notification or timeout
            let parkingLot = store.value.atomicParkingLot
            let deadline: (() -> ContinuousClock.Instant)?
            if timeout == 0 {
                // Timeout of 0 means wait indefinitely
                deadline = nil
            } else {
                // Convert nanoseconds to Duration and calculate deadline
                let timeoutDuration = Duration.nanoseconds(Int64(timeout))
                let deadlineInstant = ContinuousClock.now.advanced(by: timeoutDuration)
                deadline = { deadlineInstant }
            }

            var threadState = ThreadWaitState()
            let result = parkingLot.parkConditionally(
                address: UInt64(address),
                validate: {
                    // Re-check the value atomically
                    let currentValue = wasmkit_atomic_load_64(rawPtr)
                    return currentValue == expectedValue
                },
                deadline: deadline,
                threadState: &threadState
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
        let address = notifyOperand.offset + i
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(4 &+ notifyOperand.offset)
        if _fastPath(!isEndOverflow && endAddress <= ms) {
            let count = sp[notifyOperand.count].i32
            let parkingLot = store.value.atomicParkingLot
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
