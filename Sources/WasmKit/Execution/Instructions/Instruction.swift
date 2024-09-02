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
    case select(Instruction.SelectOperand)
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
    var rawImmediate: (any InstructionImmediate)? {
        switch self {
        case .copyStack(let copyStackOperand): return copyStackOperand
        case .globalGet(let globalGetOperand): return globalGetOperand
        case .globalSet(let globalSetOperand): return globalSetOperand
        case .call(let callOperand): return callOperand
        case .compilingCall(let compilingCallOperand): return compilingCallOperand
        case .internalCall(let internalCallOperand): return internalCallOperand
        case .callIndirect(let callIndirectOperand): return callIndirectOperand
        case .br(let offset): return offset
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
        case .memorySize(let memorySizeOperand): return memorySizeOperand
        case .memoryGrow(let memoryGrowOperand): return memoryGrowOperand
        case .memoryInit(let memoryInitOperand): return memoryInitOperand
        case .memoryDataDrop(let dataIndex): return dataIndex
        case .memoryCopy(let memoryCopyOperand): return memoryCopyOperand
        case .memoryFill(let memoryFillOperand): return memoryFillOperand
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
        case .select(let selectOperand): return selectOperand
        case .refNull(let refNullOperand): return refNullOperand
        case .refIsNull(let refIsNullOperand): return refIsNullOperand
        case .refFunc(let refFuncOperand): return refFuncOperand
        case .tableGet(let tableGetOperand): return tableGetOperand
        case .tableSet(let tableSetOperand): return tableSetOperand
        case .tableSize(let tableSizeOperand): return tableSizeOperand
        case .tableGrow(let tableGrowOperand): return tableGrowOperand
        case .tableFill(let tableFillOperand): return tableFillOperand
        case .tableCopy(let tableCopyOperand): return tableCopyOperand
        case .tableInit(let tableInitOperand): return tableInitOperand
        case .tableElementDrop(let elementIndex): return elementIndex
        case .onEnter(let onEnterOperand): return onEnterOperand
        case .onExit(let onExitOperand): return onExitOperand
        default: return nil
        }
    }
}
