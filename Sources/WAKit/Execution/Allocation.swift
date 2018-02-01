extension Store {
    func allocate(function: Function, moduleInstance: ModuleInstance) -> FunctionAddress {
        let type = moduleInstance.types[Int(function.type)]
        let address = functions.count
        let instance = FunctionInstance(type: type, module: moduleInstance, code: function)
        functions.append(instance)
        return address
    }

    func allocate(tableType: TableType) -> TableAddress {
        let address = tables.count
        let instance = TableInstance(elements: [], max: tableType.limits.max)
        tables.append(instance)
        return address
    }

    func allocate(memoryType: MemoryType) -> MemoryAddress {
        let address = memories.count
        let instance = MemoryInstance(
            data: [UInt8](repeating: 0, count: 64 * 1024 * Int(memoryType.min)),
            max: memoryType.max
        )
        memories.append(instance)
        return address
    }

    func allocate(globalType: GlobalType, value: Value) -> GlobalAddress {
        assert(value.type == globalType.valueType)
        let address = globals.count
        let instance = GlobalInstance(value: value, mutability: globalType.mutability)
        globals.append(instance)
        return address
    }

    func allocate(module: Module, externalValues: [ExternalValue], values: [Value]) throws -> ModuleInstance {
        let instance = ModuleInstance()
        instance.types = module.types

        // 2.
        for function in module.functions {
            let address = allocate(function: function, moduleInstance: instance)
            instance.functionAddresses.append(address)
        }

        // 3.
        for table in module.tables {
            let address = allocate(tableType: table.type)
            instance.tableAddresses.append(address)
        }

        // 4.
        for memory in module.memories {
            let address = allocate(memoryType: memory.type)
            instance.memoryAddresses.append(address)
        }

        // 5.
        for (global, value) in zip(module.globals, values) {
            let address = allocate(globalType: global.type, value: value)
            instance.globalAddresses.append(address)
        }

        // 6. 7. 8. 9.
        var externalFunctions: [FunctionAddress] = []
        var externalTables: [TableAddress] = []
        var externalMemories: [MemoryAddress] = []
        var externalGlobals: [GlobalAddress] = []

        for ev in externalValues {
            switch ev {
            case let .function(address):
                externalFunctions.append(address)
            case let .table(address):
                externalTables.append(address)
            case let .memory(address):
                externalMemories.append(address)
            case let .global(address):
                externalGlobals.append(address)
            }
        }

        // 10. 11. 12. 13.
        instance.functionAddresses = externalFunctions + instance.functionAddresses
        instance.tableAddresses = externalTables + instance.tableAddresses
        instance.memoryAddresses = externalMemories + instance.memoryAddresses
        instance.globalAddresses = externalGlobals + instance.globalAddresses

        // 14. 15.
        for export in module.exports {
            let externalValue: ExternalValue
            switch export.descriptor {
            case let .function(i):
                externalValue = .function(instance.functionAddresses[Int(i)])
            case let .table(i):
                externalValue = .table(instance.tableAddresses[Int(i)])
            case let .memory(i):
                externalValue = .memory(instance.memoryAddresses[Int(i)])
            case let .global(i):
                externalValue = .global(instance.globalAddresses[Int(i)])
            }
            instance.exports.append(ExportInstance(name: export.name, value: externalValue))
        }

        return instance
    }
}
