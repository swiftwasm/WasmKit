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


extension Instruction {
    var rawIndex: Int {
        switch self {
        case .copyStack: return 0
        case .globalGet: return 1
        case .globalSet: return 2
        case .call: return 3
        case .compilingCall: return 4
        case .internalCall: return 5
        case .callIndirect: return 6
        case .unreachable: return 7
        case .nop: return 8
        case .br: return 9
        case .brIf: return 10
        case .brIfNot: return 11
        case .brTable: return 12
        case ._return: return 13
        case .endOfExecution: return 14
        case .i32Load: return 15
        case .i64Load: return 16
        case .f32Load: return 17
        case .f64Load: return 18
        case .i32Load8S: return 19
        case .i32Load8U: return 20
        case .i32Load16S: return 21
        case .i32Load16U: return 22
        case .i64Load8S: return 23
        case .i64Load8U: return 24
        case .i64Load16S: return 25
        case .i64Load16U: return 26
        case .i64Load32S: return 27
        case .i64Load32U: return 28
        case .i32Store: return 29
        case .i64Store: return 30
        case .f32Store: return 31
        case .f64Store: return 32
        case .i32Store8: return 33
        case .i32Store16: return 34
        case .i64Store8: return 35
        case .i64Store16: return 36
        case .i64Store32: return 37
        case .memorySize: return 38
        case .memoryGrow: return 39
        case .memoryInit: return 40
        case .memoryDataDrop: return 41
        case .memoryCopy: return 42
        case .memoryFill: return 43
        case .const32: return 44
        case .const64: return 45
        case .i32Add: return 46
        case .i64Add: return 47
        case .i32Sub: return 48
        case .i64Sub: return 49
        case .i32Mul: return 50
        case .i64Mul: return 51
        case .i32And: return 52
        case .i64And: return 53
        case .i32Or: return 54
        case .i64Or: return 55
        case .i32Xor: return 56
        case .i64Xor: return 57
        case .i32Shl: return 58
        case .i64Shl: return 59
        case .i32ShrS: return 60
        case .i64ShrS: return 61
        case .i32ShrU: return 62
        case .i64ShrU: return 63
        case .i32Rotl: return 64
        case .i64Rotl: return 65
        case .i32Rotr: return 66
        case .i64Rotr: return 67
        case .i32DivS: return 68
        case .i64DivS: return 69
        case .i32DivU: return 70
        case .i64DivU: return 71
        case .i32RemS: return 72
        case .i64RemS: return 73
        case .i32RemU: return 74
        case .i64RemU: return 75
        case .i32Eq: return 76
        case .i64Eq: return 77
        case .i32Ne: return 78
        case .i64Ne: return 79
        case .i32LtS: return 80
        case .i64LtS: return 81
        case .i32LtU: return 82
        case .i64LtU: return 83
        case .i32GtS: return 84
        case .i64GtS: return 85
        case .i32GtU: return 86
        case .i64GtU: return 87
        case .i32LeS: return 88
        case .i64LeS: return 89
        case .i32LeU: return 90
        case .i64LeU: return 91
        case .i32GeS: return 92
        case .i64GeS: return 93
        case .i32GeU: return 94
        case .i64GeU: return 95
        case .i32Clz: return 96
        case .i64Clz: return 97
        case .i32Ctz: return 98
        case .i64Ctz: return 99
        case .i32Popcnt: return 100
        case .i64Popcnt: return 101
        case .i32Eqz: return 102
        case .i64Eqz: return 103
        case .i32WrapI64: return 104
        case .i64ExtendI32S: return 105
        case .i64ExtendI32U: return 106
        case .i32Extend8S: return 107
        case .i64Extend8S: return 108
        case .i32Extend16S: return 109
        case .i64Extend16S: return 110
        case .i64Extend32S: return 111
        case .i32TruncF32S: return 112
        case .i32TruncF32U: return 113
        case .i32TruncSatF32S: return 114
        case .i32TruncSatF32U: return 115
        case .i32TruncF64S: return 116
        case .i32TruncF64U: return 117
        case .i32TruncSatF64S: return 118
        case .i32TruncSatF64U: return 119
        case .i64TruncF32S: return 120
        case .i64TruncF32U: return 121
        case .i64TruncSatF32S: return 122
        case .i64TruncSatF32U: return 123
        case .i64TruncF64S: return 124
        case .i64TruncF64U: return 125
        case .i64TruncSatF64S: return 126
        case .i64TruncSatF64U: return 127
        case .f32ConvertI32S: return 128
        case .f32ConvertI32U: return 129
        case .f32ConvertI64S: return 130
        case .f32ConvertI64U: return 131
        case .f64ConvertI32S: return 132
        case .f64ConvertI32U: return 133
        case .f64ConvertI64S: return 134
        case .f64ConvertI64U: return 135
        case .f32ReinterpretI32: return 136
        case .f64ReinterpretI64: return 137
        case .i32ReinterpretF32: return 138
        case .i64ReinterpretF64: return 139
        case .f32Add: return 140
        case .f64Add: return 141
        case .f32Sub: return 142
        case .f64Sub: return 143
        case .f32Mul: return 144
        case .f64Mul: return 145
        case .f32Div: return 146
        case .f64Div: return 147
        case .f32Min: return 148
        case .f64Min: return 149
        case .f32Max: return 150
        case .f64Max: return 151
        case .f32CopySign: return 152
        case .f64CopySign: return 153
        case .f32Eq: return 154
        case .f64Eq: return 155
        case .f32Ne: return 156
        case .f64Ne: return 157
        case .f32Lt: return 158
        case .f64Lt: return 159
        case .f32Gt: return 160
        case .f64Gt: return 161
        case .f32Le: return 162
        case .f64Le: return 163
        case .f32Ge: return 164
        case .f64Ge: return 165
        case .f32Abs: return 166
        case .f64Abs: return 167
        case .f32Neg: return 168
        case .f64Neg: return 169
        case .f32Ceil: return 170
        case .f64Ceil: return 171
        case .f32Floor: return 172
        case .f64Floor: return 173
        case .f32Trunc: return 174
        case .f64Trunc: return 175
        case .f32Nearest: return 176
        case .f64Nearest: return 177
        case .f32Sqrt: return 178
        case .f64Sqrt: return 179
        case .f64PromoteF32: return 180
        case .f32DemoteF64: return 181
        case .select: return 182
        case .refNull: return 183
        case .refIsNull: return 184
        case .refFunc: return 185
        case .tableGet: return 186
        case .tableSet: return 187
        case .tableSize: return 188
        case .tableGrow: return 189
        case .tableFill: return 190
        case .tableCopy: return 191
        case .tableInit: return 192
        case .tableElementDrop: return 193
        case .onEnter: return 194
        case .onExit: return 195
        }
    }
}
extension Instruction {
    /// Load an instruction from the given program counter.
    /// - Parameter pc: The program counter to read from.
    /// - Returns: The instruction read from the program counter.
    /// - Precondition: The instruction sequence must be compiled with token threading model.
    static func load(from pc: inout Pc) -> Instruction {
        let rawIndex = pc.read(UInt64.self)
        switch rawIndex {
        case 0: return .copyStack(Instruction.CopyStackOperand.load(from: &pc))
        case 1: return .globalGet(Instruction.GlobalGetOperand.load(from: &pc))
        case 2: return .globalSet(Instruction.GlobalSetOperand.load(from: &pc))
        case 3: return .call(Instruction.CallOperand.load(from: &pc))
        case 4: return .compilingCall(Instruction.CompilingCallOperand.load(from: &pc))
        case 5: return .internalCall(Instruction.InternalCallOperand.load(from: &pc))
        case 6: return .callIndirect(Instruction.CallIndirectOperand.load(from: &pc))
        case 7: return .unreachable
        case 8: return .nop
        case 9: return .br(offset: Int32.load(from: &pc))
        case 10: return .brIf(Instruction.BrIfOperand.load(from: &pc))
        case 11: return .brIfNot(Instruction.BrIfOperand.load(from: &pc))
        case 12: return .brTable(Instruction.BrTable.load(from: &pc))
        case 13: return ._return
        case 14: return .endOfExecution
        case 15: return .i32Load(Instruction.LoadOperand.load(from: &pc))
        case 16: return .i64Load(Instruction.LoadOperand.load(from: &pc))
        case 17: return .f32Load(Instruction.LoadOperand.load(from: &pc))
        case 18: return .f64Load(Instruction.LoadOperand.load(from: &pc))
        case 19: return .i32Load8S(Instruction.LoadOperand.load(from: &pc))
        case 20: return .i32Load8U(Instruction.LoadOperand.load(from: &pc))
        case 21: return .i32Load16S(Instruction.LoadOperand.load(from: &pc))
        case 22: return .i32Load16U(Instruction.LoadOperand.load(from: &pc))
        case 23: return .i64Load8S(Instruction.LoadOperand.load(from: &pc))
        case 24: return .i64Load8U(Instruction.LoadOperand.load(from: &pc))
        case 25: return .i64Load16S(Instruction.LoadOperand.load(from: &pc))
        case 26: return .i64Load16U(Instruction.LoadOperand.load(from: &pc))
        case 27: return .i64Load32S(Instruction.LoadOperand.load(from: &pc))
        case 28: return .i64Load32U(Instruction.LoadOperand.load(from: &pc))
        case 29: return .i32Store(Instruction.StoreOperand.load(from: &pc))
        case 30: return .i64Store(Instruction.StoreOperand.load(from: &pc))
        case 31: return .f32Store(Instruction.StoreOperand.load(from: &pc))
        case 32: return .f64Store(Instruction.StoreOperand.load(from: &pc))
        case 33: return .i32Store8(Instruction.StoreOperand.load(from: &pc))
        case 34: return .i32Store16(Instruction.StoreOperand.load(from: &pc))
        case 35: return .i64Store8(Instruction.StoreOperand.load(from: &pc))
        case 36: return .i64Store16(Instruction.StoreOperand.load(from: &pc))
        case 37: return .i64Store32(Instruction.StoreOperand.load(from: &pc))
        case 38: return .memorySize(Instruction.MemorySizeOperand.load(from: &pc))
        case 39: return .memoryGrow(Instruction.MemoryGrowOperand.load(from: &pc))
        case 40: return .memoryInit(Instruction.MemoryInitOperand.load(from: &pc))
        case 41: return .memoryDataDrop(DataIndex.load(from: &pc))
        case 42: return .memoryCopy(Instruction.MemoryCopyOperand.load(from: &pc))
        case 43: return .memoryFill(Instruction.MemoryFillOperand.load(from: &pc))
        case 44: return .const32(Instruction.Const32Operand.load(from: &pc))
        case 45: return .const64(Instruction.Const64Operand.load(from: &pc))
        case 46: return .i32Add(Instruction.BinaryOperand.load(from: &pc))
        case 47: return .i64Add(Instruction.BinaryOperand.load(from: &pc))
        case 48: return .i32Sub(Instruction.BinaryOperand.load(from: &pc))
        case 49: return .i64Sub(Instruction.BinaryOperand.load(from: &pc))
        case 50: return .i32Mul(Instruction.BinaryOperand.load(from: &pc))
        case 51: return .i64Mul(Instruction.BinaryOperand.load(from: &pc))
        case 52: return .i32And(Instruction.BinaryOperand.load(from: &pc))
        case 53: return .i64And(Instruction.BinaryOperand.load(from: &pc))
        case 54: return .i32Or(Instruction.BinaryOperand.load(from: &pc))
        case 55: return .i64Or(Instruction.BinaryOperand.load(from: &pc))
        case 56: return .i32Xor(Instruction.BinaryOperand.load(from: &pc))
        case 57: return .i64Xor(Instruction.BinaryOperand.load(from: &pc))
        case 58: return .i32Shl(Instruction.BinaryOperand.load(from: &pc))
        case 59: return .i64Shl(Instruction.BinaryOperand.load(from: &pc))
        case 60: return .i32ShrS(Instruction.BinaryOperand.load(from: &pc))
        case 61: return .i64ShrS(Instruction.BinaryOperand.load(from: &pc))
        case 62: return .i32ShrU(Instruction.BinaryOperand.load(from: &pc))
        case 63: return .i64ShrU(Instruction.BinaryOperand.load(from: &pc))
        case 64: return .i32Rotl(Instruction.BinaryOperand.load(from: &pc))
        case 65: return .i64Rotl(Instruction.BinaryOperand.load(from: &pc))
        case 66: return .i32Rotr(Instruction.BinaryOperand.load(from: &pc))
        case 67: return .i64Rotr(Instruction.BinaryOperand.load(from: &pc))
        case 68: return .i32DivS(Instruction.BinaryOperand.load(from: &pc))
        case 69: return .i64DivS(Instruction.BinaryOperand.load(from: &pc))
        case 70: return .i32DivU(Instruction.BinaryOperand.load(from: &pc))
        case 71: return .i64DivU(Instruction.BinaryOperand.load(from: &pc))
        case 72: return .i32RemS(Instruction.BinaryOperand.load(from: &pc))
        case 73: return .i64RemS(Instruction.BinaryOperand.load(from: &pc))
        case 74: return .i32RemU(Instruction.BinaryOperand.load(from: &pc))
        case 75: return .i64RemU(Instruction.BinaryOperand.load(from: &pc))
        case 76: return .i32Eq(Instruction.BinaryOperand.load(from: &pc))
        case 77: return .i64Eq(Instruction.BinaryOperand.load(from: &pc))
        case 78: return .i32Ne(Instruction.BinaryOperand.load(from: &pc))
        case 79: return .i64Ne(Instruction.BinaryOperand.load(from: &pc))
        case 80: return .i32LtS(Instruction.BinaryOperand.load(from: &pc))
        case 81: return .i64LtS(Instruction.BinaryOperand.load(from: &pc))
        case 82: return .i32LtU(Instruction.BinaryOperand.load(from: &pc))
        case 83: return .i64LtU(Instruction.BinaryOperand.load(from: &pc))
        case 84: return .i32GtS(Instruction.BinaryOperand.load(from: &pc))
        case 85: return .i64GtS(Instruction.BinaryOperand.load(from: &pc))
        case 86: return .i32GtU(Instruction.BinaryOperand.load(from: &pc))
        case 87: return .i64GtU(Instruction.BinaryOperand.load(from: &pc))
        case 88: return .i32LeS(Instruction.BinaryOperand.load(from: &pc))
        case 89: return .i64LeS(Instruction.BinaryOperand.load(from: &pc))
        case 90: return .i32LeU(Instruction.BinaryOperand.load(from: &pc))
        case 91: return .i64LeU(Instruction.BinaryOperand.load(from: &pc))
        case 92: return .i32GeS(Instruction.BinaryOperand.load(from: &pc))
        case 93: return .i64GeS(Instruction.BinaryOperand.load(from: &pc))
        case 94: return .i32GeU(Instruction.BinaryOperand.load(from: &pc))
        case 95: return .i64GeU(Instruction.BinaryOperand.load(from: &pc))
        case 96: return .i32Clz(Instruction.UnaryOperand.load(from: &pc))
        case 97: return .i64Clz(Instruction.UnaryOperand.load(from: &pc))
        case 98: return .i32Ctz(Instruction.UnaryOperand.load(from: &pc))
        case 99: return .i64Ctz(Instruction.UnaryOperand.load(from: &pc))
        case 100: return .i32Popcnt(Instruction.UnaryOperand.load(from: &pc))
        case 101: return .i64Popcnt(Instruction.UnaryOperand.load(from: &pc))
        case 102: return .i32Eqz(Instruction.UnaryOperand.load(from: &pc))
        case 103: return .i64Eqz(Instruction.UnaryOperand.load(from: &pc))
        case 104: return .i32WrapI64(Instruction.UnaryOperand.load(from: &pc))
        case 105: return .i64ExtendI32S(Instruction.UnaryOperand.load(from: &pc))
        case 106: return .i64ExtendI32U(Instruction.UnaryOperand.load(from: &pc))
        case 107: return .i32Extend8S(Instruction.UnaryOperand.load(from: &pc))
        case 108: return .i64Extend8S(Instruction.UnaryOperand.load(from: &pc))
        case 109: return .i32Extend16S(Instruction.UnaryOperand.load(from: &pc))
        case 110: return .i64Extend16S(Instruction.UnaryOperand.load(from: &pc))
        case 111: return .i64Extend32S(Instruction.UnaryOperand.load(from: &pc))
        case 112: return .i32TruncF32S(Instruction.UnaryOperand.load(from: &pc))
        case 113: return .i32TruncF32U(Instruction.UnaryOperand.load(from: &pc))
        case 114: return .i32TruncSatF32S(Instruction.UnaryOperand.load(from: &pc))
        case 115: return .i32TruncSatF32U(Instruction.UnaryOperand.load(from: &pc))
        case 116: return .i32TruncF64S(Instruction.UnaryOperand.load(from: &pc))
        case 117: return .i32TruncF64U(Instruction.UnaryOperand.load(from: &pc))
        case 118: return .i32TruncSatF64S(Instruction.UnaryOperand.load(from: &pc))
        case 119: return .i32TruncSatF64U(Instruction.UnaryOperand.load(from: &pc))
        case 120: return .i64TruncF32S(Instruction.UnaryOperand.load(from: &pc))
        case 121: return .i64TruncF32U(Instruction.UnaryOperand.load(from: &pc))
        case 122: return .i64TruncSatF32S(Instruction.UnaryOperand.load(from: &pc))
        case 123: return .i64TruncSatF32U(Instruction.UnaryOperand.load(from: &pc))
        case 124: return .i64TruncF64S(Instruction.UnaryOperand.load(from: &pc))
        case 125: return .i64TruncF64U(Instruction.UnaryOperand.load(from: &pc))
        case 126: return .i64TruncSatF64S(Instruction.UnaryOperand.load(from: &pc))
        case 127: return .i64TruncSatF64U(Instruction.UnaryOperand.load(from: &pc))
        case 128: return .f32ConvertI32S(Instruction.UnaryOperand.load(from: &pc))
        case 129: return .f32ConvertI32U(Instruction.UnaryOperand.load(from: &pc))
        case 130: return .f32ConvertI64S(Instruction.UnaryOperand.load(from: &pc))
        case 131: return .f32ConvertI64U(Instruction.UnaryOperand.load(from: &pc))
        case 132: return .f64ConvertI32S(Instruction.UnaryOperand.load(from: &pc))
        case 133: return .f64ConvertI32U(Instruction.UnaryOperand.load(from: &pc))
        case 134: return .f64ConvertI64S(Instruction.UnaryOperand.load(from: &pc))
        case 135: return .f64ConvertI64U(Instruction.UnaryOperand.load(from: &pc))
        case 136: return .f32ReinterpretI32(Instruction.UnaryOperand.load(from: &pc))
        case 137: return .f64ReinterpretI64(Instruction.UnaryOperand.load(from: &pc))
        case 138: return .i32ReinterpretF32(Instruction.UnaryOperand.load(from: &pc))
        case 139: return .i64ReinterpretF64(Instruction.UnaryOperand.load(from: &pc))
        case 140: return .f32Add(Instruction.BinaryOperand.load(from: &pc))
        case 141: return .f64Add(Instruction.BinaryOperand.load(from: &pc))
        case 142: return .f32Sub(Instruction.BinaryOperand.load(from: &pc))
        case 143: return .f64Sub(Instruction.BinaryOperand.load(from: &pc))
        case 144: return .f32Mul(Instruction.BinaryOperand.load(from: &pc))
        case 145: return .f64Mul(Instruction.BinaryOperand.load(from: &pc))
        case 146: return .f32Div(Instruction.BinaryOperand.load(from: &pc))
        case 147: return .f64Div(Instruction.BinaryOperand.load(from: &pc))
        case 148: return .f32Min(Instruction.BinaryOperand.load(from: &pc))
        case 149: return .f64Min(Instruction.BinaryOperand.load(from: &pc))
        case 150: return .f32Max(Instruction.BinaryOperand.load(from: &pc))
        case 151: return .f64Max(Instruction.BinaryOperand.load(from: &pc))
        case 152: return .f32CopySign(Instruction.BinaryOperand.load(from: &pc))
        case 153: return .f64CopySign(Instruction.BinaryOperand.load(from: &pc))
        case 154: return .f32Eq(Instruction.BinaryOperand.load(from: &pc))
        case 155: return .f64Eq(Instruction.BinaryOperand.load(from: &pc))
        case 156: return .f32Ne(Instruction.BinaryOperand.load(from: &pc))
        case 157: return .f64Ne(Instruction.BinaryOperand.load(from: &pc))
        case 158: return .f32Lt(Instruction.BinaryOperand.load(from: &pc))
        case 159: return .f64Lt(Instruction.BinaryOperand.load(from: &pc))
        case 160: return .f32Gt(Instruction.BinaryOperand.load(from: &pc))
        case 161: return .f64Gt(Instruction.BinaryOperand.load(from: &pc))
        case 162: return .f32Le(Instruction.BinaryOperand.load(from: &pc))
        case 163: return .f64Le(Instruction.BinaryOperand.load(from: &pc))
        case 164: return .f32Ge(Instruction.BinaryOperand.load(from: &pc))
        case 165: return .f64Ge(Instruction.BinaryOperand.load(from: &pc))
        case 166: return .f32Abs(Instruction.UnaryOperand.load(from: &pc))
        case 167: return .f64Abs(Instruction.UnaryOperand.load(from: &pc))
        case 168: return .f32Neg(Instruction.UnaryOperand.load(from: &pc))
        case 169: return .f64Neg(Instruction.UnaryOperand.load(from: &pc))
        case 170: return .f32Ceil(Instruction.UnaryOperand.load(from: &pc))
        case 171: return .f64Ceil(Instruction.UnaryOperand.load(from: &pc))
        case 172: return .f32Floor(Instruction.UnaryOperand.load(from: &pc))
        case 173: return .f64Floor(Instruction.UnaryOperand.load(from: &pc))
        case 174: return .f32Trunc(Instruction.UnaryOperand.load(from: &pc))
        case 175: return .f64Trunc(Instruction.UnaryOperand.load(from: &pc))
        case 176: return .f32Nearest(Instruction.UnaryOperand.load(from: &pc))
        case 177: return .f64Nearest(Instruction.UnaryOperand.load(from: &pc))
        case 178: return .f32Sqrt(Instruction.UnaryOperand.load(from: &pc))
        case 179: return .f64Sqrt(Instruction.UnaryOperand.load(from: &pc))
        case 180: return .f64PromoteF32(Instruction.UnaryOperand.load(from: &pc))
        case 181: return .f32DemoteF64(Instruction.UnaryOperand.load(from: &pc))
        case 182: return .select(Instruction.SelectOperand.load(from: &pc))
        case 183: return .refNull(Instruction.RefNullOperand.load(from: &pc))
        case 184: return .refIsNull(Instruction.RefIsNullOperand.load(from: &pc))
        case 185: return .refFunc(Instruction.RefFuncOperand.load(from: &pc))
        case 186: return .tableGet(Instruction.TableGetOperand.load(from: &pc))
        case 187: return .tableSet(Instruction.TableSetOperand.load(from: &pc))
        case 188: return .tableSize(Instruction.TableSizeOperand.load(from: &pc))
        case 189: return .tableGrow(Instruction.TableGrowOperand.load(from: &pc))
        case 190: return .tableFill(Instruction.TableFillOperand.load(from: &pc))
        case 191: return .tableCopy(Instruction.TableCopyOperand.load(from: &pc))
        case 192: return .tableInit(Instruction.TableInitOperand.load(from: &pc))
        case 193: return .tableElementDrop(ElementIndex.load(from: &pc))
        case 194: return .onEnter(Instruction.OnEnterOperand.load(from: &pc))
        case 195: return .onExit(Instruction.OnExitOperand.load(from: &pc))
        default: fatalError("Unknown instruction index: \(rawIndex)")
        }
    }
}
