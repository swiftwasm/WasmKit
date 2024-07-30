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
    
    typealias Register = UInt16
    
    /// size = 6, alignment = 2
    struct BinaryOperand: Equatable {
        let result: Register
        let lhs: Register
        let rhs: Register
    }
    
    /// size = 4, alignment = 2
    struct UnaryOperand: Equatable {
        let result: Register
        let input: Register
    }
    
    struct ConstOperand: Equatable {
        let value: Value
        let result: Register
    }
    
    struct LoadOperand: Equatable {
        let pointer: Register
        let result: Register
        let memarg: MemArg
    }
    
    struct StoreOperand: Equatable {
        let pointer: Register
        let value: Register
        let memarg: MemArg
    }
    
    struct MemorySizeOperand: Equatable {
        let result: Register
        let memoryIndex: MemoryIndex
    }
    
    struct MemoryGrowOperand: Equatable {
        let result: Register
        let delta: Register
        let memoryIndex: MemoryIndex
    }
    
    struct MemoryInitOperand: Equatable {
        let segmentIndex: DataIndex
        let destOffset: Register
        let sourceOffset: Register
        let size: Register
    }
    
    struct MemoryCopyOperand: Equatable {
        let destOffset: Register
        let sourceOffset: Register
        let size: Register
    }
    
    struct MemoryFillOperand: Equatable {
        let destOffset: Register
        let value: Register
        let size: Register
    }
    
    struct SelectOperand: Equatable {
        let result: Register
        let condition: Register
        let onTrue: Register
        let onFalse: Register
    }
    
    struct RefNullOperand: Equatable {
        let type: ReferenceType
        let result: Register
    }
    
    struct RefIsNullOperand: Equatable {
        let value: Register
        let result: Register
    }
    
    struct RefFuncOperand: Equatable {
        let index: FunctionIndex
        let result: Register
    }
    
    struct TableGetOperand: Equatable {
        let index: Register
        let result: Register
        let tableIndex: TableIndex
    }
    
    struct TableSetOperand: Equatable {
        let index: Register
        let value: Register
        let tableIndex: TableIndex
    }
    
    struct TableSizeOperand: Equatable {
        let tableIndex: TableIndex
        let result: Register
    }
    
    struct TableGrowOperand: Equatable {
        let tableIndex: TableIndex
        let result: Register
        let delta: Register
        let value: Register
    }
    
    struct TableFillOperand: Equatable {
        let tableIndex: TableIndex
        let destOffset: Register
        let value: Register
        let size: Register
    }
    
    struct TableCopyOperand: Equatable {
        let sourceIndex: TableIndex
        let destIndex: TableIndex
        let sourceOffset: Register
        let destOffset: Register
        let size: Register
    }
    
    struct TableInitOperand: Equatable {
        let tableIndex: TableIndex
        let segmentIndex: ElementIndex
        let destOffset: Register
        let sourceOffset: Register
        let size: Register
    }

    struct LocalGetOperand: Equatable {
        let result: Register
        let index: LocalIndex
    }

    struct LocalSetOperand: Equatable {
        let value: Register
        let index: LocalIndex
    }

    struct LocalTeeOperand: Equatable {
        let value: Register
        let index: LocalIndex
    }

    struct GlobalGetOperand: Equatable {
        let result: Register
        let index: GlobalIndex
    }
    
    struct GlobalSetOperand: Equatable {
        let value: Register
        let index: GlobalIndex
    }

    struct CopyStackOperand: Equatable {
        let source: Register
        let dest: Register
    }

    struct IfOperand: Equatable {
        let condition: Register
        // elseRef for if-then-else-end sequence, endRef for if-then-end sequence
        let elseOrEndRef: ExpressionRef
    }
    
    struct BrIfOperand: Equatable {
        let condition: Register
        let offset: Int32
    }
    
    struct BrTableOperand: Equatable {
        let index: Register
        let table: Instruction.BrTable
    }
    
    struct RegisterSet: Equatable, Sequence {
        typealias Element = Register
        let registers: UnsafeBufferPointer<Register>

        func makeIterator() -> UnsafeBufferPointer<Register>.Iterator {
            registers.makeIterator()
        }

        static func == (lhs: Instruction.RegisterSet, rhs: Instruction.RegisterSet) -> Bool {
            lhs.registers.elementsEqual(rhs.registers)
        }
    }

    enum RegisterRange: Equatable {
        case empty
        case some(start: Register, count: Int)

        init() {
            self = .empty
        }

        mutating func append(_ register: Register) {
            switch self {
            case .empty:
                self = .some(start: register, count: 1)
            case .some(let start, let count):
                self = .some(start: start, count: count + 1)
            }
        }
    }

    struct CallLikeOperand: Equatable {
        let spAddend: UInt16
    }
    struct CallOperand: Equatable {
        let index: FunctionIndex
        let callLike: CallLikeOperand
    }
    
    struct CallIndirectOperand: Equatable {
        let index: Register
        let tableIndex: TableIndex
        let typeIndex: TypeIndex
        let callLike: CallLikeOperand
    }

    struct ReturnOperand: Equatable {
    }
    
    static func f32Lt(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.lt(.f32), op) }
    static func f32Gt(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.gt(.f32), op) }
    static func f32Le(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.le(.f32), op) }
    static func f32Ge(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.ge(.f32), op) }
    
    static func f64Lt(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.lt(.f64), op) }
    static func f64Gt(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.gt(.f64), op) }
    static func f64Le(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.le(.f64), op) }
    static func f64Ge(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.ge(.f64), op) }
    
    static func i32DivS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.divS(.i32), op) }
    static func i32DivU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.divU(.i32), op) }
    static func i32RemS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.remS(.i32), op) }
    static func i32RemU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.remU(.i32), op) }
    
    static func i32And(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.and(.i32), op) }
    static func i32Or(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.or(.i32), op) }
    static func i32Xor(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.xor(.i32), op) }
    static func i32Shl(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.shl(.i32), op) }
    static func i32ShrS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.shrS(.i32), op) }
    static func i32ShrU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.shrU(.i32), op) }
    static func i32Rotl(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.rotl(.i32), op) }
    static func i32Rotr(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.rotr(.i32), op) }
    
    static func i64DivS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.divS(.i64), op) }
    static func i64DivU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.divU(.i64), op) }
    static func i64RemS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.remS(.i64), op) }
    static func i64RemU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.remU(.i64), op) }

    static func i64And(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.and(.i64), op) }
    static func i64Or(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.or(.i64), op) }
    static func i64Xor(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.xor(.i64), op) }
    static func i64Shl(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.shl(.i64), op) }
    static func i64ShrS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.shrS(.i64), op) }
    static func i64ShrU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.shrU(.i64), op) }
    static func i64Rotl(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.rotl(.i64), op) }
    static func i64Rotr(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.rotr(.i64), op) }

    static func f32Abs(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.abs(.f32), op) }
    static func f32Neg(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.neg(.f32), op) }
    static func f32Ceil(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.ceil(.f32), op) }
    static func f32Floor(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.floor(.f32), op) }
    static func f32Trunc(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.trunc(.f32), op) }
    static func f32Nearest(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.nearest(.f32), op) }
    static func f32Sqrt(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.sqrt(.f32), op) }

    static func f32Div(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.div(.f32), op) }
    static func f32Min(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.min(.f32), op) }
    static func f32Max(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.max(.f32), op) }
    static func f32Copysign(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.copysign(.f32), op) }

    static func f64Abs(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.abs(.f64), op) }
    static func f64Neg(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.neg(.f64), op) }
    static func f64Ceil(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.ceil(.f64), op) }
    static func f64Floor(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.floor(.f64), op) }
    static func f64Trunc(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.trunc(.f64), op) }
    static func f64Nearest(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.nearest(.f64), op) }
    static func f64Sqrt(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.sqrt(.f64), op) }

    static func f64Div(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.div(.f64), op) }
    static func f64Min(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.min(.f64), op) }
    static func f64Max(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.max(.f64), op) }
    static func f64Copysign(_ op: BinaryOperand) -> Instruction { .numericFloatBinary(.copysign(.f64), op) }

    static func i32WrapI64(_ op: UnaryOperand) -> Instruction { .numericConversion(.wrap, op) }
    static func i32TruncF32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSigned(.i32, .f32), op) }
    static func i32TruncF32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncUnsigned(.i32, .f32), op) }
    static func i32TruncF64S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSigned(.i32, .f64), op) }
    static func i32TruncF64U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncUnsigned(.i32, .f64), op) }
    static func i64ExtendI32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.extendSigned, op) }
    static func i64ExtendI32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.extendUnsigned, op) }
    static func i64TruncF32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSigned(.i64, .f32), op) }
    static func i64TruncF32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncUnsigned(.i64, .f32), op) }
    static func i64TruncF64S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSigned(.i64, .f64), op) }
    static func i64TruncF64U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncUnsigned(.i64, .f64), op) }
    static func f32ConvertI32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertSigned(.f32, .i32), op) }
    static func f32ConvertI32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertUnsigned(.f32, .i32), op) }
    static func f32ConvertI64S(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertSigned(.f32, .i64), op) }
    static func f32ConvertI64U(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertUnsigned(.f32, .i64), op) }
    static func f32DemoteF64(_ op: UnaryOperand) -> Instruction { .numericConversion(.demote, op) }
    static func f64ConvertI32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertSigned(.f64, .i32), op) }
    static func f64ConvertI32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertUnsigned(.f64, .i32), op) }
    static func f64ConvertI64S(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertSigned(.f64, .i64), op) }
    static func f64ConvertI64U(_ op: UnaryOperand) -> Instruction { .numericConversion(.convertUnsigned(.f64, .i64), op) }
    static func f64PromoteF32(_ op: UnaryOperand) -> Instruction { .numericConversion(.promote, op) }

    static func i32ReinterpretF32(_ op: UnaryOperand) -> Instruction { .numericConversion(.reinterpret(.i32, .f32), op) }
    static func i64ReinterpretF64(_ op: UnaryOperand) -> Instruction { .numericConversion(.reinterpret(.i64, .f64), op) }
    static func f32ReinterpretI32(_ op: UnaryOperand) -> Instruction { .numericConversion(.reinterpret(.f32, .i32), op) }
    static func f64ReinterpretI64(_ op: UnaryOperand) -> Instruction { .numericConversion(.reinterpret(.f64, .i64), op) }

    static func i32Extend8S(_ op: UnaryOperand) -> Instruction { .numericConversion(.extend8Signed(.i32), op) }
    static func i32Extend16S(_ op: UnaryOperand) -> Instruction { .numericConversion(.extend16Signed(.i32), op) }
    static func i64Extend8S(_ op: UnaryOperand) -> Instruction { .numericConversion(.extend8Signed(.i64), op) }
    static func i64Extend16S(_ op: UnaryOperand) -> Instruction { .numericConversion(.extend16Signed(.i64), op) }
    static func i64Extend32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.extend32Signed, op) }

    static func i32TruncSatF32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingSigned(.i32, .f32), op) }
    static func i32TruncSatF32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingUnsigned(.i32, .f32), op) }
    static func i32TruncSatF64S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingSigned(.i32, .f64), op) }
    static func i32TruncSatF64U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingUnsigned(.i32, .f64), op) }
    static func i64TruncSatF32S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingSigned(.i64, .f32), op) }
    static func i64TruncSatF32U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingUnsigned(.i64, .f32), op) }
    static func i64TruncSatF64S(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingSigned(.i64, .f64), op) }
    static func i64TruncSatF64U(_ op: UnaryOperand) -> Instruction { .numericConversion(.truncSaturatingUnsigned(.i64, .f64), op) }
}
