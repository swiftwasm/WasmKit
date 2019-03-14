/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#addresses>
public typealias FunctionAddress = Int
public typealias TableAddress = Int
public typealias MemoryAddress = Int
public typealias GlobalAddress = Int

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#store>
final class Store {
    var functions: [FunctionInstance] = []
    var tables: [TableInstance] = []
    var memories: [MemoryInstance] = []
    var globals: [GlobalInstance] = []
}

extension Store {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-module>
    func allocate(module: Module, externalValues: [ExternalValue]) -> ModuleInstance {
        let moduleInstance = ModuleInstance()

        moduleInstance.types = module.types

        for function in module.functions {
            let address = allocate(function: function, module: moduleInstance)
            moduleInstance.functionAddresses.append(address)
        }

        for table in module.tables {
            let address = allocate(tableType: table.type)
            moduleInstance.tableAddresses.append(address)
        }

        for memory in module.memories {
            let address = allocate(memoryType: memory.type)
            moduleInstance.memoryAddresses.append(address)
        }

        for global in module.globals {
            let address = allocate(globalType: global.type)
            moduleInstance.globalAddresses.append(address)
        }

        for external in externalValues {
            switch external {
            case let .function(address):
                moduleInstance.functionAddresses.append(address)
            case let .table(address):
                moduleInstance.tableAddresses.append(address)
            case let .memory(address):
                moduleInstance.memoryAddresses.append(address)
            case let .global(address):
                moduleInstance.globalAddresses.append(address)
            }
        }

        for export in module.exports {
            let exportInstance = ExportInstance(export, moduleInstance: moduleInstance)
            moduleInstance.exportInstances.append(exportInstance)
        }

        return moduleInstance
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-func>
    func allocate(function: Function, module: ModuleInstance) -> FunctionAddress {
        let address = functions.count
        let instance = FunctionInstance(function, module: module)
        functions.append(instance)
        return address
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-table>
    func allocate(tableType: TableType) -> TableAddress {
        let address = tables.count
        let instance = TableInstance(tableType)
        tables.append(instance)
        return address
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-mem>
    func allocate(memoryType: MemoryType) -> MemoryAddress {
        let address = memories.count
        let instance = MemoryInstance(memoryType)
        memories.append(instance)
        return address
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-global>
    func allocate(globalType: GlobalType) -> GlobalAddress {
        let address = globals.count
        let instance = GlobalInstance(globalType: globalType)
        globals.append(instance)
        return address
    }

    func initializeElements(stack _: Stack) throws {
        throw Trap.unimplemented("initializeElements")
    }

    func initializeData(stack _: Stack) throws {
        throw Trap.unimplemented("initializeData")
    }
}

extension Store {
    func getGlobal(index: UInt32) throws -> Value {
        guard globals.indices.contains(Int(index)) else {
            throw Trap.globalIndexOutOfRange(index: index)
        }
        return globals[Int(index)].value
    }

    func setGlobal(index: UInt32, value: Value) throws {
        guard globals.indices.contains(Int(index)) else {
            throw Trap.globalIndexOutOfRange(index: index)
        }
        let global = globals[Int(index)]
        guard global.mutability == .variable else {
            throw Trap.globalImmutable(index: index)
        }
        global.value = value
    }
}
