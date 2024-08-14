/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension ExecutionState {
    mutating func numericConst(context: inout StackContext, sp: Sp, constOperand: Instruction.ConstOperand) {
        sp[constOperand.result] = constOperand.value
    }

    mutating func numericFloatUnary(context: inout StackContext, sp: Sp, floatUnary: NumericInstruction.FloatUnary, unaryOperand: Instruction.UnaryOperand) {
        let value = sp[unaryOperand.input]
        sp[unaryOperand.result] = UntypedValue(floatUnary(value.cast(to: floatUnary.type)))
    }

    mutating func numericIntBinary(context: inout StackContext, sp: Sp, intBinary: NumericInstruction.IntBinary, binaryOperand: Instruction.BinaryOperand) throws {
        let value2 = sp[binaryOperand.rhs].cast(to: intBinary.type)
        let value1 = sp[binaryOperand.lhs].cast(to: intBinary.type)
        sp[binaryOperand.result] = UntypedValue(try intBinary(value1, value2))
    }
    mutating func numericFloatBinary(context: inout StackContext, sp: Sp, floatBinary: NumericInstruction.FloatBinary, binaryOperand: Instruction.BinaryOperand) {
        let value2 = sp[binaryOperand.rhs].cast(to: floatBinary.type)
        let value1 = sp[binaryOperand.lhs].cast(to: floatBinary.type)
        sp[binaryOperand.result] = UntypedValue(floatBinary(value1, value2))
    }
    mutating func numericConversion(context: inout StackContext, sp: Sp, conversion: NumericInstruction.Conversion, unaryOperand: Instruction.UnaryOperand) throws {
        let value = sp[unaryOperand.input]
        sp[unaryOperand.result] = UntypedValue(try conversion(value))
    }
}

enum NumericInstruction {}

/// Numeric Instructions
extension NumericInstruction {
    internal enum Constant {
        case const(Value)
    }

    public enum FloatUnary: Equatable {
        // funop
        case abs(FloatValueType)
        case neg(FloatValueType)
        case ceil(FloatValueType)
        case floor(FloatValueType)
        case trunc(FloatValueType)
        case nearest(FloatValueType)
        case sqrt(FloatValueType)

        var type: NumericType {
            switch self {
            case let .abs(type),
                let .neg(type),
                let .ceil(type),
                let .floor(type),
                let .trunc(type),
                let .nearest(type),
                let .sqrt(type):
                return .float(type)
            }
        }

        func callAsFunction(
            _ value: Value
        ) -> Value {
            switch self {
            case .abs:
                return value.abs
            case .neg:
                return -value
            case .ceil:
                return value.ceil
            case .floor:
                return value.floor
            case .trunc:
                return value.truncate
            case .nearest:
                return value.nearest
            case .sqrt:
                return value.squareRoot
            }
        }
    }

    public enum IntBinary: Equatable {
        // ibinop
        case divS(IntValueType)
        case divU(IntValueType)
        case remS(IntValueType)
        case remU(IntValueType)

        var type: NumericType {
            switch self {
            case let .divS(type),
                let .divU(type),
                let .remS(type),
                let .remU(type):
                return .int(type)
            }
        }

        func callAsFunction(
            _ value1: Value,
            _ value2: Value
        ) throws -> Value {
            switch self {
            case .divS:
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.divisionSigned(value1, value2)
            case .divU:
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.divisionUnsigned(value1, value2)
            case .remS:
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.remainderSigned(value1, value2)
            case .remU:
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.remainderUnsigned(value1, value2)
            }
        }
    }

    public enum FloatBinary: Equatable {
        // fbinop
        case div(FloatValueType)
        case min(FloatValueType)
        case max(FloatValueType)
        case copysign(FloatValueType)

        // frelop
        case lt(FloatValueType)
        case gt(FloatValueType)
        case le(FloatValueType)
        case ge(FloatValueType)

        var type: NumericType {
            switch self {
            case let .div(type),
                let .min(type),
                let .max(type),
                let .copysign(type),
                let .lt(type),
                let .gt(type),
                let .le(type),
                let .ge(type):
                return .float(type)
            }
        }

        func callAsFunction(_ value1: Value, _ value2: Value) -> Value {
            switch self {
            case .div:
                guard !value1.isNan && !value2.isNan else {
                    return value1.type.float.nan
                }

                switch (value1.isZero, value2.isZero) {
                case (true, true):
                    return value1.type.float.nan
                case (false, true):
                    switch (value1.isNegative, value2.isNegative) {
                    case (true, true), (false, false):
                        return value1.type.float.infinity(isNegative: false)
                    default:
                        return value1.type.float.infinity(isNegative: true)
                    }
                default:
                    return value1 / value2
                }
            case .min:
                guard !value1.isNan && !value2.isNan else {
                    return value1.type.float.nan
                }
                // min(0.0, -0.0) returns 0.0 in Swift, but wasm expects to return -0.0
                // spec: https://webassembly.github.io/spec/core/exec/numerics.html#op-fmin
                switch (value1, value2) {
                case let (.f32(lhs), .f32(rhs)):
                    if value1 == value2 {
                        return .f32(lhs | rhs)
                    }
                case let (.f64(lhs), .f64(rhs)):
                    if value1 == value2 {
                        return .f64(lhs | rhs)
                    }
                default: break
                }
                return Swift.min(value1, value2)
            case .max:
                guard !value1.isNan && !value2.isNan else {
                    return value1.type.float.nan
                }
                // max(-0.0, 0.0) returns -0.0 in Swift, but wasm expects to return -0.0
                // spec: https://webassembly.github.io/spec/core/exec/numerics.html#op-fmin
                switch (value1, value2) {
                case let (.f32(lhs), .f32(rhs)):
                    if value1 == value2 {
                        return .f32(lhs & rhs)
                    }
                case let (.f64(lhs), .f64(rhs)):
                    if value1 == value2 {
                        return .f64(lhs & rhs)
                    }
                default: break
                }
                return Swift.max(value1, value2)
            case .copysign:
                return .copySign(value1, value2)
            case .lt:
                return value1 < value2 ? true : false
            case .gt:
                return value1 > value2 ? true : false
            case .le:
                return value1 <= value2 ? true : false
            case .ge:
                return value1 >= value2 ? true : false
            }
        }
    }
}

extension NumericInstruction {
    public enum Conversion: Equatable {
        case wrap
        case extendSigned
        case extendUnsigned
        case extend8Signed(IntValueType)
        case extend16Signed(IntValueType)
        case extend32Signed
        case truncSigned(IntValueType, FloatValueType)
        case truncUnsigned(IntValueType, FloatValueType)
        case truncSaturatingSigned(IntValueType, FloatValueType)
        case truncSaturatingUnsigned(IntValueType, FloatValueType)
        case convertSigned(FloatValueType, IntValueType)
        case convertUnsigned(FloatValueType, IntValueType)
        case demote
        case promote
        case reinterpret(NumericType, NumericType)

        func callAsFunction(
            _ value: UntypedValue
        ) throws -> Value {
            switch self {
            case .wrap:
                return .i32(UInt32(truncatingIfNeeded: value.i64))
            case .extendSigned:
                return .i64(UInt64(bitPattern: Int64(value.i32.signed)))
            case .extendUnsigned:
                return .i64(UInt64(value.i32))
            case let .extend8Signed(target):
                switch target {
                case .i32:
                    return .i32(UInt32(bitPattern: Int32(Int8(truncatingIfNeeded: value.i32))))
                case .i64:
                    return .i64(UInt64(bitPattern: Int64(Int8(truncatingIfNeeded: value.i64))))
                }

            case let .extend16Signed(target):
                switch target {
                case .i32:
                    return .i32(UInt32(bitPattern: Int32(Int16(truncatingIfNeeded: value.i32))))
                case .i64:
                    return .i64(UInt64(bitPattern: Int64(Int16(truncatingIfNeeded: value.i64))))
                }

            case .extend32Signed:
                return .i64(UInt64(bitPattern: Int64(Int32(truncatingIfNeeded: value.i64))))

            case let .truncSigned(target, source):
                switch (target, source) {
                case (.i32, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int32.max) > rawValue && rawValue >= Float32(Int32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case (.i32, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int32.max) >= rawValue && rawValue >= Float64(Int32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case (.i64, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int64.max) > rawValue && rawValue >= Float32(Int64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)

                case (.i64, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int64.max) > rawValue && rawValue >= Float64(Int64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)
                }

            case let .truncUnsigned(target, source):
                switch (target, source) {
                case (.i32, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt32.max) > rawValue && rawValue >= Float32(UInt32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return Value(result)

                case (.i32, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt32.max) >= rawValue && rawValue >= Float64(UInt32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return Value(result)

                case (.i64, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt64.max) > rawValue && rawValue >= Float32(UInt64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return Value(result)

                case (.i64, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt64.max) > rawValue && rawValue >= Float64(UInt64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return Value(result)
                }

            case let .truncSaturatingSigned(target, source):
                switch (target, source) {
                case (.i32, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int32.max) > rawValue else {
                            return .i32(Int32.max.unsigned)
                        }

                        guard rawValue >= Float32(Int32.min) else {
                            return .i32(Int32.min.unsigned)
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case (.i32, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int32.max) > rawValue else {
                            return .i32(Int32.max.unsigned)
                        }

                        guard rawValue >= Float64(Int32.min) else {
                            return .i32(Int32.min.unsigned)
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case (.i64, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int64.max) > rawValue else {
                            return .i64(Int64.max.unsigned)
                        }

                        guard rawValue >= Float32(Int64.min) else {
                            return .i64(Int64.min.unsigned)
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)

                case (.i64, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int64.max) > rawValue else {
                            return .i64(Int64.max.unsigned)
                        }

                        guard rawValue >= Float64(Int64.min) else {
                            return .i64(Int64.min.unsigned)
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)
                }

            case let .truncSaturatingUnsigned(target, source):
                switch (target, source) {
                case (.i32, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt32.max) > rawValue else {
                            return .i32(UInt32.max)
                        }

                        guard rawValue >= Float32(UInt32.min) else {
                            return .i32(UInt32.min)
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return .i32(result)

                case (.i32, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt32.max) > rawValue else {
                            return .i32(UInt32.max)
                        }

                        guard rawValue >= Float64(UInt32.min) else {
                            return .i32(UInt32.min)
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return .i32(result)

                case (.i64, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt64.max) > rawValue else {
                            return .i64(UInt64.max)
                        }

                        guard rawValue >= Float32(UInt64.min) else {
                            return .i64(UInt64.min)
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return .i64(result)

                case (.i64, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt64.max) > rawValue else {
                            return .i64(UInt64.max)
                        }

                        guard rawValue >= Float64(UInt64.min) else {
                            return .i64(UInt64.min)
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return .i64(result)
                }

            case let .convertSigned(target, source):
                switch (target, source) {
                case (.f32, .i32):
                    return .fromFloat32(Float32(value.i32.signed))

                case (.f32, .i64):
                    return .fromFloat32(Float32(value.i64.signed))

                case (.f64, .i32):
                    return .fromFloat64(Float64(value.i32.signed))

                case (.f64, .i64):
                    return .fromFloat64(Float64(value.rawF64.signed))
                }

            case let .convertUnsigned(target, source):
                switch (target, source) {
                case (.f32, .i32):
                    return .fromFloat32(Float32(value.i32))

                case (.f32, .i64):
                    return .fromFloat32(Float32(value.i64))

                case (.f64, .i32):
                    return .fromFloat64(Float64(value.i32))

                case (.f64, .i64):
                    return .fromFloat64(Float64(value.i64))
                }

            case .demote:
                return .fromFloat32(Float32(Float64(bitPattern: value.rawF64)))
            case .promote:
                return .fromFloat64(Float64(Float32(bitPattern: value.rawF32)))
            case let .reinterpret(target, source):
                switch (target, source) {
                case (.int(.i32), .f32):
                    return .i32(value.rawF32)

                case (.int(.i64), .f64):
                    return .i64(value.rawF64)

                case (.float(.f32), .i32):
                    return .f32(value.i32)

                case (.float(.f64), .i64):
                    return .f64(value.i64)
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }
            }
        }
    }
}
