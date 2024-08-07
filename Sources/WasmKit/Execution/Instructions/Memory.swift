/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension ExecutionState {
    typealias Memarg = Instruction.Memarg

    mutating func i32Load(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt32.self, castToValue: { .i32($0) })
    }
    mutating func i64Load(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt64.self, castToValue: { .i64($0) })
    }
    mutating func f32Load(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt32.self, castToValue: { .f32($0) })
    }
    mutating func f64Load(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt64.self, castToValue: { .f64($0) })
    }
    mutating func i32Load8S(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: Int8.self, castToValue: { .init(signed: Int32($0)) })
    }
    mutating func i32Load8U(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt8.self, castToValue: { .i32(UInt32($0)) })
    }
    mutating func i32Load16S(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: Int16.self, castToValue: { .init(signed: Int32($0)) })
    }
    mutating func i32Load16U(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt16.self, castToValue: { .i32(UInt32($0)) })
    }
    mutating func i64Load8S(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: Int8.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load8U(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt8.self, castToValue: { .i64(UInt64($0)) })
    }
    mutating func i64Load16S(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: Int16.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load16U(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt16.self, castToValue: { .i64(UInt64($0)) })
    }
    mutating func i64Load32S(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: Int32.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load32U(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, stack: &stack, memarg: memarg, loadAs: UInt32.self, castToValue: { .i64(UInt64($0)) })
    }

    @_transparent
    private mutating func memoryLoad<T: FixedWidthInteger>(
        runtime: Runtime, stack: inout Stack, memarg: Instruction.Memarg, loadAs _: T.Type = T.self, castToValue: (T) -> Value
    ) throws {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        let memoryInstance = store.memories[memoryAddress]
        let i = stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)
        let (address, isOverflow) = memarg.offset.addingReportingOverflow(i)
        guard !isOverflow else {
            throw Trap.outOfBoundsMemoryAccess
        }
        let length = UInt64(T.bitWidth) / 8
        let (endAddress, isEndOverflow) = address.addingReportingOverflow(length)
        guard !isEndOverflow, endAddress <= memoryInstance.data.count else {
            throw Trap.outOfBoundsMemoryAccess
        }

        let loaded = memoryInstance.data.withUnsafeBufferPointer { buffer in
            let rawBuffer = UnsafeRawBufferPointer(buffer)
            return rawBuffer.loadUnaligned(fromByteOffset: Int(address), as: T.self)
        }
        stack.push(value: castToValue(loaded))

    }

    mutating func i32Store(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { $0.i32 })
    }
    mutating func i64Store(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { $0.i64 })
    }
    mutating func f32Store(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { $0.f32 })
    }
    mutating func f64Store(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { $0.f64 })
    }
    mutating func i32Store8(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { UInt8(truncatingIfNeeded: $0.i32) })
    }
    mutating func i32Store16(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { UInt16(truncatingIfNeeded: $0.i32) })
    }
    mutating func i64Store8(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { UInt8(truncatingIfNeeded: $0.i64) })
    }
    mutating func i64Store16(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { UInt16(truncatingIfNeeded: $0.i64) })
    }
    mutating func i64Store32(runtime: Runtime, stack: inout Stack, memarg: Memarg) throws {
        try memoryStore(runtime: runtime, stack: &stack, memarg: memarg, castFromValue: { UInt32(truncatingIfNeeded: $0.i64) })
    }

    /// `[type].store[bitWidth]`
    @_transparent
    private mutating func memoryStore<T: FixedWidthInteger>(runtime: Runtime, stack: inout Stack, memarg: Instruction.Memarg, castFromValue: (Value) -> T) throws {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store

        let value = stack.popValue()

        let memoryAddress = moduleInstance.memoryAddresses[0]
        let address: UInt64
        let endAddress: UInt64
        let length: UInt64
        do {
            let memoryInstance = store.memories[memoryAddress]
            let i = stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)
            var isOverflow: Bool
            (address, isOverflow) = memarg.offset.addingReportingOverflow(i)
            guard !isOverflow else {
                throw Trap.outOfBoundsMemoryAccess
            }
            length = UInt64(T.bitWidth) / 8
            (endAddress, isOverflow) = address.addingReportingOverflow(length)
            guard !isOverflow, endAddress <= memoryInstance.data.count else {
                throw Trap.outOfBoundsMemoryAccess
            }
        }

        let toStore = castFromValue(value)
        store.memories[memoryAddress].data.withUnsafeMutableBufferPointer { buffer in
            let rawBuffer = UnsafeMutableRawBufferPointer(buffer)
            rawBuffer.baseAddress!.advanced(by: Int(address)).bindMemory(to: T.self, capacity: 1).pointee = toStore.littleEndian
        }
    }

    mutating func memorySize(runtime: Runtime, stack: inout Stack) {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]

        let memoryInstance = store.memories[memoryAddress]
        let pageCount = memoryInstance.data.count / MemoryInstance.pageSize
        stack.push(value: memoryInstance.limit.isMemory64 ? .i64(UInt64(pageCount)) : .i32(UInt32(pageCount)))
    }
    mutating func memoryGrow(runtime: Runtime, stack: inout Stack) throws {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        try store.withMemory(at: memoryAddress) { memoryInstance in
            let isMemory64 = memoryInstance.limit.isMemory64

            let value = stack.popValue()
            let pageCount: UInt64
            switch (isMemory64, value) {
            case let (true, .i64(value)):
                pageCount = value
            case let (false, .i32(value)):
                pageCount = UInt64(value)
            default:
                throw Trap.stackValueTypesMismatch(
                    expected: isMemory64 ? .i64 : .i32, actual: value.type
                )
            }
            let oldPageCount = memoryInstance.grow(by: Int(pageCount))
            stack.push(value: oldPageCount)
        }
    }
    mutating func memoryInit(runtime: Runtime, stack: inout Stack, dataIndex: DataIndex) throws {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        try store.withMemory(at: memoryAddress) { memoryInstance in
            let dataAddress = moduleInstance.dataAddresses[Int(dataIndex)]
            let dataInstance = store.datas[dataAddress]

            let copyCounter = stack.popValue().i32
            let sourceIndex = stack.popValue().i32
            let destinationIndex = stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)

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
                    dataInstance.data[Int(sourceIndex + i)]
            }
        }
    }
    mutating func memoryDataDrop(runtime: Runtime, stack: inout Stack, dataIndex: DataIndex) {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store
        let dataAddress = moduleInstance.dataAddresses[Int(dataIndex)]
        store.datas[dataAddress] = DataInstance(data: [])
    }
    mutating func memoryCopy(runtime: Runtime, stack: inout Stack) throws {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        try store.withMemory(at: memoryAddress) { memoryInstance in
            let isMemory64 = memoryInstance.limit.isMemory64
            let copyCounter = stack.popValue().asAddressOffset(isMemory64)
            let sourceIndex = stack.popValue().asAddressOffset(isMemory64)
            let destinationIndex = stack.popValue().asAddressOffset(isMemory64)

            guard copyCounter > 0 else { return }

            guard
                !sourceIndex.addingReportingOverflow(copyCounter).overflow
                    && !destinationIndex.addingReportingOverflow(copyCounter).overflow
                    && memoryInstance.data.count >= destinationIndex + copyCounter
                    && memoryInstance.data.count >= sourceIndex + copyCounter
            else {
                throw Trap.outOfBoundsMemoryAccess
            }

            if destinationIndex <= sourceIndex {
                for i in 0..<copyCounter {
                    memoryInstance.data[Int(destinationIndex + i)] = memoryInstance.data[Int(sourceIndex + i)]
                }
            } else {
                for i in 1...copyCounter {
                    memoryInstance.data[Int(destinationIndex + copyCounter - i)] = memoryInstance.data[Int(sourceIndex + copyCounter - i)]
                }
            }
        }
    }
    mutating func memoryFill(runtime: Runtime, stack: inout Stack) throws {
        let moduleInstance = currentModule(store: runtime.store, stack: &stack)
        let store = runtime.store
        let memoryAddress = moduleInstance.memoryAddresses[0]
        try store.withMemory(at: memoryAddress) { memoryInstance in
            let isMemory64 = memoryInstance.limit.isMemory64
            let copyCounter = Int(stack.popValue().asAddressOffset(isMemory64))
            let value = stack.popValue()
            let destinationIndex = Int(stack.popValue().asAddressOffset(isMemory64))

            guard
                !destinationIndex.addingReportingOverflow(copyCounter).overflow
                    && memoryInstance.data.count >= destinationIndex + copyCounter
            else {
                throw Trap.outOfBoundsMemoryAccess
            }

            memoryInstance.data.replaceSubrange(
                destinationIndex..<destinationIndex + copyCounter,
                with: [UInt8](repeating: value.bytes![0], count: copyCounter)
            )
        }
    }
}
