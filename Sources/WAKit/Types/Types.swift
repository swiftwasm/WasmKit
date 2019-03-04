/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#value-types>
public class Value: Equatable {
    internal required init() {
        precondition(type(of: self) != Value.self, "\(Value.self) itself shouldn't be initialized")
    }

    public static func == (lhs: Value, rhs: Value) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func isEqual(to _: Value) -> Bool {
        preconditionFailure("Subclasses of \(Value.self) must override `isEqual:` method")
    }
}

extension RawRepresentable where Self: Value {
    public init(_ value: Self.RawValue) {
        self.init(rawValue: value)!
    }
}

public typealias IntValueType = Value.Int.Type
public protocol IntValue: RawRepresentable where Self: Value, RawValue: UnsignedInteger & FixedWidthInteger {}

extension Value {
    public class Int: Value {
        internal required init() {
            super.init()
            precondition(type(of: self) != Int.self, "\(Int.self) itself shouldn't be initialized")
        }

        override func isEqual(to _: Value) -> Bool {
            preconditionFailure("Subclasses of \(Int.self) must override `isEqual:` method")
        }
    }

    public class Int32: Int, IntValue {
        public let rawValue: Swift.UInt32

        public required init() {
            rawValue = 0
        }

        public required init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public convenience init(_ value: Swift.Int32) {
            self.init(rawValue: UInt32(bitPattern: value))
        }

        public override func isEqual(to value: Value) -> Bool {
            guard let value = value as? Value.Int32 else { return false }
            return rawValue == value.rawValue
        }
    }

    public class Int64: Int, IntValue {
        public let rawValue: Swift.UInt64

        public required init() {
            rawValue = 0
        }

        public required init(rawValue: UInt64) {
            self.rawValue = rawValue
        }

        public convenience init(_ value: Swift.Int64) {
            self.init(rawValue: UInt64(bitPattern: value))
        }

        public override func isEqual(to value: Value) -> Bool {
            guard let value = value as? Value.Int64 else { return false }
            return rawValue == value.rawValue
        }
    }
}

extension Value.Int32: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self))(\(rawValue)))"
    }
}

extension Value.Int64: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self))(\(rawValue)))"
    }
}

public typealias FloatValueType = Value.Float.Type
public protocol FloatValue: RawRepresentable where Self: Value, RawValue: BinaryFloatingPoint {}

extension Value {
    public class Float: Value {
        internal required init() {
            super.init()
            precondition(type(of: self) != Float.self, "\(Float.self) itself shouldn't be initialized")
        }

        override func isEqual(to _: Value) -> Bool {
            preconditionFailure("Subclasses of \(Float.self) must override `isEqual:` method")
        }
    }

    public final class Float32: Float, FloatValue {
        public let rawValue: Swift.Float32

        public required init() {
            rawValue = 0
        }

        public required init(rawValue: Swift.Float32) {
            self.rawValue = rawValue
        }

        public override func isEqual(to value: Value) -> Bool {
            guard let value = value as? Value.Float32 else { return false }
            return rawValue == value.rawValue
        }
    }

    public final class Float64: Float, FloatValue {
        public let rawValue: Swift.Float64

        public required init() {
            rawValue = 0
        }

        public required init(rawValue: Swift.Float64) {
            self.rawValue = rawValue
        }

        public override func isEqual(to value: Value) -> Bool {
            guard let value = value as? Value.Float64 else { return false }
            return rawValue == value.rawValue
        }
    }
}

extension Value.Float32: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self))(\(rawValue)))"
    }
}

extension Value.Float64: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self))(\(rawValue)))"
    }
}

public typealias ValueType = Value.Type

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

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#result-types>
typealias ResultType = [ValueType]

/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#function-types>
// sourcery: AutoEquatable
public enum FunctionType {
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
// sourcery: AutoEquatable
public struct TableType {
    let elementType: FunctionType
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
