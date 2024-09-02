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
    case br(offset: Int32)
    case brIf(Instruction.BrIfOperand)
    case brIfNot(Instruction.BrIfOperand)
    case brTable(Instruction.BrTable)
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
        case .call: return true
        case .compilingCall: return true
        case .internalCall: return true
        case .callIndirect: return true
        case .brIf: return true
        case .brIfNot: return true
        case .brTable: return true
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
        case .memoryInit: return true
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
        case .onEnter: return true
        case .onExit: return true
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
        case .call(let callOperand): return callOperand
        case .compilingCall(let compilingCallOperand): return compilingCallOperand
        case .internalCall(let internalCallOperand): return internalCallOperand
        case .callIndirect(let callIndirectOperand): return callIndirectOperand
        case .brIf(let brIfOperand): return brIfOperand
        case .brIfNot(let brIfOperand): return brIfOperand
        case .brTable(let brTable): return brTable
        case .i32Load(let loadOperand): return loadOperand
        case .i64Load(let loadOperand): return loadOperand
        case .f32Load(let loadOperand): return loadOperand
        case .f64Load(let loadOperand): return loadOperand
        case .i32Load8S(let loadOperand): return loadOperand
        case .i32Load8U(let loadOperand): return loadOperand
        case .i32Load16S(let loadOperand): return loadOperand
        case .i32Load16U(let loadOperand): return loadOperand
        case .i64Load8S(let loadOperand): return loadOperand
        case .i64Load8U(let loadOperand): return loadOperand
        case .i64Load16S(let loadOperand): return loadOperand
        case .i64Load16U(let loadOperand): return loadOperand
        case .i64Load32S(let loadOperand): return loadOperand
        case .i64Load32U(let loadOperand): return loadOperand
        case .i32Store(let storeOperand): return storeOperand
        case .i64Store(let storeOperand): return storeOperand
        case .f32Store(let storeOperand): return storeOperand
        case .f64Store(let storeOperand): return storeOperand
        case .i32Store8(let storeOperand): return storeOperand
        case .i32Store16(let storeOperand): return storeOperand
        case .i64Store8(let storeOperand): return storeOperand
        case .i64Store16(let storeOperand): return storeOperand
        case .i64Store32(let storeOperand): return storeOperand
        case .memoryInit(let memoryInitOperand): return memoryInitOperand
        case .const32(let const32Operand): return const32Operand
        case .const64(let const64Operand): return const64Operand
        case .i32Add(let binaryOperand): return binaryOperand
        case .i64Add(let binaryOperand): return binaryOperand
        case .i32Sub(let binaryOperand): return binaryOperand
        case .i64Sub(let binaryOperand): return binaryOperand
        case .i32Mul(let binaryOperand): return binaryOperand
        case .i64Mul(let binaryOperand): return binaryOperand
        case .i32And(let binaryOperand): return binaryOperand
        case .i64And(let binaryOperand): return binaryOperand
        case .i32Or(let binaryOperand): return binaryOperand
        case .i64Or(let binaryOperand): return binaryOperand
        case .i32Xor(let binaryOperand): return binaryOperand
        case .i64Xor(let binaryOperand): return binaryOperand
        case .i32Shl(let binaryOperand): return binaryOperand
        case .i64Shl(let binaryOperand): return binaryOperand
        case .i32ShrS(let binaryOperand): return binaryOperand
        case .i64ShrS(let binaryOperand): return binaryOperand
        case .i32ShrU(let binaryOperand): return binaryOperand
        case .i64ShrU(let binaryOperand): return binaryOperand
        case .i32Rotl(let binaryOperand): return binaryOperand
        case .i64Rotl(let binaryOperand): return binaryOperand
        case .i32Rotr(let binaryOperand): return binaryOperand
        case .i64Rotr(let binaryOperand): return binaryOperand
        case .i32DivS(let binaryOperand): return binaryOperand
        case .i64DivS(let binaryOperand): return binaryOperand
        case .i32DivU(let binaryOperand): return binaryOperand
        case .i64DivU(let binaryOperand): return binaryOperand
        case .i32RemS(let binaryOperand): return binaryOperand
        case .i64RemS(let binaryOperand): return binaryOperand
        case .i32RemU(let binaryOperand): return binaryOperand
        case .i64RemU(let binaryOperand): return binaryOperand
        case .i32Eq(let binaryOperand): return binaryOperand
        case .i64Eq(let binaryOperand): return binaryOperand
        case .i32Ne(let binaryOperand): return binaryOperand
        case .i64Ne(let binaryOperand): return binaryOperand
        case .i32LtS(let binaryOperand): return binaryOperand
        case .i64LtS(let binaryOperand): return binaryOperand
        case .i32LtU(let binaryOperand): return binaryOperand
        case .i64LtU(let binaryOperand): return binaryOperand
        case .i32GtS(let binaryOperand): return binaryOperand
        case .i64GtS(let binaryOperand): return binaryOperand
        case .i32GtU(let binaryOperand): return binaryOperand
        case .i64GtU(let binaryOperand): return binaryOperand
        case .i32LeS(let binaryOperand): return binaryOperand
        case .i64LeS(let binaryOperand): return binaryOperand
        case .i32LeU(let binaryOperand): return binaryOperand
        case .i64LeU(let binaryOperand): return binaryOperand
        case .i32GeS(let binaryOperand): return binaryOperand
        case .i64GeS(let binaryOperand): return binaryOperand
        case .i32GeU(let binaryOperand): return binaryOperand
        case .i64GeU(let binaryOperand): return binaryOperand
        case .i32Clz(let unaryOperand): return unaryOperand
        case .i64Clz(let unaryOperand): return unaryOperand
        case .i32Ctz(let unaryOperand): return unaryOperand
        case .i64Ctz(let unaryOperand): return unaryOperand
        case .i32Popcnt(let unaryOperand): return unaryOperand
        case .i64Popcnt(let unaryOperand): return unaryOperand
        case .i32Eqz(let unaryOperand): return unaryOperand
        case .i64Eqz(let unaryOperand): return unaryOperand
        case .i32WrapI64(let unaryOperand): return unaryOperand
        case .i64ExtendI32S(let unaryOperand): return unaryOperand
        case .i64ExtendI32U(let unaryOperand): return unaryOperand
        case .i32Extend8S(let unaryOperand): return unaryOperand
        case .i64Extend8S(let unaryOperand): return unaryOperand
        case .i32Extend16S(let unaryOperand): return unaryOperand
        case .i64Extend16S(let unaryOperand): return unaryOperand
        case .i64Extend32S(let unaryOperand): return unaryOperand
        case .i32TruncF32S(let unaryOperand): return unaryOperand
        case .i32TruncF32U(let unaryOperand): return unaryOperand
        case .i32TruncSatF32S(let unaryOperand): return unaryOperand
        case .i32TruncSatF32U(let unaryOperand): return unaryOperand
        case .i32TruncF64S(let unaryOperand): return unaryOperand
        case .i32TruncF64U(let unaryOperand): return unaryOperand
        case .i32TruncSatF64S(let unaryOperand): return unaryOperand
        case .i32TruncSatF64U(let unaryOperand): return unaryOperand
        case .i64TruncF32S(let unaryOperand): return unaryOperand
        case .i64TruncF32U(let unaryOperand): return unaryOperand
        case .i64TruncSatF32S(let unaryOperand): return unaryOperand
        case .i64TruncSatF32U(let unaryOperand): return unaryOperand
        case .i64TruncF64S(let unaryOperand): return unaryOperand
        case .i64TruncF64U(let unaryOperand): return unaryOperand
        case .i64TruncSatF64S(let unaryOperand): return unaryOperand
        case .i64TruncSatF64U(let unaryOperand): return unaryOperand
        case .f32ConvertI32S(let unaryOperand): return unaryOperand
        case .f32ConvertI32U(let unaryOperand): return unaryOperand
        case .f32ConvertI64S(let unaryOperand): return unaryOperand
        case .f32ConvertI64U(let unaryOperand): return unaryOperand
        case .f64ConvertI32S(let unaryOperand): return unaryOperand
        case .f64ConvertI32U(let unaryOperand): return unaryOperand
        case .f64ConvertI64S(let unaryOperand): return unaryOperand
        case .f64ConvertI64U(let unaryOperand): return unaryOperand
        case .f32ReinterpretI32(let unaryOperand): return unaryOperand
        case .f64ReinterpretI64(let unaryOperand): return unaryOperand
        case .i32ReinterpretF32(let unaryOperand): return unaryOperand
        case .i64ReinterpretF64(let unaryOperand): return unaryOperand
        case .f32Add(let binaryOperand): return binaryOperand
        case .f64Add(let binaryOperand): return binaryOperand
        case .f32Sub(let binaryOperand): return binaryOperand
        case .f64Sub(let binaryOperand): return binaryOperand
        case .f32Mul(let binaryOperand): return binaryOperand
        case .f64Mul(let binaryOperand): return binaryOperand
        case .f32Div(let binaryOperand): return binaryOperand
        case .f64Div(let binaryOperand): return binaryOperand
        case .f32Min(let binaryOperand): return binaryOperand
        case .f64Min(let binaryOperand): return binaryOperand
        case .f32Max(let binaryOperand): return binaryOperand
        case .f64Max(let binaryOperand): return binaryOperand
        case .f32CopySign(let binaryOperand): return binaryOperand
        case .f64CopySign(let binaryOperand): return binaryOperand
        case .f32Eq(let binaryOperand): return binaryOperand
        case .f64Eq(let binaryOperand): return binaryOperand
        case .f32Ne(let binaryOperand): return binaryOperand
        case .f64Ne(let binaryOperand): return binaryOperand
        case .f32Lt(let binaryOperand): return binaryOperand
        case .f64Lt(let binaryOperand): return binaryOperand
        case .f32Gt(let binaryOperand): return binaryOperand
        case .f64Gt(let binaryOperand): return binaryOperand
        case .f32Le(let binaryOperand): return binaryOperand
        case .f64Le(let binaryOperand): return binaryOperand
        case .f32Ge(let binaryOperand): return binaryOperand
        case .f64Ge(let binaryOperand): return binaryOperand
        case .f32Abs(let unaryOperand): return unaryOperand
        case .f64Abs(let unaryOperand): return unaryOperand
        case .f32Neg(let unaryOperand): return unaryOperand
        case .f64Neg(let unaryOperand): return unaryOperand
        case .f32Ceil(let unaryOperand): return unaryOperand
        case .f64Ceil(let unaryOperand): return unaryOperand
        case .f32Floor(let unaryOperand): return unaryOperand
        case .f64Floor(let unaryOperand): return unaryOperand
        case .f32Trunc(let unaryOperand): return unaryOperand
        case .f64Trunc(let unaryOperand): return unaryOperand
        case .f32Nearest(let unaryOperand): return unaryOperand
        case .f64Nearest(let unaryOperand): return unaryOperand
        case .f32Sqrt(let unaryOperand): return unaryOperand
        case .f64Sqrt(let unaryOperand): return unaryOperand
        case .f64PromoteF32(let unaryOperand): return unaryOperand
        case .f32DemoteF64(let unaryOperand): return unaryOperand
        case .onEnter(let onEnterOperand): return onEnterOperand
        case .onExit(let onExitOperand): return onExitOperand
        default: preconditionFailure()
        }
    }
}
extension Instruction {
    enum Tagged {
        case br(Int32)
        case memorySize(Instruction.MemorySizeOperand)
        case memoryGrow(Instruction.MemoryGrowOperand)
        case memoryDataDrop(DataIndex)
        case memoryCopy(Instruction.MemoryCopyOperand)
        case memoryFill(Instruction.MemoryFillOperand)
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
    }

    var tagged: Tagged {
        switch self {
        case let .br(offset): return .br(offset)
        case let .memorySize(memorySizeOperand): return .memorySize(memorySizeOperand)
        case let .memoryGrow(memoryGrowOperand): return .memoryGrow(memoryGrowOperand)
        case let .memoryDataDrop(dataIndex): return .memoryDataDrop(dataIndex)
        case let .memoryCopy(memoryCopyOperand): return .memoryCopy(memoryCopyOperand)
        case let .memoryFill(memoryFillOperand): return .memoryFill(memoryFillOperand)
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
        default: preconditionFailure()
        }
    }
}
