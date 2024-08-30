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
    case numericFloatUnary(NumericInstruction.FloatUnary, Instruction.UnaryOperand)
    case numericConversion(NumericInstruction.Conversion, Instruction.UnaryOperand)
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
    case i32TruncF64S(Instruction.UnaryOperand)
    case i32TruncF64U(Instruction.UnaryOperand)
    case i64TruncF32S(Instruction.UnaryOperand)
    case i64TruncF32U(Instruction.UnaryOperand)
    case i64TruncF64S(Instruction.UnaryOperand)
    case i64TruncF64U(Instruction.UnaryOperand)
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
        case .numericFloatUnary: return true
        case .numericConversion: return true
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
        case .i32TruncF64S: return true
        case .i32TruncF64U: return true
        case .i64TruncF32S: return true
        case .i64TruncF32U: return true
        case .i64TruncF64S: return true
        case .i64TruncF64U: return true
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
