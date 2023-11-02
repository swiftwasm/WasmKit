struct CanonicalABIError: Error, CustomStringConvertible {
    let description: String
}

/// Call context for `(canon lift)` or `(canon lower)` operations.
/// This type corresponds to `CallContext` in the Canonical ABI spec.
///
/// > Note:
/// <https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md#runtime-state>
public struct CanonicalCallContext {
    /// The options used for lifting or lowering operations.
    public let options: CanonicalOptions
    /// The module instance that defines the lift/lower operation.
    public let moduleInstance: ModuleInstance
    /// The executing `Runtime` instance
    public let runtime: Runtime
    /// A reference to the guest memory.
    public var guestMemory: GuestMemory {
        GuestMemory(store: runtime.store, address: options.memory)
    }

    public init(options: CanonicalOptions, moduleInstance: ModuleInstance, runtime: Runtime) {
        self.options = options
        self.moduleInstance = moduleInstance
        self.runtime = runtime
    }

    /// Call `cabi_realloc` export with the given arguments.
    public func realloc(
        old: UInt32,
        oldSize: UInt32,
        oldAlign: UInt32,
        newSize: UInt32
    ) throws -> UnsafeGuestRawPointer {
        guard let realloc = options.realloc else {
            throw CanonicalABIError(description: "Missing required \"cabi_realloc\" export")
        }
        let results = try runtime.invoke(realloc, with: [.i32(old), .i32(oldSize), .i32(oldAlign), .i32(newSize)])
        guard results.count == 1 else {
            throw CanonicalABIError(description: "\"cabi_realloc\" export should return a single value")
        }
        guard case let .i32(new) = results[0] else {
            throw CanonicalABIError(description: "\"cabi_realloc\" export should return an i32 value")
        }
        return UnsafeGuestRawPointer(memorySpace: guestMemory, offset: new)
    }
}
