/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension ExecutionState {
    mutating func numericConst(runtime: Runtime, stack: inout Stack, constOperand: Instruction.ConstOperand) {
        stack[constOperand.result] = constOperand.value
    }
    @inline(__always)
    private mutating func numericUnary<T>(stack: inout Stack, operand: Instruction.UnaryOperand, castTo: (Value) -> T, unary: (T) -> Value) {
        let value = stack[operand.input]

        stack[operand.result] = unary(castTo(value))
    }
    mutating func numericFloatUnary(runtime: Runtime, stack: inout Stack, floatUnary: NumericInstruction.FloatUnary, unaryOperand: Instruction.UnaryOperand) {
        let value = stack[unaryOperand.input]
        stack[unaryOperand.result] = floatUnary(value)
    }
    @inline(__always)
    private mutating func numericBinary<T>(stack: inout Stack, operand: Instruction.BinaryOperand, castTo: (Value) -> T, binary: (T, T) -> Value) {
        let value2 = stack[operand.rhs]
        let value1 = stack[operand.lhs]

        stack[operand.result] = binary(castTo(value1), castTo(value2))
    }

    mutating func i32Add(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { .i32($0 &+ $1) })
    }

    mutating func i64Add(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { .i64($0 &+ $1) })
    }

    mutating func f32Add(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f32, binary: { .f32((Float32(bitPattern: $0) + Float32(bitPattern: $1)).bitPattern) })
    }

    mutating func f64Add(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f64, binary: { .f64((Float64(bitPattern: $0) + Float64(bitPattern: $1)).bitPattern) })
    }

    mutating func i32Sub(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { .i32($0 &- $1) })
    }

    mutating func i64Sub(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { .i64($0 &- $1) })
    }

    mutating func f32Sub(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f32, binary: { .f32((Float32(bitPattern: $0) - Float32(bitPattern: $1)).bitPattern) })
    }

    mutating func f64Sub(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f64, binary: { .f64((Float64(bitPattern: $0) - Float64(bitPattern: $1)).bitPattern) })
    }

    mutating func i32Mul(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { .i32($0 &* $1) })
    }

    mutating func i64Mul(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { .i64($0 &* $1) })
    }

    mutating func f32Mul(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f32, binary: { .f32((Float32(bitPattern: $0) * Float32(bitPattern: $1)).bitPattern) })
    }

    mutating func f64Mul(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f64, binary: { .f64((Float64(bitPattern: $0) * Float64(bitPattern: $1)).bitPattern) })
    }

    mutating func i32Eq(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0 == $1 ? true : false })
    }

    mutating func i64Eq(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0 == $1 ? true : false })
    }

    mutating func f32Eq(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f32, binary: { Float32(bitPattern: $0) == Float32(bitPattern: $1) ? true : false })
    }

    mutating func f64Eq(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f64, binary: { Float64(bitPattern: $0) == Float64(bitPattern: $1) ? true : false })
    }

    mutating func i32Ne(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0 == $1 ? false : true })
    }

    mutating func i64Ne(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0 == $1 ? false : true })
    }

    mutating func f32Ne(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f32, binary: { Float32(bitPattern: $0) == Float32(bitPattern: $1) ? false : true })
    }

    mutating func f64Ne(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.f64, binary: { Float64(bitPattern: $0) == Float64(bitPattern: $1) ? false : true })
    }

    mutating func i32LtS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0.signed < $1.signed ? true : false })
    }
    mutating func i64LtS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0.signed < $1.signed ? true : false })
    }
    mutating func i32LtU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0 < $1 ? true : false })
    }
    mutating func i64LtU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0 < $1 ? true : false })
    }
    mutating func i32GtS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0.signed > $1.signed ? true : false })
    }
    mutating func i64GtS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0.signed > $1.signed ? true : false })
    }
    mutating func i32GtU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0 > $1 ? true : false })
    }
    mutating func i64GtU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0 > $1 ? true : false })
    }
    mutating func i32LeS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0.signed <= $1.signed ? true : false })
    }
    mutating func i64LeS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0.signed <= $1.signed ? true : false })
    }
    mutating func i32LeU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0 <= $1 ? true : false })
    }
    mutating func i64LeU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0 <= $1 ? true : false })
    }
    mutating func i32GeS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0.signed >= $1.signed ? true : false })
    }
    mutating func i64GeS(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0.signed >= $1.signed ? true : false })
    }
    mutating func i32GeU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i32, binary: { $0 >= $1 ? true : false })
    }
    mutating func i64GeU(runtime: Runtime, stack: inout Stack, binaryOperand: Instruction.BinaryOperand) {
        numericBinary(stack: &stack, operand: binaryOperand, castTo: \.i64, binary: { $0 >= $1 ? true : false })
    }
    mutating func i32Clz(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i32, unary: { .i32(UInt32($0.leadingZeroBitCount)) })
    }
    mutating func i64Clz(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i64, unary: { .i64(UInt64($0.leadingZeroBitCount)) })
    }
    mutating func i32Ctz(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i32, unary: { .i32(UInt32($0.trailingZeroBitCount)) })
    }
    mutating func i64Ctz(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i64, unary: { .i64(UInt64($0.trailingZeroBitCount)) })
    }
    mutating func i32Popcnt(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i32, unary: { .i32(UInt32($0.nonzeroBitCount)) })
    }
    mutating func i64Popcnt(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i64, unary: { .i64(UInt64($0.nonzeroBitCount)) })
    }
    mutating func i32Eqz(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i32, unary: { $0 == 0 ? true : false })
    }
    mutating func i64Eqz(runtime: Runtime, stack: inout Stack, unaryOperand: Instruction.UnaryOperand) {
        numericUnary(stack: &stack, operand: unaryOperand, castTo: \.i64, unary: { $0 == 0 ? true : false })
    }
    mutating func numericIntBinary(runtime: Runtime, stack: inout Stack, intBinary: NumericInstruction.IntBinary, binaryOperand: Instruction.BinaryOperand) throws {
        let value2 = stack[binaryOperand.rhs]
        let value1 = stack[binaryOperand.lhs]
        stack[binaryOperand.result] = try intBinary(value1, value2)
    }
    mutating func numericFloatBinary(runtime: Runtime, stack: inout Stack, floatBinary: NumericInstruction.FloatBinary, binaryOperand: Instruction.BinaryOperand) {
        let value2 = stack[binaryOperand.rhs]
        let value1 = stack[binaryOperand.lhs]
        stack[binaryOperand.result] = floatBinary(value1, value2)
    }
    mutating func numericConversion(runtime: Runtime, stack: inout Stack, conversion: NumericInstruction.Conversion, unaryOperand: Instruction.UnaryOperand) throws {
        let value = stack[unaryOperand.input]
        stack[unaryOperand.result] = try conversion(value)
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
        case and(IntValueType)
        case or(IntValueType)
        case xor(IntValueType)
        case shl(IntValueType)
        case shrS(IntValueType)
        case shrU(IntValueType)
        case rotl(IntValueType)
        case rotr(IntValueType)

        var type: NumericType {
            switch self {
            case let .divS(type),
                let .divU(type),
                let .remS(type),
                let .remU(type),
                let .and(type),
                let .or(type),
                let .xor(type),
                let .shl(type),
                let .shrS(type),
                let .shrU(type),
                let .rotl(type),
                let .rotr(type):
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
            case .and:
                return value1 & value2
            case .or:
                return value1 | value2
            case .xor:
                return value1 ^ value2
            case .shl:
                return value1 << value2
            case .shrS:
                return Value.rightShiftSigned(value1, value2)
            case .shrU:
                return Value.rightShiftUnsigned(value1, value2)
            case .rotl:
                return value1.rotl(value2)
            case .rotr:
                return value1.rotr(value2)
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
            _ value: Value
        ) throws -> Value {
            switch self {
            case .wrap:
                switch value {
                case let .i64(rawValue):
                    return .i32(UInt32(truncatingIfNeeded: rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .extendSigned:
                switch value {
                case let .i32(rawValue):
                    return .i64(UInt64(bitPattern: Int64(rawValue.signed)))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .extendUnsigned:
                switch value {
                case let .i32(rawValue):
                    return .i64(UInt64(rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .extend8Signed(target):
                switch (target, value) {
                case let (.i32, .i32(rawValue)):
                    return .i32(UInt32(bitPattern: Int32(Int8(truncatingIfNeeded: rawValue))))
                case let (.i64, .i64(rawValue)):
                    return .i64(UInt64(bitPattern: Int64(Int8(truncatingIfNeeded: rawValue))))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .extend16Signed(target):
                switch (target, value) {
                case let (.i32, .i32(rawValue)):
                    return .i32(UInt32(bitPattern: Int32(Int16(truncatingIfNeeded: rawValue))))
                case let (.i64, .i64(rawValue)):
                    return .i64(UInt64(bitPattern: Int64(Int16(truncatingIfNeeded: rawValue))))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .extend32Signed:
                switch value {
                case let .i64(rawValue):
                    return .i64(UInt64(bitPattern: Int64(Int32(truncatingIfNeeded: rawValue))))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncSigned(target, _):
                switch (target, value) {
                case let (.i32, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
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

                case let (.i32, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int32.max) >= rawValue && rawValue >= Float64(Int32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case let (.i64, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int64.max) > rawValue && rawValue >= Float32(Int64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)

                case let (.i64, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int64.max) > rawValue && rawValue >= Float64(Int64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncUnsigned(target, _):
                switch (target, value) {
                case let (.i32, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt32.max) > rawValue && rawValue >= Float32(UInt32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return Value(result)

                case let (.i32, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt32.max) >= rawValue && rawValue >= Float64(UInt32.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return Value(result)

                case let (.i64, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt64.max) > rawValue && rawValue >= Float32(UInt64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return Value(result)

                case let (.i64, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt64.max) > rawValue && rawValue >= Float64(UInt64.min) else {
                            throw Trap.integerOverflowed
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return Value(result)
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncSaturatingSigned(target, _):
                switch (target, value) {
                case let (.i32, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
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

                case let (.i32, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
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

                case let (.i64, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
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

                case let (.i64, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
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

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncSaturatingUnsigned(target, _):
                switch (target, value) {
                case let (.i32, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
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

                case let (.i32, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
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

                case let (.i64, .f32(bitPattern)):
                    var rawValue = Float32(bitPattern: bitPattern)
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

                case let (.i64, .f64(bitPattern)):
                    var rawValue = Float64(bitPattern: bitPattern)
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

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .convertSigned(target, _):
                switch (target, value) {
                case let (.f32, .i32(rawValue)):
                    return .fromFloat32(Float32(rawValue.signed))

                case let (.f32, .i64(rawValue)):
                    return .fromFloat32(Float32(rawValue.signed))

                case let (.f64, .i32(rawValue)):
                    return .fromFloat64(Float64(rawValue.signed))

                case let (.f64, .i64(rawValue)):
                    return .fromFloat64(Float64(rawValue.signed))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .convertUnsigned(target, _):
                switch (target, value) {
                case let (.f32, .i32(rawValue)):
                    return .fromFloat32(Float32(rawValue))

                case let (.f32, .i64(rawValue)):
                    return .fromFloat32(Float32(rawValue))

                case let (.f64, .i32(rawValue)):
                    return .fromFloat64(Float64(rawValue))

                case let (.f64, .i64(rawValue)):
                    return .fromFloat64(Float64(rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .demote:
                switch value {
                case let .f64(rawValue):
                    return .fromFloat32(Float32(Float64(bitPattern: rawValue)))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .promote:
                switch value {
                case let .f32(rawValue):
                    return .fromFloat64(Float64(Float32(bitPattern: rawValue)))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .reinterpret(target, _):
                switch (target, value) {
                case let (.int(.i32), .f32(rawValue)):
                    return .i32(rawValue)

                case let (.int(.i64), .f64(rawValue)):
                    return .i64(rawValue)

                case let (.float(.f32), .i32(rawValue)):
                    return .f32(rawValue)

                case let (.float(.f64), .i64(rawValue)):
                    return .f64(rawValue)
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }
            }
        }
    }
}
