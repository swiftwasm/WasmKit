/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension ExecutionState {
    mutating func localGet(runtime: Runtime, index: LocalIndex) throws {
        let value = try stack.localGet(index: index)
        stack.push(value: value)
    }
    mutating func localSet(runtime: Runtime, index: LocalIndex) throws {
        let value = try stack.popValue()
        try stack.localSet(index: index, value: value)
    }
    mutating func localTee(runtime: Runtime, index: LocalIndex) throws {
        let value = stack.topValue
        try stack.localSet(index: index, value: value)
    }
    mutating func globalGet(runtime: Runtime, index: GlobalIndex) throws {
        let address = Int(currentModule(store: runtime.store).globalAddresses[Int(index)])
        let globals = runtime.store.globals

        guard globals.indices.contains(address) else {
            throw Trap.globalAddressOutOfRange(index: address)
        }
        let value = globals[address].value
        stack.push(value: value)
    }

    mutating func globalSet(runtime: Runtime, index: GlobalIndex) throws {
        let address = Int(currentModule(store: runtime.store).globalAddresses[Int(index)])
        try doGlobalSet(address: address, &runtime.store.globals)
    }
    mutating func doGlobalSet(address: GlobalAddress, _ globals: inout [GlobalInstance]) throws {
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
