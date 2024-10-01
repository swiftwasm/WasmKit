import WasmParser

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
    public var globals: [String: Global]

    /// Names of memories exported by this module mapped to corresponding addresses of memory instances.
    public var memories: [String: Memory]

    /// Names of functions exported by this module mapped to corresponding host functions.
    public var functions: [String: HostFunction]
}

/// A container to manage WebAssembly object space.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#store>
public final class Store {
    var nameRegistry = NameRegistry()
    @_spi(Fuzzing) // Consider making this public
    public var resourceLimiter: ResourceLimiter = DefaultResourceLimiter()

    @available(*, unavailable)
    public var namedModuleInstances: [String: Any] {
        fatalError()
    }

    /// The allocator allocating and retaining resources for this store.
    let allocator: StoreAllocator
    /// The engine associated with this store.
    let engine: Engine

    /// Create a new store associated with the given engine.
    public init(engine: Engine) {
        self.engine = engine
        self.allocator = StoreAllocator(funcTypeInterner: engine.funcTypeInterner)
    }
}

extension Store: Equatable {
    public static func == (lhs: Store, rhs: Store) -> Bool {
        /// Use reference identity for equality comparison.
        return lhs === rhs
    }
}

/// A caller context passed to host functions
public struct Caller {
    private let instanceHandle: InternalInstance?
    /// The instance that called the host function.
    /// - Note: This property is `nil` if a `Function` backed by a host function is called directly.
    public var instance: Instance? {
        guard let instanceHandle else { return nil }
        return Instance(handle: instanceHandle, store: store)
    }

    /// The engine associated with the caller execution context.
    public var engine: Engine { store.engine }

    /// The store associated with the caller execution context.
    public let store: Store

    /// The runtime that called the host function.
    @available(*, unavailable, message: "Use `engine` instead")
    public var runtime: Runtime { fatalError() }

    init(instanceHandle: InternalInstance?, store: Store) {
        self.instanceHandle = instanceHandle
        self.store = store
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
    @available(*, unavailable, message: "Use ``Imports/define(_:as:)`` instead. Or use ``Runtime/register(_:as:)`` as a temporary drop-in replacement.")
    public func register(_ instance: Instance, as name: String) throws {}

    /// Register the given host module in this store with the given name.
    ///
    /// - Parameters:
    ///   - hostModule: A host module to register.
    ///   - name: A name to register the given host module.
    @available(*, unavailable, message: "Use ``Imports/define(_:as:)`` instead. Or use ``Runtime/register(_:as:)`` as a temporary drop-in replacement.")
    public func register(_ hostModule: HostModule, as name: String, runtime: Any) throws {}

    @available(*, deprecated, message: "Address-based APIs has been removed; use Memory instead")
    public func memory(at address: Memory) -> Memory {
        address
    }

    @available(*, deprecated, message: "Address-based APIs has been removed; use Memory instead")
    public func withMemory<T>(at address: Memory, _ body: (Memory) throws -> T) rethrows -> T {
        try body(address)
    }
}
