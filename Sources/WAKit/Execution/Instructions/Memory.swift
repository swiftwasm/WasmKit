/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension InstructionFactory {
    func load<V: Value & ByteConvertible>(_ type: V.Type, _ offset: UInt32) -> Instruction {
        return makeInstruction { pc, store, stack in
            let frame = try stack.get(current: Frame.self)
            let memoryAddress = frame.module.memoryAddresses[0]
            let memoryInstance = store.memories[memoryAddress]
            let i = try stack.pop(I32.self).rawValue
            let address = Int(offset + i)
            let length = type.bitWidth / 8
            guard memoryInstance.data.indices.contains(address + length) else {
                throw Trap.memoryOverflow
            }

            let bytes = memoryInstance.data[address ..< address + length]
            let value = V(bytes)

            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func store<V: Value & ByteConvertible>(_ type: V.Type, _ offset: UInt32) -> Instruction {
        return makeInstruction { pc, store, stack in
            let value = try stack.pop(type)

            let frame = try stack.get(current: Frame.self)
            let memoryAddress = frame.module.memoryAddresses[0]
            let memoryInstance = store.memories[memoryAddress]
            let i = try stack.pop(I32.self).rawValue
            let address = Int(offset + i)
            let length = type.bitWidth / 8
            guard memoryInstance.data.indices.contains(address + length) else {
                throw Trap.memoryOverflow
            }

            memoryInstance.data.replaceSubrange(address ..< address + length, with: value.bytes())
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
