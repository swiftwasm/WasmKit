import Synchronization
import WasmParser

@_exported import struct WasmParser.GlobalType
@_exported import struct WasmParser.Limits
@_exported import struct WasmParser.MemoryType
@_exported import struct WasmParser.TableType

// This file defines the internal representation of WebAssembly entities and
// their public API.
//
// Typically, the internal representation is an unowned handle to an entity
// storage, and the public API provides a memory-safe way to access and
// manipulate the entity. The handle is usually owned by a ``StoreAllocator``
// that manages the lifetime of the entity storage. The public API must ensure
// that the entity handle does not outlive the ``StoreAllocator``.
//
// # Naming Conventions
// - Internal entity storage: `${Name}Entity`
// - Entity handle: `Internal${Name}`
// - Public entity: `${Name}`
//
// +--- Public API -----------------------------------------------+
// |                                                              |
// |     allocator: StoreAllocator  ---------+                    |
// |     handle: Internal${Name}             |                    |
// |        |                                v                    |
// |        |                    +--- StoreAllocator ---+         |
// |        v                    |                      |         |
// |   +---------------+         |  +-----------------+ |         |
// |   | Entity handle | ---------->| Entity storage  | |         |
// |   +---------------+         |  +-----------------+ |         |
// |                             |                      |         |
// |                             +----------------------+         |
// |                                                              |
// +--------------------------------------------------------------+

/// Internal representation of a reference to a WebAssembly entity.
///
/// This type is designed to eliminate ARC retain/release for entities
/// known to be alive during a VM execution.
@dynamicMemberLookup
package struct EntityHandle<T: ~Copyable>: Equatable, Hashable, Copyable {
    private let pointer: UnsafeMutablePointer<T>

    init(unsafe pointer: UnsafeMutablePointer<T>) {
        self.pointer = pointer
    }

    init?(bitPattern: UInt) {
        guard let pointer = UnsafeMutablePointer<T>(bitPattern: bitPattern) else { return nil }
        self.pointer = pointer
    }

    package subscript<R>(dynamicMember keyPath: KeyPath<T, R>) -> R where T: Copyable {
        withValue { $0[keyPath: keyPath] }
    }

    @inline(__always)
    package func withValue<R>(_ body: (inout T) throws -> R) rethrows -> R {
        return try body(&pointer.pointee)
    }

    var bitPattern: Int {
        return Int(bitPattern: pointer)
    }
}

extension EntityHandle: ValidatableEntity where T: ValidatableEntity, T: ~Copyable {
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        T.createOutOfBoundsError(index: index, count: count)
    }
}

package struct InstanceEntity /* : ~Copyable */ {
    var types: [FunctionType]
    var functions: ImmutableArray<InternalFunction>
    var tables: ImmutableArray<InternalTable>
    var memories: ImmutableArray<InternalMemory>
    var globals: ImmutableArray<InternalGlobal>
    var tags: ImmutableArray<InternalTag>
    var elementSegments: ImmutableArray<InternalElementSegment>
    var dataSegments: ImmutableArray<InternalDataSegment>
    var exports: [String: InternalExternalValue]
    var functionRefs: Set<InternalFunction>
    var features: WasmFeatureSet
    var dataCount: UInt32?
    var isDebuggable: Bool

    var instructionMapping: DebuggerInstructionMapping

    static var empty: InstanceEntity {
        InstanceEntity(
            types: [],
            functions: ImmutableArray(),
            tables: ImmutableArray(),
            memories: ImmutableArray(),
            globals: ImmutableArray(),
            tags: ImmutableArray(),
            elementSegments: ImmutableArray(),
            dataSegments: ImmutableArray(),
            exports: [:],
            functionRefs: [],
            features: [],
            dataCount: nil,
            isDebuggable: false,
            instructionMapping: .init()
        )
    }

    package func compileAllFunctions(store: Store) throws {
        let store = StoreRef(store)
        for function in functions {
            guard function.isWasm else { continue }
            try function.wasm.ensureCompiled(store: store)
        }
    }
}

package typealias InternalInstance = EntityHandle<InstanceEntity>

/// A map of exported entities by name.
public struct Exports: Sequence {
    let store: Store
    let items: [String: InternalExternalValue]

    /// A collection of exported entities without their names.
    public var values: [ExternalValue] {
        self.map { $0.value }
    }

    /// Returns the exported entity with the given name.
    public subscript(_ name: String) -> ExternalValue? {
        guard let entity = items[name] else { return nil }
        return ExternalValue(handle: entity, store: store)
    }

    /// Returns the exported function with the given name.
    public subscript(function name: String) -> Function? {
        guard case .function(let function) = self[name] else { return nil }
        return function
    }

    /// Returns the exported table with the given name.
    public subscript(table name: String) -> Table? {
        guard case .table(let table) = self[name] else { return nil }
        return table
    }

    /// Returns the exported memory with the given name.
    public subscript(memory name: String) -> Memory? {
        guard case .memory(let memory) = self[name] else { return nil }
        return memory
    }

    /// Returns the exported global with the given name.
    public subscript(global name: String) -> Global? {
        guard case .global(let global) = self[name] else { return nil }
        return global
    }

    public struct Iterator: IteratorProtocol {
        private let store: Store
        private var iterator: Dictionary<String, InternalExternalValue>.Iterator

        init(parent: Exports) {
            self.store = parent.store
            self.iterator = parent.items.makeIterator()
        }

        public mutating func next() -> (name: String, value: ExternalValue)? {
            guard let (name, entity) = iterator.next() else { return nil }
            return (name, ExternalValue(handle: entity, store: store))
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(parent: self)
    }
}

/// A stateful instance of a WebAssembly module.
/// Usually instantiated by ``Module/instantiate(store:imports:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#module-instances>
public struct Instance {
    package let handle: InternalInstance
    let store: Store

    init(handle: InternalInstance, store: Store) {
        self.handle = handle
        self.store = store
    }

    /// Finds an exported entity by name.
    ///
    /// - Parameter name: The name of the exported entity.
    /// - Returns: The exported entity if found, otherwise `nil`.
    public func export(_ name: String) -> ExternalValue? {
        guard let entity = handle.exports[name] else { return nil }
        return ExternalValue(handle: entity, store: store)
    }

    /// Finds an exported function by name.
    ///
    /// - Parameter name: The name of the exported function.
    /// - Returns: The address of the exported function if found, otherwise `nil`.
    package func exportedFunction(name: String) -> Function? {
        guard case .function(let function) = self.export(name) else { return nil }
        return function
    }

    /// A dictionary of exported entities by name.
    public var exports: Exports {
        Exports(store: store, items: handle.exports)
    }

    /// Dumps the textual representation of all functions in the instance.
    ///
    /// - Precondition: The instance must be compiled with the token threading model.
    @_spi(OnlyForCLI)
    public func dumpFunctions<Target>(to target: inout Target, module: Module) throws where Target: TextOutputStream {
        for (offset, function) in self.handle.functions.enumerated() {
            let index = offset
            guard function.isWasm else { continue }
            target.write("==== Function[\(index)]")
            if let name = try? store.nameRegistry.lookup(function) {
                target.write(" '\(name)'")
            }
            target.write(" ====\n")
            guard case .uncompiled(let code) = function.wasm.code else {
                fatalError("Already compiled!?")
            }
            try function.wasm.ensureCompiled(store: StoreRef(store))
            let (iseq, _, _) = function.assumeCompiled()

            // Print slot space information
            let localTypes = code.withValue { $0.locals }
            let stackLayout = try StackLayout(
                type: store.engine.funcTypeInterner.resolve(function.type),
                locals: localTypes,
                codeSize: code.expression.count
            )
            stackLayout.dump(to: &target, iseq: iseq)

            var context = InstructionPrintingContext(
                shouldColor: true,
                function: Function(handle: function, store: store),
                nameRegistry: store.nameRegistry
            )
            iseq.write(to: &target, context: &context)
        }
    }
}

extension Instance {
    @available(*, unavailable, message: "Address-based APIs has been removed; use `Instance/export` to access exported memories")
    public var memoryAddresses: [Never] { [] }
    @available(*, unavailable, message: "Address-based APIs has been removed; use `Instance/export` to access exported globals")
    public var globalAddresses: [Never] { [] }
    @available(*, unavailable, message: "Address-based APIs has been removed;")
    public var elementAddresses: [Never] { [] }
    @available(*, unavailable, message: "Address-based APIs has been removed;")
    public var dataAddresses: [Never] { [] }
    @available(*, unavailable, message: "Address-based APIs has been removed;")
    public var exportInstances: [Never] { [] }
}

/// Deprecated typealias for `Instance`.
@available(*, deprecated, renamed: "Instance", message: "ModuleInstance has been renamed to Instance to match the terminology in the WebAssembly ecosystem")
public typealias ModuleInstance = Instance

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#table-instances>
struct TableEntity /* : ~Copyable */ {
    var elements: [Reference]
    let tableType: TableType
    var limits: Limits { tableType.limits }

    static func maxSize(isMemory64: Bool) -> UInt64 {
        return UInt64(UInt32.max)
    }

    init(_ tableType: TableType, resourceLimiter: any ResourceLimiter) throws {
        let emptyElement: Reference
        switch tableType.elementType.heapType {
        case .abstract(.funcRef):
            emptyElement = .function(nil)
        case .abstract(.externRef):
            emptyElement = .extern(nil)
        case .abstract(.exnRef):
            emptyElement = .exception(nil)
        case .concrete:
            throw Trap(.unimplemented(feature: "heap type other than `func`, `extern`, and `exn`"))
        }

        let numberOfElements = Int(tableType.limits.min)
        guard try resourceLimiter.limitTableGrowth(to: numberOfElements) else {
            throw Trap(.initialTableSizeExceedsLimit(numberOfElements: numberOfElements))
        }
        elements = Array(repeating: emptyElement, count: numberOfElements)
        self.tableType = tableType
    }

    /// > Note: https://webassembly.github.io/spec/core/exec/modules.html#grow-table
    /// Returns true if gorwth succeeds, otherwise returns false
    mutating func grow(by growthSize: UInt64, value: Reference, resourceLimiter: any ResourceLimiter) throws -> Bool {
        let oldSize = UInt64(elements.count)
        guard !UInt64(elements.count).addingReportingOverflow(growthSize).overflow else {
            return false
        }

        let maxLimit = limits.max ?? (limits.isMemory64 ? UInt64.max : UInt64(UInt32.max))

        let newSize = oldSize + growthSize
        if newSize > maxLimit {
            return false
        }
        guard try resourceLimiter.limitTableGrowth(to: Int(newSize)) else {
            return false
        }
        elements.append(contentsOf: Array(repeating: value, count: Int(growthSize)))
        return true
    }

    mutating func initialize(_ segment: InternalElementSegment, from source: Int, to destination: Int, count: Int) throws {
        try self.initialize(segment.references, from: source, to: destination, count: count)
    }

    mutating func initialize(_ references: [Reference], from source: Int, to destination: Int, count: Int) throws {
        let (destinationEnd, destinationOverflow) = destination.addingReportingOverflow(count)
        let (sourceEnd, sourceOverflow) = source.addingReportingOverflow(count)

        guard !destinationOverflow, destinationEnd <= elements.count else {
            throw Trap(.tableOutOfBounds(destinationEnd))
        }
        guard !sourceOverflow, sourceEnd <= references.count else {
            throw Trap(.tableOutOfBounds(sourceEnd))
        }

        elements.withUnsafeMutableBufferPointer { table in
            references.withUnsafeBufferPointer { segment in
                _ = table[destination..<destination + count].initialize(from: segment[source..<source + count])
            }
        }
    }

    mutating func fill(repeating value: Reference, from index: Int, count: Int) throws {
        let (end, overflow) = index.addingReportingOverflow(count)
        guard !overflow, end <= elements.count else { throw Trap(.tableOutOfBounds(end)) }

        elements.withUnsafeMutableBufferPointer {
            $0[index..<index + count].initialize(repeating: value)
        }
    }

    static func copy(
        _ sourceTable: UnsafeBufferPointer<Reference>,
        _ destinationTable: UnsafeMutableBufferPointer<Reference>,
        from source: Int, to destination: Int, count: Int
    ) throws {
        let (destinationEnd, destinationOverflow) = destination.addingReportingOverflow(count)
        let (sourceEnd, sourceOverflow) = source.addingReportingOverflow(count)

        guard !destinationOverflow, destinationEnd <= destinationTable.count else {
            throw Trap(.tableOutOfBounds(Int(destinationEnd)))
        }
        guard !sourceOverflow, sourceEnd <= sourceTable.count else {
            throw Trap(.tableOutOfBounds(Int(sourceEnd)))
        }

        let source = UnsafeBufferPointer(rebasing: sourceTable[source..<source + count])
        let destination = UnsafeMutableBufferPointer(rebasing: destinationTable[destination..<destination + count])

        // Note: Do not use `UnsafeMutableBufferPointer.update(from:)` overload here because it does not
        // provide the same semantics as `memmove` for overlapping memory regions.
        // TODO: We can optimize this to use `memcpy` if the source and destination tables are known to be different
        // at translation time.
        _ = destination.update(fromContentsOf: source)
    }
}

extension TableEntity: ValidatableEntity {
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        WasmKitError(message: .indexOutOfBounds("table", index, max: count))
    }
}

typealias InternalTable = EntityHandle<TableEntity>

extension InternalTable {
    func copy(_ sourceTable: InternalTable, from source: Int, to destination: Int, count: Int) throws {
        // Check if the source and destination tables are the same for dynamic exclusive
        // access enforcement
        if self == sourceTable {
            try withValue {
                try $0.elements.withUnsafeMutableBufferPointer {
                    try TableEntity.copy(UnsafeBufferPointer($0), $0, from: source, to: destination, count: count)
                }
            }
        } else {
            try withValue { destinationTable in
                try sourceTable.withValue { sourceTable in
                    try destinationTable.elements.withUnsafeMutableBufferPointer { dest in
                        try sourceTable.elements.withUnsafeBufferPointer { src in
                            try TableEntity.copy(src, dest, from: source, to: destination, count: count)
                        }
                    }
                }
            }
        }
    }
}

/// A WebAssembly `table` instance.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#table-instances>
public struct Table: Equatable {
    let handle: InternalTable
    let allocator: StoreAllocator

    init(handle: InternalTable, allocator: StoreAllocator) {
        self.handle = handle
        self.allocator = allocator
    }

    /// Creates a new WebAssembly `table` instance with the given type.
    ///
    /// - Parameters:
    ///   - store: The store that to allocate the global instance in.
    ///   - type: The type of the table instance.
    /// - Throws: `Trap` if the initial and maximum table size exceeds the resource limit.
    ///
    /// ```swift
    /// let engine = Engine()
    /// let store = Store(engine: engine)
    /// let tableType = TableType(elementType: .funcRef, limits: Limits(min: 1))
    /// let table = try Table(store: store, type: tableType)
    ///
    /// let module = try parseWasm(
    ///     bytes: try wat2wasm(#"(module (table (import "env" "table") 1 funcref))"#)
    /// )
    /// let imports: Imports = ["env": ["table": table]]
    /// let instance = try module.instantiate(store: store, imports: imports)
    /// ```
    public init(store: Store, type: TableType) throws {
        self.init(
            handle: try store.allocator.allocate(tableType: type, resourceLimiter: store.resourceLimiter),
            allocator: store.allocator
        )
    }

    /// The type of the table instance.
    public var type: TableType {
        handle.tableType
    }

    /// Accesses the element at the given index.
    public subscript(index: Int) -> Reference {
        get { handle.elements[index] }
        nonmutating set { handle.withValue { $0.elements[index] = newValue } }
    }
}

struct MemoryEntity: ~Copyable {
    static let pageSize = 64 * 1024

    static func maxPageCount(isMemory64: Bool) -> UInt64 {
        isMemory64 ? UInt64.max : UInt64(1 << 32) / UInt64(pageSize)
    }

    private struct MallocStorage {
        var buffer: UnsafeMutableBufferPointer<UInt8>

        init(byteSize: Int, isMemory64: Bool, engineConfiguration: EngineConfiguration) {
            buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: byteSize)
            if byteSize > 0 { buffer.initialize(repeating: 0) }
        }

        var data: UnsafeBufferPointer<UInt8> {
            UnsafeBufferPointer(buffer)
        }
        var baseAddress: UnsafeMutableRawPointer? {
            UnsafeMutableRawPointer(buffer.baseAddress)
        }

        var byteCount: Int {
            buffer.count
        }

        var trapGuardReservationSize: Int { 0 }

        mutating func grow(to newByteCount: Int) throws {
            let storage = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: newByteCount)
            let oldStorage = self.buffer
            if newByteCount > 0 { storage.initialize(repeating: 0) }
            if oldStorage.count > 0 {
                storage.baseAddress!.update(from: oldStorage.baseAddress!, count: oldStorage.count)
            }
            oldStorage.deallocate()
            self.buffer = storage
        }

        func deallocate() {
            buffer.deallocate()
        }
    }

    /// Backing storage for a linear memory; shared memories are the `.shared` case.
    private enum Storage {
        #if os(macOS) || os(Linux)
            case mprotect(MprotectLinearMemory)
            case shared(SharedMemoryStorage)
        #endif
        case malloc(MallocStorage)

        init(
            initialBytes: Int,
            maxBytes: Int,
            isMemory64: Bool,
            isShared: Bool,
            engineConfiguration: EngineConfiguration
        ) throws(Trap) {
            if isShared {
                #if os(macOS) || os(Linux)
                    self = .shared(try SharedMemoryStorage(initialBytes: initialBytes, maxBytes: maxBytes, isMemory64: isMemory64, engineConfiguration: engineConfiguration))
                    return
                #else
                    throw Trap(.sharedMemoryRequiresMprotect)
                #endif
            }

            #if os(macOS) || os(Linux)
                if !isMemory64, engineConfiguration.memoryBoundsChecking == .mprotect {
                    let reservationSize = MprotectLinearMemory.wasm32ReservationSize(offsetGuardSize: engineConfiguration.memoryOffsetGuardSize)
                    do {
                        self = .mprotect(try MprotectLinearMemory(committedSize: initialBytes, reservationSize: reservationSize))
                        return
                    } catch {
                        // Fall back to malloc if mprotect fails for some reasons (e.g. vm.max_map_count exhaustion on Linux)
                    }
                }
            #endif
            self = .malloc(MallocStorage(byteSize: initialBytes, isMemory64: isMemory64, engineConfiguration: engineConfiguration))
        }

        var data: UnsafeBufferPointer<UInt8> {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(let memory):
                    return memory.makeBufferPointer()
            #endif
            case .malloc(let buffer):
                return buffer.data
            #if os(macOS) || os(Linux)
                case .shared(let shared):
                    return UnsafeBufferPointer(
                        start: shared.basePointer.assumingMemoryBound(to: UInt8.self),
                        count: shared.currentByteCount.load(ordering: .acquiring)
                    )
            #endif
            }
        }

        var baseAddress: UnsafeMutableRawPointer? {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(let memory):
                    return memory.baseAddress
            #endif
            case .malloc(let buffer):
                return buffer.baseAddress
            #if os(macOS) || os(Linux)
                case .shared(let shared):
                    return shared.basePointer
            #endif
            }
        }

        var byteCount: Int {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(let memory):
                    return memory.committedSize
            #endif
            case .malloc(let buffer):
                return buffer.byteCount
            #if os(macOS) || os(Linux)
                case .shared(let shared):
                    return shared.currentByteCount.load(ordering: .acquiring)
            #endif
            }
        }

        var trapGuardReservationSize: Int {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(let memory):
                    return memory.reservationSize
            #endif
            case .malloc(let buffer):
                return buffer.trapGuardReservationSize
            #if os(macOS) || os(Linux)
                case .shared(let shared):
                    return shared.reservationSize
            #endif
            }
        }

        /// The `Ms` bound for the fast-path software check. Equal to `byteCount` for
        /// inline memories, but the (constant) guard-page reservation for shared memory,
        /// whose real bound is enforced by the guard pages via the trap guard.
        var boundsCheckLimit: Int {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(let memory):
                    return memory.committedSize
            #endif
            case .malloc(let buffer):
                return buffer.byteCount
            #if os(macOS) || os(Linux)
                case .shared(let shared):
                    return shared.reservationSize
            #endif
            }
        }

        /// Grows by `pageCount` pages and returns the old page count, or -1 if rejected
        /// (over the maximum or the resource limit). Shared memory serializes its own
        /// bounds/limiter/commit atomically; the single-threaded backings check then commit.
        mutating func grow(by pageCount: Int, maxPageCount: UInt64, resourceLimiter: any ResourceLimiter) throws -> Int {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(var memory):
                    guard let target = try Self.checkGrow(currentBytes: memory.committedSize, by: pageCount, maxPageCount: maxPageCount, resourceLimiter: resourceLimiter) else { return -1 }
                    try memory.grow(to: target.newByteCount)
                    self = .mprotect(memory)
                    return target.oldPages
            #endif
            case .malloc(var buffer):
                guard let target = try Self.checkGrow(currentBytes: buffer.byteCount, by: pageCount, maxPageCount: maxPageCount, resourceLimiter: resourceLimiter) else { return -1 }
                try buffer.grow(to: target.newByteCount)
                self = .malloc(buffer)
                return target.oldPages
            #if os(macOS) || os(Linux)
                case .shared(let shared):
                    return try shared.grow(by: pageCount, resourceLimiter: resourceLimiter)
            #endif
            }
        }

        /// Bounds + resource-limit check shared by the single-threaded backings. Returns the
        /// old page count and the target byte size, or `nil` if the grow is rejected.
        private static func checkGrow(
            currentBytes: Int, by pageCount: Int, maxPageCount: UInt64, resourceLimiter: any ResourceLimiter
        ) throws -> (oldPages: Int, newByteCount: Int)? {
            let oldPages = currentBytes / MemoryEntity.pageSize
            let newPageCount = oldPages + pageCount
            guard newPageCount <= maxPageCount else { return nil }
            let newByteCount = newPageCount * MemoryEntity.pageSize
            guard try resourceLimiter.limitMemoryGrowth(to: newByteCount) else { return nil }
            return (oldPages, newByteCount)
        }

        func deallocate() {
            switch self {
            #if os(macOS) || os(Linux)
                case .mprotect(let memory):
                    memory.deallocate()
            #endif
            case .malloc(let buffer):
                buffer.deallocate()
            #if os(macOS) || os(Linux)
                case .shared:
                    // Ref-counted; ARC frees the backing when the last importer is released.
                    break
            #endif
            }
        }
    }
    private var storage: Storage
    let maxPageCount: UInt64
    let limit: Limits

    /// The shared backing's `atomic.wait`/`notify` parking lot, or nil if not shared.
    var sharedParkingLot: AtomicParkingLot? {
        #if os(macOS) || os(Linux)
            if case .shared(let shared) = storage { return shared.parkingLot }
        #endif
        return nil
    }

    init(_ memoryType: MemoryType, engineConfiguration: EngineConfiguration, resourceLimiter: any ResourceLimiter) throws {
        let initialBytes = Int(memoryType.min) * Self.pageSize
        guard try resourceLimiter.limitMemoryGrowth(to: initialBytes) else {
            throw Trap(.initialMemorySizeExceedsLimit(byteSize: initialBytes))
        }

        let defaultMaxPageCount = Self.maxPageCount(isMemory64: memoryType.isMemory64)
        let maxPages = memoryType.max ?? defaultMaxPageCount
        // Clamp an overflowing maximum rather than failing; the real cap is enforced at grow.
        let (product, overflow) = Int(clamping: maxPages).multipliedReportingOverflow(by: Self.pageSize)
        let maxBytes = overflow ? (Int.max / Self.pageSize) * Self.pageSize : product

        self.storage = try Storage(
            initialBytes: initialBytes,
            maxBytes: maxBytes,
            isMemory64: memoryType.isMemory64,
            isShared: memoryType.shared,
            engineConfiguration: engineConfiguration
        )

        maxPageCount = maxPages
        limit = memoryType
    }

    #if os(macOS) || os(Linux)
        /// Creates a memory entity for a shared memory backed by pre-allocated `SharedMemoryStorage`.
        init(_ memoryType: MemoryType, sharedStorage: SharedMemoryStorage) {
            precondition(memoryType.shared)
            self.storage = .shared(sharedStorage)
            self.maxPageCount = memoryType.max ?? Self.maxPageCount(isMemory64: memoryType.isMemory64)
            self.limit = memoryType
        }
    #endif

    deinit {
        // Frees the inline `.mprotect`/`.malloc` backing. `.shared` is a no-op: ARC
        // releases the ref-counted backing when `storage` is torn down.
        storage.deallocate()
    }

    var data: UnsafeBufferPointer<UInt8> { storage.data }

    var baseAddress: UnsafeMutableRawPointer? { storage.baseAddress }

    var byteCount: Int { storage.byteCount }

    var boundsCheckLimit: Int { storage.boundsCheckLimit }

    var trapGuardReservationSize: Int { storage.trapGuardReservationSize }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#grow-mem>
    mutating func grow(by pageCount: Int, resourceLimiter: any ResourceLimiter) throws -> Value {
        let oldPages = try storage.grow(by: pageCount, maxPageCount: maxPageCount, resourceLimiter: resourceLimiter)
        guard oldPages >= 0 else {
            return limit.isMemory64 ? .i64((-1 as Int64).unsigned) : .i32((-1 as Int32).unsigned)
        }
        return limit.isMemory64 ? .i64(UInt64(oldPages)) : .i32(UInt32(oldPages))
    }

    mutating func copy(from source: UInt64, to destination: UInt64, count: UInt64) throws {
        let (destinationEnd, destinationOverflow) = destination.addingReportingOverflow(count)
        let (sourceEnd, sourceOverflow) = source.addingReportingOverflow(count)

        let byteCount = byteCount
        guard !destinationOverflow, destinationEnd <= byteCount,
            !sourceOverflow, sourceEnd <= byteCount
        else {
            throw Trap(.memoryOutOfBounds)
        }
        let count = Int(count)
        guard count > 0 else { return }
        guard let baseAddress = baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
        let destination = Int(destination)
        let source = Int(source)
        if destination < source {
            for i in 0..<count {
                baseAddress[destination + i] = baseAddress[source + i]
            }
        } else if destination > source {
            for i in stride(from: count - 1, through: 0, by: -1) {
                baseAddress[destination + i] = baseAddress[source + i]
            }
        }
    }

    mutating func initialize(_ segment: InternalDataSegment, from source: UInt32, to destination: UInt64, count: UInt32) throws {
        let (destinationEnd, destinationOverflow) = destination.addingReportingOverflow(UInt64(count))
        let (sourceEnd, sourceOverflow) = source.addingReportingOverflow(count)

        let byteCount = byteCount
        guard !destinationOverflow, destinationEnd <= byteCount,
            !sourceOverflow, sourceEnd <= segment.data.count
        else {
            throw Trap(.memoryOutOfBounds)
        }
        segment.data.withUnsafeBufferPointer { segment in
            guard
                let memory = baseAddress,
                let segment = UnsafeRawPointer(segment.baseAddress)
            else { return }
            let dest = memory.advanced(by: Int(destination))
            let src = segment.advanced(by: Int(source))
            dest.copyMemory(from: src, byteCount: Int(count))
        }
    }

    mutating func write(offset: Int, bytes: ArraySlice<UInt8>) throws {
        let endOffset = offset + bytes.count
        guard endOffset <= byteCount else {
            throw Trap(.memoryOutOfBounds)
        }
        guard bytes.count > 0 else { return }
        bytes.withUnsafeBufferPointer { source in
            baseAddress!.advanced(by: offset).assumingMemoryBound(to: UInt8.self).update(from: source.baseAddress!, count: bytes.count)
        }
    }

    mutating func fill(offset: Int, value: UInt8, count: Int) throws {
        let endOffset = offset + count
        guard endOffset <= byteCount else {
            throw Trap(.memoryOutOfBounds)
        }
        guard count > 0 else { return }
        baseAddress!.advanced(by: offset).assumingMemoryBound(to: UInt8.self).update(repeating: value, count: count)
    }
}

extension MemoryEntity: ValidatableEntity {
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        WasmKitError(message: .indexOutOfBounds("memory", index, max: count))
    }
}

typealias InternalMemory = EntityHandle<MemoryEntity>

/// A WebAssembly `memory` instance.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#memory-instances>
public struct Memory: Equatable {
    let handle: InternalMemory
    let allocator: StoreAllocator

    init(handle: InternalMemory, allocator: StoreAllocator) {
        self.handle = handle
        self.allocator = allocator
    }

    /// Creates a new WebAssembly `memory` instance with the given type.
    ///
    /// - Parameters:
    ///   - store: The store that to allocate the global instance in.
    ///   - type: The type of the memory instance.
    /// - Throws: `Trap` if the initial and maximum memory size exceeds the resource limit.
    ///
    /// ```swift
    /// import WasmKit
    /// import WAT
    ///
    /// let engine = Engine()
    /// let store = Store(engine: engine)
    /// let memoryType = MemoryType(min: 1, max: nil)
    /// let memory = try Memory(store: store, type: memoryType)
    ///
    /// let module = try parseWasm(
    ///     bytes: try wat2wasm(#"(module (memory (import "env" "memory") 1))"#)
    /// )
    /// let imports: Imports = ["env": ["memory": memory]]
    /// let instance = try module.instantiate(store: store, imports: imports)
    /// ```
    public init(store: Store, type: MemoryType) throws {
        // Validate the memory type because the type is not validated at instantiation time.
        try ModuleValidator.checkMemoryType(type, features: store.engine.configuration.features)

        self.init(
            handle: try store.allocator.allocate(memoryType: type, engineConfiguration: store.engine.configuration, resourceLimiter: store.resourceLimiter),
            allocator: store.allocator
        )
    }

    #if os(macOS) || os(Linux)
        /// Wrap an existing `SharedMemoryStorage` in a new `Memory`, so one shared memory can
        /// be imported into child `Store`s (the `wasi_thread_spawn` path).
        init(store: Store, type: MemoryType, sharedStorage: SharedMemoryStorage) {
            self.init(
                handle: store.allocator.allocate(memoryType: type, sharedStorage: sharedStorage),
                allocator: store.allocator
            )
        }
    #endif

    /// Returns a copy of the memory data.
    @available(*, deprecated, message: "Use `withUnsafeBufferPointer(offset:count:_:)` or `withUnsafeMutableBufferPointer(offset:count:_:)` instead")
    public var data: [UInt8] {
        handle.withValue { Array($0.data) }
    }

    /// The type of the memory instance.
    public var type: MemoryType {
        handle.withValue { $0.limit }
    }

    /// The current size of the memory in bytes.
    public var byteCount: Int {
        handle.withValue { $0.byteCount }
    }
}

extension Memory: GuestMemory {
    /// Executes the given closure with an immutable buffer pointer to the host memory region mapped as guest memory.
    public func withUnsafeBufferPointer<T>(
        offset: UInt,
        count: Int,
        _ body: (UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        return try handle.withValue { memory in
            precondition(Int(offset) + count <= memory.byteCount, "Memory access out of bounds")
            guard let base = memory.baseAddress else {
                preconditionFailure("Memory has no base address")
            }
            let start = base.advanced(by: Int(offset))
            return try body(UnsafeRawBufferPointer(start: UnsafeRawPointer(start), count: count))
        }
    }

    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    public func withUnsafeMutableBufferPointer<T>(
        offset: UInt,
        count: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> T
    ) rethrows -> T {
        return try handle.withValue { memory in
            precondition(Int(offset) + count <= memory.byteCount, "Memory access out of bounds")
            guard let base = memory.baseAddress else {
                preconditionFailure("Memory has no base address")
            }
            let start = base.advanced(by: Int(offset))
            return try body(UnsafeMutableRawBufferPointer(start: start, count: count))
        }
    }
}

/// An entity representing a WebAssembly `global` instance storage.
struct GlobalEntity /* : ~Copyable */ {
    enum Storage {
        case scalar(UntypedValue)
        case v128(V128Storage)
    }

    var storage: Storage
    var value: Value {
        get {
            switch storage {
            case .scalar(let raw):
                return raw.cast(to: globalType.valueType)
            case .v128(let v):
                return .v128(v.value)
            }
        }
        set {
            switch newValue {
            case .v128(let v):
                storage = .v128(V128Storage(v))
            case .i32, .i64, .f32, .f64, .ref:
                storage = .scalar(UntypedValue(newValue))
            }
        }
    }
    let globalType: GlobalType

    init(globalType: GlobalType, initialValue: Value) throws {
        try initialValue.checkType(globalType.valueType)
        switch initialValue {
        case .v128(let v):
            storage = .v128(V128Storage(v))
        case .i32, .i64, .f32, .f64, .ref:
            storage = .scalar(UntypedValue(initialValue))
        }
        self.globalType = globalType
    }
}

extension GlobalEntity: ValidatableEntity {
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        WasmKitError(message: .indexOutOfBounds("global", index, max: count))
    }
}

typealias InternalGlobal = EntityHandle<GlobalEntity>

/// A WebAssembly `global` instance.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#global-instances>
public struct Global: Equatable {
    let handle: InternalGlobal
    let allocator: StoreAllocator

    /// The value of the global instance.
    public var value: Value {
        handle.value
    }

    /// Assigns a new value to the global instance.
    ///
    /// - Parameter value: The new value to assign.
    /// - Throws: `Trap` if the global is immutable.
    public func assign(_ value: Value) throws {
        try handle.withValue { global in
            guard global.globalType.mutability == .variable else {
                throw Trap(.cannotAssignToImmutableGlobal)
            }
            try value.checkType(global.globalType.valueType)
            global.value = value
        }
    }

    init(handle: InternalGlobal, allocator: StoreAllocator) {
        self.handle = handle
        self.allocator = allocator
    }

    /// Initializes a new global instance with the given type and initial value.
    /// The returned global instance may be used to instantiate a new
    /// WebAssembly module.
    @available(*, deprecated, renamed: "init(store:type:value:)")
    public init(globalType: GlobalType, initialValue: Value, store: Store) {
        try! self.init(store: store, type: globalType, value: initialValue)
    }

    /// Create a new WebAssembly `global` instance.
    ///
    /// - Parameters:
    ///   - store: The store that to allocate the global instance in.
    ///   - type: The type of the global instance.
    ///   - value: Initial value of the global instance.
    /// - Throws: `Trap` if the initial value does not match the global type.
    ///
    /// ```swift
    /// import WasmKit
    /// import WAT
    ///
    /// let engine = Engine()
    /// let store = Store(engine: engine)
    /// let globalType = GlobalType(mutability: .constant, valueType: .i32)
    /// let i32Global = try Global(store: store, type: globalType, value: .i32(42))
    ///
    /// let module = try parseWasm(
    ///     bytes: try wat2wasm(#"(module (global (import "env" "i32-global") i32))"#)
    /// )
    /// let imports: Imports = ["env": ["i32-global": i32Global]]
    /// let instance = try module.instantiate(store: store, imports: imports)
    /// ```
    public init(store: Store, type: GlobalType, value: Value) throws {
        let handle = try store.allocator.allocate(globalType: type, initialValue: value)
        self.init(handle: handle, allocator: store.allocator)
    }
}

/// A WebAssembly `tag` instance.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-taginst>
public struct Tag: Equatable {
    let handle: InternalTag
    let allocator: StoreAllocator

    init(handle: InternalTag, allocator: StoreAllocator) {
        self.handle = handle
        self.allocator = allocator
    }

    /// Create a new WebAssembly `tag` instance.
    ///
    /// - Parameters:
    ///   - store: The store to allocate the tag instance in.
    ///   - type: The function type describing the tag's parameters.
    public init(store: Store, type: FunctionType) {
        let handle = store.allocator.allocate(tagType: type, engine: store.engine)
        self.init(handle: handle, allocator: store.allocator)
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#element-instances>
struct ElementSegmentEntity {
    let type: ReferenceType
    var references: [Reference]

    mutating func drop() {
        self.references = []
    }
}

extension ElementSegmentEntity: ValidatableEntity {
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        WasmKitError(message: .indexOutOfBounds("element", index, max: count))
    }
}

typealias InternalElementSegment = EntityHandle<ElementSegmentEntity>

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-datainst>
struct DataSegmentEntity {
    /// Bytes stored in this data instance.
    let data: ArraySlice<UInt8>

    mutating func drop() {
        self = DataSegmentEntity(data: [])
    }
}

typealias InternalDataSegment = EntityHandle<DataSegmentEntity>

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-taginst>
struct TagEntity {
    let type: InternedFuncType
}

extension TagEntity: ValidatableEntity {
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        WasmKitError(message: .indexOutOfBounds("tag", index, max: count))
    }
}

typealias InternalTag = EntityHandle<TagEntity>

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-externval>
public enum ExternalValue: Equatable {
    case function(Function)
    case table(Table)
    case memory(Memory)
    case global(Global)
    case tag(Tag)

    init(handle: InternalExternalValue, store: Store) {
        switch handle {
        case .function(let function):
            self = .function(Function(handle: function, store: store))
        case .table(let table):
            self = .table(Table(handle: table, allocator: store.allocator))
        case .memory(let memory):
            self = .memory(Memory(handle: memory, allocator: store.allocator))
        case .global(let global):
            self = .global(Global(handle: global, allocator: store.allocator))
        case .tag(let tag):
            self = .tag(Tag(handle: tag, allocator: store.allocator))
        }
    }

    func internalize() -> (InternalExternalValue, StoreAllocator) {
        switch self {
        case .function(let function):
            return (.function(function.handle), function.store.allocator)
        case .table(let table):
            return (.table(table.handle), table.allocator)
        case .memory(let memory):
            return (.memory(memory.handle), memory.allocator)
        case .global(let global):
            return (.global(global.handle), global.allocator)
        case .tag(let tag):
            return (.tag(tag.handle), tag.allocator)
        }
    }
}

enum InternalExternalValue {
    case function(InternalFunction)
    case table(InternalTable)
    case memory(InternalMemory)
    case global(InternalGlobal)
    case tag(InternalTag)
}
