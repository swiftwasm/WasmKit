import WasmParser

extension Instruction {
    struct MemArg: Equatable {
        let offset: UInt64
    }
    
    struct BrTable: Equatable {
        struct Entry {
            var offset: Int32
        }
        let buffer: UnsafeBufferPointer<Entry>
        
        static func == (lhs: Instruction.BrTable, rhs: Instruction.BrTable) -> Bool {
            lhs.buffer.baseAddress == rhs.buffer.baseAddress
        }
    }

    typealias Register = Int

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
        let value: UntypedValue
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

    struct CallLikeOperand: Equatable {
        let spAddend: Instruction.Register
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
    

    static func i64DivS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.divS(.i64), op) }
    static func i64DivU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.divU(.i64), op) }
    static func i64RemS(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.remS(.i64), op) }
    static func i64RemU(_ op: BinaryOperand) -> Instruction { .numericIntBinary(.remU(.i64), op) }

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

extension Instruction {
    func print<Target>(to target: inout Target) where Target : TextOutputStream {
        func reg(_ reg: Register) -> String {
            let regColor = reg < 15 ? "\u{001B}[3\(reg + 1)m" : ""
            return "\(regColor)reg:\(reg)\u{001B}[0m"
        }
        func memarg(_ memarg: MemArg) -> String {
            "offset: \(memarg.offset)"
        }
        switch self {
        case .unreachable:
            target.write("unreachable")
        case .nop:
            target.write("nop")
        case .globalGet(let op):
            target.write("\(reg(op.result)) = global.get \(op.index)")
        case .globalSet(let op):
            target.write("global.set \(op.index), \(reg(op.value))")
        case .numericConst(let op):
            target.write("\(reg(op.result)) = \(op.value)")
        case .call(let op):
            target.write("call \(op.index), sp: +\(op.callLike.spAddend)")
        case .callIndirect(let op):
            target.write("call_indirect \(reg(op.index)), \(op.tableIndex), \(op.typeIndex), sp: +\(op.callLike.spAddend)")
        case .i32Load(let op):
            target.write("\(reg(op.result)) = i32.load \(reg(op.pointer)), \(memarg(op.memarg))")
        case .i64Load(let op):
            target.write("\(reg(op.result)) = i64.load \(reg(op.pointer)), \(memarg(op.memarg))")
        case .f32Load(let op):
            target.write("\(reg(op.result)) = f32.load \(reg(op.pointer)), \(memarg(op.memarg))")
        case .f64Load(let op):
            target.write("\(reg(op.result)) = f64.load \(reg(op.pointer)), \(memarg(op.memarg))")
        case .copyStack(let op):
            target.write("\(reg(op.dest)) = copy \(reg(op.source))")
        case .i32Add(let op):
            target.write("\(reg(op.result)) = i32.add \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Sub(let op):
            target.write("\(reg(op.result)) = i32.sub \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32LtU(let op):
            target.write("\(reg(op.result)) = i32.lt_u \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Eq(let op):
            target.write("\(reg(op.result)) = i32.eq \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Store(let op):
            target.write("i32.store \(reg(op.pointer)), \(reg(op.value)), \(memarg(op.memarg))")
        case .numericIntBinary(let op, let operands):
            target.write("\(reg(operands.result)) = \(op) \(reg(operands.lhs)), \(reg(operands.rhs))")
        case .brIfNot(let op):
            target.write("br_if_not \(reg(op.condition)), +\(op.offset)")
        case .br(let offset):
            target.write("br \(offset > 0 ? "+" : "")\(offset)")
        case .return:
            target.write("return")
        case .endOfFunction:
            target.write("end")
        default:
            target.write(String(describing: self))
        }
    }
}
