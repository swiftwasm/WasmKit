enum Instruction: Equatable {
    case copyStack(Instruction.CopyStackOperand)
    case copyX0ToStackI32(dest: LLVReg)
    case copyX0ToStackI64(dest: LLVReg)
    case copyD0ToStackF32(dest: LLVReg)
    case copyD0ToStackF64(dest: LLVReg)
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
    case i32LoadS(Instruction.LoadOperandS)
    case i32LoadR(Instruction.LoadOperandR)
    case i64LoadS(Instruction.LoadOperandS)
    case i64LoadR(Instruction.LoadOperandR)
    case f32LoadS(Instruction.LoadOperandS)
    case f32LoadR(Instruction.LoadOperandR)
    case f64LoadS(Instruction.LoadOperandS)
    case f64LoadR(Instruction.LoadOperandR)
    case i32Load8SS(Instruction.LoadOperandS)
    case i32Load8SR(Instruction.LoadOperandR)
    case i32Load8US(Instruction.LoadOperandS)
    case i32Load8UR(Instruction.LoadOperandR)
    case i32Load16SS(Instruction.LoadOperandS)
    case i32Load16SR(Instruction.LoadOperandR)
    case i32Load16US(Instruction.LoadOperandS)
    case i32Load16UR(Instruction.LoadOperandR)
    case i64Load8SS(Instruction.LoadOperandS)
    case i64Load8SR(Instruction.LoadOperandR)
    case i64Load8US(Instruction.LoadOperandS)
    case i64Load8UR(Instruction.LoadOperandR)
    case i64Load16SS(Instruction.LoadOperandS)
    case i64Load16SR(Instruction.LoadOperandR)
    case i64Load16US(Instruction.LoadOperandS)
    case i64Load16UR(Instruction.LoadOperandR)
    case i64Load32SS(Instruction.LoadOperandS)
    case i64Load32SR(Instruction.LoadOperandR)
    case i64Load32US(Instruction.LoadOperandS)
    case i64Load32UR(Instruction.LoadOperandR)
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
    case constI32(Instruction.Const32Operand)
    case constI64(Instruction.Const64Operand)
    case constF32(Instruction.Const32Operand)
    case constF64(Instruction.Const64Operand)
    case i32AddSS(Instruction.BinaryOperandSS)
    case i32AddSR(Instruction.BinaryOperandSR)
    case i64AddSS(Instruction.BinaryOperandSS)
    case i64AddSR(Instruction.BinaryOperandSR)
    case i32MulSS(Instruction.BinaryOperandSS)
    case i32MulSR(Instruction.BinaryOperandSR)
    case i64MulSS(Instruction.BinaryOperandSS)
    case i64MulSR(Instruction.BinaryOperandSR)
    case i32AndSS(Instruction.BinaryOperandSS)
    case i32AndSR(Instruction.BinaryOperandSR)
    case i64AndSS(Instruction.BinaryOperandSS)
    case i64AndSR(Instruction.BinaryOperandSR)
    case i32OrSS(Instruction.BinaryOperandSS)
    case i32OrSR(Instruction.BinaryOperandSR)
    case i64OrSS(Instruction.BinaryOperandSS)
    case i64OrSR(Instruction.BinaryOperandSR)
    case i32XorSS(Instruction.BinaryOperandSS)
    case i32XorSR(Instruction.BinaryOperandSR)
    case i64XorSS(Instruction.BinaryOperandSS)
    case i64XorSR(Instruction.BinaryOperandSR)
    case i32SubSS(Instruction.BinaryOperandSS)
    case i32SubSR(Instruction.BinaryOperandSR)
    case i32SubRS(Instruction.BinaryOperandRS)
    case i64SubSS(Instruction.BinaryOperandSS)
    case i64SubSR(Instruction.BinaryOperandSR)
    case i64SubRS(Instruction.BinaryOperandRS)
    case i32ShlSS(Instruction.BinaryOperandSS)
    case i32ShlSR(Instruction.BinaryOperandSR)
    case i32ShlRS(Instruction.BinaryOperandRS)
    case i64ShlSS(Instruction.BinaryOperandSS)
    case i64ShlSR(Instruction.BinaryOperandSR)
    case i64ShlRS(Instruction.BinaryOperandRS)
    case i32ShrSSS(Instruction.BinaryOperandSS)
    case i32ShrSSR(Instruction.BinaryOperandSR)
    case i32ShrSRS(Instruction.BinaryOperandRS)
    case i64ShrSSS(Instruction.BinaryOperandSS)
    case i64ShrSSR(Instruction.BinaryOperandSR)
    case i64ShrSRS(Instruction.BinaryOperandRS)
    case i32ShrUSS(Instruction.BinaryOperandSS)
    case i32ShrUSR(Instruction.BinaryOperandSR)
    case i32ShrURS(Instruction.BinaryOperandRS)
    case i64ShrUSS(Instruction.BinaryOperandSS)
    case i64ShrUSR(Instruction.BinaryOperandSR)
    case i64ShrURS(Instruction.BinaryOperandRS)
    case i32RotlSS(Instruction.BinaryOperandSS)
    case i32RotlSR(Instruction.BinaryOperandSR)
    case i32RotlRS(Instruction.BinaryOperandRS)
    case i64RotlSS(Instruction.BinaryOperandSS)
    case i64RotlSR(Instruction.BinaryOperandSR)
    case i64RotlRS(Instruction.BinaryOperandRS)
    case i32RotrSS(Instruction.BinaryOperandSS)
    case i32RotrSR(Instruction.BinaryOperandSR)
    case i32RotrRS(Instruction.BinaryOperandRS)
    case i64RotrSS(Instruction.BinaryOperandSS)
    case i64RotrSR(Instruction.BinaryOperandSR)
    case i64RotrRS(Instruction.BinaryOperandRS)
    case i32DivSSS(Instruction.BinaryOperandSS)
    case i32DivSSR(Instruction.BinaryOperandSR)
    case i32DivSRS(Instruction.BinaryOperandRS)
    case i64DivSSS(Instruction.BinaryOperandSS)
    case i64DivSSR(Instruction.BinaryOperandSR)
    case i64DivSRS(Instruction.BinaryOperandRS)
    case i32DivUSS(Instruction.BinaryOperandSS)
    case i32DivUSR(Instruction.BinaryOperandSR)
    case i32DivURS(Instruction.BinaryOperandRS)
    case i64DivUSS(Instruction.BinaryOperandSS)
    case i64DivUSR(Instruction.BinaryOperandSR)
    case i64DivURS(Instruction.BinaryOperandRS)
    case i32RemSSS(Instruction.BinaryOperandSS)
    case i32RemSSR(Instruction.BinaryOperandSR)
    case i32RemSRS(Instruction.BinaryOperandRS)
    case i64RemSSS(Instruction.BinaryOperandSS)
    case i64RemSSR(Instruction.BinaryOperandSR)
    case i64RemSRS(Instruction.BinaryOperandRS)
    case i32RemUSS(Instruction.BinaryOperandSS)
    case i32RemUSR(Instruction.BinaryOperandSR)
    case i32RemURS(Instruction.BinaryOperandRS)
    case i64RemUSS(Instruction.BinaryOperandSS)
    case i64RemUSR(Instruction.BinaryOperandSR)
    case i64RemURS(Instruction.BinaryOperandRS)
    case i32EqSS(Instruction.BinaryOperandSS)
    case i32EqSR(Instruction.BinaryOperandSR)
    case i64EqSS(Instruction.BinaryOperandSS)
    case i64EqSR(Instruction.BinaryOperandSR)
    case i32NeSS(Instruction.BinaryOperandSS)
    case i32NeSR(Instruction.BinaryOperandSR)
    case i64NeSS(Instruction.BinaryOperandSS)
    case i64NeSR(Instruction.BinaryOperandSR)
    case i32LtSSS(Instruction.BinaryOperandSS)
    case i32LtSSR(Instruction.BinaryOperandSR)
    case i32LtSRS(Instruction.BinaryOperandRS)
    case i64LtSSS(Instruction.BinaryOperandSS)
    case i64LtSSR(Instruction.BinaryOperandSR)
    case i64LtSRS(Instruction.BinaryOperandRS)
    case i32LtUSS(Instruction.BinaryOperandSS)
    case i32LtUSR(Instruction.BinaryOperandSR)
    case i32LtURS(Instruction.BinaryOperandRS)
    case i64LtUSS(Instruction.BinaryOperandSS)
    case i64LtUSR(Instruction.BinaryOperandSR)
    case i64LtURS(Instruction.BinaryOperandRS)
    case i32GtSSS(Instruction.BinaryOperandSS)
    case i32GtSSR(Instruction.BinaryOperandSR)
    case i32GtSRS(Instruction.BinaryOperandRS)
    case i64GtSSS(Instruction.BinaryOperandSS)
    case i64GtSSR(Instruction.BinaryOperandSR)
    case i64GtSRS(Instruction.BinaryOperandRS)
    case i32GtUSS(Instruction.BinaryOperandSS)
    case i32GtUSR(Instruction.BinaryOperandSR)
    case i32GtURS(Instruction.BinaryOperandRS)
    case i64GtUSS(Instruction.BinaryOperandSS)
    case i64GtUSR(Instruction.BinaryOperandSR)
    case i64GtURS(Instruction.BinaryOperandRS)
    case i32LeSSS(Instruction.BinaryOperandSS)
    case i32LeSSR(Instruction.BinaryOperandSR)
    case i32LeSRS(Instruction.BinaryOperandRS)
    case i64LeSSS(Instruction.BinaryOperandSS)
    case i64LeSSR(Instruction.BinaryOperandSR)
    case i64LeSRS(Instruction.BinaryOperandRS)
    case i32LeUSS(Instruction.BinaryOperandSS)
    case i32LeUSR(Instruction.BinaryOperandSR)
    case i32LeURS(Instruction.BinaryOperandRS)
    case i64LeUSS(Instruction.BinaryOperandSS)
    case i64LeUSR(Instruction.BinaryOperandSR)
    case i64LeURS(Instruction.BinaryOperandRS)
    case i32GeSSS(Instruction.BinaryOperandSS)
    case i32GeSSR(Instruction.BinaryOperandSR)
    case i32GeSRS(Instruction.BinaryOperandRS)
    case i64GeSSS(Instruction.BinaryOperandSS)
    case i64GeSSR(Instruction.BinaryOperandSR)
    case i64GeSRS(Instruction.BinaryOperandRS)
    case i32GeUSS(Instruction.BinaryOperandSS)
    case i32GeUSR(Instruction.BinaryOperandSR)
    case i32GeURS(Instruction.BinaryOperandRS)
    case i64GeUSS(Instruction.BinaryOperandSS)
    case i64GeUSR(Instruction.BinaryOperandSR)
    case i64GeURS(Instruction.BinaryOperandRS)
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
        case .copyX0ToStackI32(let dest): return dest
        case .copyX0ToStackI64(let dest): return dest
        case .copyD0ToStackF32(let dest): return dest
        case .copyD0ToStackF64(let dest): return dest
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
        case .i32LoadS(let loadOperandS): return loadOperandS
        case .i32LoadR(let loadOperandR): return loadOperandR
        case .i64LoadS(let loadOperandS): return loadOperandS
        case .i64LoadR(let loadOperandR): return loadOperandR
        case .f32LoadS(let loadOperandS): return loadOperandS
        case .f32LoadR(let loadOperandR): return loadOperandR
        case .f64LoadS(let loadOperandS): return loadOperandS
        case .f64LoadR(let loadOperandR): return loadOperandR
        case .i32Load8SS(let loadOperandS): return loadOperandS
        case .i32Load8SR(let loadOperandR): return loadOperandR
        case .i32Load8US(let loadOperandS): return loadOperandS
        case .i32Load8UR(let loadOperandR): return loadOperandR
        case .i32Load16SS(let loadOperandS): return loadOperandS
        case .i32Load16SR(let loadOperandR): return loadOperandR
        case .i32Load16US(let loadOperandS): return loadOperandS
        case .i32Load16UR(let loadOperandR): return loadOperandR
        case .i64Load8SS(let loadOperandS): return loadOperandS
        case .i64Load8SR(let loadOperandR): return loadOperandR
        case .i64Load8US(let loadOperandS): return loadOperandS
        case .i64Load8UR(let loadOperandR): return loadOperandR
        case .i64Load16SS(let loadOperandS): return loadOperandS
        case .i64Load16SR(let loadOperandR): return loadOperandR
        case .i64Load16US(let loadOperandS): return loadOperandS
        case .i64Load16UR(let loadOperandR): return loadOperandR
        case .i64Load32SS(let loadOperandS): return loadOperandS
        case .i64Load32SR(let loadOperandR): return loadOperandR
        case .i64Load32US(let loadOperandS): return loadOperandS
        case .i64Load32UR(let loadOperandR): return loadOperandR
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
        case .constI32(let const32Operand): return const32Operand
        case .constI64(let const64Operand): return const64Operand
        case .constF32(let const32Operand): return const32Operand
        case .constF64(let const64Operand): return const64Operand
        case .i32AddSS(let binaryOperandSS): return binaryOperandSS
        case .i32AddSR(let binaryOperandSR): return binaryOperandSR
        case .i64AddSS(let binaryOperandSS): return binaryOperandSS
        case .i64AddSR(let binaryOperandSR): return binaryOperandSR
        case .i32MulSS(let binaryOperandSS): return binaryOperandSS
        case .i32MulSR(let binaryOperandSR): return binaryOperandSR
        case .i64MulSS(let binaryOperandSS): return binaryOperandSS
        case .i64MulSR(let binaryOperandSR): return binaryOperandSR
        case .i32AndSS(let binaryOperandSS): return binaryOperandSS
        case .i32AndSR(let binaryOperandSR): return binaryOperandSR
        case .i64AndSS(let binaryOperandSS): return binaryOperandSS
        case .i64AndSR(let binaryOperandSR): return binaryOperandSR
        case .i32OrSS(let binaryOperandSS): return binaryOperandSS
        case .i32OrSR(let binaryOperandSR): return binaryOperandSR
        case .i64OrSS(let binaryOperandSS): return binaryOperandSS
        case .i64OrSR(let binaryOperandSR): return binaryOperandSR
        case .i32XorSS(let binaryOperandSS): return binaryOperandSS
        case .i32XorSR(let binaryOperandSR): return binaryOperandSR
        case .i64XorSS(let binaryOperandSS): return binaryOperandSS
        case .i64XorSR(let binaryOperandSR): return binaryOperandSR
        case .i32SubSS(let binaryOperandSS): return binaryOperandSS
        case .i32SubSR(let binaryOperandSR): return binaryOperandSR
        case .i32SubRS(let binaryOperandRS): return binaryOperandRS
        case .i64SubSS(let binaryOperandSS): return binaryOperandSS
        case .i64SubSR(let binaryOperandSR): return binaryOperandSR
        case .i64SubRS(let binaryOperandRS): return binaryOperandRS
        case .i32ShlSS(let binaryOperandSS): return binaryOperandSS
        case .i32ShlSR(let binaryOperandSR): return binaryOperandSR
        case .i32ShlRS(let binaryOperandRS): return binaryOperandRS
        case .i64ShlSS(let binaryOperandSS): return binaryOperandSS
        case .i64ShlSR(let binaryOperandSR): return binaryOperandSR
        case .i64ShlRS(let binaryOperandRS): return binaryOperandRS
        case .i32ShrSSS(let binaryOperandSS): return binaryOperandSS
        case .i32ShrSSR(let binaryOperandSR): return binaryOperandSR
        case .i32ShrSRS(let binaryOperandRS): return binaryOperandRS
        case .i64ShrSSS(let binaryOperandSS): return binaryOperandSS
        case .i64ShrSSR(let binaryOperandSR): return binaryOperandSR
        case .i64ShrSRS(let binaryOperandRS): return binaryOperandRS
        case .i32ShrUSS(let binaryOperandSS): return binaryOperandSS
        case .i32ShrUSR(let binaryOperandSR): return binaryOperandSR
        case .i32ShrURS(let binaryOperandRS): return binaryOperandRS
        case .i64ShrUSS(let binaryOperandSS): return binaryOperandSS
        case .i64ShrUSR(let binaryOperandSR): return binaryOperandSR
        case .i64ShrURS(let binaryOperandRS): return binaryOperandRS
        case .i32RotlSS(let binaryOperandSS): return binaryOperandSS
        case .i32RotlSR(let binaryOperandSR): return binaryOperandSR
        case .i32RotlRS(let binaryOperandRS): return binaryOperandRS
        case .i64RotlSS(let binaryOperandSS): return binaryOperandSS
        case .i64RotlSR(let binaryOperandSR): return binaryOperandSR
        case .i64RotlRS(let binaryOperandRS): return binaryOperandRS
        case .i32RotrSS(let binaryOperandSS): return binaryOperandSS
        case .i32RotrSR(let binaryOperandSR): return binaryOperandSR
        case .i32RotrRS(let binaryOperandRS): return binaryOperandRS
        case .i64RotrSS(let binaryOperandSS): return binaryOperandSS
        case .i64RotrSR(let binaryOperandSR): return binaryOperandSR
        case .i64RotrRS(let binaryOperandRS): return binaryOperandRS
        case .i32DivSSS(let binaryOperandSS): return binaryOperandSS
        case .i32DivSSR(let binaryOperandSR): return binaryOperandSR
        case .i32DivSRS(let binaryOperandRS): return binaryOperandRS
        case .i64DivSSS(let binaryOperandSS): return binaryOperandSS
        case .i64DivSSR(let binaryOperandSR): return binaryOperandSR
        case .i64DivSRS(let binaryOperandRS): return binaryOperandRS
        case .i32DivUSS(let binaryOperandSS): return binaryOperandSS
        case .i32DivUSR(let binaryOperandSR): return binaryOperandSR
        case .i32DivURS(let binaryOperandRS): return binaryOperandRS
        case .i64DivUSS(let binaryOperandSS): return binaryOperandSS
        case .i64DivUSR(let binaryOperandSR): return binaryOperandSR
        case .i64DivURS(let binaryOperandRS): return binaryOperandRS
        case .i32RemSSS(let binaryOperandSS): return binaryOperandSS
        case .i32RemSSR(let binaryOperandSR): return binaryOperandSR
        case .i32RemSRS(let binaryOperandRS): return binaryOperandRS
        case .i64RemSSS(let binaryOperandSS): return binaryOperandSS
        case .i64RemSSR(let binaryOperandSR): return binaryOperandSR
        case .i64RemSRS(let binaryOperandRS): return binaryOperandRS
        case .i32RemUSS(let binaryOperandSS): return binaryOperandSS
        case .i32RemUSR(let binaryOperandSR): return binaryOperandSR
        case .i32RemURS(let binaryOperandRS): return binaryOperandRS
        case .i64RemUSS(let binaryOperandSS): return binaryOperandSS
        case .i64RemUSR(let binaryOperandSR): return binaryOperandSR
        case .i64RemURS(let binaryOperandRS): return binaryOperandRS
        case .i32EqSS(let binaryOperandSS): return binaryOperandSS
        case .i32EqSR(let binaryOperandSR): return binaryOperandSR
        case .i64EqSS(let binaryOperandSS): return binaryOperandSS
        case .i64EqSR(let binaryOperandSR): return binaryOperandSR
        case .i32NeSS(let binaryOperandSS): return binaryOperandSS
        case .i32NeSR(let binaryOperandSR): return binaryOperandSR
        case .i64NeSS(let binaryOperandSS): return binaryOperandSS
        case .i64NeSR(let binaryOperandSR): return binaryOperandSR
        case .i32LtSSS(let binaryOperandSS): return binaryOperandSS
        case .i32LtSSR(let binaryOperandSR): return binaryOperandSR
        case .i32LtSRS(let binaryOperandRS): return binaryOperandRS
        case .i64LtSSS(let binaryOperandSS): return binaryOperandSS
        case .i64LtSSR(let binaryOperandSR): return binaryOperandSR
        case .i64LtSRS(let binaryOperandRS): return binaryOperandRS
        case .i32LtUSS(let binaryOperandSS): return binaryOperandSS
        case .i32LtUSR(let binaryOperandSR): return binaryOperandSR
        case .i32LtURS(let binaryOperandRS): return binaryOperandRS
        case .i64LtUSS(let binaryOperandSS): return binaryOperandSS
        case .i64LtUSR(let binaryOperandSR): return binaryOperandSR
        case .i64LtURS(let binaryOperandRS): return binaryOperandRS
        case .i32GtSSS(let binaryOperandSS): return binaryOperandSS
        case .i32GtSSR(let binaryOperandSR): return binaryOperandSR
        case .i32GtSRS(let binaryOperandRS): return binaryOperandRS
        case .i64GtSSS(let binaryOperandSS): return binaryOperandSS
        case .i64GtSSR(let binaryOperandSR): return binaryOperandSR
        case .i64GtSRS(let binaryOperandRS): return binaryOperandRS
        case .i32GtUSS(let binaryOperandSS): return binaryOperandSS
        case .i32GtUSR(let binaryOperandSR): return binaryOperandSR
        case .i32GtURS(let binaryOperandRS): return binaryOperandRS
        case .i64GtUSS(let binaryOperandSS): return binaryOperandSS
        case .i64GtUSR(let binaryOperandSR): return binaryOperandSR
        case .i64GtURS(let binaryOperandRS): return binaryOperandRS
        case .i32LeSSS(let binaryOperandSS): return binaryOperandSS
        case .i32LeSSR(let binaryOperandSR): return binaryOperandSR
        case .i32LeSRS(let binaryOperandRS): return binaryOperandRS
        case .i64LeSSS(let binaryOperandSS): return binaryOperandSS
        case .i64LeSSR(let binaryOperandSR): return binaryOperandSR
        case .i64LeSRS(let binaryOperandRS): return binaryOperandRS
        case .i32LeUSS(let binaryOperandSS): return binaryOperandSS
        case .i32LeUSR(let binaryOperandSR): return binaryOperandSR
        case .i32LeURS(let binaryOperandRS): return binaryOperandRS
        case .i64LeUSS(let binaryOperandSS): return binaryOperandSS
        case .i64LeUSR(let binaryOperandSR): return binaryOperandSR
        case .i64LeURS(let binaryOperandRS): return binaryOperandRS
        case .i32GeSSS(let binaryOperandSS): return binaryOperandSS
        case .i32GeSSR(let binaryOperandSR): return binaryOperandSR
        case .i32GeSRS(let binaryOperandRS): return binaryOperandRS
        case .i64GeSSS(let binaryOperandSS): return binaryOperandSS
        case .i64GeSSR(let binaryOperandSR): return binaryOperandSR
        case .i64GeSRS(let binaryOperandRS): return binaryOperandRS
        case .i32GeUSS(let binaryOperandSS): return binaryOperandSS
        case .i32GeUSR(let binaryOperandSR): return binaryOperandSR
        case .i32GeURS(let binaryOperandRS): return binaryOperandRS
        case .i64GeUSS(let binaryOperandSS): return binaryOperandSS
        case .i64GeUSR(let binaryOperandSR): return binaryOperandSR
        case .i64GeURS(let binaryOperandRS): return binaryOperandRS
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
