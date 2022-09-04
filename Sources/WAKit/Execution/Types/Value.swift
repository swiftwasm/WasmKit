/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#value-types>

public enum ValueType: Equatable {
    case int(IntValueType)
    case float(FloatValueType)

    var defaultValue: Value {
        switch self {
        case .int(.i32): return .i32(0)
        case .int(.i64): return .i64(0)
        case .float(.f32): return .f32(0)
        case .float(.f64): return .f64(0)
        }
    }

    var bitWidth: Int {
        switch self {
        case .int(.i32), .float(.f32): return 32
        case .int(.i64), .float(.f64): return 64
        }
    }
}

public enum Value: Equatable, Hashable {
    case i32(UInt32)
    case i64(UInt64)
    case f32(Float32)
    case f64(Float64)

    var type: ValueType {
        switch self {
        case .i32: return .int(.i32)
        case .i64: return .int(.i64)
        case .f32: return .float(.f32)
        case .f64: return .float(.f64)
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

    public init<V: RawSignedInteger>(signed value: V) {
        if value < 0 {
            self.init(V.Unsigned(~value))
        } else {
            self.init(V.Unsigned(value))
        }
    }

    init<V: BinaryFloatingPoint>(_ rawValue: V) {
        switch rawValue {
        case let value as Float32:
            self = .f32(value)
        case let value as Float64:
            self = .f64(value)
        default:
            fatalError("unknown raw float type \(Swift.type(of: rawValue)) passed to `Value.init` ")
        }
    }

    var i32: UInt32 {
        guard case let .i32(result) = self else { fatalError() }
        return result
    }

    var i64: UInt64 {
        guard case let .i64(result) = self else { fatalError() }
        return result
    }
}

extension Value: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return lhs < rhs
        case let (.i64(lhs), .i64(rhs)): return lhs < rhs
        case let (.f32(lhs), .f32(rhs)): return lhs < rhs
        case let (.f64(lhs), .f64(rhs)): return lhs < rhs
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value: Comparable` implementation")
        }
    }
}

extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        if value {
            self = .i32(1)
        } else {
            self = .i32(0)
        }
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .i32(let rawValue): return "I32(\(rawValue))"
        case .i64(let rawValue): return "I64(\(rawValue))"
        case .f32(let rawValue): return "F32(\(rawValue))"
        case .f64(let rawValue): return "F64(\(rawValue))"
        }
    }
}


// Integers
/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#integers>

public enum IntValueType {
    case i32
    case i64
}

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

public enum FloatValueType {
    case f32
    case f64
}

protocol ByteConvertible {
    init<T: Sequence>(_ bytes: T, _ type: ValueType) where T.Element == UInt8

    var bytes: [UInt8] { get }
}

extension Value: ByteConvertible {
    init<T: Sequence>(_ bytes: T, _ type: ValueType) where T.Element == UInt8 {
        switch type {
        case .int(.i32): self = .i32(UInt32(littleEndian: bytes))
        case .int(.i64): self = .i64(UInt64(littleEndian: bytes))
        case .float(.f32): self = .f32(Float32(bitPattern: UInt32(bigEndian: bytes)))
        case .float(.f64): self = .f64(Float64(bitPattern: UInt64(bigEndian: bytes)))
        }
    }

    var bytes: [UInt8] {
        switch self {
        case let .i32(rawValue): return rawValue.littleEndianBytes
        case let .i64(rawValue): return rawValue.littleEndianBytes
        case let .f32(rawValue): return rawValue.bitPattern.bigEndianBytes
        case let .f64(rawValue): return rawValue.bitPattern.bigEndianBytes
        }
    }
}

extension FixedWidthInteger {
    init<T: Sequence>(littleEndian bytes: T) where T.Element == UInt8 {
        self.init(bigEndian: bytes.reversed())
    }

    var littleEndianBytes: [UInt8] {
        return (0 ..< Self.bitWidth / 8).map { UInt8(truncatingIfNeeded: self >> $0) }
    }

    init<T: Sequence>(bigEndian bytes: T) where T.Element == UInt8 {
        self = bytes.reduce(into: Self()) { acc, next in
            acc <<= 8
            acc |= Self(next)
        }
    }

    var bigEndianBytes: [UInt8] {
        return littleEndianBytes.reversed()
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
        case let .f32(rawValue): return .f32(Swift.abs(rawValue))
        case let .f64(rawValue): return .f64(Swift.abs(rawValue))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var isZero: Bool {
        switch self {
        case let .i32(rawValue): return rawValue == 0
        case let .i64(rawValue): return rawValue == 0
        case let .f32(rawValue): return rawValue.isZero
        case let .f64(rawValue): return rawValue.isZero
        }
    }

    var ceil: Value {
        switch self {
        case var .f32(rawValue):
            rawValue.round(.up)
            return .f32(rawValue)
        case var .f64(rawValue):
            rawValue.round(.up)
            return .f64(rawValue)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var floor: Value {
        switch self {
        case var .f32(rawValue):
            rawValue.round(.down)
            return .f32(rawValue)
        case var .f64(rawValue):
            rawValue.round(.down)
            return .f64(rawValue)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var truncate: Value {
        switch self {
        case var .f32(rawValue):
            rawValue.round(.towardZero)
            return .f32(rawValue)
        case var .f64(rawValue):
            rawValue.round(.towardZero)
            return .f64(rawValue)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var nearest: Value {
        switch self {
        case var .f32(rawValue):
            rawValue.round(.toNearestOrEven)
            return .f32(rawValue)
        case var .f64(rawValue):
            rawValue.round(.toNearestOrEven)
            return .f64(rawValue)
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var squareRoot: Value {
        switch self {
        case let .f32(rawValue): return .f32(rawValue.squareRoot())
        case let .f64(rawValue): return .f64(rawValue.squareRoot())
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var leadingZeroBitCount: Value {
        switch self {
        case let .i32(rawValue): return .i32(UInt32(rawValue.leadingZeroBitCount))
        case let .i64(rawValue): return .i64(UInt64(rawValue.leadingZeroBitCount))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var trailingZeroBitCount: Value {
        switch self {
        case let .i32(rawValue): return .i32(UInt32(rawValue.trailingZeroBitCount))
        case let .i64(rawValue): return .i64(UInt64(rawValue.trailingZeroBitCount))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    var nonzeroBitCount: Value {
        switch self {
        case let .i32(rawValue): return .i32(UInt32(rawValue.nonzeroBitCount))
        case let .i64(rawValue): return .i64(UInt64(rawValue.nonzeroBitCount))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    func rotl(_ l: Self) -> Self {
        switch (self, l) {
        case let (.i32(rawValue), .i32(l)):
            let shift = l % UInt32(type.bitWidth)
            return .i32(rawValue << shift | rawValue >> (32 - shift))
        case let (.i64(rawValue), .i64(l)):
            let shift = l % UInt64(type.bitWidth)
            return .i64(rawValue << shift | rawValue >> (64 - shift))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    func rotr(_ r: Self) -> Self {
        switch (self, r) {
        case let (.i32(rawValue), .i32(r)):
            let shift = r % UInt32(type.bitWidth)
            return .i32(rawValue >> shift | rawValue << (32 - shift))
        case let (.i64(rawValue), .i64(r)):
            let shift = r % UInt64(type.bitWidth)
            return .i64(rawValue >> shift | rawValue << (64 - shift))
        default: fatalError("Invalid type \(type) for `Value.\(#function)` implementation")
        }
    }

    prefix static func -(_ value: Self) -> Self {
        switch value {
        case let .f32(rawValue): return .f32(-rawValue)
        case let .f64(rawValue): return .f64(-rawValue)
        default: fatalError("Invalid type \(value.type) for prefix `Value.-` implementation")
        }
    }

    static func copySign(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.f32(lhs), .f32(rhs)): return .f32(lhs.sign == rhs.sign ? lhs : -lhs)
        case let (.f64(lhs), .f64(rhs)): return .f64(lhs.sign == rhs.sign ? lhs : -lhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return .i32(lhs &+ rhs)
        case let (.i64(lhs), .i64(rhs)): return .i64(lhs &+ rhs)
        case let (.f32(lhs), .f32(rhs)): return .f32(lhs + rhs)
        case let (.f64(lhs), .f64(rhs)): return .f64(lhs + rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return .i32(lhs &- rhs)
        case let (.i64(lhs), .i64(rhs)): return .i64(lhs &- rhs)
        case let (.f32(lhs), .f32(rhs)): return .f32(lhs - rhs)
        case let (.f64(lhs), .f64(rhs)): return .f64(lhs - rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.i32(lhs), .i32(rhs)): return .i32(lhs &* rhs)
        case let (.i64(lhs), .i64(rhs)): return .i64(lhs &* rhs)
        case let (.f32(lhs), .f32(rhs)): return .f32(lhs * rhs)
        case let (.f64(lhs), .f64(rhs)): return .f64(lhs * rhs)
        default: fatalError("Invalid types \(lhs.type) and \(rhs.type) for `Value.\(#function)` implementation")
        }
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case let (.f32(lhs), .f32(rhs)): return .f32(lhs / rhs)
        case let (.f64(lhs), .f64(rhs)): return .f64(lhs / rhs)
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
            return .i32((lhs.signed >> shift).unsigned)
        case let (.i64(lhs), .i64(rhs)):
            let shift = rhs.signed % 64
            return .i64((lhs.signed >> shift).unsigned)
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
            guard !overflow else { throw Trap.integerOverflowed }
            return .i32(signed.unsigned)
        case let (.i64(lhs), .i64(rhs)):
            let (signed, overflow) = lhs.signed.remainderReportingOverflow(dividingBy: rhs.signed)
            guard !overflow else { throw Trap.integerOverflowed }
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
