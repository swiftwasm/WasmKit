/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#value-types>
public class Value: Equatable, Hashable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    required init() {
        precondition(type(of: self) != Value.self, "Subclasses of Value have to be used")
    }

    public func hash(into _: inout Hasher) {
        preconditionFailure("Subclasses of Value must override `hash(into:)`")
    }
}

public typealias ValueType = Value.Type

// Integers
/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#integers>

public protocol RawUnsignedInteger: FixedWidthInteger & UnsignedInteger {
    associatedtype Signed: RawSignedInteger where Signed.Unsigned == Self
}

public protocol RawSignedInteger: FixedWidthInteger & SignedInteger {
    associatedtype Unsigned: RawUnsignedInteger
    init(bitPattern: Unsigned)
}

extension UInt32: RawUnsignedInteger {
    public typealias Signed = Int32
}

extension UInt64: RawUnsignedInteger {
    public typealias Signed = Int64
}

extension Int32: RawSignedInteger {}
extension Int64: RawSignedInteger {}

extension RawUnsignedInteger {
    var signed: Signed {
        return self > Signed.max ? -Signed(Self.max - self) - 1 : Signed(self)
    }
}

extension RawSignedInteger {
    var unsigned: Unsigned {
        return self < 0 ? Unsigned.max - Unsigned(-(self + 1)) : Unsigned(self)
    }
}

// Floating-Point
/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#floating-point>

typealias RawFloatingPoint = BinaryFloatingPoint

public protocol RawRepresentableValue where Self: Value {
    associatedtype RawValue

    var rawValue: RawValue { get }

    init(_ rawValue: RawValue)
}

public final class I32: Value, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: UInt32

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

public final class I64: Value, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: UInt64

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

public final class F32: Value, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: Float32

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: Float32) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

public final class F64: Value, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: Float64

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: Float64) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

extension RawRepresentableValue where Self: Value, RawValue: RawUnsignedInteger {
    var signed: RawValue.Signed {
        return rawValue.signed
    }

    public init(_ value: RawValue.Signed) {
        let rawValue: RawValue
        if value < 0 {
            rawValue = RawValue(~value)
        } else {
            rawValue = RawValue(value)
        }
        self.init(rawValue)
    }

    public static func == (lhs: Self, rhs: RawValue) -> Bool {
        return lhs.rawValue == rhs
    }

    public static func != (lhs: Self, rhs: RawValue) -> Bool {
        return lhs.rawValue != rhs
    }
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
