/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
enum VariableInstruction: Equatable {
    case localGet(index: LocalIndex)
    case localSet(index: LocalIndex)
    case localTee(index: LocalIndex)
    case globalGet(index: GlobalIndex)
    case globalSet(index: GlobalIndex)

    func execute(_ stack: inout Stack, _ globals: inout [GlobalInstance]) throws {
        switch self {
        case let .localGet(index):
            let value = try stack.currentFrame.localGet(index: index)
            stack.push(value: value)

        case let .localSet(index):
            let value = try stack.popValue()
            try stack.currentFrame.localSet(index: index, value: value)

        case let .localTee(index):
            let value = try stack.topValue
            try stack.currentFrame.localSet(index: index, value: value)

        case let .globalGet(index):
            let address = Int(stack.currentFrame.module.globalAddresses[Int(index)])

            guard globals.indices.contains(address) else {
                throw Trap.globalAddressOutOfRange(index: address)
            }
            let value = globals[address].value
            stack.push(value: value)

        case let .globalSet(index):
            let address = Int(stack.currentFrame.module.globalAddresses[Int(index)])
            let value = try stack.popValue()

            guard globals.indices.contains(address) else {
                throw Trap.globalAddressOutOfRange(index: address)
            }

            let mutability = globals[address].globalType.mutability
            guard mutability == .variable else {
                throw Trap.globalImmutable(index: address)
            }

            globals[address].value = value
        }
    }
}

extension VariableInstruction: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .globalGet(index: i):
            return "global.get \(i)"
        case let .globalSet(index: i):
            return "global.set \(i)"
        case let .localGet(index: i):
            return "local.get \(i)"
        case let .localSet(index: i):
            return "local.set \(i)"
        case let .localTee(index: i):
            return "local.tee \(i)"
        }
    }
}
