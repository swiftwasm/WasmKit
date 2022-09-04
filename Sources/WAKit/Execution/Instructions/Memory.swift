/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension InstructionFactory {
    func load(
        _ type: ValueType,
        bitWidth: Int? = nil,
        isSigned: Bool = true,
        _ offset: UInt32
    ) -> Instruction {
        // FIXME: handle `isSigned`
        return makeInstruction { pc, store, stack in
            let frame = try stack.get(current: Frame.self)
            let memoryAddress = frame.module.memoryAddresses[0]
            let memoryInstance = store.memories[memoryAddress]
            let i = try stack.pop(Value.self).i32
            let (incrementedOffset, isOverflow) = offset.addingReportingOverflow(i)
            guard !isOverflow else {
                throw Trap.outOfBoundsMemoryAccess
            }
            let address = Int(incrementedOffset)
            let length = (bitWidth ?? type.bitWidth) / 8
            guard memoryInstance.data.indices.contains(address + length) else {
                throw Trap.outOfBoundsMemoryAccess
            }

            let bytes = memoryInstance.data[address ..< address + length]
            let value = Value(bytes, type)

            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func store(_ type: ValueType, _ offset: UInt32) -> Instruction {
        return makeInstruction { pc, store, stack in
            let value = try stack.pop(Value.self)

            let frame = try stack.get(current: Frame.self)
            let memoryAddress = frame.module.memoryAddresses[0]
            let memoryInstance = store.memories[memoryAddress]
            let i = try stack.pop(Value.self).i32
            let address = Int(offset + i)
            let length = type.bitWidth / 8
            guard memoryInstance.data.indices.contains(address + length) else {
                throw Trap.outOfBoundsMemoryAccess
            }

            memoryInstance.data.replaceSubrange(address ..< address + length, with: value.bytes)
            return .jump(pc + 1)
        }
    }

    var memorySize: Instruction {
        return makeInstruction { _, _, _ in
            throw Trap.unimplemented()
        }
    }

    var memoryGrow: Instruction {
        return makeInstruction { _, _, _ in
            throw Trap.unimplemented()
        }
    }
}
