import WasmParser

extension Instruction {
    typealias Memarg = MemArg

    struct BrTable: Equatable {
        struct Entry {
            var labelIndex: LabelIndex
            var offset: Int32
            var copyCount: UInt16
            var popCount: UInt16
        }
        let buffer: UnsafeBufferPointer<Entry>

        static func == (lhs: Instruction.BrTable, rhs: Instruction.BrTable) -> Bool {
            lhs.buffer.baseAddress == rhs.buffer.baseAddress
        }
    }

    static let f32Lt: Instruction = .numericFloatBinary(.lt(.f32))
    static let f32Gt: Instruction = .numericFloatBinary(.gt(.f32))
    static let f32Le: Instruction = .numericFloatBinary(.le(.f32))
    static let f32Ge: Instruction = .numericFloatBinary(.ge(.f32))

    static let f64Lt: Instruction = .numericFloatBinary(.lt(.f64))
    static let f64Gt: Instruction = .numericFloatBinary(.gt(.f64))
    static let f64Le: Instruction = .numericFloatBinary(.le(.f64))
    static let f64Ge: Instruction = .numericFloatBinary(.ge(.f64))

    static let i32DivS: Instruction = .numericIntBinary(.divS(.i32))
    static let i32DivU: Instruction = .numericIntBinary(.divU(.i32))
    static let i32RemS: Instruction = .numericIntBinary(.remS(.i32))
    static let i32RemU: Instruction = .numericIntBinary(.remU(.i32))

    static let i32And: Instruction = .numericIntBinary(.and(.i32))
    static let i32Or: Instruction = .numericIntBinary(.or(.i32))
    static let i32Xor: Instruction = .numericIntBinary(.xor(.i32))
    static let i32Shl: Instruction = .numericIntBinary(.shl(.i32))
    static let i32ShrS: Instruction = .numericIntBinary(.shrS(.i32))
    static let i32ShrU: Instruction = .numericIntBinary(.shrU(.i32))
    static let i32Rotl: Instruction = .numericIntBinary(.rotl(.i32))
    static let i32Rotr: Instruction = .numericIntBinary(.rotr(.i32))

    static let i64DivS: Instruction = .numericIntBinary(.divS(.i64))
    static let i64DivU: Instruction = .numericIntBinary(.divU(.i64))
    static let i64RemS: Instruction = .numericIntBinary(.remS(.i64))
    static let i64RemU: Instruction = .numericIntBinary(.remU(.i64))

    static let i64And: Instruction = .numericIntBinary(.and(.i64))
    static let i64Or: Instruction = .numericIntBinary(.or(.i64))
    static let i64Xor: Instruction = .numericIntBinary(.xor(.i64))
    static let i64Shl: Instruction = .numericIntBinary(.shl(.i64))
    static let i64ShrS: Instruction = .numericIntBinary(.shrS(.i64))
    static let i64ShrU: Instruction = .numericIntBinary(.shrU(.i64))
    static let i64Rotl: Instruction = .numericIntBinary(.rotl(.i64))
    static let i64Rotr: Instruction = .numericIntBinary(.rotr(.i64))

    static let f32Abs: Instruction = .numericFloatUnary(.abs(.f32))
    static let f32Neg: Instruction = .numericFloatUnary(.neg(.f32))
    static let f32Ceil: Instruction = .numericFloatUnary(.ceil(.f32))
    static let f32Floor: Instruction = .numericFloatUnary(.floor(.f32))
    static let f32Trunc: Instruction = .numericFloatUnary(.trunc(.f32))
    static let f32Nearest: Instruction = .numericFloatUnary(.nearest(.f32))
    static let f32Sqrt: Instruction = .numericFloatUnary(.sqrt(.f32))

    static let f32Div: Instruction = .numericFloatBinary(.div(.f32))
    static let f32Min: Instruction = .numericFloatBinary(.min(.f32))
    static let f32Max: Instruction = .numericFloatBinary(.max(.f32))
    static let f32Copysign: Instruction = .numericFloatBinary(.copysign(.f32))

    static let f64Abs: Instruction = .numericFloatUnary(.abs(.f64))
    static let f64Neg: Instruction = .numericFloatUnary(.neg(.f64))
    static let f64Ceil: Instruction = .numericFloatUnary(.ceil(.f64))
    static let f64Floor: Instruction = .numericFloatUnary(.floor(.f64))
    static let f64Trunc: Instruction = .numericFloatUnary(.trunc(.f64))
    static let f64Nearest: Instruction = .numericFloatUnary(.nearest(.f64))
    static let f64Sqrt: Instruction = .numericFloatUnary(.sqrt(.f64))

    static let f64Div: Instruction = .numericFloatBinary(.div(.f64))
    static let f64Min: Instruction = .numericFloatBinary(.min(.f64))
    static let f64Max: Instruction = .numericFloatBinary(.max(.f64))
    static let f64Copysign: Instruction = .numericFloatBinary(.copysign(.f64))

    static let i32WrapI64: Instruction = .numericConversion(.wrap)
    static let i32TruncF32S: Instruction = .numericConversion(.truncSigned(.i32, .f32))
    static let i32TruncF32U: Instruction = .numericConversion(.truncUnsigned(.i32, .f32))
    static let i32TruncF64S: Instruction = .numericConversion(.truncSigned(.i32, .f64))
    static let i32TruncF64U: Instruction = .numericConversion(.truncUnsigned(.i32, .f64))
    static let i64ExtendI32S: Instruction = .numericConversion(.extendSigned)
    static let i64ExtendI32U: Instruction = .numericConversion(.extendUnsigned)
    static let i64TruncF32S: Instruction = .numericConversion(.truncSigned(.i64, .f32))
    static let i64TruncF32U: Instruction = .numericConversion(.truncUnsigned(.i64, .f32))
    static let i64TruncF64S: Instruction = .numericConversion(.truncSigned(.i64, .f64))
    static let i64TruncF64U: Instruction = .numericConversion(.truncUnsigned(.i64, .f64))
    static let f32ConvertI32S: Instruction = .numericConversion(.convertSigned(.f32, .i32))
    static let f32ConvertI32U: Instruction = .numericConversion(.convertUnsigned(.f32, .i32))
    static let f32ConvertI64S: Instruction = .numericConversion(.convertSigned(.f32, .i64))
    static let f32ConvertI64U: Instruction = .numericConversion(.convertUnsigned(.f32, .i64))
    static let f32DemoteF64: Instruction = .numericConversion(.demote)
    static let f64ConvertI32S: Instruction = .numericConversion(.convertSigned(.f64, .i32))
    static let f64ConvertI32U: Instruction = .numericConversion(.convertUnsigned(.f64, .i32))
    static let f64ConvertI64S: Instruction = .numericConversion(.convertSigned(.f64, .i64))
    static let f64ConvertI64U: Instruction = .numericConversion(.convertUnsigned(.f64, .i64))
    static let f64PromoteF32: Instruction = .numericConversion(.promote)

    static let i32ReinterpretF32: Instruction = .numericConversion(.reinterpret(.i32, .f32))
    static let i64ReinterpretF64: Instruction = .numericConversion(.reinterpret(.i64, .f64))
    static let f32ReinterpretI32: Instruction = .numericConversion(.reinterpret(.f32, .i32))
    static let f64ReinterpretI64: Instruction = .numericConversion(.reinterpret(.f64, .i64))

    static let i32Extend8S: Instruction = .numericConversion(.extend8Signed(.i32))
    static let i32Extend16S: Instruction = .numericConversion(.extend16Signed(.i32))
    static let i64Extend8S: Instruction = .numericConversion(.extend8Signed(.i64))
    static let i64Extend16S: Instruction = .numericConversion(.extend16Signed(.i64))
    static let i64Extend32S: Instruction = .numericConversion(.extend32Signed)

    static let i32TruncSatF32S: Instruction = .numericConversion(.truncSaturatingSigned(.i32, .f32))
    static let i32TruncSatF32U: Instruction = .numericConversion(.truncSaturatingUnsigned(.i32, .f32))
    static let i32TruncSatF64S: Instruction = .numericConversion(.truncSaturatingSigned(.i32, .f64))
    static let i32TruncSatF64U: Instruction = .numericConversion(.truncSaturatingUnsigned(.i32, .f64))
    static let i64TruncSatF32S: Instruction = .numericConversion(.truncSaturatingSigned(.i64, .f32))
    static let i64TruncSatF32U: Instruction = .numericConversion(.truncSaturatingUnsigned(.i64, .f32))
    static let i64TruncSatF64S: Instruction = .numericConversion(.truncSaturatingSigned(.i64, .f64))
    static let i64TruncSatF64U: Instruction = .numericConversion(.truncSaturatingUnsigned(.i64, .f64))
}
