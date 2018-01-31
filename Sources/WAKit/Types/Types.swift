// https://webassembly.github.io/spec/syntax/types.html#value-types
protocol Value {}
struct AnyValue: Value {}

protocol IntegerValue: Value {}
extension Int32: IntegerValue {}
extension Int64: IntegerValue {}

protocol FloatingPointValue: Value {}
extension Float32: FloatingPointValue {}
extension Float64: FloatingPointValue {}

extension Array where Element == Value.Type {
    static func == (lhs: [Value.Type], rhs: [Value.Type]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(true) { result, zipped in
            result && zipped.0 == zipped.1
        }
    }

    static func != (lhs: [Value.Type], rhs: [Value.Type]) -> Bool {
        return !(lhs == rhs)
    }
}

// https://webassembly.github.io/spec/syntax/types.html#result-types
typealias ResultType = [Value.Type]

// https://webassembly.github.io/spec/syntax/types.html#function-types
public struct FunctionType {
    let parameters: [Value.Type]
    let results: [Value.Type]

    static let any = FunctionType(parameters: [AnyValue.self], results: [AnyValue.self])
}

extension FunctionType: AutoEquatable {}

// https://webassembly.github.io/spec/syntax/types.html#limits
public struct Limits {
    let min: UInt32
    let max: UInt32?
}

extension Limits: AutoEquatable {}

// https://webassembly.github.io/spec/syntax/types.html#memory-types
public typealias MemoryType = Limits

// https://webassembly.github.io/spec/syntax/types.html#table-types
public struct TableType {
    let elementType: FunctionType
    let limits: Limits
}

extension TableType: AutoEquatable {}

// https://webassembly.github.io/spec/syntax/types.html#global-types
public enum Mutability {
    case constant
    case variable
}

// https://webassembly.github.io/spec/syntax/types.html#global-types
public struct GlobalType {
    let mutability: Mutability?
    let valueType: Value.Type
}

extension GlobalType: AutoEquatable {}

// https://webassembly.github.io/spec/syntax/types.html#external-types
public enum ExternalType {
    case function(FunctionType)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}

extension ExternalType: AutoEquatable {}
