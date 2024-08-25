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
    var float: FloatValueType {
        switch self {
        case .f32: return .f32
        case .f64: return .f64
        default:
            fatalError("unexpected value type \(self)")
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

    func maybeAddressOffset(_ isMemory64: Bool) -> UInt64? {
        switch (isMemory64, self) {
        case (true, .i64(let value)): return value
        case (false, .i32(let value)): return UInt64(value)
        default: return nil
        }
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

    func infinity(isNegative: Bool) -> Value {
        switch self {
        case .f32:
            return .fromFloat32(isNegative ? -.infinity : .infinity)
        case .f64:
            return .fromFloat64(isNegative ? -.infinity : .infinity)
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

extension ValueType {
    static func addressType(isMemory64: Bool) -> ValueType {
        return isMemory64 ? .i64 : .i32
    }
}


extension FixedWidthInteger {
    func add(_ other: Self) -> Self { self &+ other }
    func sub(_ other: Self) -> Self { self &- other }
    func mul(_ other: Self) -> Self { self &* other }
    func eq(_ other: Self) -> UInt32 { self == other ? 1 : 0 }
    func ne(_ other: Self) -> UInt32 { self == other ? 0 : 1 }
    func and(_ other: Self) -> Self { self & other }
    func or(_ other: Self) -> Self { self | other }
    func xor(_ other: Self) -> Self { self ^ other }

    var clz: Self { Self(leadingZeroBitCount) }
    var ctz: Self { Self(trailingZeroBitCount) }
    var popcnt: Self { Self(nonzeroBitCount) }
    var eqz: UInt32 { self == 0 ? 1 : 0 }
}

extension RawUnsignedInteger {
    func lts(_ other: Self) -> UInt32 { self.signed < other.signed ? 1 : 0 }
    func ltu(_ other: Self) -> UInt32 { self < other ? 1 : 0 }
    func gts(_ other: Self) -> UInt32 { self.signed > other.signed ? 1 : 0 }
    func gtu(_ other: Self) -> UInt32 { self > other ? 1 : 0 }
    func les(_ other: Self) -> UInt32 { self.signed <= other.signed ? 1 : 0 }
    func leu(_ other: Self) -> UInt32 { self <= other ? 1 : 0 }
    func ges(_ other: Self) -> UInt32 { self.signed >= other.signed ? 1 : 0 }
    func geu(_ other: Self) -> UInt32 { self >= other ? 1 : 0 }

    func shl(_ other: Self) -> Self {
        let shift = other % Self(Self.bitWidth)
        return self << shift
    }
    func shrs(_ other: Self) -> Self {
        let shift = other.signed % Self.Signed(Self.bitWidth)
        return (self.signed >> shift.unsigned).unsigned
    }
    func shru(_ other: Self) -> Self {
        let shift = other % Self(Self.bitWidth)
        return self >> shift
    }
    func rotl(_ other: Self) -> Self {
        let shift = other % Self(Self.bitWidth)
        return self << shift | self >> (Self(Self.bitWidth) - shift)
    }
    func rotr(_ other: Self) -> Self {
        let shift = other % Self(Self.bitWidth)
        return self >> shift | self << (Self(Self.bitWidth) - shift)
    }
}

extension FloatingPoint {
    func add(_ other: Self) -> Self { self + other }
    func sub(_ other: Self) -> Self { self - other }
    func mul(_ other: Self) -> Self { self * other }
    func div(_ other: Self) -> Self { self / other }
    func eq(_ other: Self) -> UInt32 { self == other ? 1 : 0 }
    func ne(_ other: Self) -> UInt32 { self == other ? 0 : 1 }
}

extension UInt32 {
    var untyped: UntypedValue { UntypedValue.i32(self) }
}

extension UInt64 {
    var untyped: UntypedValue { UntypedValue.i64(self) }
}

extension Float32 {
    var untyped: UntypedValue { UntypedValue.f32(self) }
}

extension Float64 {
    var untyped: UntypedValue { UntypedValue.f64(self) }
}
