import WasmParser

/// A budget for WebAssembly execution, measured in fuel.
///
/// One unit of fuel is roughly one executed WebAssembly operator; bulk memory and table
/// operations additionally cost one unit per 64 bytes they move.
public struct Fuel: Sendable {
    /// The fuel remaining in this budget.
    public var remaining: UInt64

    /// Creates a budget with the given amount of fuel remaining.
    public init(remaining: UInt64) {
        self.remaining = remaining
    }
}

/// A container to manage WebAssembly object space.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#store>
public final class Store {
    var nameRegistry = NameRegistry()
    @_spi(Fuzzing)  // Consider making this public
    public var resourceLimiter: ResourceLimiter = DefaultResourceLimiter()

    /// The remaining fuel. `UInt64.max` means "unlimited".
    ///
    /// In a ``Cell`` so that the interpreter can charge it through its address. Unsynchronized: a
    /// `Store` is thread-confined, and each wasi thread gets its own.
    let remainingFuel = Cell<UInt64>(.max)
    /// Whether this store's engine meters fuel.
    ///
    /// Bulk memory and table handlers exist whether or not fuel is metered, so they have to ask.
    /// Resolved once here rather than per operation, because reaching the engine's configuration
    /// from a handler is a chain of loads that a copy-heavy guest pays for on every copy, metered
    /// or not.
    let isFuelMetered: Bool
    /// Whether a budget was ever set. Distinguishes "unlimited" from a budget that happens to
    /// hold `UInt64.max`.
    private var hasFuel: Bool = false
    /// The program counter of the fuel charge that exhausted the budget.
    ///
    /// Written on the out-of-fuel path and not read yet: resuming a suspended execution needs the
    /// program counter of the charge in order to retry it, and recording it keeps that change
    /// additive. It lives here rather than in `Execution` because adding a stored property there
    /// grows the call and throw handlers noticeably, even though they never read it.
    var fuelTrapPC: UnsafeRawPointer? = nil

    /// The remaining execution budget of this store, or `nil` when execution is unlimited.
    /// (Default: `nil`)
    ///
    /// Execution traps with an out-of-fuel trap once the budget is exhausted. The remaining fuel
    /// is left untouched by the failed charge, and the store stays usable: assign a new budget and
    /// call again.
    ///
    /// - Note: This has no effect unless the store's engine was configured with
    ///   ``EngineConfiguration/fuelMetering``. Setting a budget on an engine without fuel metering
    ///   is accepted, but nothing consumes it, so the value never decreases.
    public var fuel: Fuel? {
        get {
            hasFuel ? Fuel(remaining: remainingFuel.value) : nil
        }
        set {
            assign(fuel: newValue)
        }
        _modify {
            var value = hasFuel ? Fuel(remaining: remainingFuel.value) : nil
            defer { assign(fuel: value) }
            yield &value
        }
    }

    private func assign(fuel newValue: Fuel?) {
        hasFuel = newValue != nil
        remainingFuel.value = newValue?.remaining ?? .max
    }

    @available(*, unavailable)
    public var namedModuleInstances: [String: Any] {
        fatalError()
    }

    /// The allocator allocating and retaining resources for this store.
    let allocator: StoreAllocator
    /// The engine associated with this store.
    public let engine: Engine

    /// Create a new store associated with the given engine.
    public init(engine: Engine) {
        self.engine = engine
        self.allocator = StoreAllocator(funcTypeInterner: engine.funcTypeInterner)
        self.isFuelMetered = engine.configuration.fuelMetering
    }
}

extension Store: Equatable {
    public static func == (lhs: Store, rhs: Store) -> Bool {
        /// Use reference identity for equality comparison.
        return lhs === rhs
    }
}

/// A caller context passed to host functions
/// Not copyable to avoid storing stale stack pointer.
public struct Caller: ~Copyable {
    private let instanceHandle: InternalInstance?
    /// The stack pointer at the point of the host function call.
    private let sp: Sp?
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

    init(instanceHandle: InternalInstance?, store: Store, sp: Sp? = nil) {
        self.instanceHandle = instanceHandle
        self.store = store
        self.sp = sp
    }

    /// Captures the current WebAssembly call stack backtrace.
    ///
    /// Returns `nil` if the caller context does not have stack pointer information
    /// (e.g., when a host function is called directly rather than from WebAssembly).
    public func captureBacktrace() -> Backtrace? {
        guard let sp else { return nil }
        return Execution.captureBacktrace(sp: sp, store: store)
    }
}

struct HostFunctionEntity {
    let type: InternedFuncType
    /// The signature, resolved once here rather than looked up through the
    /// engine's interner on every call. On a small device the lookup and the
    /// retain traffic on the type's arrays cost more than the call they
    /// preface.
    let parameterTypes: [ValueType]
    let resultTypes: [ValueType]
    let layout: FrameHeaderLayout
    /// Always the buffer-based form. A host function written against the
    /// array-based API is wrapped in one of these when it is created, so the
    /// engine has a single shape to call and only the functions that want
    /// arrays pay for them.
    let implementation: Function.RawImplementation
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
