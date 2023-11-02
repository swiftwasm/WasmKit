/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
enum MemoryInstruction: Equatable {
    struct Memarg: Equatable {
        let offset: UInt64
        let align: UInt32
    }

    case load(
        _ memarg: Memarg,
        bitWidth: UInt8,
        _ type: NumericType,
        isSigned: Bool = true
    )
    case store(_ memarg: Memarg, bitWidth: UInt8, _ type: ValueType)
    case size
    case grow
    case `init`(DataIndex)
    case dataDrop(DataIndex)
    case copy
    case fill

    func execute(_ stack: inout Stack, _ store: Store) throws {
        let moduleInstance = stack.currentFrame.module

        switch self {
        case let .load(memarg, bitWidth, type, isSigned):
            let memoryAddress = moduleInstance.memoryAddresses[0]
            let memoryInstance = store.memories[memoryAddress]
            let i = try stack.popValue().asAddressOffset(memoryInstance.limit.isMemory64)
            let (address, isOverflow) = memarg.offset.addingReportingOverflow(i)
            guard !isOverflow else {
                throw Trap.outOfBoundsMemoryAccess
            }
            let length = UInt64(bitWidth) / 8
            let (endAddress, isEndOverflow) = address.addingReportingOverflow(length)
            guard !isEndOverflow, endAddress <= memoryInstance.data.count else {
                throw Trap.outOfBoundsMemoryAccess
            }

            let bytes = memoryInstance.data[Int(address)..<Int(endAddress)]

            stack.push(value: Value(bytes, .numeric(type), isSigned: isSigned)!)

        case let .store(memarg, bitWidth, _):
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

            // NOTE: Swift.Array can't allocate 2^64-1 bytes, so we actually support 2^63-1 bytes at most
            store.memories[memoryAddress].data
                .replaceSubrange(Int(address)..<Int(endAddress), with: value.bytes![0..<Int(length)])

        case .size:
            let memoryAddress = moduleInstance.memoryAddresses[0]

            let memoryInstance = store.memories[memoryAddress]
            let pageCount = memoryInstance.data.count / MemoryInstance.pageSize
            stack.push(value: memoryInstance.limit.isMemory64 ? .i64(UInt64(pageCount)) : .i32(UInt32(pageCount)))

        case .grow:
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

        case let .`init`(dataIndex):
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

        case let .dataDrop(dataIndex):
            let dataAddress = moduleInstance.dataAddresses[Int(dataIndex)]
            store.datas[dataAddress] = DataInstance(data: [])

        case .fill:
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

        case .copy:
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
    }
}
