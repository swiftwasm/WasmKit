import WasmParser

internal typealias ModuleAddress = Int

/// A collection of globals and functions that are exported from a host module.
public struct HostModule {
    public init(
        globals: [String: Global] = [:],
        memories: [String: Memory] = [:],
        functions: [String: HostFunction] = [:]
    ) {
        self.globals = globals
        self.memories = memories
        self.functions = functions
    }

    /// Names of globals exported by this module mapped to corresponding global instances.
    public let globals: [String: Global]

    /// Names of memories exported by this module mapped to corresponding addresses of memory instances.
    public let memories: [String: Memory]

    /// Names of functions exported by this module mapped to corresponding host functions.
    public let functions: [String: HostFunction]
}

/// A container to manage WebAssembly object space.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#store>
public final class Store {
    var hostFunctions: [HostFunction] = []
    private var hostGlobals: [Global] = []
    var nameRegistry = NameRegistry()

    @available(*, unavailable)
    public var namedModuleInstances: [String: Any] {
        fatalError()
    }

    /// This property is separate from `registeredModuleInstances`, as host exports
    /// won't have a corresponding module instance.
    fileprivate var availableExports: [String: [String: ExternalValue]] = [:]

    let allocator: StoreAllocator

    init(funcTypeInterner: Interner<FunctionType>) {
        self.allocator = StoreAllocator(funcTypeInterner: funcTypeInterner)
    }
}

/// A caller context passed to host functions
public struct Caller {
    private let instanceHandle: InternalInstance?
    /// The instance that called the host function.
    /// - Note: This property is `nil` if a `Function` backed by a host function is called directly.
    public var instance: Instance? {
        guard let instanceHandle else { return nil }
        return Instance(handle: instanceHandle, allocator: runtime.store.allocator)
    }
    /// The runtime that called the host function.
    public let runtime: Runtime
    /// The store associated with the caller execution context.
    public var store: Store {
        runtime.store
    }

    init(instanceHandle: InternalInstance?, runtime: Runtime) {
        self.instanceHandle = instanceHandle
        self.runtime = runtime
    }
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

struct HostFunctionEntity {
    let type: InternedFuncType
    let implementation: (Caller, [Value]) throws -> [Value]
}

extension Store {
    public func register(_ instance: Instance, as name: String) throws {
        guard availableExports[name] == nil else {
            throw ImportError.moduleInstanceAlreadyRegistered(name)
        }

        availableExports[name] = instance.exports
    }

    /// Register the given host module in this store with the given name.
    ///
    /// - Parameters:
    ///   - hostModule: A host module to register.
    ///   - name: A name to register the given host module.
    public func register(_ hostModule: HostModule, as name: String, runtime: Runtime) throws {
        guard availableExports[name] == nil else {
            throw ImportError.moduleInstanceAlreadyRegistered(name)
        }

        registerUniqueHostModule(hostModule, as: name, runtime: runtime)
    }

    /// Register the given host module assuming that the given name is not registered yet.
    func registerUniqueHostModule(_ hostModule: HostModule, as name: String, runtime: Runtime) {
        var moduleExports = [String: ExternalValue]()

        for (globalName, global) in hostModule.globals {
            moduleExports[globalName] = .global(global)
            hostGlobals.append(global)
        }

        for (functionName, function) in hostModule.functions {
            moduleExports[functionName] = .function(
                Function(
                    handle: allocator.allocate(hostFunction: function, runtime: runtime),
                    allocator: allocator
                )
            )
            hostFunctions.append(function)
        }

        for (memoryName, memoryAddr) in hostModule.memories {
            moduleExports[memoryName] = .memory(memoryAddr)
        }

        availableExports[name] = moduleExports
    }

    @available(*, deprecated, message: "Address-based APIs has been removed; use `Memory` instead")
    public func memory(at address: Memory) -> Memory {
        address
    }

    @available(*, deprecated, message: "Address-based APIs has been removed; use `Memory` instead")
    public func withMemory<T>(at address: Memory, _ body: (Memory) throws -> T) rethrows -> T {
        try body(address)
    }

    func getExternalValues(_ module: Module, runtime: Runtime) throws -> [ExternalValue] {
        var result = [ExternalValue]()

        for i in module.imports {
            guard let moduleExports = availableExports[i.module], let external = moduleExports[i.name] else {
                throw ImportError.unknownImport(moduleName: i.module, externalName: i.name)
            }

            switch (i.descriptor, external) {
            case let (.function(typeIndex), .function(externalFunc)):
                let type = externalFunc.handle.type
                guard runtime.internType(module.types[Int(typeIndex)]) == type else {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.table(tableType), .table(table)):
                if let max = table.handle.limits.max, max < tableType.limits.min {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.memory(memoryType), .memory(memory)):
                if let max = memory.handle.limit.max, max < memoryType.min {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.global(globalType), .global(global))
                where globalType == global.handle.globalType:
                result.append(external)

            default:
                throw ImportError.incompatibleImportType
            }
        }

        return result
    }

    func allocate(
        module: Module,
        runtime: Runtime,
        externalValues: [ExternalValue]
    ) throws -> InternalInstance {
        try allocator.allocate(
            module: module, runtime: runtime,
            externalValues: externalValues,
            nameRegistry: &nameRegistry
        )
    }
}
