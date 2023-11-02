/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#addresses>
public typealias FunctionAddress = Int
public typealias TableAddress = Int
public typealias MemoryAddress = Int
public typealias GlobalAddress = Int
public typealias ElementAddress = Int
public typealias DataAddress = Int
public typealias ExternAddress = Int

/// A collection of globals and functions that are exported from a host module.
public struct HostModule {
    public init(globals: [String: GlobalInstance] = [:], functions: [String: HostFunction] = [:]) {
        self.globals = globals
        self.functions = functions
    }

    /// Names of globals exported by this module mapped to corresponding global instances.
    public let globals: [String: GlobalInstance]

    /// Names of functions exported by this module mapped to corresponding host functions.
    public let functions: [String: HostFunction]
}

/// A container to manage WebAssembly object space.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#store>
public final class Store {
    private var hostFunctions: [HostFunction] = []
    private var hostGlobals: [GlobalInstance] = []
    var nameRegistry = NameRegistry()

    public internal(set) var namedModuleInstances: [String: ModuleInstance] = [:]

    /// This property is separate from `registeredModuleInstances`, as host exports
    /// won't have a corresponding module instance.
    fileprivate var availableExports: [String: ModuleInstance.Exports] = [:]

    var functions: [FunctionInstance] = []
    var tables: [TableInstance] = []
    var memories: [MemoryInstance] = []
    var globals: [GlobalInstance] = []
    var elements: [ElementInstance] = []
    var datas: [DataInstance] = []

    init(_ hostModules: [String: HostModule]) {
        for (moduleName, hostModule) in hostModules {
            var moduleExports = ModuleInstance.Exports()

            for (globalName, global) in hostModule.globals {
                moduleExports[globalName] = .global(-hostGlobals.count - 1)
                hostGlobals.append(global)
            }

            for (functionName, function) in hostModule.functions {
                moduleExports[functionName] = .function(-hostFunctions.count - 1)
                hostFunctions.append(function)
            }

            availableExports[moduleName] = moduleExports
        }
    }
}

/// A caller context passed to host functions
public struct Caller {
    public let store: Store
    public let instance: ModuleInstance
}

/// A host-defined function which can be imported by a WebAssembly module instance.
///
/// ## Examples
///
/// This example section shows how to interact with WebAssembly process with ``HostFunction``.
///
/// ### Print Int32 given by WebAssembly process
///
/// ```swift
/// HostFunction(type: FunctionType(parameters: [.i32])) { _, args in
///     print(args[0])
///     return []
/// }
/// ```
///
/// ### Print a UTF-8 string passed by a WebAssembly module instance
///
/// ```swift
/// HostFunction(type: FunctionType(parameters: [.i32, .i32])) { caller, args in
///     let (stringPtr, stringLength) = (Int(args[0].i32), Int(args[1].i32))
///     guard case let .memory(memoryAddr) = caller.instance.exports["memory"] else {
///         fatalError("Missing \"memory\" export")
///     }
///     let bytesRange = stringPtr..<(stringPtr + stringLength)
///     let bytes = caller.store.memory(at: memoryAddr).data[bytesRange]
///     print(String(decoding: bytes, as: UTF8.self))
///     return []
/// }
/// ```
public struct HostFunction {
    public init(type: FunctionType, implementation: @escaping (Caller, [Value]) throws -> [Value]) {
        self.type = type
        self.implementation = implementation
    }

    public let type: FunctionType
    public let implementation: (Caller, [Value]) throws -> [Value]
}

enum StoreFunction {
    case wasm(FunctionInstance, body: Expression)
    case host(HostFunction)
}

extension Store {
    public func register(_ moduleInstance: ModuleInstance, as name: String) throws {
        guard availableExports[name] == nil else {
            throw ImportError.moduleInstanceAlreadyRegistered(name)
        }

        availableExports[name] = moduleInstance.exports
    }

    public func memory(at address: MemoryAddress) -> MemoryInstance {
        return self.memories[address]
    }

    public func withMemory<T>(at address: MemoryAddress, _ body: (inout MemoryInstance) throws -> T) rethrows -> T {
        try body(&self.memories[address])
    }

    func function(at address: FunctionAddress) throws -> StoreFunction {
        if address < 0 {
            return .host(hostFunctions[-address - 1])
        } else {
            let body = try functions[address].code.body
            return .wasm(functions[address], body: body)
        }
    }

    func getExternalValues(_ module: Module) throws -> [ExternalValue] {
        var result = [ExternalValue]()

        for i in module.imports {
            guard let moduleExports = availableExports[i.module], let external = moduleExports[i.name] else {
                throw ImportError.unknownImport(moduleName: i.module, externalName: i.name)
            }

            switch (i.descriptor, external) {
            case let (.function(typeIndex), .function(functionAddress)):
                let type: FunctionType
                switch try function(at: functionAddress) {
                case let .host(function):
                    type = function.type

                case let .wasm(function, _):
                    type = function.type
                }

                guard module.types[Int(typeIndex)] == type else {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.table(tableType), .table(tableAddress)):
                if let max = tables[Int(tableAddress)].max, max < tableType.limits.min {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.memory(memoryType), .memory(memoryAddress)):
                if let max = memories[Int(memoryAddress)].limit.max, max < memoryType.min {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.global(globalType), .global(globalAddress))
            where globalType == globals[globalAddress].globalType:
                result.append(external)

            default:
                throw ImportError.incompatibleImportType
            }
        }

        return result
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-module>
    func allocate(
        module: Module,
        externalValues: [ExternalValue],
        initialGlobals: [Value]
    ) -> ModuleInstance {
        // Step 1 of module allocation algorithm, according to Wasm 2.0 spec.
        let moduleInstance = ModuleInstance()

        moduleInstance.types = module.types

        // External values imported in this module should be included in corresponding index spaces before definitions
        // local to to the module are added.
        for external in externalValues {
            switch external {
            case let .function(address):
                // Step 14.
                moduleInstance.functionAddresses.append(address)
            case let .table(address):
                // Step 15.
                moduleInstance.tableAddresses.append(address)
            case let .memory(address):
                // Step 16.
                moduleInstance.memoryAddresses.append(address)
            case let .global(address):
                // Step 17.
                moduleInstance.globalAddresses.append(address)
            }
        }

        // Step 2.
        for function in module.functions {
            let address = allocate(function: function, module: moduleInstance)
            moduleInstance.functionAddresses.append(address)
        }

        // Step 3.
        for table in module.tables {
            let address = allocate(tableType: table.type)
            moduleInstance.tableAddresses.append(address)
        }

        // Step 4.
        for memory in module.memories {
            let address = allocate(memoryType: memory.type)
            moduleInstance.memoryAddresses.append(address)
        }

        // Step 5.
        assert(module.globals.count == initialGlobals.count)
        for (global, initialValue) in zip(module.globals, initialGlobals) {
            let address = allocate(globalType: global.type, initialValue: initialValue)
            moduleInstance.globalAddresses.append(address)
        }

        // Step 6.
        for element in module.elements {
            let references = element.initializer.map { expression -> Reference in
                switch expression.instructions[0] {
                case let .reference(.refFunc(index)):
                    let addr = moduleInstance.functionAddresses[Int(index)]
                    return .function(addr)
                case .reference(.refNull(.funcRef)):
                    return .function(nil)
                case .reference(.refNull(.externRef)):
                    return .extern(nil)
                default:
                    fatalError("Unexpected element initializer expression: \(expression)")
                }
            }
            let address = allocate(elementType: element.type, references: references)
            moduleInstance.elementAddresses.append(address)
        }

        // Step 13.
        for datum in module.data {
            let address: DataAddress
            switch datum {
            case let .passive(bytes):
                address = allocate(bytes: bytes)
            case let .active(datum):
                address = allocate(bytes: Array(datum.initializer))
            }
            moduleInstance.dataAddresses.append(address)
        }

        // Step 19.
        for export in module.exports {
            let exportInstance = ExportInstance(export, moduleInstance: moduleInstance)
            moduleInstance.exportInstances.append(exportInstance)
        }

        if let nameSection = module.customSections.first(where: { $0.name == "name" }) {
            // FIXME?: Just ignore parsing error of name section for now.
            // Should emit warning instead of just discarding it?
            try? nameRegistry.register(instance: moduleInstance, nameSection: nameSection)
        }

        // Steps 20-21.
        return moduleInstance
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-func>
    func allocate(function: Function, module: ModuleInstance) -> FunctionAddress {
        let address = functions.count
        let instance = FunctionInstance(function, module: module)
        functions.append(instance)
        return address
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-table>
    func allocate(tableType: TableType) -> TableAddress {
        let address = tables.count
        let instance = TableInstance(tableType)
        tables.append(instance)
        return address
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-mem>
    func allocate(memoryType: MemoryType) -> MemoryAddress {
        let address = memories.count
        let instance = MemoryInstance(memoryType)
        memories.append(instance)
        return address
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#alloc-global>
    func allocate(globalType: GlobalType, initialValue: Value) -> GlobalAddress {
        let address = globals.count
        let instance = GlobalInstance(globalType: globalType, initialValue: initialValue)
        globals.append(instance)
        return address
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#element-segments>
    func allocate(elementType: ReferenceType, references: [Reference]) -> ElementAddress {
        let address = elements.count
        let instance = ElementInstance(type: elementType, references: references)
        elements.append(instance)
        return address
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#data-segments>
    func allocate(bytes: [UInt8]) -> DataAddress {
        let address = datas.count
        let instance = DataInstance(data: bytes)
        datas.append(instance)
        return address
    }
}
