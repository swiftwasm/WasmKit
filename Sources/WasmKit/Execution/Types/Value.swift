import enum WasmParser.ReferenceType
import enum WasmParser.ValueType

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#value-types>

/// Numeric types
enum NumericType: Equatable {
    /// Integer value type.
    case int(IntValueType)
    /// Floating-point value type.
    case float(FloatValueType)

    /// 32-bit signed or unsigned integer.
    static let i32: Self = .int(.i32)
    /// 64-bit signed or unsigned integer.
    static let i64: Self = .int(.i64)
    /// 32-bit IEEE 754 floating-point number.
    static let f32: Self = .float(.f32)
    /// 64-bit IEEE 754 floating-point number.
    static let f64: Self = .float(.f64)
}

extension WasmParser.ValueType {
    var defaultValue: Value {
        switch self {
        case .i32: return .i32(0)
        case .i64: return .i64(0)
        case .f32: return .f32(0)
        case .f64: return .f64(0)
        case .ref(.externRef):
            return .ref(.extern(nil))
        case .ref(.funcRef):
            return .ref(.function(nil))
        }
    }

    var float: FloatValueType {
        switch self {
        case .f32: return .f32
        case .f64: return .f64
        default:
            fatalError("unexpected value type \(self)")
        }
    }
    var bitWidth: Int? {
        switch self {
        case .i32, .f32: return 32
        case .i64, .f64: return 64
        case .ref: return nil
        }
    }
}

public typealias ReferenceType = WasmParser.ReferenceType

extension Value {
    var type: WasmParser.ValueType {
        switch self {
        case .i32:
            return .i32
        case .i64:
            return .i64
        case .f32:
            return .f32
        case .f64:
            return .f64
        case .ref(.function):
            return .ref(.funcRef)
        case .ref(.extern):
            return .ref(.externRef)
        }
    }

    init<V: RawUnsignedInteger>(_ rawValue: V) {
        switch rawValue {
        case let value as UInt32:
            self = .i32(value)
        case let value as UInt64:
            self = .i64(value)
        default:
            fatalError("unknown raw integer type \(Swift.type(of: rawValue)) passed to `Value.init` ")
        }
    }

    func asAddressOffset(_ isMemory64: Bool) -> UInt64 {
        return isMemory64 ? i64 : UInt64(i32)
    }

    /// Returns if the given values are equal.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            return lhs == rhs
        case let (.i64(lhs), .i64(rhs)):
            return lhs == rhs
        case let (.f32(lhs), .f32(rhs)):
            return Float32(bitPattern: lhs) == Float32(bitPattern: rhs)
        case let (.f64(lhs), .f64(rhs)):
            return Float64(bitPattern: lhs) == Float64(bitPattern: rhs)
        case let (.ref(.extern(lhs)), .ref(.extern(rhs))):
            return lhs == rhs
        case let (.ref(.function(lhs)), .ref(.function(rhs))):
            return lhs == rhs
        default:
            return false
        }
    }

    static func isBitwiseEqual(_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            return lhs == rhs
        case let (.i64(lhs), .i64(rhs)):
            return lhs == rhs
        case let (.f32(lhs), .f32(rhs)):
            return lhs == rhs
        case let (.f64(lhs), .f64(rhs)):
            return lhs == rhs
        case let (.ref(.extern(lhs)), .ref(.extern(rhs))):
            return lhs == rhs
        case let (.ref(.function(lhs)), .ref(.function(rhs))):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension Value: Comparable {
    /// Returns if the left value is less than the right value.
    /// - Precondition: The values are of the same type.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return lhs < rhs
        case let (.i64(lhs), .i64(rhs)): return lhs < rhs
        case let (.f32(lhs), .f32(rhs)): return Float32(bitPattern: lhs) < Float32(bitPattern: rhs)
        case let (.f64(lhs), .f64(rhs)): return Float64(bitPattern: lhs) < Float64(bitPattern: rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value: Comparable` implementation")
        }
    }

    /// Returns if the left value is greater than the right value.
    /// - Precondition: The values are of the same type.
    public static func > (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return lhs > rhs
        case let (.i64(lhs), .i64(rhs)): return lhs > rhs
        case let (.f32(lhs), .f32(rhs)): return Float32(bitPattern: lhs) > Float32(bitPattern: rhs)
        case let (.f64(lhs), .f64(rhs)): return Float64(bitPattern: lhs) > Float64(bitPattern: rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value: Comparable` implementation")
        }
    }

    /// Returns if the left value is less than or equal to the right value.
    /// - Precondition: The values are of the same type.
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return lhs >= rhs
        case let (.i64(lhs), .i64(rhs)): return lhs >= rhs
        case let (.f32(lhs), .f32(rhs)): return Float32(bitPattern: lhs) >= Float32(bitPattern: rhs)
        case let (.f64(lhs), .f64(rhs)): return Float64(bitPattern: lhs) >= Float64(bitPattern: rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value: Comparable` implementation")
        }
    }

    /// Returns if the left value is less than or equal to the right value.
    /// - Precondition: The values are of the same type.
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return lhs <= rhs
        case let (.i64(lhs), .i64(rhs)): return lhs <= rhs
        case let (.f32(lhs), .f32(rhs)): return Float32(bitPattern: lhs) <= Float32(bitPattern: rhs)
        case let (.f64(lhs), .f64(rhs)): return Float64(bitPattern: lhs) <= Float64(bitPattern: rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value: Comparable` implementation")
        }
    }
}

extension Value: ExpressibleByBooleanLiteral {
    /// Create a new value from a boolean literal.
    public init(booleanLiteral value: BooleanLiteralType) {
        if value {
            self = .i32(1)
        } else {
            self = .i32(0)
        }
    }
}

extension Value: CustomStringConvertible {
    /// A textual representation of the value.
    public var description: String {
        switch self {
        case let .i32(rawValue): return "I32(\(rawValue.signed))"
        case let .i64(rawValue): return "I64(\(rawValue.signed))"
        case let .f32(rawValue): return "F32(\(Float32(bitPattern: rawValue)))"
        case let .f64(rawValue): return "F64(\(Float64(bitPattern: rawValue)))"
        case let .ref(.extern(tableIndex)): return "externref(\(tableIndex?.description ?? "null"))"
        case let .ref(.function(functionAddress)): return "funcref(\(functionAddress?.description ?? "null"))"
        }
    }
}

// Integers
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#integers>

/// Integer value types
enum IntValueType {
    /// 32-bit signed or unsigned integer.
    case i32
    /// 64-bit signed or unsigned integer.
    case i64
}

protocol RawUnsignedInteger: FixedWidthInteger & UnsignedInteger {
    associatedtype Signed: RawSignedInteger where Signed.Unsigned == Self
    init(bitPattern: Signed)
}

protocol RawSignedInteger: FixedWidthInteger & SignedInteger {
    associatedtype Unsigned: RawUnsignedInteger where Unsigned.Signed == Self
    init(bitPattern: Unsigned)
}

extension UInt8: RawUnsignedInteger {
    typealias Signed = Int8
}

extension UInt16: RawUnsignedInteger {
    typealias Signed = Int16
}

extension UInt32: RawUnsignedInteger {
    typealias Signed = Int32
}

extension UInt64: RawUnsignedInteger {
    typealias Signed = Int64
}

extension Int8: RawSignedInteger {}
extension Int16: RawSignedInteger {}
extension Int32: RawSignedInteger {}
extension Int64: RawSignedInteger {}

extension RawUnsignedInteger {
    var signed: Signed {
        .init(bitPattern: self)
    }
}

extension RawSignedInteger {
    var unsigned: Unsigned {
        .init(bitPattern: self)
    }
}

// Floating-Point
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#floating-point>

/// Floating-point value types
enum FloatValueType {
    /// 32-bit IEEE 754 floating-point number.
    case f32
    /// 64-bit IEEE 754 floating-point number.
    case f64

    var nan: Value {
        switch self {
        case .f32:
            return .fromFloat32(.nan)
        case .f64:
            return .fromFloat64(.nan)
        }
    }

    var zero: Value {
        switch self {
        case .f32:
            return .f32(.zero)
        case .f64:
            return .f64(.zero)
        }
    }

    func infinity(isNegative: Bool) -> Value {
        switch self {
        case .f32:
            return .fromFloat32(isNegative ? -.infinity : .infinity)
        case .f64:
            return .fromFloat64(isNegative ? -.infinity : .infinity)
        }
    }
}

extension Value {
    var bytes: [UInt8]? {
        switch self {
        case let .i32(rawValue): return rawValue.littleEndianBytes
        case let .i64(rawValue): return rawValue.littleEndianBytes
        case let .f32(rawValue): return rawValue.littleEndianBytes
        case let .f64(rawValue): return rawValue.littleEndianBytes
        case .ref(.function), .ref(.extern): return nil
        }
    }
}

extension RawUnsignedInteger {
    init<T: RandomAccessCollection>(littleEndian bytes: T) where T.Element == UInt8, T.Index == Int {
        self = .zero

        for i in stride(from: bytes.endIndex - 1, to: bytes.startIndex - 1, by: -1) {
            self <<= 8
            self |= Self(bytes[i])
        }
    }
}

extension RawUnsignedInteger {
    // FIXME: shouldn't use arrays with potential heap allocations for this
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: littleEndian) { Array($0) }
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

// MARK: Arithmetic

extension Value {
    var abs: Value {
        switch self {
        case let .f32(rawValue): return .f32(Swift.abs(Float32(bitPattern: rawValue)).bitPattern)
        case let .f64(rawValue): return .f64(Swift.abs(Float64(bitPattern: rawValue)).bitPattern)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var isZero: Bool {
        switch self {
        case let .i32(rawValue): return rawValue == 0
        case let .i64(rawValue): return rawValue == 0
        case let .f32(rawValue): return Float32(bitPattern: rawValue).isZero
        case let .f64(rawValue): return Float64(bitPattern: rawValue).isZero
        case .ref(.extern), .ref(.function):
            fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var isNegative: Bool {
        switch self {
        case let .i32(rawValue): return rawValue.signum() < 0
        case let .i64(rawValue): return rawValue.signum() < 0
        case let .f32(rawValue): return Float32(bitPattern: rawValue).sign == .minus
        case let .f64(rawValue): return Float64(bitPattern: rawValue).sign == .minus
        case .ref(.extern), .ref(.function):
            fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var isNan: Bool {
        switch self {
        case let .f32(rawValue): return Float32(bitPattern: rawValue).isNaN
        case let .f64(rawValue): return Float64(bitPattern: rawValue).isNaN
        default:
            fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var ceil: Value {
        switch self {
        case let .f32(rawValue):
            var rawValue = Float32(bitPattern: rawValue)
            rawValue.round(.up)
            return .f32(rawValue.bitPattern)
        case let .f64(rawValue):
            var rawValue = Float64(bitPattern: rawValue)
            rawValue.round(.up)
            return .f64(rawValue.bitPattern)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var floor: Value {
        switch self {
        case let .f32(rawValue):
            var rawValue = Float32(bitPattern: rawValue)
            rawValue.round(.down)
            return .f32(rawValue.bitPattern)
        case let .f64(rawValue):
            var rawValue = Float64(bitPattern: rawValue)
            rawValue.round(.down)
            return .f64(rawValue.bitPattern)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var truncate: Value {
        switch self {
        case let .f32(rawValue):
            var rawValue = Float32(bitPattern: rawValue)
            rawValue.round(.towardZero)
            return .f32(rawValue.bitPattern)
        case let .f64(rawValue):
            var rawValue = Float64(bitPattern: rawValue)
            rawValue.round(.towardZero)
            return .f64(rawValue.bitPattern)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var nearest: Value {
        switch self {
        case let .f32(rawValue):
            var rawValue = Float32(bitPattern: rawValue)
            rawValue.round(.toNearestOrEven)
            return .f32(rawValue.bitPattern)
        case let .f64(rawValue):
            var rawValue = Float64(bitPattern: rawValue)
            rawValue.round(.toNearestOrEven)
            return .f64(rawValue.bitPattern)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var squareRoot: Value {
        switch self {
        case let .f32(rawValue): return .f32(Float32(bitPattern: rawValue).squareRoot().bitPattern)
        case let .f64(rawValue): return .f64(Float64(bitPattern: rawValue).squareRoot().bitPattern)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    func rotl(_ l: Self) -> Self {
        switch (self, l) {
        case let (.i32(rawValue), .i32(l)):
            let shift = l % UInt32(type.bitWidth!)
            return .i32(rawValue << shift | rawValue >> (32 - shift))
        case let (.i64(rawValue), .i64(l)):
            let shift = l % UInt64(type.bitWidth!)
            return .i64(rawValue << shift | rawValue >> (64 - shift))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    func rotr(_ r: Self) -> Self {
        switch (self, r) {
        case let (.i32(rawValue), .i32(r)):
            let shift = r % UInt32(type.bitWidth!)
            return .i32(rawValue >> shift | rawValue << (32 - shift))
        case let (.i64(rawValue), .i64(r)):
            let shift = r % UInt64(type.bitWidth!)
            return .i64(rawValue >> shift | rawValue << (64 - shift))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    static prefix func - (_ value: Self) -> Self {
        switch value {
        case let .f32(rawValue):
            let sign = rawValue & (1 << 31)
            if sign != 0 {
                return .f32(rawValue & ~(1 << 31))
            } else {
                return .f32(rawValue | (1 << 31))
            }
        case let .f64(rawValue):
            let sign = rawValue & (1 << 63)
            if sign != 0 {
                return .f64(rawValue & ~(1 << 63))
            } else {
                return .f64(rawValue | (1 << 63))
            }
        default: fatalError("Invalid type \(value.type) for prefix `Value.-` implementation")
        }
    }

    static func copySign(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.f32(lhs), .f32(rhs)):
            let lhs = Float32(bitPattern: lhs)
            let rhs = Float32(bitPattern: rhs)
            return .f32(lhs.sign == rhs.sign ? lhs.bitPattern : (-lhs).bitPattern)
        case let (.f64(lhs), .f64(rhs)):
            let lhs = Float64(bitPattern: lhs)
            let rhs = Float64(bitPattern: rhs)
            return .f64(lhs.sign == rhs.sign ? lhs.bitPattern : (-lhs).bitPattern)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.f32(lhs), .f32(rhs)): return .f32((Float32(bitPattern: lhs) / Float32(bitPattern: rhs)).bitPattern)
        case let (.f64(lhs), .f64(rhs)): return .f64((Float64(bitPattern: lhs) / Float64(bitPattern: rhs)).bitPattern)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return .i32(lhs & rhs)
        case let (.i64(lhs), .i64(rhs)): return .i64(lhs & rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func | (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return .i32(lhs | rhs)
        case let (.i64(lhs), .i64(rhs)): return .i64(lhs | rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return .i32(lhs ^ rhs)
        case let (.i64(lhs), .i64(rhs)): return .i64(lhs ^ rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func << (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let shift = rhs % 32
            return .i32(lhs << shift)
        case let (.i64(lhs), .i64(rhs)):
            let shift = rhs % 64
            return .i64(lhs << shift)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func rightShiftSigned(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let shift = rhs.signed % 32
            return .i32((lhs.signed >> shift.unsigned).unsigned)
        case let (.i64(lhs), .i64(rhs)):
            let shift = rhs.signed % 64
            return .i64((lhs.signed >> shift.unsigned).unsigned)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func rightShiftUnsigned(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let shift = rhs % 32
            return .i32(lhs >> shift)
        case let (.i64(lhs), .i64(rhs)):
            let shift = rhs % 64
            return .i64(lhs >> shift)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func divisionSigned(_ lhs: Self, _ rhs: Self) throws -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let (signed, overflow) = lhs.signed.dividedReportingOverflow(by: rhs.signed)
            guard !overflow else { throw Trap.integerOverflowed }
            return .i32(signed.unsigned)
        case let (.i64(lhs), .i64(rhs)):
            let (signed, overflow) = lhs.signed.dividedReportingOverflow(by: rhs.signed)
            guard !overflow else { throw Trap.integerOverflowed }
            return .i64(signed.unsigned)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func divisionUnsigned(_ lhs: Self, _ rhs: Self) throws -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let (signed, overflow) = lhs.dividedReportingOverflow(by: rhs)
            guard !overflow else { throw Trap.integerOverflowed }
            return .i32(signed)
        case let (.i64(lhs), .i64(rhs)):
            let (signed, overflow) = lhs.dividedReportingOverflow(by: rhs)
            guard !overflow else { throw Trap.integerOverflowed }
            return .i64(signed)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func remainderSigned(_ lhs: Self, _ rhs: Self) throws -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let (signed, overflow) = lhs.signed.remainderReportingOverflow(dividingBy: rhs.signed)
            guard !overflow else { return .i32(0) }
            return .i32(signed.unsigned)
        case let (.i64(lhs), .i64(rhs)):
            let (signed, overflow) = lhs.signed.remainderReportingOverflow(dividingBy: rhs.signed)
            guard !overflow else { return .i64(0) }
            return .i64(signed.unsigned)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func remainderUnsigned(_ lhs: Self, _ rhs: Self) throws -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)):
            let (signed, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
            guard !overflow else { throw Trap.integerOverflowed }
            return .i32(signed)
        case let (.i64(lhs), .i64(rhs)):
            let (signed, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
            guard !overflow else { throw Trap.integerOverflowed }
            return .i64(signed)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }
}
