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

extension Instruction: Equatable {
    public static func == (lhs: Instruction, rhs: Instruction) -> Bool {
        // TODO: Compare with instruction arguments
        return lhs.code == rhs.code
    }
}
