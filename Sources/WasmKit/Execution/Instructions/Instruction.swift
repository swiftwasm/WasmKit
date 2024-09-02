enum Instruction: Equatable {
    case copyStack(Instruction.CopyStackOperand)
    case globalGet(Instruction.GlobalGetOperand)
    case globalSet(Instruction.GlobalSetOperand)
    case call(Instruction.CallOperand)
    case compilingCall(Instruction.CompilingCallOperand)
    case internalCall(Instruction.InternalCallOperand)
    case callIndirect(Instruction.CallIndirectOperand)
    case unreachable
    case nop
    case ifThen(Instruction.IfOperand)
    case br(offset: Int32)
    case brIf(Instruction.BrIfOperand)
    case brIfNot(Instruction.BrIfOperand)
    case brTable(Instruction.BrTableOperand)
    case _return
    case endOfExecution
    case i32Load(Instruction.LoadOperand)
    case i64Load(Instruction.LoadOperand)
    case f32Load(Instruction.LoadOperand)
    case f64Load(Instruction.LoadOperand)
    case i32Load8S(Instruction.LoadOperand)
    case i32Load8U(Instruction.LoadOperand)
    case i32Load16S(Instruction.LoadOperand)
    case i32Load16U(Instruction.LoadOperand)
    case i64Load8S(Instruction.LoadOperand)
    case i64Load8U(Instruction.LoadOperand)
    case i64Load16S(Instruction.LoadOperand)
    case i64Load16U(Instruction.LoadOperand)
    case i64Load32S(Instruction.LoadOperand)
    case i64Load32U(Instruction.LoadOperand)
    case i32Store(Instruction.StoreOperand)
    case i64Store(Instruction.StoreOperand)
    case f32Store(Instruction.StoreOperand)
    case f64Store(Instruction.StoreOperand)
    case i32Store8(Instruction.StoreOperand)
    case i32Store16(Instruction.StoreOperand)
    case i64Store8(Instruction.StoreOperand)
    case i64Store16(Instruction.StoreOperand)
    case i64Store32(Instruction.StoreOperand)
    case memorySize(Instruction.MemorySizeOperand)
    case memoryGrow(Instruction.MemoryGrowOperand)
    case memoryInit(Instruction.MemoryInitOperand)
    case memoryDataDrop(DataIndex)
    case memoryCopy(Instruction.MemoryCopyOperand)
    case memoryFill(Instruction.MemoryFillOperand)
    case const32(Instruction.Const32Operand)
    case const64(Instruction.Const64Operand)
    case i32Add(Instruction.BinaryOperand)
    case i64Add(Instruction.BinaryOperand)
    case i32Sub(Instruction.BinaryOperand)
    case i64Sub(Instruction.BinaryOperand)
    case i32Mul(Instruction.BinaryOperand)
    case i64Mul(Instruction.BinaryOperand)
    case i32And(Instruction.BinaryOperand)
    case i64And(Instruction.BinaryOperand)
    case i32Or(Instruction.BinaryOperand)
    case i64Or(Instruction.BinaryOperand)
    case i32Xor(Instruction.BinaryOperand)
    case i64Xor(Instruction.BinaryOperand)
    case i32Shl(Instruction.BinaryOperand)
    case i64Shl(Instruction.BinaryOperand)
    case i32ShrS(Instruction.BinaryOperand)
    case i64ShrS(Instruction.BinaryOperand)
    case i32ShrU(Instruction.BinaryOperand)
    case i64ShrU(Instruction.BinaryOperand)
    case i32Rotl(Instruction.BinaryOperand)
    case i64Rotl(Instruction.BinaryOperand)
    case i32Rotr(Instruction.BinaryOperand)
    case i64Rotr(Instruction.BinaryOperand)
    case i32DivS(Instruction.BinaryOperand)
    case i64DivS(Instruction.BinaryOperand)
    case i32DivU(Instruction.BinaryOperand)
    case i64DivU(Instruction.BinaryOperand)
    case i32RemS(Instruction.BinaryOperand)
    case i64RemS(Instruction.BinaryOperand)
    case i32RemU(Instruction.BinaryOperand)
    case i64RemU(Instruction.BinaryOperand)
    case i32Eq(Instruction.BinaryOperand)
    case i64Eq(Instruction.BinaryOperand)
    case i32Ne(Instruction.BinaryOperand)
    case i64Ne(Instruction.BinaryOperand)
    case i32LtS(Instruction.BinaryOperand)
    case i64LtS(Instruction.BinaryOperand)
    case i32LtU(Instruction.BinaryOperand)
    case i64LtU(Instruction.BinaryOperand)
    case i32GtS(Instruction.BinaryOperand)
    case i64GtS(Instruction.BinaryOperand)
    case i32GtU(Instruction.BinaryOperand)
    case i64GtU(Instruction.BinaryOperand)
    case i32LeS(Instruction.BinaryOperand)
    case i64LeS(Instruction.BinaryOperand)
    case i32LeU(Instruction.BinaryOperand)
    case i64LeU(Instruction.BinaryOperand)
    case i32GeS(Instruction.BinaryOperand)
    case i64GeS(Instruction.BinaryOperand)
    case i32GeU(Instruction.BinaryOperand)
    case i64GeU(Instruction.BinaryOperand)
    case i32Clz(Instruction.UnaryOperand)
    case i64Clz(Instruction.UnaryOperand)
    case i32Ctz(Instruction.UnaryOperand)
    case i64Ctz(Instruction.UnaryOperand)
    case i32Popcnt(Instruction.UnaryOperand)
    case i64Popcnt(Instruction.UnaryOperand)
    case i32Eqz(Instruction.UnaryOperand)
    case i64Eqz(Instruction.UnaryOperand)
    case i32WrapI64(Instruction.UnaryOperand)
    case i64ExtendI32S(Instruction.UnaryOperand)
    case i64ExtendI32U(Instruction.UnaryOperand)
    case i32Extend8S(Instruction.UnaryOperand)
    case i64Extend8S(Instruction.UnaryOperand)
    case i32Extend16S(Instruction.UnaryOperand)
    case i64Extend16S(Instruction.UnaryOperand)
    case i64Extend32S(Instruction.UnaryOperand)
    case i32TruncF32S(Instruction.UnaryOperand)
    case i32TruncF32U(Instruction.UnaryOperand)
    case i32TruncSatF32S(Instruction.UnaryOperand)
    case i32TruncSatF32U(Instruction.UnaryOperand)
    case i32TruncF64S(Instruction.UnaryOperand)
    case i32TruncF64U(Instruction.UnaryOperand)
    case i32TruncSatF64S(Instruction.UnaryOperand)
    case i32TruncSatF64U(Instruction.UnaryOperand)
    case i64TruncF32S(Instruction.UnaryOperand)
    case i64TruncF32U(Instruction.UnaryOperand)
    case i64TruncSatF32S(Instruction.UnaryOperand)
    case i64TruncSatF32U(Instruction.UnaryOperand)
    case i64TruncF64S(Instruction.UnaryOperand)
    case i64TruncF64U(Instruction.UnaryOperand)
    case i64TruncSatF64S(Instruction.UnaryOperand)
    case i64TruncSatF64U(Instruction.UnaryOperand)
    case f32ConvertI32S(Instruction.UnaryOperand)
    case f32ConvertI32U(Instruction.UnaryOperand)
    case f32ConvertI64S(Instruction.UnaryOperand)
    case f32ConvertI64U(Instruction.UnaryOperand)
    case f64ConvertI32S(Instruction.UnaryOperand)
    case f64ConvertI32U(Instruction.UnaryOperand)
    case f64ConvertI64S(Instruction.UnaryOperand)
    case f64ConvertI64U(Instruction.UnaryOperand)
    case f32ReinterpretI32(Instruction.UnaryOperand)
    case f64ReinterpretI64(Instruction.UnaryOperand)
    case i32ReinterpretF32(Instruction.UnaryOperand)
    case i64ReinterpretF64(Instruction.UnaryOperand)
    case f32Add(Instruction.BinaryOperand)
    case f64Add(Instruction.BinaryOperand)
    case f32Sub(Instruction.BinaryOperand)
    case f64Sub(Instruction.BinaryOperand)
    case f32Mul(Instruction.BinaryOperand)
    case f64Mul(Instruction.BinaryOperand)
    case f32Div(Instruction.BinaryOperand)
    case f64Div(Instruction.BinaryOperand)
    case f32Min(Instruction.BinaryOperand)
    case f64Min(Instruction.BinaryOperand)
    case f32Max(Instruction.BinaryOperand)
    case f64Max(Instruction.BinaryOperand)
    case f32CopySign(Instruction.BinaryOperand)
    case f64CopySign(Instruction.BinaryOperand)
    case f32Eq(Instruction.BinaryOperand)
    case f64Eq(Instruction.BinaryOperand)
    case f32Ne(Instruction.BinaryOperand)
    case f64Ne(Instruction.BinaryOperand)
    case f32Lt(Instruction.BinaryOperand)
    case f64Lt(Instruction.BinaryOperand)
    case f32Gt(Instruction.BinaryOperand)
    case f64Gt(Instruction.BinaryOperand)
    case f32Le(Instruction.BinaryOperand)
    case f64Le(Instruction.BinaryOperand)
    case f32Ge(Instruction.BinaryOperand)
    case f64Ge(Instruction.BinaryOperand)
    case f32Abs(Instruction.UnaryOperand)
    case f64Abs(Instruction.UnaryOperand)
    case f32Neg(Instruction.UnaryOperand)
    case f64Neg(Instruction.UnaryOperand)
    case f32Ceil(Instruction.UnaryOperand)
    case f64Ceil(Instruction.UnaryOperand)
    case f32Floor(Instruction.UnaryOperand)
    case f64Floor(Instruction.UnaryOperand)
    case f32Trunc(Instruction.UnaryOperand)
    case f64Trunc(Instruction.UnaryOperand)
    case f32Nearest(Instruction.UnaryOperand)
    case f64Nearest(Instruction.UnaryOperand)
    case f32Sqrt(Instruction.UnaryOperand)
    case f64Sqrt(Instruction.UnaryOperand)
    case f64PromoteF32(Instruction.UnaryOperand)
    case f32DemoteF64(Instruction.UnaryOperand)
    case select
    case refNull(Instruction.RefNullOperand)
    case refIsNull(Instruction.RefIsNullOperand)
    case refFunc(Instruction.RefFuncOperand)
    case tableGet(Instruction.TableGetOperand)
    case tableSet(Instruction.TableSetOperand)
    case tableSize(Instruction.TableSizeOperand)
    case tableGrow(Instruction.TableGrowOperand)
    case tableFill(Instruction.TableFillOperand)
    case tableCopy(Instruction.TableCopyOperand)
    case tableInit(Instruction.TableInitOperand)
    case tableElementDrop(ElementIndex)
    case onEnter(Instruction.OnEnterOperand)
    case onExit(Instruction.OnExitOperand)
}

extension Instruction {
    var hasImmediate: Bool {
        switch self {
        case .copyStack: return true
        case .globalGet: return true
        case .globalSet: return true
        case .call: return true
        case .compilingCall: return true
        case .internalCall: return true
        case .callIndirect: return true
        case .unreachable: return false
        case .nop: return false
        case .ifThen: return true
        case .br: return true
        case .brIf: return true
        case .brIfNot: return true
        case .brTable: return true
        case ._return: return false
        case .endOfExecution: return false
        case .i32Load: return true
        case .i64Load: return true
        case .f32Load: return true
        case .f64Load: return true
        case .i32Load8S: return true
        case .i32Load8U: return true
        case .i32Load16S: return true
        case .i32Load16U: return true
        case .i64Load8S: return true
        case .i64Load8U: return true
        case .i64Load16S: return true
        case .i64Load16U: return true
        case .i64Load32S: return true
        case .i64Load32U: return true
        case .i32Store: return true
        case .i64Store: return true
        case .f32Store: return true
        case .f64Store: return true
        case .i32Store8: return true
        case .i32Store16: return true
        case .i64Store8: return true
        case .i64Store16: return true
        case .i64Store32: return true
        case .memorySize: return true
        case .memoryGrow: return true
        case .memoryInit: return true
        case .memoryDataDrop: return true
        case .memoryCopy: return true
        case .memoryFill: return true
        case .const32: return true
        case .const64: return true
        case .i32Add: return true
        case .i64Add: return true
        case .i32Sub: return true
        case .i64Sub: return true
        case .i32Mul: return true
        case .i64Mul: return true
        case .i32And: return true
        case .i64And: return true
        case .i32Or: return true
        case .i64Or: return true
        case .i32Xor: return true
        case .i64Xor: return true
        case .i32Shl: return true
        case .i64Shl: return true
        case .i32ShrS: return true
        case .i64ShrS: return true
        case .i32ShrU: return true
        case .i64ShrU: return true
        case .i32Rotl: return true
        case .i64Rotl: return true
        case .i32Rotr: return true
        case .i64Rotr: return true
        case .i32DivS: return true
        case .i64DivS: return true
        case .i32DivU: return true
        case .i64DivU: return true
        case .i32RemS: return true
        case .i64RemS: return true
        case .i32RemU: return true
        case .i64RemU: return true
        case .i32Eq: return true
        case .i64Eq: return true
        case .i32Ne: return true
        case .i64Ne: return true
        case .i32LtS: return true
        case .i64LtS: return true
        case .i32LtU: return true
        case .i64LtU: return true
        case .i32GtS: return true
        case .i64GtS: return true
        case .i32GtU: return true
        case .i64GtU: return true
        case .i32LeS: return true
        case .i64LeS: return true
        case .i32LeU: return true
        case .i64LeU: return true
        case .i32GeS: return true
        case .i64GeS: return true
        case .i32GeU: return true
        case .i64GeU: return true
        case .i32Clz: return true
        case .i64Clz: return true
        case .i32Ctz: return true
        case .i64Ctz: return true
        case .i32Popcnt: return true
        case .i64Popcnt: return true
        case .i32Eqz: return true
        case .i64Eqz: return true
        case .i32WrapI64: return true
        case .i64ExtendI32S: return true
        case .i64ExtendI32U: return true
        case .i32Extend8S: return true
        case .i64Extend8S: return true
        case .i32Extend16S: return true
        case .i64Extend16S: return true
        case .i64Extend32S: return true
        case .i32TruncF32S: return true
        case .i32TruncF32U: return true
        case .i32TruncSatF32S: return true
        case .i32TruncSatF32U: return true
        case .i32TruncF64S: return true
        case .i32TruncF64U: return true
        case .i32TruncSatF64S: return true
        case .i32TruncSatF64U: return true
        case .i64TruncF32S: return true
        case .i64TruncF32U: return true
        case .i64TruncSatF32S: return true
        case .i64TruncSatF32U: return true
        case .i64TruncF64S: return true
        case .i64TruncF64U: return true
        case .i64TruncSatF64S: return true
        case .i64TruncSatF64U: return true
        case .f32ConvertI32S: return true
        case .f32ConvertI32U: return true
        case .f32ConvertI64S: return true
        case .f32ConvertI64U: return true
        case .f64ConvertI32S: return true
        case .f64ConvertI32U: return true
        case .f64ConvertI64S: return true
        case .f64ConvertI64U: return true
        case .f32ReinterpretI32: return true
        case .f64ReinterpretI64: return true
        case .i32ReinterpretF32: return true
        case .i64ReinterpretF64: return true
        case .f32Add: return true
        case .f64Add: return true
        case .f32Sub: return true
        case .f64Sub: return true
        case .f32Mul: return true
        case .f64Mul: return true
        case .f32Div: return true
        case .f64Div: return true
        case .f32Min: return true
        case .f64Min: return true
        case .f32Max: return true
        case .f64Max: return true
        case .f32CopySign: return true
        case .f64CopySign: return true
        case .f32Eq: return true
        case .f64Eq: return true
        case .f32Ne: return true
        case .f64Ne: return true
        case .f32Lt: return true
        case .f64Lt: return true
        case .f32Gt: return true
        case .f64Gt: return true
        case .f32Le: return true
        case .f64Le: return true
        case .f32Ge: return true
        case .f64Ge: return true
        case .f32Abs: return true
        case .f64Abs: return true
        case .f32Neg: return true
        case .f64Neg: return true
        case .f32Ceil: return true
        case .f64Ceil: return true
        case .f32Floor: return true
        case .f64Floor: return true
        case .f32Trunc: return true
        case .f64Trunc: return true
        case .f32Nearest: return true
        case .f64Nearest: return true
        case .f32Sqrt: return true
        case .f64Sqrt: return true
        case .f64PromoteF32: return true
        case .f32DemoteF64: return true
        case .select: return false
        case .refNull: return true
        case .refIsNull: return true
        case .refFunc: return true
        case .tableGet: return true
        case .tableSet: return true
        case .tableSize: return true
        case .tableGrow: return true
        case .tableFill: return true
        case .tableCopy: return true
        case .tableInit: return true
        case .tableElementDrop: return true
        case .onEnter: return true
        case .onExit: return true
        }
    }
}

extension Instruction {
    var useRawOperand: Bool {
        switch self {
        case .copyStack: return true
        case .globalGet: return true
        case .globalSet: return true
        case .const32: return true
        case .const64: return true
        default: return false
        }
    }
}
extension Instruction {
    var rawImmediate: any InstructionImmediate {
        switch self {
        case .copyStack(let copyStackOperand): return copyStackOperand
        case .globalGet(let globalGetOperand): return globalGetOperand
        case .globalSet(let globalSetOperand): return globalSetOperand
        case .const32(let const32Operand): return const32Operand
        case .const64(let const64Operand): return const64Operand
        default: preconditionFailure()
        }
    }
}
extension Instruction {
    enum Tagged {
        case call(Instruction.CallOperand)
        case compilingCall(Instruction.CompilingCallOperand)
        case internalCall(Instruction.InternalCallOperand)
        case callIndirect(Instruction.CallIndirectOperand)
        case ifThen(Instruction.IfOperand)
        case br(Int32)
        case brIf(Instruction.BrIfOperand)
        case brIfNot(Instruction.BrIfOperand)
        case brTable(Instruction.BrTableOperand)
        case i32Load(Instruction.LoadOperand)
        case i64Load(Instruction.LoadOperand)
        case f32Load(Instruction.LoadOperand)
        case f64Load(Instruction.LoadOperand)
        case i32Load8S(Instruction.LoadOperand)
        case i32Load8U(Instruction.LoadOperand)
        case i32Load16S(Instruction.LoadOperand)
        case i32Load16U(Instruction.LoadOperand)
        case i64Load8S(Instruction.LoadOperand)
        case i64Load8U(Instruction.LoadOperand)
        case i64Load16S(Instruction.LoadOperand)
        case i64Load16U(Instruction.LoadOperand)
        case i64Load32S(Instruction.LoadOperand)
        case i64Load32U(Instruction.LoadOperand)
        case i32Store(Instruction.StoreOperand)
        case i64Store(Instruction.StoreOperand)
        case f32Store(Instruction.StoreOperand)
        case f64Store(Instruction.StoreOperand)
        case i32Store8(Instruction.StoreOperand)
        case i32Store16(Instruction.StoreOperand)
        case i64Store8(Instruction.StoreOperand)
        case i64Store16(Instruction.StoreOperand)
        case i64Store32(Instruction.StoreOperand)
        case memorySize(Instruction.MemorySizeOperand)
        case memoryGrow(Instruction.MemoryGrowOperand)
        case memoryInit(Instruction.MemoryInitOperand)
        case memoryDataDrop(DataIndex)
        case memoryCopy(Instruction.MemoryCopyOperand)
        case memoryFill(Instruction.MemoryFillOperand)
        case i32Add(Instruction.BinaryOperand)
        case i64Add(Instruction.BinaryOperand)
        case i32Sub(Instruction.BinaryOperand)
        case i64Sub(Instruction.BinaryOperand)
        case i32Mul(Instruction.BinaryOperand)
        case i64Mul(Instruction.BinaryOperand)
        case i32And(Instruction.BinaryOperand)
        case i64And(Instruction.BinaryOperand)
        case i32Or(Instruction.BinaryOperand)
        case i64Or(Instruction.BinaryOperand)
        case i32Xor(Instruction.BinaryOperand)
        case i64Xor(Instruction.BinaryOperand)
        case i32Shl(Instruction.BinaryOperand)
        case i64Shl(Instruction.BinaryOperand)
        case i32ShrS(Instruction.BinaryOperand)
        case i64ShrS(Instruction.BinaryOperand)
        case i32ShrU(Instruction.BinaryOperand)
        case i64ShrU(Instruction.BinaryOperand)
        case i32Rotl(Instruction.BinaryOperand)
        case i64Rotl(Instruction.BinaryOperand)
        case i32Rotr(Instruction.BinaryOperand)
        case i64Rotr(Instruction.BinaryOperand)
        case i32DivS(Instruction.BinaryOperand)
        case i64DivS(Instruction.BinaryOperand)
        case i32DivU(Instruction.BinaryOperand)
        case i64DivU(Instruction.BinaryOperand)
        case i32RemS(Instruction.BinaryOperand)
        case i64RemS(Instruction.BinaryOperand)
        case i32RemU(Instruction.BinaryOperand)
        case i64RemU(Instruction.BinaryOperand)
        case i32Eq(Instruction.BinaryOperand)
        case i64Eq(Instruction.BinaryOperand)
        case i32Ne(Instruction.BinaryOperand)
        case i64Ne(Instruction.BinaryOperand)
        case i32LtS(Instruction.BinaryOperand)
        case i64LtS(Instruction.BinaryOperand)
        case i32LtU(Instruction.BinaryOperand)
        case i64LtU(Instruction.BinaryOperand)
        case i32GtS(Instruction.BinaryOperand)
        case i64GtS(Instruction.BinaryOperand)
        case i32GtU(Instruction.BinaryOperand)
        case i64GtU(Instruction.BinaryOperand)
        case i32LeS(Instruction.BinaryOperand)
        case i64LeS(Instruction.BinaryOperand)
        case i32LeU(Instruction.BinaryOperand)
        case i64LeU(Instruction.BinaryOperand)
        case i32GeS(Instruction.BinaryOperand)
        case i64GeS(Instruction.BinaryOperand)
        case i32GeU(Instruction.BinaryOperand)
        case i64GeU(Instruction.BinaryOperand)
        case i32Clz(Instruction.UnaryOperand)
        case i64Clz(Instruction.UnaryOperand)
        case i32Ctz(Instruction.UnaryOperand)
        case i64Ctz(Instruction.UnaryOperand)
        case i32Popcnt(Instruction.UnaryOperand)
        case i64Popcnt(Instruction.UnaryOperand)
        case i32Eqz(Instruction.UnaryOperand)
        case i64Eqz(Instruction.UnaryOperand)
        case i32WrapI64(Instruction.UnaryOperand)
        case i64ExtendI32S(Instruction.UnaryOperand)
        case i64ExtendI32U(Instruction.UnaryOperand)
        case i32Extend8S(Instruction.UnaryOperand)
        case i64Extend8S(Instruction.UnaryOperand)
        case i32Extend16S(Instruction.UnaryOperand)
        case i64Extend16S(Instruction.UnaryOperand)
        case i64Extend32S(Instruction.UnaryOperand)
        case i32TruncF32S(Instruction.UnaryOperand)
        case i32TruncF32U(Instruction.UnaryOperand)
        case i32TruncSatF32S(Instruction.UnaryOperand)
        case i32TruncSatF32U(Instruction.UnaryOperand)
        case i32TruncF64S(Instruction.UnaryOperand)
        case i32TruncF64U(Instruction.UnaryOperand)
        case i32TruncSatF64S(Instruction.UnaryOperand)
        case i32TruncSatF64U(Instruction.UnaryOperand)
        case i64TruncF32S(Instruction.UnaryOperand)
        case i64TruncF32U(Instruction.UnaryOperand)
        case i64TruncSatF32S(Instruction.UnaryOperand)
        case i64TruncSatF32U(Instruction.UnaryOperand)
        case i64TruncF64S(Instruction.UnaryOperand)
        case i64TruncF64U(Instruction.UnaryOperand)
        case i64TruncSatF64S(Instruction.UnaryOperand)
        case i64TruncSatF64U(Instruction.UnaryOperand)
        case f32ConvertI32S(Instruction.UnaryOperand)
        case f32ConvertI32U(Instruction.UnaryOperand)
        case f32ConvertI64S(Instruction.UnaryOperand)
        case f32ConvertI64U(Instruction.UnaryOperand)
        case f64ConvertI32S(Instruction.UnaryOperand)
        case f64ConvertI32U(Instruction.UnaryOperand)
        case f64ConvertI64S(Instruction.UnaryOperand)
        case f64ConvertI64U(Instruction.UnaryOperand)
        case f32ReinterpretI32(Instruction.UnaryOperand)
        case f64ReinterpretI64(Instruction.UnaryOperand)
        case i32ReinterpretF32(Instruction.UnaryOperand)
        case i64ReinterpretF64(Instruction.UnaryOperand)
        case f32Add(Instruction.BinaryOperand)
        case f64Add(Instruction.BinaryOperand)
        case f32Sub(Instruction.BinaryOperand)
        case f64Sub(Instruction.BinaryOperand)
        case f32Mul(Instruction.BinaryOperand)
        case f64Mul(Instruction.BinaryOperand)
        case f32Div(Instruction.BinaryOperand)
        case f64Div(Instruction.BinaryOperand)
        case f32Min(Instruction.BinaryOperand)
        case f64Min(Instruction.BinaryOperand)
        case f32Max(Instruction.BinaryOperand)
        case f64Max(Instruction.BinaryOperand)
        case f32CopySign(Instruction.BinaryOperand)
        case f64CopySign(Instruction.BinaryOperand)
        case f32Eq(Instruction.BinaryOperand)
        case f64Eq(Instruction.BinaryOperand)
        case f32Ne(Instruction.BinaryOperand)
        case f64Ne(Instruction.BinaryOperand)
        case f32Lt(Instruction.BinaryOperand)
        case f64Lt(Instruction.BinaryOperand)
        case f32Gt(Instruction.BinaryOperand)
        case f64Gt(Instruction.BinaryOperand)
        case f32Le(Instruction.BinaryOperand)
        case f64Le(Instruction.BinaryOperand)
        case f32Ge(Instruction.BinaryOperand)
        case f64Ge(Instruction.BinaryOperand)
        case f32Abs(Instruction.UnaryOperand)
        case f64Abs(Instruction.UnaryOperand)
        case f32Neg(Instruction.UnaryOperand)
        case f64Neg(Instruction.UnaryOperand)
        case f32Ceil(Instruction.UnaryOperand)
        case f64Ceil(Instruction.UnaryOperand)
        case f32Floor(Instruction.UnaryOperand)
        case f64Floor(Instruction.UnaryOperand)
        case f32Trunc(Instruction.UnaryOperand)
        case f64Trunc(Instruction.UnaryOperand)
        case f32Nearest(Instruction.UnaryOperand)
        case f64Nearest(Instruction.UnaryOperand)
        case f32Sqrt(Instruction.UnaryOperand)
        case f64Sqrt(Instruction.UnaryOperand)
        case f64PromoteF32(Instruction.UnaryOperand)
        case f32DemoteF64(Instruction.UnaryOperand)
        case refNull(Instruction.RefNullOperand)
        case refIsNull(Instruction.RefIsNullOperand)
        case refFunc(Instruction.RefFuncOperand)
        case tableGet(Instruction.TableGetOperand)
        case tableSet(Instruction.TableSetOperand)
        case tableSize(Instruction.TableSizeOperand)
        case tableGrow(Instruction.TableGrowOperand)
        case tableFill(Instruction.TableFillOperand)
        case tableCopy(Instruction.TableCopyOperand)
        case tableInit(Instruction.TableInitOperand)
        case tableElementDrop(ElementIndex)
        case onEnter(Instruction.OnEnterOperand)
        case onExit(Instruction.OnExitOperand)
    }

    var tagged: Tagged {
        switch self {
        case let .call(callOperand): return .call(callOperand)
        case let .compilingCall(compilingCallOperand): return .compilingCall(compilingCallOperand)
        case let .internalCall(internalCallOperand): return .internalCall(internalCallOperand)
        case let .callIndirect(callIndirectOperand): return .callIndirect(callIndirectOperand)
        case let .ifThen(ifOperand): return .ifThen(ifOperand)
        case let .br(offset): return .br(offset)
        case let .brIf(brIfOperand): return .brIf(brIfOperand)
        case let .brIfNot(brIfOperand): return .brIfNot(brIfOperand)
        case let .brTable(brTableOperand): return .brTable(brTableOperand)
        case let .i32Load(loadOperand): return .i32Load(loadOperand)
        case let .i64Load(loadOperand): return .i64Load(loadOperand)
        case let .f32Load(loadOperand): return .f32Load(loadOperand)
        case let .f64Load(loadOperand): return .f64Load(loadOperand)
        case let .i32Load8S(loadOperand): return .i32Load8S(loadOperand)
        case let .i32Load8U(loadOperand): return .i32Load8U(loadOperand)
        case let .i32Load16S(loadOperand): return .i32Load16S(loadOperand)
        case let .i32Load16U(loadOperand): return .i32Load16U(loadOperand)
        case let .i64Load8S(loadOperand): return .i64Load8S(loadOperand)
        case let .i64Load8U(loadOperand): return .i64Load8U(loadOperand)
        case let .i64Load16S(loadOperand): return .i64Load16S(loadOperand)
        case let .i64Load16U(loadOperand): return .i64Load16U(loadOperand)
        case let .i64Load32S(loadOperand): return .i64Load32S(loadOperand)
        case let .i64Load32U(loadOperand): return .i64Load32U(loadOperand)
        case let .i32Store(storeOperand): return .i32Store(storeOperand)
        case let .i64Store(storeOperand): return .i64Store(storeOperand)
        case let .f32Store(storeOperand): return .f32Store(storeOperand)
        case let .f64Store(storeOperand): return .f64Store(storeOperand)
        case let .i32Store8(storeOperand): return .i32Store8(storeOperand)
        case let .i32Store16(storeOperand): return .i32Store16(storeOperand)
        case let .i64Store8(storeOperand): return .i64Store8(storeOperand)
        case let .i64Store16(storeOperand): return .i64Store16(storeOperand)
        case let .i64Store32(storeOperand): return .i64Store32(storeOperand)
        case let .memorySize(memorySizeOperand): return .memorySize(memorySizeOperand)
        case let .memoryGrow(memoryGrowOperand): return .memoryGrow(memoryGrowOperand)
        case let .memoryInit(memoryInitOperand): return .memoryInit(memoryInitOperand)
        case let .memoryDataDrop(dataIndex): return .memoryDataDrop(dataIndex)
        case let .memoryCopy(memoryCopyOperand): return .memoryCopy(memoryCopyOperand)
        case let .memoryFill(memoryFillOperand): return .memoryFill(memoryFillOperand)
        case let .i32Add(binaryOperand): return .i32Add(binaryOperand)
        case let .i64Add(binaryOperand): return .i64Add(binaryOperand)
        case let .i32Sub(binaryOperand): return .i32Sub(binaryOperand)
        case let .i64Sub(binaryOperand): return .i64Sub(binaryOperand)
        case let .i32Mul(binaryOperand): return .i32Mul(binaryOperand)
        case let .i64Mul(binaryOperand): return .i64Mul(binaryOperand)
        case let .i32And(binaryOperand): return .i32And(binaryOperand)
        case let .i64And(binaryOperand): return .i64And(binaryOperand)
        case let .i32Or(binaryOperand): return .i32Or(binaryOperand)
        case let .i64Or(binaryOperand): return .i64Or(binaryOperand)
        case let .i32Xor(binaryOperand): return .i32Xor(binaryOperand)
        case let .i64Xor(binaryOperand): return .i64Xor(binaryOperand)
        case let .i32Shl(binaryOperand): return .i32Shl(binaryOperand)
        case let .i64Shl(binaryOperand): return .i64Shl(binaryOperand)
        case let .i32ShrS(binaryOperand): return .i32ShrS(binaryOperand)
        case let .i64ShrS(binaryOperand): return .i64ShrS(binaryOperand)
        case let .i32ShrU(binaryOperand): return .i32ShrU(binaryOperand)
        case let .i64ShrU(binaryOperand): return .i64ShrU(binaryOperand)
        case let .i32Rotl(binaryOperand): return .i32Rotl(binaryOperand)
        case let .i64Rotl(binaryOperand): return .i64Rotl(binaryOperand)
        case let .i32Rotr(binaryOperand): return .i32Rotr(binaryOperand)
        case let .i64Rotr(binaryOperand): return .i64Rotr(binaryOperand)
        case let .i32DivS(binaryOperand): return .i32DivS(binaryOperand)
        case let .i64DivS(binaryOperand): return .i64DivS(binaryOperand)
        case let .i32DivU(binaryOperand): return .i32DivU(binaryOperand)
        case let .i64DivU(binaryOperand): return .i64DivU(binaryOperand)
        case let .i32RemS(binaryOperand): return .i32RemS(binaryOperand)
        case let .i64RemS(binaryOperand): return .i64RemS(binaryOperand)
        case let .i32RemU(binaryOperand): return .i32RemU(binaryOperand)
        case let .i64RemU(binaryOperand): return .i64RemU(binaryOperand)
        case let .i32Eq(binaryOperand): return .i32Eq(binaryOperand)
        case let .i64Eq(binaryOperand): return .i64Eq(binaryOperand)
        case let .i32Ne(binaryOperand): return .i32Ne(binaryOperand)
        case let .i64Ne(binaryOperand): return .i64Ne(binaryOperand)
        case let .i32LtS(binaryOperand): return .i32LtS(binaryOperand)
        case let .i64LtS(binaryOperand): return .i64LtS(binaryOperand)
        case let .i32LtU(binaryOperand): return .i32LtU(binaryOperand)
        case let .i64LtU(binaryOperand): return .i64LtU(binaryOperand)
        case let .i32GtS(binaryOperand): return .i32GtS(binaryOperand)
        case let .i64GtS(binaryOperand): return .i64GtS(binaryOperand)
        case let .i32GtU(binaryOperand): return .i32GtU(binaryOperand)
        case let .i64GtU(binaryOperand): return .i64GtU(binaryOperand)
        case let .i32LeS(binaryOperand): return .i32LeS(binaryOperand)
        case let .i64LeS(binaryOperand): return .i64LeS(binaryOperand)
        case let .i32LeU(binaryOperand): return .i32LeU(binaryOperand)
        case let .i64LeU(binaryOperand): return .i64LeU(binaryOperand)
        case let .i32GeS(binaryOperand): return .i32GeS(binaryOperand)
        case let .i64GeS(binaryOperand): return .i64GeS(binaryOperand)
        case let .i32GeU(binaryOperand): return .i32GeU(binaryOperand)
        case let .i64GeU(binaryOperand): return .i64GeU(binaryOperand)
        case let .i32Clz(unaryOperand): return .i32Clz(unaryOperand)
        case let .i64Clz(unaryOperand): return .i64Clz(unaryOperand)
        case let .i32Ctz(unaryOperand): return .i32Ctz(unaryOperand)
        case let .i64Ctz(unaryOperand): return .i64Ctz(unaryOperand)
        case let .i32Popcnt(unaryOperand): return .i32Popcnt(unaryOperand)
        case let .i64Popcnt(unaryOperand): return .i64Popcnt(unaryOperand)
        case let .i32Eqz(unaryOperand): return .i32Eqz(unaryOperand)
        case let .i64Eqz(unaryOperand): return .i64Eqz(unaryOperand)
        case let .i32WrapI64(unaryOperand): return .i32WrapI64(unaryOperand)
        case let .i64ExtendI32S(unaryOperand): return .i64ExtendI32S(unaryOperand)
        case let .i64ExtendI32U(unaryOperand): return .i64ExtendI32U(unaryOperand)
        case let .i32Extend8S(unaryOperand): return .i32Extend8S(unaryOperand)
        case let .i64Extend8S(unaryOperand): return .i64Extend8S(unaryOperand)
        case let .i32Extend16S(unaryOperand): return .i32Extend16S(unaryOperand)
        case let .i64Extend16S(unaryOperand): return .i64Extend16S(unaryOperand)
        case let .i64Extend32S(unaryOperand): return .i64Extend32S(unaryOperand)
        case let .i32TruncF32S(unaryOperand): return .i32TruncF32S(unaryOperand)
        case let .i32TruncF32U(unaryOperand): return .i32TruncF32U(unaryOperand)
        case let .i32TruncSatF32S(unaryOperand): return .i32TruncSatF32S(unaryOperand)
        case let .i32TruncSatF32U(unaryOperand): return .i32TruncSatF32U(unaryOperand)
        case let .i32TruncF64S(unaryOperand): return .i32TruncF64S(unaryOperand)
        case let .i32TruncF64U(unaryOperand): return .i32TruncF64U(unaryOperand)
        case let .i32TruncSatF64S(unaryOperand): return .i32TruncSatF64S(unaryOperand)
        case let .i32TruncSatF64U(unaryOperand): return .i32TruncSatF64U(unaryOperand)
        case let .i64TruncF32S(unaryOperand): return .i64TruncF32S(unaryOperand)
        case let .i64TruncF32U(unaryOperand): return .i64TruncF32U(unaryOperand)
        case let .i64TruncSatF32S(unaryOperand): return .i64TruncSatF32S(unaryOperand)
        case let .i64TruncSatF32U(unaryOperand): return .i64TruncSatF32U(unaryOperand)
        case let .i64TruncF64S(unaryOperand): return .i64TruncF64S(unaryOperand)
        case let .i64TruncF64U(unaryOperand): return .i64TruncF64U(unaryOperand)
        case let .i64TruncSatF64S(unaryOperand): return .i64TruncSatF64S(unaryOperand)
        case let .i64TruncSatF64U(unaryOperand): return .i64TruncSatF64U(unaryOperand)
        case let .f32ConvertI32S(unaryOperand): return .f32ConvertI32S(unaryOperand)
        case let .f32ConvertI32U(unaryOperand): return .f32ConvertI32U(unaryOperand)
        case let .f32ConvertI64S(unaryOperand): return .f32ConvertI64S(unaryOperand)
        case let .f32ConvertI64U(unaryOperand): return .f32ConvertI64U(unaryOperand)
        case let .f64ConvertI32S(unaryOperand): return .f64ConvertI32S(unaryOperand)
        case let .f64ConvertI32U(unaryOperand): return .f64ConvertI32U(unaryOperand)
        case let .f64ConvertI64S(unaryOperand): return .f64ConvertI64S(unaryOperand)
        case let .f64ConvertI64U(unaryOperand): return .f64ConvertI64U(unaryOperand)
        case let .f32ReinterpretI32(unaryOperand): return .f32ReinterpretI32(unaryOperand)
        case let .f64ReinterpretI64(unaryOperand): return .f64ReinterpretI64(unaryOperand)
        case let .i32ReinterpretF32(unaryOperand): return .i32ReinterpretF32(unaryOperand)
        case let .i64ReinterpretF64(unaryOperand): return .i64ReinterpretF64(unaryOperand)
        case let .f32Add(binaryOperand): return .f32Add(binaryOperand)
        case let .f64Add(binaryOperand): return .f64Add(binaryOperand)
        case let .f32Sub(binaryOperand): return .f32Sub(binaryOperand)
        case let .f64Sub(binaryOperand): return .f64Sub(binaryOperand)
        case let .f32Mul(binaryOperand): return .f32Mul(binaryOperand)
        case let .f64Mul(binaryOperand): return .f64Mul(binaryOperand)
        case let .f32Div(binaryOperand): return .f32Div(binaryOperand)
        case let .f64Div(binaryOperand): return .f64Div(binaryOperand)
        case let .f32Min(binaryOperand): return .f32Min(binaryOperand)
        case let .f64Min(binaryOperand): return .f64Min(binaryOperand)
        case let .f32Max(binaryOperand): return .f32Max(binaryOperand)
        case let .f64Max(binaryOperand): return .f64Max(binaryOperand)
        case let .f32CopySign(binaryOperand): return .f32CopySign(binaryOperand)
        case let .f64CopySign(binaryOperand): return .f64CopySign(binaryOperand)
        case let .f32Eq(binaryOperand): return .f32Eq(binaryOperand)
        case let .f64Eq(binaryOperand): return .f64Eq(binaryOperand)
        case let .f32Ne(binaryOperand): return .f32Ne(binaryOperand)
        case let .f64Ne(binaryOperand): return .f64Ne(binaryOperand)
        case let .f32Lt(binaryOperand): return .f32Lt(binaryOperand)
        case let .f64Lt(binaryOperand): return .f64Lt(binaryOperand)
        case let .f32Gt(binaryOperand): return .f32Gt(binaryOperand)
        case let .f64Gt(binaryOperand): return .f64Gt(binaryOperand)
        case let .f32Le(binaryOperand): return .f32Le(binaryOperand)
        case let .f64Le(binaryOperand): return .f64Le(binaryOperand)
        case let .f32Ge(binaryOperand): return .f32Ge(binaryOperand)
        case let .f64Ge(binaryOperand): return .f64Ge(binaryOperand)
        case let .f32Abs(unaryOperand): return .f32Abs(unaryOperand)
        case let .f64Abs(unaryOperand): return .f64Abs(unaryOperand)
        case let .f32Neg(unaryOperand): return .f32Neg(unaryOperand)
        case let .f64Neg(unaryOperand): return .f64Neg(unaryOperand)
        case let .f32Ceil(unaryOperand): return .f32Ceil(unaryOperand)
        case let .f64Ceil(unaryOperand): return .f64Ceil(unaryOperand)
        case let .f32Floor(unaryOperand): return .f32Floor(unaryOperand)
        case let .f64Floor(unaryOperand): return .f64Floor(unaryOperand)
        case let .f32Trunc(unaryOperand): return .f32Trunc(unaryOperand)
        case let .f64Trunc(unaryOperand): return .f64Trunc(unaryOperand)
        case let .f32Nearest(unaryOperand): return .f32Nearest(unaryOperand)
        case let .f64Nearest(unaryOperand): return .f64Nearest(unaryOperand)
        case let .f32Sqrt(unaryOperand): return .f32Sqrt(unaryOperand)
        case let .f64Sqrt(unaryOperand): return .f64Sqrt(unaryOperand)
        case let .f64PromoteF32(unaryOperand): return .f64PromoteF32(unaryOperand)
        case let .f32DemoteF64(unaryOperand): return .f32DemoteF64(unaryOperand)
        case let .refNull(refNullOperand): return .refNull(refNullOperand)
        case let .refIsNull(refIsNullOperand): return .refIsNull(refIsNullOperand)
        case let .refFunc(refFuncOperand): return .refFunc(refFuncOperand)
        case let .tableGet(tableGetOperand): return .tableGet(tableGetOperand)
        case let .tableSet(tableSetOperand): return .tableSet(tableSetOperand)
        case let .tableSize(tableSizeOperand): return .tableSize(tableSizeOperand)
        case let .tableGrow(tableGrowOperand): return .tableGrow(tableGrowOperand)
        case let .tableFill(tableFillOperand): return .tableFill(tableFillOperand)
        case let .tableCopy(tableCopyOperand): return .tableCopy(tableCopyOperand)
        case let .tableInit(tableInitOperand): return .tableInit(tableInitOperand)
        case let .tableElementDrop(elementIndex): return .tableElementDrop(elementIndex)
        case let .onEnter(onEnterOperand): return .onEnter(onEnterOperand)
        case let .onExit(onExitOperand): return .onExit(onExitOperand)
        default: preconditionFailure()
        }
    }
}
