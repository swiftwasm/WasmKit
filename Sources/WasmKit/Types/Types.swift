/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#result-types>
public enum ResultType: Equatable {
    /// Single type encoded directly.
    case single(ValueType)
    /// A tuple of multiple types encoded in the type section where it can be looked up
    /// with a given `typeIndex`.
    case multi(typeIndex: UInt8)
    /// Empty result type
    case empty

    func arity(typeSection: () -> [FunctionType]) -> (parameters: Int, results: Int) {
        switch self {
        case .single:
            return (0, 1)
        case .empty:
            return (0, 0)
        case let .multi(typeIndex):
            let funcType = typeSection()[Int(typeIndex)]
            return (funcType.parameters.count, funcType.results.count)
        }
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#function-types>
public struct FunctionType: Equatable {
    public init(parameters: [ValueType], results: [ValueType] = []) {
        self.parameters = parameters
        self.results = results
    }

    public let parameters: [ValueType]
    public let results: [ValueType]
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#limits>
public struct Limits: Equatable {
    public let min: UInt64
    public let max: UInt64?
    public let isMemory64: Bool

    public init(min: UInt64, max: UInt64?, isMemory64: Bool = false) {
        self.min = min
        self.max = max
        self.isMemory64 = isMemory64
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#memory-types>
public typealias MemoryType = Limits

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#table-types>
public struct TableType: Equatable {
    public let elementType: ReferenceType
    public let limits: Limits
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public enum Mutability: Equatable {
    case constant
    case variable
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#global-types>
public struct GlobalType: Equatable {
    public let mutability: Mutability
    public let valueType: ValueType
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#external-types>
public enum ExternalType {
    case function(FunctionType)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}
