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
    typealias Validator = (inout ExpressionValidator, Instruction, ValidationContext) throws -> Void

    public let code: InstructionCode
    let implementation: Implementation
    let validator: Validator

    init(_ code: InstructionCode, implementation: @escaping Implementation,
         validator: @escaping Validator)
    {
        self.code = code
        self.implementation = implementation
        self.validator = validator
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
    // sourcery: AutoEquatable
    enum Constant {
        case const(Value)
    }

    // sourcery: AutoEquatable
    enum Unary {
        // iunop
        case clz(IntValueType)
        case ctz(IntValueType)
        case popcnt(IntValueType)

        /// itestop
        case eqz(IntValueType)

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
            case let .clz(type),
                 let .ctz(type),
                 let .popcnt(type),
                 let .eqz(type):
                return type

            case let .abs(type),
                 let .neg(type),
                 let .ceil(type),
                 let .floor(type),
                 let .trunc(type),
                 let .nearest(type),
                 let .sqrt(type):
                return type
            }
        }
    }

    // sourcery: AutoEquatable
    enum Binary {
        // binop
        case add(ValueType)
        case sub(ValueType)
        case mul(ValueType)

        // relop
        case eq(ValueType)
        case ne(ValueType)

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
            case let .add(type),
                 let .sub(type),
                 let .mul(type),
                 let .eq(type),
                 let .ne(type):
                return type
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
                return type
            case let .div(type),
                 let .min(type),
                 let .max(type),
                 let .copysign(type),
                 let .lt(type),
                 let .gt(type),
                 let .le(type),
                 let .ge(type):
                return type
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
    // sourcery: AutoEquatable
    enum Conversion {
        case wrap(I32.Type, I64.Type)
        case extendS(I64.Type, I32.Type)
        case extendU(I64.Type, I32.Type)
        case truncS(IntValueType, FloatValueType)
        case truncU(IntValueType, FloatValueType)
        case convertS(FloatValueType, IntValueType)
        case convertU(FloatValueType, IntValueType)
        case demote(F32.Type, F64.Type)
        case promote(F64.Type, F32.Type)
        case reinterpret(ValueType, ValueType)

        var types: (ValueType, ValueType) {
            switch self {
            case let .wrap(type1, type2):
                return (type1, type2)
            case let .extendS(type1, type2):
                return (type1, type2)
            case let .extendU(type1, type2):
                return (type1, type2)
            case let .truncS(type1, type2):
                return (type1, type2)
            case let .truncU(type1, type2):
                return (type1, type2)
            case let .convertS(type1, type2):
                return (type1, type2)
            case let .convertU(type1, type2):
                return (type1, type2)
            case let .demote(type1, type2):
                return (type1, type2)
            case let .promote(type1, type2):
                return (type1, type2)
            case let .reinterpret(type1, type2):
                return (type1, type2)
            }
        }
    }
}
