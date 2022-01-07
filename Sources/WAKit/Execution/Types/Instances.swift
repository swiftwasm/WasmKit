/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#module-instances>
// sourcery: AutoEquatable
public final class ModuleInstance {
    var types: [FunctionType] = []
    var functionAddresses: [FunctionAddress] = []
    var tableAddresses: [TableAddress] = []
    var memoryAddresses: [MemoryAddress] = []
    var globalAddresses: [GlobalAddress] = []
    var exportInstances: [ExportInstance] = []

    public var exports: [String: ExternalValue] {
        return exportInstances.reduce(into: [:]) { exports, export in
            exports[export.name] = export.value
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#function-instances>
final class FunctionInstance {
    let type: FunctionType
    let module: ModuleInstance
    let code: Function

    init(_ function: Function, module: ModuleInstance) {
        type = module.types[Int(function.type)]
        self.module = module
        code = function
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#table-instances>
final class TableInstance {
    var elements: [FunctionAddress?]
    let max: UInt32?

    init(_ tableType: TableType) {
        elements = Array(repeating: nil, count: Int(tableType.limits.min))
        max = tableType.limits.max
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#memory-instances>
final class MemoryInstance {
    private static let pageSize = 64 * 1024

    var data: [UInt8]
    let max: UInt32?

    init(_ memoryType: MemoryType) {
        data = Array(repeating: 0, count: Int(memoryType.min) * MemoryInstance.pageSize)
        max = memoryType.max
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#global-instances>
final class GlobalInstance {
    var value: Value
    let mutability: Mutability

    init(globalType: GlobalType, initialValue: Value) {
        value = initialValue
        mutability = globalType.mutability
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#syntax-externval>
public enum ExternalValue: Equatable {
    case function(FunctionAddress)
    case table(TableAddress)
    case memory(MemoryAddress)
    case global(GlobalAddress)
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#export-instances>
// sourcery: AutoEquatable
final class ExportInstance {
    let name: String
    let value: ExternalValue

    init(_ export: Export, moduleInstance: ModuleInstance) {
        name = export.name
        switch export.descriptor {
        case let .function(index):
            value = ExternalValue.function(moduleInstance.functionAddresses[Int(index)])
        case let .table(index):
            value = ExternalValue.table(moduleInstance.tableAddresses[Int(index)])
        case let .memory(index):
            value = ExternalValue.memory(moduleInstance.memoryAddresses[Int(index)])
        case let .global(index):
            value = ExternalValue.global(moduleInstance.globalAddresses[Int(index)])
        }
    }
}
