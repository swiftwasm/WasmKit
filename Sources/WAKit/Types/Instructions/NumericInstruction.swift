/// Numeric Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#numeric-instructions>
enum NumericInstruction {
    enum Constant {
        case const(Value)
    }

    enum IntUnary {
        // iunop
        case clz(IntValueType)
        case ctz(IntValueType)
        case popcnt(IntValueType)

        /// itestop
        case eqz(IntValueType)

        var type: ValueType {
            switch self {
            case let .clz(type),
                 let .ctz(type),
                 let .popcnt(type),
                 let .eqz(type):
                return .int(type)
            }
        }

        func callAsFunction(_ value: Value) -> Value {
            switch self {
            case .clz:
                return value.leadingZeroBitCount
            case .ctz:
                return value.trailingZeroBitCount
            case .popcnt:
                return value.nonzeroBitCount

            case .eqz:
                return value.isZero ? true : false
            }
        }
    }

    enum FloatUnary {
        // funop
        case abs(FloatValueType)
        case neg(FloatValueType)
        case ceil(FloatValueType)
        case floor(FloatValueType)
        case trunc(FloatValueType)
        case nearest(FloatValueType)
        case sqrt(FloatValueType)

        var type: ValueType {
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

    enum Binary {
        // binop
        case add(ValueType)
        case sub(ValueType)
        case mul(ValueType)

        // relop
        case eq(ValueType)
        case ne(ValueType)

        var type: ValueType {
            switch self {
            case let .add(type),
                 let .sub(type),
                 let .mul(type),
                 let .eq(type),
                 let .ne(type):
                return type
            }
        }

        func callAsFunction(_ value1: Value, _ value2: Value) -> Value {
            switch self {
            case .add:
                return value1 + value2
            case .sub:
                return value1 - value2
            case .mul:
                return value1 * value2

            case .eq:
                return value1 == value2 ? true : false
            case .ne:
                return value1 == value2 ? false : true
            }
        }
    }

    enum IntBinary {
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

        // irelop
        case ltS(IntValueType)
        case ltU(IntValueType)
        case gtS(IntValueType)
        case gtU(IntValueType)
        case leS(IntValueType)
        case leU(IntValueType)
        case geS(IntValueType)
        case geU(IntValueType)

        var type: ValueType {
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
                 let .rotr(type),
                 let .ltS(type),
                 let .ltU(type),
                 let .gtS(type),
                 let .gtU(type),
                 let .leS(type),
                 let .leU(type),
                 let .geS(type),
                 let .geU(type):
                return .int(type)
            }
        }

        func callAsFunction(
            _ type: ValueType,
            _ value1: Value,
            _ value2: Value
        ) throws -> Value {
            switch (self, type) {
            case (.divS, _):
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.divisionSigned(value1, value2)
            case (.divU, _):
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.divisionUnsigned(value1, value2)
            case (.remS, _):
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.remainderSigned(value1, value2)
            case (.remU, _):
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return try Value.remainderUnsigned(value1, value2)
            case (.and, _):
                return value1 & value2
            case (.or, _):
                return value1 | value2
            case (.xor, _):
                return value1 ^ value2
            case (.shl, _):
                return value1 << value2
            case (.shrS, _):
                return Value.rightShiftSigned(value1, value2)
            case (.shrU, _):
                return Value.rightShiftUnsigned(value1, value2)
            case (.rotl, _):
                return value1.rotr(value2)
            case (.rotr, _):
                return value1.rotr(value2)

            case (.ltS, .int(.i32)):
                return value1.i32.signed < value2.i32.signed ? true : false
            case (.ltU, .int(.i32)):
                return value1.i32 < value2.i32 ? true : false
            case (.gtS, .int(.i32)):
                return value1.i32.signed > value2.i32.signed ? true : false
            case (.gtU, .int(.i32)):
                return value1.i32 > value2.i32 ? true : false
            case (.leS, .int(.i32)):
                return value1.i32.signed <= value2.i32.signed ? true : false
            case (.leU, .int(.i32)):
                return value1.i32 <= value2.i32 ? true : false
            case (.geS, .int(.i32)):
                return value1.i32.signed >= value2.i32.signed ? true : false
            case (.geU, .int(.i32)):
                return value1.i32 >= value2.i32 ? true : false

            case (.ltS, .int(.i64)):
                return value1.i64.signed < value2.i64.signed ? true : false
            case (.ltU, .int(.i64)):
                return value1.i64 < value2.i64 ? true : false
            case (.gtS, .int(.i64)):
                return value1.i64.signed > value2.i32.signed ? true : false
            case (.gtU, .int(.i64)):
                return value1.i64 > value2.i64 ? true : false
            case (.leS, .int(.i64)):
                return value1.i64.signed <= value2.i64.signed ? true : false
            case (.leU, .int(.i64)):
                return value1.i64 <= value2.i64 ? true : false
            case (.geS, .int(.i64)):
                return value1.i32.signed >= value2.i32.signed ? true : false
            case (.geU, .int(.i64)):
                return value1.i64 >= value2.i64 ? true : false

            default:
                fatalError("Invalid type \(type) for instruction \(self)")
            }
        }
    }

    enum FloatBinary {
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

        var type: ValueType {
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

        func callAsFunction(_ value1: Value, _ value2: Value) throws -> Value {
            switch self {
            case .div:
                guard !value2.isZero else { throw Trap.integerDividedByZero }
                return value1 / value2
            case .min:
                return Swift.min(value1, value2)
            case .max:
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

extension Instruction: Equatable {
    public static func == (lhs: Instruction, rhs: Instruction) -> Bool {
        // TODO: Compare with instruction arguments
        return lhs.code == rhs.code
    }
}

extension NumericInstruction {
    enum Conversion {
        case wrap
        case extendS
        case extendU
        case truncS(IntValueType, FloatValueType)
        case truncU(IntValueType, FloatValueType)
        case convertS(FloatValueType, IntValueType)
        case convertU(FloatValueType, IntValueType)
        case demote
        case promote
        case reinterpret(ValueType, ValueType)

        var types: (ValueType, ValueType) {
            switch self {
            case .wrap:
                return (.int(.i32), .int(.i64))
            case .extendS:
                return (.int(.i64), .int(.i32))
            case .extendU:
                return (.int(.i64), .int(.i32))
            case let .truncS(type1, type2):
                return (.int(type1), .float(type2))
            case let .truncU(type1, type2):
                return (.int(type1), .float(type2))
            case let .convertS(type1, type2):
                return (.float(type1), .int(type2))
            case let .convertU(type1, type2):
                return (.float(type1), .int(type2))
            case .demote:
                return (.float(.f32), .float(.f64))
            case .promote:
                return (.float(.f64), .float(.f32))
            case let .reinterpret(type1, type2):
                return (type1, type2)
            }
        }

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

            case .extendS:
                switch value {
                case let .i32(rawValue):
                    return .i64(UInt64(bitPattern: Int64(rawValue.signed)))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .extendU:
                switch value {
                case let .i32(rawValue):
                    return .i64(UInt64(rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncS(target, _):
                switch (target, value) {
                case (.i32, let .f32(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(signed: Int32(rawValue))

                case (.i32, let .f64(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(signed: Int32(rawValue))

                case (.i64, let .f32(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(signed: Int64(rawValue))

                case (.i64, let .f64(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(signed: Int64(rawValue))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncU(target, _):
                switch (target, value) {
                case (.i32, let .f32(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(UInt32(rawValue))

                case (.i32, let .f64(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(UInt32(rawValue))

                case (.i64, let .f32(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(UInt64(rawValue))

                case (.i64, let .f64(rawValue)):
                    guard !rawValue.isNaN else { throw Trap.invalidConversionToInteger }
                    return Value(UInt64(rawValue))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .convertS(target, _):
                switch (target, value) {
                case (.f32, let .i32(rawValue)):
                    return .f32(Float32(rawValue.signed))

                case (.f32, let .i64(rawValue)):
                    return .f32(Float32(rawValue.signed))

                case (.f64, let .i32(rawValue)):
                    return .f64(Float64(rawValue.signed))

                case (.f64, let .i64(rawValue)):
                    return .f64(Float64(rawValue.signed))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .convertU(target, _):
                switch (target, value) {
                case (.f32, let .i32(rawValue)):
                    return .f32(Float32(rawValue))

                case (.f32, let .i64(rawValue)):
                    return .f32(Float32(rawValue))

                case (.f64, let .i32(rawValue)):
                    return .f64(Float64(rawValue))

                case (.f64, let .i64(rawValue)):
                    return .f64(Float64(rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }


            case .demote:
                switch value {
                case let .f64(rawValue):
                    return .f32(Float32(rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case .promote:
                switch value {
                case let .f32(rawValue):
                    return .f64(Float64(rawValue))

                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .reinterpret(target, _):
                switch (target, value) {
                case (.int(.i32), let .f32(rawValue)):
                    return .i32(rawValue.bitPattern)

                case (.int(.i64), let .f64(rawValue)):
                    return .i64(rawValue.bitPattern)

                case (.float(.f32), let .i32(rawValue)):
                    return .f32(Float32(bitPattern: rawValue))

                case (.float(.f64), let .i64(rawValue)):
                    return .f64(Float64(bitPattern: rawValue))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }
            }
        }
    }
}
