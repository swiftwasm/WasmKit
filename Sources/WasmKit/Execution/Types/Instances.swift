import WasmParser

@dynamicMemberLookup
struct EntityHandle<T>: Equatable, Hashable {
    private let pointer: UnsafeMutablePointer<T>

    init(unsafe pointer: UnsafeMutablePointer<T>) {
        self.pointer = pointer
    }

    subscript<R>(dynamicMember keyPath: KeyPath<T, R>) -> R {
        pointer.pointee[keyPath: keyPath]
    }

    @inline(__always)
    func withValue<R>(_ body: (inout T) throws -> R) rethrows -> R {
        return try body(&pointer.pointee)
    }

    var bitPattern: Int {
        return Int(bitPattern: pointer)
    }
}

struct ImmutableBumpPtrVector<T> {
    private let buffer: UnsafeMutableBufferPointer<T>
    init(buffer: UnsafeMutableBufferPointer<T>) {
        self.buffer = buffer
    }

    subscript(index: Int) -> T {
        buffer[index]
    }

    var first: T? { buffer.first }
    var count: Int { buffer.count }
}

struct InstanceEntity /* : ~Copyable */ {
    var types: [FunctionType]
    var functions: ImmutableBumpPtrVector<InternalFunction>
    var tables: ImmutableBumpPtrVector<InternalTable>
    var memories: ImmutableBumpPtrVector<InternalMemory>
    var globals: ImmutableBumpPtrVector<InternalGlobal>
    var elementSegments: ImmutableBumpPtrVector<InternalElementSegment>
    var dataSegments: ImmutableBumpPtrVector<InternalDataSegment>
    var exports: [Export]
    var features: WasmFeatureSet
    var hasDataCount: Bool
}

typealias InternalInstance = EntityHandle<InstanceEntity>

/// A stateful instance of a WebAssembly module.
/// Usually instantiated by ``Runtime/instantiate(module:name:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#module-instances>
public struct Instance {
    let handle: InternalInstance
    let allocator: StoreAllocator

    init(handle: InternalInstance, allocator: StoreAllocator) {
        self.handle = handle
        self.allocator = allocator
    }

    public func export(_ name: String) -> ExternalValue? {
        guard let export = handle.exports.first(where: { $0.name == name }) else {
            return nil
        }
        return ExternalValue(export, instance: handle, allocator: allocator)
    }

    /// Finds an exported function by name.
    ///
    /// - Parameter name: The name of the exported function.
    /// - Returns: The address of the exported function if found, otherwise `nil`.
    func exportedFunction(name: String) -> Function? {
        guard case .function(let function) = self.export(name) else { return nil }
        return function
    }

    public typealias Exports = [String: ExternalValue]

    public var exports: Exports {
        handle.exports.reduce(into: [:]) { exports, export in
            exports[export.name] = ExternalValue(export, instance: handle, allocator: allocator)
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

@available(*, deprecated, renamed: "Instance")
public typealias ModuleInstance = Instance

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#table-instances>
struct TableEntity /* : ~Copyable */ {
    public internal(set) var elements: [Reference]
    let tableType: TableType
    public var limits: Limits { tableType.limits }

    init(_ tableType: TableType) {
        let emptyElement: Reference
        switch tableType.elementType {
        case .funcRef:
            emptyElement = .function(nil)
        case .externRef:
            emptyElement = .extern(nil)
        }

        elements = Array(repeating: emptyElement, count: Int(tableType.limits.min))
        self.tableType = tableType
    }

    /// > Note: https://webassembly.github.io/spec/core/exec/modules.html#grow-table
    /// Returns true if gorwth succeeds, otherwise returns false
    mutating func grow(by growthSize: UInt64, value: Reference) -> Bool {
        let oldSize = UInt64(elements.count)
        guard !UInt64(elements.count).addingReportingOverflow(growthSize).overflow else {
            return false
        }

        let maxLimit = limits.max ?? (limits.isMemory64 ? UInt64.max : UInt64(UInt32.max))

        let newSize = oldSize + growthSize
        if newSize > maxLimit {
            return false
        }
        elements.append(contentsOf: Array(repeating: value, count: Int(growthSize)))
        return true
    }

    mutating func initialize(elements source: [Reference], from fromIndex: Int, to toIndex: Int, count: Int) throws {
        guard count > 0 else { return }

        guard !fromIndex.addingReportingOverflow(count).overflow,
              !toIndex.addingReportingOverflow(count).overflow
        else {
            throw Trap.tableSizeOverflow
        }

        guard fromIndex + count <= source.count else {
            throw Trap.outOfBoundsTableAccess(fromIndex + count)
        }
        guard toIndex + count <= self.elements.count else {
            throw Trap.outOfBoundsTableAccess(toIndex + count)
        }
        elements[toIndex..<(toIndex + count)] = source[fromIndex..<fromIndex + count]
    }
}

typealias InternalTable = EntityHandle<TableEntity>

public struct Table: Equatable {
    let handle: InternalTable
    let allocator: StoreAllocator
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#memory-instances>
struct MemoryEntity /* : ~Copyable */ {
    static let pageSize = 64 * 1024

    public var data: [UInt8]
    let maxPageCount: UInt64
    let limit: Limits

    init(_ memoryType: MemoryType) {
        data = Array(repeating: 0, count: Int(memoryType.min) * Self.pageSize)
        let defaultMaxPageCount = (memoryType.isMemory64 ? UInt64.max : UInt64(UInt32.max)) / UInt64(Self.pageSize)
        maxPageCount = memoryType.max ?? defaultMaxPageCount
        limit = memoryType
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#grow-mem>
    mutating func grow(by pageCount: Int) -> Value {
        let newPageCount = data.count / Self.pageSize + pageCount

        guard newPageCount <= maxPageCount else {
            return limit.isMemory64 ? .i64((-1 as Int64).unsigned) : .i32((-1 as Int32).unsigned)
        }

        let result = Int32(data.count / MemoryEntity.pageSize).unsigned
        data.append(contentsOf: Array(repeating: 0, count: Int(pageCount) * MemoryEntity.pageSize))

        return limit.isMemory64 ? .i64(UInt64(result)) : .i32(result)
    }

    mutating func write(offset: Int, bytes: ArraySlice<UInt8>) throws {
        let endOffset = offset + bytes.count
        guard endOffset <= data.count else {
            throw Trap.outOfBoundsMemoryAccess
        }
        data[offset..<endOffset] = bytes
    }

    public subscript(i32 address: UInt32) -> UInt32 {
        get {
            .init(littleEndian: data[Int(address)..<Int(address + 4)])
        }
        set {
            data[Int(address)..<Int(address + 4)] = ArraySlice(newValue.littleEndianBytes)
        }
    }

    public subscript(i64 address: UInt32) -> UInt64 {
        .init(littleEndian: data[Int(address)..<Int(address + 8)])
    }

    public subscript(bytes count: UInt32, at address: UInt32) -> ArraySlice<UInt8> {
        get {
            data[Int(address)..<Int(address + count)]
        }
        set {
            data[Int(address)..<Int(address + count)] = newValue
        }
    }
}

typealias InternalMemory = EntityHandle<MemoryEntity>

public struct Memory: Equatable {
    let handle: InternalMemory
    let allocator: StoreAllocator
}

extension Memory: GuestMemory {
    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    public func withUnsafeMutableBufferPointer<T>(
        offset: UInt,
        count: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> T
    ) rethrows -> T {
        try handle.withValue { memory in
            try memory.data.withUnsafeMutableBufferPointer { buffer in
                try body(UnsafeMutableRawBufferPointer(start: buffer.baseAddress! + Int(offset), count: count))
            }
        }
    }
}

/// Instance of a global
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#global-instances>
struct GlobalEntity {
    public internal(set) var value: Value
    public let globalType: GlobalType

    init(globalType: GlobalType, initialValue: Value) {
        value = initialValue
        self.globalType = globalType
    }

    mutating func assign(_ value: UntypedValue) {
        self.value = value.cast(to: globalType.valueType)
    }
}

typealias InternalGlobal = EntityHandle<GlobalEntity>

public struct Global: Equatable {
    let handle: InternalGlobal
    let allocator: StoreAllocator

    var value: Value {
        return handle.value
    }

    init(handle: InternalGlobal, allocator: StoreAllocator) {
        self.handle = handle
        self.allocator = allocator
    }

    public init(globalType: GlobalType, initialValue: Value, store: Store) {
        let handle = store.allocator.allocate(globalType: globalType, initialValue: initialValue)
        self.init(handle: handle, allocator: store.allocator)
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#element-instances>
struct ElementSegmentEntity {
    public let type: ReferenceType
    public var references: [Reference]

    mutating func drop() {
        self.references = []
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
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-externval>
public enum ExternalValue: Equatable {
    case function(Function)
    case table(Table)
    case memory(Memory)
    case global(Global)

    init(_ export: WasmParser.Export, instance: InternalInstance, allocator: StoreAllocator) {
        switch export.descriptor {
        case let .function(index):
            self = .function(
                Function(handle: instance.functions[Int(index)], allocator: allocator)
            )
        case let .table(index):
            self = .table(
                Table(handle: instance.tables[Int(index)], allocator: allocator)
            )
        case let .memory(index):
            self = .memory(
                Memory(handle: instance.memories[Int(index)], allocator: allocator)
            )
        case let .global(index):
            self = .global(
                Global(handle: instance.globals[Int(index)], allocator: allocator)
            )
        }
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#export-instances>
public struct ExportInstance: Equatable {
    public let name: String
    public let value: ExternalValue

    init(_ export: WasmParser.Export, instance: InternalInstance, allocator: StoreAllocator) {
        name = export.name
        value = .init(export, instance: instance, allocator: allocator)
    }
}
