// https://webassembly.github.io/spec/syntax/types.html#value-types
enum Value: Equatable {
    case i32(Int32)
    case i64(Int64)
    case f32(Float32)
    case f64(Float64)
}

enum ValueType: Equatable {
    case i32
    case i64
    case f32
    case f64
}

extension Array where Element == ValueType {
    static func == (lhs: [ValueType], rhs: [ValueType]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(true) { result, zipped in
            result && zipped.0 == zipped.1
        }
    }

    static func != (lhs: [ValueType], rhs: [ValueType]) -> Bool {
        return !(lhs == rhs)
    }
}

// https://webassembly.github.io/spec/syntax/types.html#result-types
typealias ResultType = [ValueType]

// https://webassembly.github.io/spec/syntax/types.html#function-types
public struct FunctionType {
    let parameters: [ValueType]?
    let results: [ValueType]?

    static let any = FunctionType(parameters: nil, results: nil)
}

extension FunctionType: Equatable {}

// https://webassembly.github.io/spec/syntax/types.html#limits
public struct Limits {
    let min: UInt32
    let max: UInt32?
}

extension Limits: Equatable {}

// https://webassembly.github.io/spec/syntax/types.html#memory-types
public typealias MemoryType = Limits

// https://webassembly.github.io/spec/syntax/types.html#table-types
public struct TableType {
    let elementType: FunctionType
    let limits: Limits
}

extension TableType: Equatable {}

// https://webassembly.github.io/spec/syntax/types.html#global-types
public enum Mutability {
    case constant
    case variable
}

// https://webassembly.github.io/spec/syntax/types.html#global-types
public struct GlobalType {
    let mutability: Mutability?
    let valueType: ValueType
}

extension GlobalType: Equatable {}

// https://webassembly.github.io/spec/syntax/types.html#external-types
public enum ExternalType {
    case function(FunctionType)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}

extension ExternalType: Equatable {}
