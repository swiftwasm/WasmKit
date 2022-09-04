/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#result-types>
typealias ResultType = [ValueType]

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#function-types>
public enum FunctionType: Equatable {
    case any
    case some(parameters: [ValueType], results: [ValueType])
}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#limits>
public struct Limits {
    let min: UInt32
    let max: UInt32?
}

extension Limits: Equatable {}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#memory-types>
public typealias MemoryType = Limits

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#table-types>
public struct TableType: Equatable {
    let elementType: FunctionType
    let limits: Limits
}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public enum Mutability: Equatable {
    case constant
    case variable
}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public struct GlobalType: Equatable {
    let mutability: Mutability
    let valueType: ValueType
}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#external-types>
// sourcery: AutoEquatable
public enum ExternalType {
    case function(FunctionType)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}
