import WasmParser

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
