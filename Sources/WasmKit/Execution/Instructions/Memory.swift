/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension Execution {
    @inline(never) func throwOutOfBoundsMemoryAccess() throws -> Never {
        throw Trap(.memoryOutOfBounds)
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

        let pageCount = memory.data.count / MemoryEntity.pageSize
        let value: Value = memory.limit.isMemory64 ? .i64(UInt64(pageCount)) : .i32(UInt32(pageCount))
        sp[immediate.result] = UntypedValue(value)
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

            guard
                !destinationIndex.addingReportingOverflow(copyCounter).overflow
                    && memoryInstance.data.count >= destinationIndex + copyCounter
            else {
                throw Trap(.memoryOutOfBounds)
            }

            memoryInstance.data.replaceSubrange(
                destinationIndex..<destinationIndex + copyCounter,
                with: [UInt8](repeating: value.littleEndianBytes[0], count: copyCounter)
            )
        }
    }
}
