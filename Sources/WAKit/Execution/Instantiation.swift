enum InstantiationError: Error {
    case genericError
}

public final class Runtime {

    var stack = Stack()
    var store = Store()

	public init() {}

    // https://webassembly.github.io/spec/core/exec/modules.html#instantiation
    public func instantiate(module: Module, externalValues: [ExternalValue]) throws {
        // 1.
        // 2.
        // try module.validate()

        // 3.
        // module.imports.count == externalValues.count

        // 4.

        // 5.
        let globalAddresses: [GlobalAddress] = externalValues.flatMap {
            guard case let .global(address) = $0 else { return nil }
            return address
        }
        let importedModuleInstance = ModuleInstance()
        importedModuleInstance.globalAddresses = globalAddresses

        // 6.
        let frame = Frame(module: importedModuleInstance, locals: [])

        // 7.
        stack.push(.activation(frame))

        // 14.
        let moduleInstance = try store.allocate(module: module, externalValues: [], values: [])

        // 8.
        // 9.
        // 10.
        // 11.
        var dataOffsets: [Int] = []
        for data in module.data {
            try data.offset.execute(stack: &stack)
            guard case let .i32(dataOffset) = try stack.popValue(of: .i32) else {
                throw InstantiationError.genericError
            }
            dataOffsets.append(Int(dataOffset))
            let index = data.data
            let address = moduleInstance.memoryAddresses[Int(index)]
            let memoryInstance = store.memories[address]
            let dataEnd = Int(dataOffset) + data.initializer.count
            guard dataEnd <= memoryInstance.data.count else {
                throw InstantiationError.genericError
            }
        }

        // 12. 13.
        guard stack.pop() == .activation(frame) else {
            throw InstantiationError.genericError
        }

        // 15.
        for element in module.elements {
            for index in element.initializer {
                _ = moduleInstance.functionAddresses[Int(index)]
            }
        }

        // 16.
        for (i, data) in module.data.enumerated() {
            let memoryInstance = store.memories[i]
            let offset = dataOffsets[i]
            for (j, byte) in data.initializer.enumerated() {
                memoryInstance.data[offset + j] = byte
            }
        }

        // 17.
    }
}
