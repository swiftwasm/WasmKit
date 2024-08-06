/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension ExecutionState {
    mutating func i32Load(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt32.self, castToValue: { .i32($0) })
    }
    mutating func i64Load(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt64.self, castToValue: { .i64($0) })
    }
    mutating func f32Load(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt32.self, castToValue: { .f32($0) })
    }
    mutating func f64Load(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt64.self, castToValue: { .f64($0) })
    }
    mutating func i32Load8S(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: Int8.self, castToValue: { .init(signed: Int32($0)) })
    }
    mutating func i32Load8U(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt8.self, castToValue: { .i32(UInt32($0)) })
    }
    mutating func i32Load16S(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: Int16.self, castToValue: { .init(signed: Int32($0)) })
    }
    mutating func i32Load16U(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt16.self, castToValue: { .i32(UInt32($0)) })
    }
    mutating func i64Load8S(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: Int8.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load8U(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt8.self, castToValue: { .i64(UInt64($0)) })
    }
    mutating func i64Load16S(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: Int16.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load16U(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt16.self, castToValue: { .i64(UInt64($0)) })
    }
    mutating func i64Load32S(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: Int32.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load32U(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand) throws {
        try memoryLoad(stack: stack, md: md, ms: ms, loadOperand: loadOperand, loadAs: UInt32.self, castToValue: { .i64(UInt64($0)) })
    }

    @_transparent
    private mutating func memoryLoad<T: FixedWidthInteger>(
        stack: FrameBase, md: Md, ms: Ms, loadOperand: Instruction.LoadOperand, loadAs _: T.Type = T.self, castToValue: (T) -> UntypedValue
    ) throws {
        let memarg = loadOperand.memarg

        let length = UInt64(T.bitWidth) / 8
        let i = stack[loadOperand.pointer].asAddressOffset()
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length + memarg.offset)
        guard !isEndOverflow, endAddress <= ms else {
            // TODO(optimize): Swift-native exception leads code-bloating
            throw Trap.outOfBoundsMemoryAccess
        }
        let address = memarg.offset + i
        let loaded = UnsafeMutableRawBufferPointer(start: md, count: ms).loadUnaligned(fromByteOffset: Int(address), as: T.self)
        stack[loadOperand.result] = castToValue(loaded)

    }

    mutating func i32Store(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { $0.i32 })
    }
    mutating func i64Store(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { $0.i64 })
    }
    mutating func f32Store(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { $0.f32 })
    }
    mutating func f64Store(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { $0.f64 })
    }
    mutating func i32Store8(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { UInt8(truncatingIfNeeded: $0.i32) })
    }
    mutating func i32Store16(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { UInt16(truncatingIfNeeded: $0.i32) })
    }
    mutating func i64Store8(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { UInt8(truncatingIfNeeded: $0.i64) })
    }
    mutating func i64Store16(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { UInt16(truncatingIfNeeded: $0.i64) })
    }
    mutating func i64Store32(context: inout StackContext, stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand) throws {
        try memoryStore(stack: stack, md: md, ms: ms, storeOperand: storeOperand, castFromValue: { UInt32(truncatingIfNeeded: $0.i64) })
    }

    /// `[type].store[bitWidth]`
    @_transparent
    private mutating func memoryStore<T: FixedWidthInteger>(stack: FrameBase, md: Md, ms: Ms, storeOperand: Instruction.StoreOperand, castFromValue: (UntypedValue) -> T) throws {
        let memarg = storeOperand.memarg

        let value = stack[storeOperand.value]
        let length = UInt64(T.bitWidth) / 8
        let i = stack[storeOperand.pointer].asAddressOffset()
        let (endAddress, isEndOverflow) = i.addingReportingOverflow(length + memarg.offset)
        guard !isEndOverflow, endAddress <= ms else {
            // TODO(optimize): Swift-native exception leads code-bloating
            throw Trap.outOfBoundsMemoryAccess
        }
        let address = memarg.offset + i
        let toStore = castFromValue(value)
        md!.advanced(by: Int(address))
            .bindMemory(to: T.self, capacity: 1).pointee = toStore.littleEndian
    }

    mutating func memorySize(context: inout StackContext, stack: FrameBase, memorySizeOperand: Instruction.MemorySizeOperand) {
        let memory = context.currentInstance.memories[0]

        let pageCount = memory.data.count / MemoryEntity.pageSize
        let value: Value = memory.limit.isMemory64 ? .i64(UInt64(pageCount)) : .i32(UInt32(pageCount))
        stack[memorySizeOperand.result] = UntypedValue(value)
    }
    mutating func memoryGrow(context: inout StackContext, stack: FrameBase, md: inout Md, ms: inout Ms, memoryGrowOperand: Instruction.MemoryGrowOperand) throws {
        let memory = context.currentInstance.memories[0]
        memory.withValue { memory in
            let isMemory64 = memory.limit.isMemory64

            let value = stack[memoryGrowOperand.delta]
            let pageCount: UInt64 = isMemory64 ? value.i64 : UInt64(value.i32)
            let oldPageCount = memory.grow(by: Int(pageCount))
            stack[memoryGrowOperand.result] = UntypedValue(oldPageCount)
        }
        mayUpdateCurrentInstance(store: store, stack: context)
    }
    mutating func memoryInit(context: inout StackContext, stack: FrameBase, memoryInitOperand: Instruction.MemoryInitOperand) throws {
        let instance = context.currentInstance
        let memory = instance.memories[0]
        try memory.withValue { memoryInstance in
            let dataInstance = instance.dataSegments[Int(memoryInitOperand.segmentIndex)]

            let copyCounter = stack[memoryInitOperand.size].i32
            let sourceIndex = stack[memoryInitOperand.sourceOffset].i32
            let destinationIndex = stack[memoryInitOperand.destOffset].asAddressOffset(memoryInstance.limit.isMemory64)

            guard copyCounter > 0 else { return }

            guard
                !sourceIndex.addingReportingOverflow(copyCounter).overflow
                    && !destinationIndex.addingReportingOverflow(UInt64(copyCounter)).overflow
                    && memoryInstance.data.count >= destinationIndex + UInt64(copyCounter)
                    && dataInstance.data.count >= sourceIndex + copyCounter
            else {
                throw Trap.outOfBoundsMemoryAccess
            }

            // FIXME: benchmark if using `replaceSubrange` is faster than this loop
            for i in 0..<copyCounter {
                memoryInstance.data[Int(destinationIndex + UInt64(i))] =
                    dataInstance.data[dataInstance.data.startIndex + Int(sourceIndex + i)]
            }
        }
    }
    mutating func memoryDataDrop(context: inout StackContext, stack: FrameBase, dataIndex: DataIndex) {
        let segment = context.currentInstance.dataSegments[Int(dataIndex)]
        segment.withValue { $0.drop() }
    }
    mutating func memoryCopy(context: inout StackContext, stack: FrameBase, memoryCopyOperand: Instruction.MemoryCopyOperand) throws {
        let memory = context.currentInstance.memories[0]
        try memory.withValue { memory in
            let isMemory64 = memory.limit.isMemory64
            let copyCounter = stack[memoryCopyOperand.size].asAddressOffset(isMemory64)
            let sourceIndex = stack[memoryCopyOperand.sourceOffset].asAddressOffset(isMemory64)
            let destinationIndex = stack[memoryCopyOperand.destOffset].asAddressOffset(isMemory64)

            guard copyCounter > 0 else { return }

            guard
                !sourceIndex.addingReportingOverflow(copyCounter).overflow
                    && !destinationIndex.addingReportingOverflow(copyCounter).overflow
                    && memory.data.count >= destinationIndex + copyCounter
                    && memory.data.count >= sourceIndex + copyCounter
            else {
                throw Trap.outOfBoundsMemoryAccess
            }

            if destinationIndex <= sourceIndex {
                for i in 0..<copyCounter {
                    memory.data[Int(destinationIndex + i)] = memory.data[Int(sourceIndex + i)]
                }
            } else {
                for i in 1...copyCounter {
                    memory.data[Int(destinationIndex + copyCounter - i)] = memory.data[Int(sourceIndex + copyCounter - i)]
                }
            }
        }
    }
    mutating func memoryFill(context: inout StackContext, stack: FrameBase, memoryFillOperand: Instruction.MemoryFillOperand) throws {
        let memory = context.currentInstance.memories[0]
        try memory.withValue { memoryInstance in
            let isMemory64 = memoryInstance.limit.isMemory64
            let copyCounter = Int(stack[memoryFillOperand.size].asAddressOffset(isMemory64))
            let value = stack[memoryFillOperand.value].i32
            let destinationIndex = Int(stack[memoryFillOperand.destOffset].asAddressOffset(isMemory64))

            guard
                !destinationIndex.addingReportingOverflow(copyCounter).overflow
                    && memoryInstance.data.count >= destinationIndex + copyCounter
            else {
                throw Trap.outOfBoundsMemoryAccess
            }

            memoryInstance.data.replaceSubrange(
                destinationIndex..<destinationIndex + copyCounter,
                with: [UInt8](repeating: value.littleEndianBytes[0], count: copyCounter)
            )
        }
    }
}
