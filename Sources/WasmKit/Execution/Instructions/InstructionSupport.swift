import WasmParser

typealias VReg = Int16
typealias LVReg = Int32
typealias LLVReg = Int64

protocol InstructionImmediate {
    static func load(from pc: inout Pc) -> Self
    static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void)
}

extension InstructionImmediate {
    func emit(to emitSlot: (CodeSlot) -> Void) {
        Self.emit { buildCodeSlot in
            emitSlot(buildCodeSlot(self))
        }
    }
}

extension LLVReg: InstructionImmediate {
    static func load(from pc: inout Pc) -> Self {
        Self(bitPattern: pc.read())
    }
    static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
        emitSlot { UInt64(bitPattern: $0) }
    }
}

extension Instruction {
    struct MemArg: Equatable {
        let offset: UInt64
    }
    
    struct BrTable: Equatable {
        struct Entry {
            var offset: Int32
        }
        let baseAddress: UnsafePointer<Entry>
        
        static func == (lhs: Instruction.BrTable, rhs: Instruction.BrTable) -> Bool {
            lhs.baseAddress == rhs.baseAddress
        }
    }

    /// size = 6, alignment = 2
    struct BinaryOperand: Equatable {
        let result: VReg
        let lhs: VReg
        let rhs: VReg
    }
    
    /// size = 4, alignment = 2
    struct UnaryOperand: Equatable {
        let result: VReg
        let input: VReg
    }
    
    /// size = 6, alignment = 4
    struct Const32Operand: Equatable, InstructionImmediate {
        let value: UInt32
        let result: LVReg
        static func load(from pc: inout Pc) -> Self {
            pc.read()
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
        }
    }
    /// size = 2, alignment = 2
    struct Const64Operand: Equatable {
        let result: VReg
    }

    struct FloatUnaryOperand: Equatable {
        let operation: NumericInstruction.FloatUnary
        let unary: UnaryOperand
    }

    struct ConversionOperand: Equatable {
        let operation: NumericInstruction.Conversion
        let unary: UnaryOperand
    }

    /// size = 4, alignment = 8
    struct LoadOperand: Equatable {
        let pointer: VReg
        let result: VReg
    }

    struct StoreOperand: Equatable {
        let pointer: VReg
        let value: VReg
    }
    
    struct MemorySizeOperand: Equatable {
        let memoryIndex: MemoryIndex
        let result: VReg
    }
    
    struct MemoryGrowOperand: Equatable {
        let result: VReg
        let delta: VReg
    }
    
    struct MemoryInitOperand: Equatable {
        let destOffset: VReg
        let sourceOffset: VReg
        let size: VReg
    }
    
    struct MemoryCopyOperand: Equatable {
        let destOffset: VReg
        let sourceOffset: VReg
        let size: VReg
    }
    
    struct MemoryFillOperand: Equatable {
        let destOffset: VReg
        let value: VReg
        let size: VReg
    }
    
    struct SelectOperand: Equatable {
        let result: VReg
        let condition: VReg
        let onTrue: VReg
        let onFalse: VReg
    }
    
    struct RefNullOperand: Equatable {
        let type: ReferenceType
        let result: VReg
    }
    
    struct RefIsNullOperand: Equatable {
        let value: VReg
        let result: VReg
    }
    
    struct RefFuncOperand: Equatable {
        let index: FunctionIndex
        let result: VReg
    }
    
    struct TableGetOperand: Equatable {
        let index: VReg
        let result: VReg
    }
    
    struct TableSetOperand: Equatable {
        let index: VReg
        let value: VReg
    }
    
    struct TableSizeOperand: Equatable {
        let tableIndex: TableIndex
        let result: VReg
    }
    
    struct TableGrowOperand: Equatable {
        let result: VReg
        let delta: VReg
        let value: VReg
    }
    
    struct TableFillOperand: Equatable {
        let destOffset: VReg
        let value: VReg
        let size: VReg
    }
    
    struct TableCopyOperand: Equatable {
        let sourceOffset: VReg
        let destOffset: VReg
        let size: VReg
    }
    
    struct TableInitOperand: Equatable {
        let destOffset: VReg
        let sourceOffset: VReg
        let size: VReg
    }

    typealias GlobalGetOperand = LLVReg
    typealias GlobalSetOperand = LLVReg

    struct CopyStackOperand: Equatable, InstructionImmediate {
        let source: Int32
        let dest: Int32

        static func load(from pc: inout Pc) -> Self {
            pc.read()
        }
        static func emit(to emitSlot: ((Self) -> CodeSlot) -> Void) {
            emitSlot { unsafeBitCast($0, to: CodeSlot.self) }
        }
    }

    struct IfOperand: Equatable {
        // `else` for if-then-else-end sequence, `end` for if-then-end sequence
        let elseOrEndOffset: UInt32
        let condition: VReg
    }
    
    struct BrIfOperand: Equatable {
        let offset: Int32
        let condition: VReg
    }
    
    struct BrTableOperand: Equatable {
        let count: UInt16
        let index: VReg
    }

    struct CallLikeOperand: Equatable {
        let spAddend: VReg
    }
    struct CallOperand: Equatable {
        let callLike: CallLikeOperand
    }

    struct InternalCallOperand: Equatable {
        let callLike: CallLikeOperand
    }

    typealias CompilingCallOperand = InternalCallOperand
    
    struct CallIndirectOperand: Equatable {
        let index: VReg
        let callLike: CallLikeOperand
    }

    typealias OnEnterOperand = FunctionIndex
    typealias OnExitOperand = FunctionIndex
    

    static func numericFloatUnary(_ op: NumericInstruction.FloatUnary, _ unary: Instruction.UnaryOperand) -> Instruction {
        .numericFloatUnary(FloatUnaryOperand(operation: op, unary: unary))
    }
    static func numericConversion(_ op: NumericInstruction.Conversion, _ unary: Instruction.UnaryOperand) -> Instruction {
        .numericConversion(ConversionOperand(operation: op, unary: unary))
    }

    static func f32Abs(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.abs(.f32), op) }
    static func f32Neg(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.neg(.f32), op) }
    static func f32Ceil(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.ceil(.f32), op) }
    static func f32Floor(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.floor(.f32), op) }
    static func f32Trunc(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.trunc(.f32), op) }
    static func f32Nearest(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.nearest(.f32), op) }
    static func f32Sqrt(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.sqrt(.f32), op) }

    static func f64Abs(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.abs(.f64), op) }
    static func f64Neg(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.neg(.f64), op) }
    static func f64Ceil(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.ceil(.f64), op) }
    static func f64Floor(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.floor(.f64), op) }
    static func f64Trunc(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.trunc(.f64), op) }
    static func f64Nearest(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.nearest(.f64), op) }
    static func f64Sqrt(_ op: UnaryOperand) -> Instruction { .numericFloatUnary(.sqrt(.f64), op) }

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
    var rawValue: UInt64 {
        assert(_isPOD(Instruction.self))
        typealias RawInstruction = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        let raw = unsafeBitCast(self.tagged, to: RawInstruction.self)
        let slotData: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            raw.0, raw.1, raw.2, raw.3, raw.4, raw.5, raw.6, 0
        )
        return unsafeBitCast(slotData, to: UInt64.self)
    }
}

extension Instruction.Tagged {
    init(rawValue: UInt64) {
        assert(_isPOD(Instruction.Tagged.self))
        typealias RawBytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        let raw = unsafeBitCast(rawValue, to: RawBytes.self)
        let rawInst: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            raw.0, raw.1, raw.2, raw.3, raw.4, raw.5, raw.6
        )
        self = unsafeBitCast(rawInst, to: Instruction.Tagged.self)
    }
}

struct InstructionPrintingContext {
    let shouldColor: Bool
    let function: Function
    var nameRegistry: NameRegistry

    func reg(_ reg: VReg) -> String {
        let adjusted = VReg(StackLayout.frameHeaderSize(type: function.type)) + reg
        if shouldColor {
            let regColor = adjusted < 15 ? "\u{001B}[3\(adjusted + 1)m" : ""
            return "\(regColor)reg:\(reg)\u{001B}[0m"
        } else {
            return "reg:\(reg)"
        }
    }

    func memarg(_ memarg: Instruction.MemArg) -> String {
        "offset: \(memarg.offset)"
    }

    mutating func callee(_ callee: InternalFunction) -> String {
        return "'" + nameRegistry.symbolicate(callee) + "'"
    }

    func hex<T: BinaryInteger>(_ value: T) -> String {
        let hex = String(value, radix: 16)
        return "0x\(String(repeating: "0", count: 16 - hex.count) + hex)"
    }

    func global(_ global: InternalGlobal) -> String {
        "global:\(hex(global.bitPattern))"
    }

    func value(_ value: UntypedValue) -> String {
        "untyped:\(hex(value.storage))"
    }

    mutating func print<Target>(
        instruction: Instruction,
        to target: inout Target
    ) where Target : TextOutputStream {
        switch instruction {
        case .unreachable:
            target.write("unreachable")
        case .nop:
            target.write("nop")
//        case .globalGet(let op):
//            target.write("\(reg(op.result)) = global.get \(global(op.global))")
//        case .globalSet(let op):
//            target.write("global.set \(global(op.global)), \(reg(op.value))")
//        case .numericConst(let op):
//            target.write("\(reg(op.result)) = \(value(op.value))")
//        case .call(let op):
//            target.write("call \(callee(op.callee)), sp: +\(op.callLike.spAddend)")
//        case .callIndirect(let op):
//            target.write("call_indirect \(reg(op.index)), \(op.tableIndex), (func_ty id:\(op.type.id)), sp: +\(op.callLike.spAddend)")
//        case .compilingCall(let op):
//            target.write("compiling_call \(callee(op.callee)), sp: +\(op.callLike.spAddend)")
//        case .i32Load(let op):
//            target.write("\(reg(op.result)) = i32.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .i64Load(let op):
//            target.write("\(reg(op.result)) = i64.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .f32Load(let op):
//            target.write("\(reg(op.result)) = f32.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .f64Load(let op):
//            target.write("\(reg(op.result)) = f64.load \(reg(op.pointer)), \(memarg(op.memarg))")
//        case .copyStack(let op):
//            target.write("\(reg(op.dest)) = copy \(reg(op.source))")
        case .i32Add(let op):
            target.write("\(reg(op.result)) = i32.add \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Sub(let op):
            target.write("\(reg(op.result)) = i32.sub \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32LtU(let op):
            target.write("\(reg(op.result)) = i32.lt_u \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Eq(let op):
            target.write("\(reg(op.result)) = i32.eq \(reg(op.lhs)), \(reg(op.rhs))")
        case .i32Eqz(let op):
            target.write("\(reg(op.result)) = i32.eqz \(reg(op.input))")
//        case .i32Store(let op):
//            target.write("i32.store \(reg(op.pointer)), \(reg(op.value)), \(memarg(op.memarg))")
        case .brIfNot(let op):
            target.write("br_if_not \(reg(op.condition)), +\(op.offset)")
        case .brIf(let op):
            target.write("br_if \(reg(op.condition)), +\(op.offset)")
        case .br(let offset):
            target.write("br \(offset > 0 ? "+" : "")\(offset)")
        case ._return:
            target.write("return")
        default:
            target.write(String(describing: instruction))
        }
    }
}
