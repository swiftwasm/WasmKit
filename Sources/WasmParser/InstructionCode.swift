enum InstructionCode: UInt8 {
    case unreachable = 0x00
    case nop = 0x01
    case block = 0x02
    case loop = 0x03
    case `if` = 0x04
    case `else` = 0x05

    case end = 0x0B
    case br
    case br_if
    case br_table
    case `return`
    case call
    case call_indirect

    case drop = 0x1A
    case select = 0x1B
    case typed_select = 0x1C

    case local_get = 0x20
    case local_set = 0x21
    case local_tee = 0x22

    case global_get = 0x23
    case global_set = 0x24

    case table_get = 0x25
    case table_set = 0x26

    case i32_load = 0x28
    case i64_load = 0x29
    case f32_load = 0x2A
    case f64_load = 0x2B

    case i32_load8_s = 0x2C
    case i32_load8_u
    case i32_load16_s
    case i32_load16_u
    case i64_load8_s
    case i64_load8_u
    case i64_load16_s
    case i64_load16_u
    case i64_load32_s
    case i64_load32_u

    case i32_store = 0x36
    case i64_store = 0x37
    case f32_store = 0x38
    case f64_store = 0x39
    case i32_store8 = 0x3A
    case i32_store16 = 0x3B
    case i64_store8 = 0x3C
    case i64_store16 = 0x3D
    case i64_store32 = 0x3E

    case memory_size = 0x3F
    case memory_grow = 0x40

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

    case i32_wrap_i64 = 0xA7
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
    case i32_reinterpret_f32 = 0xBC
    case i64_reinterpret_f64 = 0xBD
    case f32_reinterpret_i32 = 0xBE
    case f64_reinterpret_i64 = 0xBF

    case i32_extend8_s = 0xC0
    case i32_extend16_s = 0xC1
    case i64_extend8_s = 0xC2
    case i64_extend16_s = 0xC3
    case i64_extend32_s = 0xC4

    case ref_null = 0xD0
    case ref_is_null = 0xD1
    case ref_func = 0xD2

    case wasm2InstructionPrefix = 0xFC
}
