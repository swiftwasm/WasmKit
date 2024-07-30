import WasmParser

/// A stateful runtime representation of a ``Module``.
/// Usually instantiated by ``Runtime/instantiate(module:name:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#module-instances>
public final class ModuleInstance {
    public internal(set) var types: [FunctionType] = []
    var functionAddresses: [FunctionAddress] = []
    public internal(set) var tableAddresses: [TableAddress] = []
    public internal(set) var memoryAddresses: [MemoryAddress] = []
    public internal(set) var globalAddresses: [GlobalAddress] = []
    public internal(set) var elementAddresses: [ElementAddress] = []
    public internal(set) var dataAddresses: [DataAddress] = []
    public internal(set) var exportInstances: [ExportInstance] = []
    internal let selfAddress: ModuleAddress

    init(selfAddress: ModuleAddress) {
        self.selfAddress = selfAddress
    }

    public typealias Exports = [String: ExternalValue]

    public var exports: Exports {
        exportInstances.reduce(into: [:]) { exports, export in
            exports[export.name] = export.value
        }
    }

    /// Finds an exported function by name.
    ///
    /// - Parameter name: The name of the exported function.
    /// - Returns: The address of the exported function if found, otherwise `nil`.
    func exportedFunction(name: String) -> Function? {
        switch exports[name] {
        case .function(let function): return function
        default: return nil
        }
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#function-instances>
public struct FunctionInstance {
    public let type: FunctionType
    let module: ModuleAddress
    var code: GuestFunction

    init(_ function: GuestFunction, module: ModuleInstance) {
        self.init(function, module: module.selfAddress, type: module.types[Int(function.type)])
    }

    init(_ function: GuestFunction, module: ModuleAddress, type: FunctionType) {
        self.type = type
        self.module = module
        code = function
    }

    internal static func stackRegBase(type: FunctionType, nonParamLocals: Int) -> Instruction.Register {
        Instruction.Register(
            max(type.parameters.count, type.results.count) + nonParamLocals
        )
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#table-instances>
public struct TableInstance {
    public internal(set) var elements: [Reference?]
    public let limits: Limits

    init(_ tableType: TableType) {
        let emptyElement: Reference
        switch tableType.elementType {
        case .funcRef:
            emptyElement = .function(nil)
        case .externRef:
            emptyElement = .extern(nil)
        }

        elements = Array(repeating: emptyElement, count: Int(tableType.limits.min))
        limits = tableType.limits
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
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#memory-instances>
public struct MemoryInstance {
    static let pageSize = 64 * 1024

    public var data: [UInt8]
    let maxPageCount: UInt64
    let limit: Limits

    init(_ memoryType: MemoryType) {
        data = Array(repeating: 0, count: Int(memoryType.min) * MemoryInstance.pageSize)
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

        let result = Int32(data.count / MemoryInstance.pageSize).unsigned
        data.append(contentsOf: Array(repeating: 0, count: Int(pageCount) * MemoryInstance.pageSize))

        return limit.isMemory64 ? .i64(UInt64(result)) : .i32(result)
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

/// Instance of a global
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#global-instances>
public struct GlobalInstance {
    public internal(set) var value: Value
    public let globalType: GlobalType

    init(globalType: GlobalType, initialValue: Value) {
        value = initialValue
        self.globalType = globalType
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#element-instances>
struct ElementInstance {
    public let type: ReferenceType
    public var references: [Reference]

    mutating func drop() {
        self.references = []
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-datainst>
struct DataInstance {
    /// Bytes stored in this data instance.
    let data: [UInt8]
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-externval>
public enum ExternalValue: Equatable {
    case function(Function)
    case table(TableAddress)
    case memory(MemoryAddress)
    case global(GlobalAddress)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#export-instances>
public struct ExportInstance: Equatable {
    public let name: String
    public let value: ExternalValue

    init(_ export: Export, moduleInstance: ModuleInstance) {
        name = export.name
        switch export.descriptor {
        case let .function(index):
            value = ExternalValue.function(
                Function(address: moduleInstance.functionAddresses[Int(index)])
            )
        case let .table(index):
            value = ExternalValue.table(moduleInstance.tableAddresses[Int(index)])
        case let .memory(index):
            value = ExternalValue.memory(moduleInstance.memoryAddresses[Int(index)])
        case let .global(index):
            value = ExternalValue.global(moduleInstance.globalAddresses[Int(index)])
        }
    }
}
