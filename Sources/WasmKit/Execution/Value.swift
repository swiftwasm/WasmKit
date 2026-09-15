import struct WasmTypes.ReferenceType
import enum WasmTypes.ValueType

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#value-types>

public typealias ReferenceType = WasmTypes.ReferenceType

extension Value {
    func maybeAddressOffset(_ isMemory64: Bool) -> UInt64? {
        switch (isMemory64, self) {
        case (true, .i64(let value)): return value
        case (false, .i32(let value)): return UInt64(value)
        default: return nil
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
}

extension RawUnsignedInteger {
    // FIXME: shouldn't use arrays with potential heap allocations for this
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: littleEndian) { Array($0) }
    }
}

extension ValueType {
    static func addressType(isMemory64: Bool) -> ValueType {
        return isMemory64 ? .i64 : .i32
    }
}

// MARK: Arithmetic

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
    func ltS(_ other: Self) -> UInt32 { self.signed < other.signed ? 1 : 0 }
    func ltU(_ other: Self) -> UInt32 { self < other ? 1 : 0 }
    func gtS(_ other: Self) -> UInt32 { self.signed > other.signed ? 1 : 0 }
    func gtU(_ other: Self) -> UInt32 { self > other ? 1 : 0 }
    func leS(_ other: Self) -> UInt32 { self.signed <= other.signed ? 1 : 0 }
    func leU(_ other: Self) -> UInt32 { self <= other ? 1 : 0 }
    func geS(_ other: Self) -> UInt32 { self.signed >= other.signed ? 1 : 0 }
    func geU(_ other: Self) -> UInt32 { self >= other ? 1 : 0 }

    func shl(_ other: Self) -> Self {
        let shift = other % Self(Self.bitWidth)
        return self << shift
    }
    func shrS(_ other: Self) -> Self {
        let shift = other % Self(Self.bitWidth)
        return (self.signed >> shift).unsigned
    }
    func shrU(_ other: Self) -> Self {
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

    func divS(_ other: Self) throws -> Self {
        if _slowPath(other == 0) { throw Trap(.integerDividedByZero) }
        let (signed, overflow) = signed.dividedReportingOverflow(by: other.signed)
        guard !overflow else { throw Trap(.integerOverflow) }
        return signed.unsigned
    }
    func divU(_ other: Self) throws -> Self {
        if _slowPath(other == 0) { throw Trap(.integerDividedByZero) }
        let (unsigned, overflow) = dividedReportingOverflow(by: other)
        guard !overflow else { throw Trap(.integerOverflow) }
        return unsigned
    }
    func remS(_ other: Self) throws -> Self {
        if _slowPath(other == 0) { throw Trap(.integerDividedByZero) }
        let (signed, overflow) = signed.remainderReportingOverflow(dividingBy: other.signed)
        guard !overflow else { return 0 }
        return signed.unsigned
    }
    func remU(_ other: Self) throws -> Self {
        if _slowPath(other == 0) { throw Trap(.integerDividedByZero) }
        let (unsigned, overflow) = remainderReportingOverflow(dividingBy: other)
        guard !overflow else { throw Trap(.integerOverflow) }
        return unsigned
    }
}

extension UInt32 {
    var extendI32S: UInt64 {
        return UInt64(bitPattern: Int64(signed))
    }
    var extendI32U: UInt64 {
        return UInt64(self)
    }
    var convertToF32S: Float32 { Float32(signed) }
    var convertToF32U: Float32 { Float32(self) }
    var convertToF64S: Float64 { Float64(signed) }
    var convertToF64U: Float64 { Float64(self) }
    var reinterpretToF32: Float32 { Float32(bitPattern: self) }
}

extension RawUnsignedInteger {
    var extend8S: Self {
        return Self(bitPattern: Self.Signed(Int8(truncatingIfNeeded: self)))
    }
    var extend16S: Self {
        return Self(bitPattern: Self.Signed(Int16(truncatingIfNeeded: self)))
    }
}

extension UInt64 {
    var extend32S: UInt64 {
        return UInt64(bitPattern: Int64(Int32(truncatingIfNeeded: self)))
    }
    var convertToF32S: Float32 { Float32(signed) }
    var convertToF32U: Float32 { Float32(self) }
    var convertToF64S: Float64 { Float64(signed) }
    var convertToF64U: Float64 { Float64(self) }
    var reinterpretToF64: Float64 { Float64(bitPattern: self) }
}

extension UInt64 {
    var wrap: UInt32 {
        return UInt32(truncatingIfNeeded: self)
    }
}

// Wasm's `min`/`max` are IEEE 754-2019 `minimum`/`maximum` (a NaN operand gives a NaN,
// and -0.0 orders below +0.0), and `trunc_sat` is `fptosi.sat`/`fptoui.sat` (NaN to zero,
// out-of-range values clamped). Those are LLVM intrinsics with no Swift spelling, so they
// are declared by name; the equivalent Swift keeps its comparisons and NaN checks.
@_silgen_name("llvm.fptosi.sat.i32.f32") private func _llvmFPToSISatI32F32(_ a: Float32) -> Int32
@_silgen_name("llvm.fptoui.sat.i32.f32") private func _llvmFPToUISatI32F32(_ a: Float32) -> UInt32
@_silgen_name("llvm.fptosi.sat.i64.f32") private func _llvmFPToSISatI64F32(_ a: Float32) -> Int64
@_silgen_name("llvm.fptoui.sat.i64.f32") private func _llvmFPToUISatI64F32(_ a: Float32) -> UInt64
@_silgen_name("llvm.fptosi.sat.i32.f64") private func _llvmFPToSISatI32F64(_ a: Float64) -> Int32
@_silgen_name("llvm.fptoui.sat.i32.f64") private func _llvmFPToUISatI32F64(_ a: Float64) -> UInt32
@_silgen_name("llvm.fptosi.sat.i64.f64") private func _llvmFPToSISatI64F64(_ a: Float64) -> Int64
@_silgen_name("llvm.fptoui.sat.i64.f64") private func _llvmFPToUISatI64F64(_ a: Float64) -> UInt64

// `minimum`/`maximum` become instructions on arm64 and x86_64. Other targets may lower
// them to `fminimum`/`fmaximum` calls, which not every C library provides.
#if arch(arm64) || arch(x86_64)
    @_silgen_name("llvm.minimum.f32") private func _llvmMinimumF32(_ a: Float32, _ b: Float32) -> Float32
    @_silgen_name("llvm.maximum.f32") private func _llvmMaximumF32(_ a: Float32, _ b: Float32) -> Float32
    @_silgen_name("llvm.minimum.f64") private func _llvmMinimumF64(_ a: Float64, _ b: Float64) -> Float64
    @_silgen_name("llvm.maximum.f64") private func _llvmMaximumF64(_ a: Float64, _ b: Float64) -> Float64

    extension Float32 {
        func min(_ other: Float32) -> Float32 { _llvmMinimumF32(self, other) }
        func max(_ other: Float32) -> Float32 { _llvmMaximumF32(self, other) }
    }

    extension Float64 {
        func min(_ other: Float64) -> Float64 { _llvmMinimumF64(self, other) }
        func max(_ other: Float64) -> Float64 { _llvmMaximumF64(self, other) }
    }
#else
    extension FloatingPoint {
        func min(_ other: Self) -> Self {
            guard !isNaN && !other.isNaN else {
                return .nan
            }
            // min(0.0, -0.0) returns 0.0 in Swift, but wasm expects to return -0.0
            // spec: https://webassembly.github.io/spec/core/exec/numerics.html#op-fmin
            if self.isZero, self == other {
                return self.sign == .minus ? self : other
            }
            return Swift.min(self, other)
        }
        func max(_ other: Self) -> Self {
            guard !isNaN && !other.isNaN else {
                return .nan
            }
            //  max(-0.0, 0.0) returns -0.0 in Swift, but wasm expects to return 0.0
            // spec: https://webassembly.github.io/spec/core/exec/numerics.html#op-fmax
            if self.isZero, self == other {
                return self.sign == .plus ? self : other
            }
            return Swift.max(self, other)
        }
    }
#endif

// `f32` operations on a whole slot, the value and a `+0.0` high half, for the
// `f32x2` accessor. Each maps `+0.0` to `+0.0`, so the high half stays zero, and the
// slot is loaded, computed and stored without moving the result out of FP registers.
extension SIMD2 where Scalar == Float32 {
    func add(_ other: Self) -> Self { self + other }
    func sub(_ other: Self) -> Self { self - other }
    func mul(_ other: Self) -> Self { self * other }
    var sqrt: Self { self.squareRoot() }
    var ceil: Self { self.rounded(.up) }
    var floor: Self { self.rounded(.down) }
    var trunc: Self { self.rounded(.towardZero) }
    var nearest: Self { self.rounded(.toNearestOrEven) }
}

extension SIMD2 where Scalar == UInt32 {
    var convertToF32S: SIMD2<Float32> { SIMD2<Float32>(SIMD2<Int32>(truncatingIfNeeded: self)) }
    var convertToF32U: SIMD2<Float32> { SIMD2<Float32>(self) }
}

extension FloatingPoint {
    func add(_ other: Self) -> Self { self + other }
    func sub(_ other: Self) -> Self { self - other }
    func mul(_ other: Self) -> Self { self * other }
    func div(_ other: Self) -> Self { self / other }
    func copySign(_ other: Self) -> Self {
        return sign == other.sign ? self : -self
    }
    func eq(_ other: Self) -> UInt32 { self == other ? 1 : 0 }
    func ne(_ other: Self) -> UInt32 { self == other ? 0 : 1 }
    func lt(_ other: Self) -> UInt32 { self < other ? 1 : 0 }
    func gt(_ other: Self) -> UInt32 { self > other ? 1 : 0 }
    func le(_ other: Self) -> UInt32 { self <= other ? 1 : 0 }
    func ge(_ other: Self) -> UInt32 { self >= other ? 1 : 0 }

    var abs: Self { Swift.abs(self) }
    var neg: Self { -self }
    var ceil: Self { self.rounded(.up) }
    var floor: Self { self.rounded(.down) }
    var trunc: Self { self.rounded(.towardZero) }
    var nearest: Self { self.rounded(.toNearestOrEven) }
    var sqrt: Self { self.squareRoot() }
}

extension FloatingPoint {
    @inline(__always)
    fileprivate func truncTo<T: FixedWidthInteger>(
        rounding: (Self) -> T,
        max: Self, min: Self
    ) throws -> T {
        guard !self.isNaN else { throw Trap(.invalidConversionToInteger) }
        if self <= min || self >= max {
            throw Trap(.integerOverflow)
        }
        return rounding(self)
    }
}

extension Float32 {
    var truncToI32S: UInt32 {
        get throws {
            return try truncTo(rounding: { Int32($0) }, max: 2147483648.0, min: -2147483904.0).unsigned
        }
    }
    var truncToI64S: UInt64 {
        get throws {
            return try truncTo(rounding: { Int64($0) }, max: 9223372036854775808.0, min: -9223373136366403584.0).unsigned
        }
    }
    var truncToI32U: UInt32 {
        get throws {
            return try truncTo(rounding: { UInt32($0) }, max: 4294967296.0, min: -1.0)
        }
    }
    var truncToI64U: UInt64 {
        get throws {
            return try truncTo(rounding: { UInt64($0) }, max: 18446744073709551616.0, min: -1.0)
        }
    }
    var truncSatToI32S: UInt32 { UInt32(bitPattern: _llvmFPToSISatI32F32(self)) }
    var truncSatToI64S: UInt64 { UInt64(bitPattern: _llvmFPToSISatI64F32(self)) }
    var truncSatToI32U: UInt32 { _llvmFPToUISatI32F32(self) }
    var truncSatToI64U: UInt64 { _llvmFPToUISatI64F32(self) }
    var promoteF32: Float64 { Float64(self) }
    var reinterpretToI32: UInt32 { bitPattern }
}
extension Float64 {
    var truncToI32S: UInt32 {
        get throws {
            return try truncTo(rounding: { Int32($0) }, max: 2147483648.0, min: -2147483649.0).unsigned
        }
    }
    var truncToI64S: UInt64 {
        get throws {
            return try truncTo(rounding: { Int64($0) }, max: 9223372036854775808.0, min: -9223372036854777856.0).unsigned
        }
    }
    var truncToI32U: UInt32 {
        get throws {
            return try truncTo(rounding: { UInt32($0) }, max: 4294967296.0, min: -1.0)
        }
    }
    var truncToI64U: UInt64 {
        get throws {
            return try truncTo(rounding: { UInt64($0) }, max: 18446744073709551616.0, min: -1.0)
        }
    }
    var truncSatToI32S: UInt32 { UInt32(bitPattern: _llvmFPToSISatI32F64(self)) }
    var truncSatToI64S: UInt64 { UInt64(bitPattern: _llvmFPToSISatI64F64(self)) }
    var truncSatToI32U: UInt32 { _llvmFPToUISatI32F64(self) }
    var truncSatToI64U: UInt64 { _llvmFPToUISatI64F64(self) }
    var demoteF64: Float32 { Float32(self) }
    var reinterpretToI64: UInt64 { bitPattern }
}
