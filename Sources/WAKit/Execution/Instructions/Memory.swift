/// - Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#memory-instructions>
extension Runtime {
    func execute(memory instruction: MemoryInstruction) throws {
        switch instruction {
        case let .load(type, offset, _):
            switch type {
            case is I32.Type: try load(type: I32.self, offset: offset)
            case is I64.Type: try load(type: I64.self, offset: offset)
            case is F32.Type: try load(type: F32.self, offset: offset)
            case is F64.Type: try load(type: F64.self, offset: offset)
            default: throw Trap.invalidTypeForInstruction(type, instruction)
            }
        case let .store(type, offset, _):
            switch type {
            case is I32.Type: try store(type: I32.self, offset: offset)
            case is I64.Type: try store(type: I64.self, offset: offset)
            case is F32.Type: try store(type: F32.self, offset: offset)
            case is F64.Type: try store(type: F64.self, offset: offset)
            default: throw Trap.invalidTypeForInstruction(type, instruction)
            }
        default:
            throw Trap.unimplemented("\(instruction)")
        }
    }

    private func load<V: Value & ByteConvertible>(type: V.Type, offset: UInt32) throws {
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
        let value = V.init(bytes)

        stack.push(value)
    }

    private func store<V: Value & ByteConvertible>(type: V.Type, offset: UInt32) throws {
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
    }
}
