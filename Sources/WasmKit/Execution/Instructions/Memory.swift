/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension ExecutionState {
    typealias Memarg = Instruction.Memarg

    mutating func i32Load(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt32.self, castToValue: { .i32($0) })
    }
    mutating func i64Load(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt64.self, castToValue: { .i64($0) })
    }
    mutating func f32Load(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt32.self, castToValue: { .f32($0) })
    }
    mutating func f64Load(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt64.self, castToValue: { .f64($0) })
    }
    mutating func i32Load8S(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: Int8.self, castToValue: { .init(signed: Int32($0)) })
    }
    mutating func i32Load8U(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt8.self, castToValue: { .i32(UInt32($0)) })
    }
    mutating func i32Load16S(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: Int16.self, castToValue: { .init(signed: Int32($0)) })
    }
    mutating func i32Load16U(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt16.self, castToValue: { .i32(UInt32($0)) })
    }
    mutating func i64Load8S(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: Int8.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load8U(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt8.self, castToValue: { .i64(UInt64($0)) })
    }
    mutating func i64Load16S(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: Int16.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load16U(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt16.self, castToValue: { .i64(UInt64($0)) })
    }
    mutating func i64Load32S(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: Int32.self, castToValue: { .init(signed: Int64($0)) })
    }
    mutating func i64Load32U(runtime: Runtime, memarg: Memarg) throws {
        try memoryLoad(runtime: runtime, memarg: memarg, loadAs: UInt32.self, castToValue: { .i64(UInt64($0)) })
    }

    @_transparent
    private mutating func memoryLoad<T: FixedWidthInteger>(
        runtime: Runtime, memarg: Instruction.Memarg, loadAs _: T.Type = T.self, castToValue: (T) -> Value
    ) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        let memoryInstance = store.memories[memoryAddress]
        let i = try stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)
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
    /// `[type].store[bitWidth]`
    mutating func memoryStore(runtime: Runtime, memarg: Instruction.Memarg, bitWidth: UInt8, type: ValueType) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let value = try stack.popValue()

        let memoryAddress = moduleInstance.memoryAddresses[0]
        let address: UInt64
        let endAddress: UInt64
        let length: UInt64
        do {
            let memoryInstance = store.memories[memoryAddress]
            let i = try stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)
            var isOverflow: Bool
            (address, isOverflow) = memarg.offset.addingReportingOverflow(i)
            guard !isOverflow else {
                throw Trap.outOfBoundsMemoryAccess
            }
            length = UInt64(bitWidth) / 8
            (endAddress, isOverflow) = address.addingReportingOverflow(length)
            guard !isOverflow, endAddress <= memoryInstance.data.count else {
                throw Trap.outOfBoundsMemoryAccess
            }
        }

        @inline(__always)
        func memoryStore<T: FixedWidthInteger>(value: T) {
            let address = Int(address)
            store.memories[memoryAddress].data.withUnsafeMutableBufferPointer { buffer in
                let rawBuffer = UnsafeMutableRawBufferPointer(buffer)
                rawBuffer.baseAddress!.advanced(by: address).bindMemory(to: T.self, capacity: 1).pointee = value.littleEndian
            }
        }

        // TODO: Switch on those parameters at instruction dispatching time
        switch (value, bitWidth) {
        case (.i32(let v), 32):
            memoryStore(value: v)
        case (.i32(let v), 16):
            memoryStore(value: UInt16(truncatingIfNeeded: v))
        case (.i32(let v), 8):
            memoryStore(value: UInt8(truncatingIfNeeded: v))
        case (.i64(let v), 64):
            memoryStore(value: v)
        case (.i64(let v), 32):
            memoryStore(value: UInt32(truncatingIfNeeded: v))
        case (.i64(let v), 16):
            memoryStore(value: UInt16(truncatingIfNeeded: v))
        case (.i64(let v), 8):
            memoryStore(value: UInt8(truncatingIfNeeded: v))

        case (.f32(let v), 32):
            memoryStore(value: v)
        case (.f32(let v), 16):
            memoryStore(value: UInt16(truncatingIfNeeded: v))
        case (.f32(let v), 8):
            memoryStore(value: UInt8(truncatingIfNeeded: v))
        case (.f64(let v), 64):
            memoryStore(value: v)
        case (.f64(let v), 32):
            memoryStore(value: UInt32(truncatingIfNeeded: v))
        case (.f64(let v), 16):
            memoryStore(value: UInt16(truncatingIfNeeded: v))
        case (.f64(let v), 8):
            memoryStore(value: UInt8(truncatingIfNeeded: v))
        default:
            fatalError("unexpected value and bitWidth combination. value: \(value), bitWidth: \(bitWidth)")
        }
    }

    mutating func memorySize(runtime: Runtime) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]

        let memoryInstance = store.memories[memoryAddress]
        let pageCount = memoryInstance.data.count / MemoryInstance.pageSize
        stack.push(value: memoryInstance.limit.isMemory64 ? .i64(UInt64(pageCount)) : .i32(UInt32(pageCount)))
    }
    mutating func memoryGrow(runtime: Runtime) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        let isMemory64 = store.memories[memoryAddress].limit.isMemory64

        let value = try stack.popValue()
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
        let oldPageCount = store.memories[memoryAddress].grow(by: Int(pageCount))
        stack.push(value: oldPageCount)
    }
    mutating func memoryInit(runtime: Runtime, dataIndex: DataIndex) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]
        let dataAddress = moduleInstance.dataAddresses[Int(dataIndex)]
        let dataInstance = store.datas[dataAddress]
        let memoryInstance = store.memories[memoryAddress]

        let copyCounter = try stack.popValue().i32
        let sourceIndex = try stack.popValue().i32
        let destinationIndex = try stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)

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
            store.memories[memoryAddress].data[Int(destinationIndex + UInt64(i))] =
                dataInstance.data[Int(sourceIndex + i)]
        }
    }
    mutating func memoryDataDrop(runtime: Runtime, dataIndex: DataIndex) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store
        let dataAddress = moduleInstance.dataAddresses[Int(dataIndex)]
        store.datas[dataAddress] = DataInstance(data: [])
    }
    mutating func memoryCopy(runtime: Runtime) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]

        let copyCounter = try stack.popValue().i32
        let sourceIndex = try stack.popValue().i32
        let destinationIndex = try stack.popValue().i32

        guard copyCounter > 0 else { return }

        guard
            !sourceIndex.addingReportingOverflow(copyCounter).overflow
                && !destinationIndex.addingReportingOverflow(copyCounter).overflow
                && store.memories[memoryAddress].data.count >= destinationIndex + copyCounter
                && store.memories[memoryAddress].data.count >= sourceIndex + copyCounter
        else {
            throw Trap.outOfBoundsMemoryAccess
        }

        if destinationIndex <= sourceIndex {
            for i in 0..<copyCounter {
                store.memories[memoryAddress].data[Int(destinationIndex + i)] =
                    store.memories[memoryAddress].data[Int(sourceIndex + i)]
            }
        } else {
            for i in 1...copyCounter {
                store.memories[memoryAddress].data[Int(destinationIndex + copyCounter - i)] =
                    store.memories[memoryAddress].data[Int(sourceIndex + copyCounter - i)]
            }
        }
    }
    mutating func memoryFill(runtime: Runtime) throws {
        let moduleInstance = currentModule(store: runtime.store)
        let store = runtime.store

        let memoryAddress = moduleInstance.memoryAddresses[0]

        let copyCounter = try Int(stack.popValue().i32)
        let value = try stack.popValue()
        let destinationIndex = try Int(stack.popValue().i32)

        guard
            !destinationIndex.addingReportingOverflow(copyCounter).overflow
                && store.memories[memoryAddress].data.count >= destinationIndex + copyCounter
        else {
            throw Trap.outOfBoundsMemoryAccess
        }

        store.memories[memoryAddress].data.replaceSubrange(
            destinationIndex..<destinationIndex + copyCounter,
            with: [UInt8](repeating: value.bytes![0], count: copyCounter)
        )
    }
}
