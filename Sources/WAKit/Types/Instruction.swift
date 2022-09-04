struct Expression: Equatable {
    let instructions: [Instruction]

    init(instructions: [Instruction] = []) {
        self.instructions = instructions
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.instructions == rhs.instructions
    }

    func execute(address: Int, store: Store, stack: inout Stack) throws -> Instruction.Action {
        return try instructions[address].implementation(address, store, &stack)
    }
}

public enum InstructionCode: UInt8 {
    case unreachable = 0x00
    case nop
    case block
    case loop
    case `if`
    case `else`

    case end = 0x0B
    case br
    case br_if
    case br_table
    case `return`
    case call
    case call_indirect

    case drop = 0x1A
    case select

    case local_get = 0x20
    case local_set
    case local_tee

    case global_get
    case global_set

    case i32_load = 0x28
    case i64_load
    case f32_load
    case f64_load

    case i32_load8_s
    case i32_load8_u
    case i32_load16_s
    case i32_load16_u
    case i64_load8_s
    case i64_load8_u
    case i64_load16_s
    case i64_load16_u
    case i64_load32_s
    case i64_load32_u

    case i32_store
    case i64_store
    case f32_store
    case f64_store
    case i32_store8
    case i32_store16
    case i64_store8
    case i64_store16
    case i64_store32

    case memory_size
    case memory_grow

    case i32_const
    case i64_const
    case f32_const
    case f64_const

    case i32_eqz
    case i32_eq
    case i32_ne
    case i32_lt_s
    case i32_lt_u
    case i32_gt_s
    case i32_gt_u
    case i32_le_s
    case i32_le_u
    case i32_ge_s
    case i32_ge_u

    case i64_eqz
    case i64_eq
    case i64_ne
    case i64_lt_s
    case i64_lt_u
    case i64_gt_s
    case i64_gt_u
    case i64_le_s
    case i64_le_u
    case i64_ge_s
    case i64_ge_u

    case f32_eq
    case f32_ne
    case f32_lt
    case f32_gt
    case f32_le
    case f32_ge

    case f64_eq
    case f64_ne
    case f64_lt
    case f64_gt
    case f64_le
    case f64_ge

    case i32_clz
    case i32_ctz
    case i32_popcnt
    case i32_add
    case i32_sub
    case i32_mul
    case i32_div_s
    case i32_div_u
    case i32_rem_s
    case i32_rem_u
    case i32_and
    case i32_or
    case i32_xor
    case i32_shl
    case i32_shr_s
    case i32_shr_u
    case i32_rotl
    case i32_rotr

    case i64_clz
    case i64_ctz
    case i64_popcnt
    case i64_add
    case i64_sub
    case i64_mul
    case i64_div_s
    case i64_div_u
    case i64_rem_s
    case i64_rem_u
    case i64_and
    case i64_or
    case i64_xor
    case i64_shl
    case i64_shr_s
    case i64_shr_u
    case i64_rotl
    case i64_rotr

    case f32_abs
    case f32_neg
    case f32_ceil
    case f32_floor
    case f32_trunc
    case f32_nearest
    case f32_sqrt
    case f32_add
    case f32_sub
    case f32_mul
    case f32_div
    case f32_min
    case f32_max
    case f32_copysign

    case f64_abs
    case f64_neg
    case f64_ceil
    case f64_floor
    case f64_trunc
    case f64_nearest
    case f64_sqrt
    case f64_add
    case f64_sub
    case f64_mul
    case f64_div
    case f64_min
    case f64_max
    case f64_copysign

    case i32_wrap_i64
    case i32_trunc_f32_s
    case i32_trunc_f32_u
    case i32_trunc_f64_s
    case i32_trunc_f64_u
    case i64_extend_i32_s
    case i64_extend_i32_u
    case i64_trunc_f32_s
    case i64_trunc_f32_u
    case i64_trunc_f64_s
    case i64_trunc_f64_u
    case f32_convert_i32_s
    case f32_convert_i32_u
    case f32_convert_i64_s
    case f32_convert_i64_u
    case f32_demote_f64
    case f64_convert_i32_s
    case f64_convert_i32_u
    case f64_convert_i64_s
    case f64_convert_i64_u
    case f64_promote_f32
    case i32_reinterpret_f32
    case i64_reinterpret_f64
    case f32_reinterpret_i32
    case f64_reinterpret_i64
}

public struct Instruction {
    enum Action: Equatable {
        case jump(Int)
        case invoke(Int)
    }

    typealias Implementation = (Int, Store, inout Stack) throws -> Action

    public let code: InstructionCode
    let implementation: Implementation

    init(_ code: InstructionCode, implementation: @escaping Implementation) {
        self.code = code
        self.implementation = implementation
    }

    var isPseudo: Bool {
        switch code {
        case .end, .else: return true
        default: return false
        }
    }
}

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
            case let .truncS(target, _):
                switch (target, value) {
                case (.i32, let .f32(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(signed: Int32(rawValue))

                case (.i32, let .f64(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(signed: Int32(rawValue))

                case (.i64, let .f32(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(signed: Int64(rawValue))

                case (.i64, let .f64(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(signed: Int64(rawValue))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            case let .truncU(target, _):
                switch (target, value) {
                case (.i32, let .f32(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(UInt32(rawValue))

                case (.i32, let .f64(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(UInt32(rawValue))

                case (.i64, let .f32(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(UInt64(rawValue))

                case (.i64, let .f64(rawValue)):
                    guard !rawValue.isNaN else {
                        throw Trap.invalidConversionToInteger
                    }
                    return Value(UInt64(rawValue))
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }

            default:
                throw Trap.unimplemented("\(self)")
            }
        }
    }
}
