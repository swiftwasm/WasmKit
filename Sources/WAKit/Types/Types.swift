/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#result-types>
typealias ResultType = [ValueType]

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#function-types>
// sourcery: AutoEquatable
public struct FunctionType {
    let parameters: [ValueType]
    let results: [ValueType]
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
// sourcery: AutoEquatable
public struct TableType {
    let limits: Limits
}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public enum Mutability {
    case constant
    case variable
}

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
// sourcery: AutoEquatable
public struct GlobalType {
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
