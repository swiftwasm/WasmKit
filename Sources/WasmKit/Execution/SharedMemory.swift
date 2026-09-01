import WasmParser

/// A store-independent backing for a shared WebAssembly linear memory.
///
/// A ``SharedMemory`` may be wrapped by a separate ``Memory`` in each
/// ``Store``. The wrappers are intentionally not Sendable; only their bytes,
/// growth state, and atomic wait/notify state are shared.
public final class SharedMemory: @unchecked Sendable {
    /// The declared type of this memory.
    public let type: MemoryType
    private let resourceLimiter: any ResourceLimiter

    #if os(macOS) || os(Linux)
        let storage: SharedMemoryStorage

        /// Creates a shared wasm32 memory backing.
        ///
        /// Shared memories require the threads feature and mprotect-based
        /// bounds checking on a supported 64-bit host.
        public init(engine: Engine, type: MemoryType, resourceLimiter: any ResourceLimiter) throws {
            guard type.shared, !type.isMemory64 else {
                throw Trap(.sharedMemoryRequiresMprotect)
            }
            try ModuleValidator.checkMemoryType(type, features: engine.configuration.features)

            let maxPages = type.max ?? MemoryEntity.maxPageCount(isMemory64: false)
            let initialBytes = Int(type.min) * MemoryEntity.pageSize
            guard try resourceLimiter.limitMemoryGrowth(to: initialBytes) else {
                throw Trap(.initialMemorySizeExceedsLimit(byteSize: initialBytes))
            }
            let (maxBytes, overflow) = Int(clamping: maxPages).multipliedReportingOverflow(by: MemoryEntity.pageSize)
            self.type = type
            self.resourceLimiter = resourceLimiter
            self.storage = try SharedMemoryStorage(
                initialBytes: initialBytes,
                maxBytes: overflow ? (Int.max / MemoryEntity.pageSize) * MemoryEntity.pageSize : maxBytes,
                isMemory64: false,
                engineConfiguration: engine.configuration
            )
        }

        /// The current committed size in bytes.
        public var byteCount: Int {
            storage.currentByteCount.load(ordering: .acquiring)
        }

        /// Grows the backing by `pageCount` WebAssembly pages.
        ///
        /// Returns the previous page count, or `-1` when the requested size
        /// exceeds the declared maximum. This operation is shared by every
        /// store-local ``Memory`` wrapper made from this backing.
        public func grow(by pageCount: Int) throws -> Int {
            guard pageCount >= 0 else { return -1 }
            return try storage.grow(by: pageCount, resourceLimiter: resourceLimiter)
        }
    #else
        /// Shared memory is unavailable on this platform.
        public init(engine: Engine, type: MemoryType, resourceLimiter: any ResourceLimiter) throws {
            self.type = type
            self.resourceLimiter = resourceLimiter
            throw Trap(.sharedMemoryRequiresMprotect)
        }

        /// Always zero on unsupported platforms.
        public var byteCount: Int { 0 }
    #endif
}
