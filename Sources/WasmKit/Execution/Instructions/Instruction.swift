enum Instruction: Equatable {
    case unreachable
    case nop
    case block(endRef: ExpressionRef, type: ResultType)
    case loop(type: ResultType)
    case ifThen(endRef: ExpressionRef, type: ResultType)
    case ifThenElse(elseRef: ExpressionRef, endRef: ExpressionRef, type: ResultType)
    case end
    case `else`
    case br(labelIndex: LabelIndex)
    case brIf(labelIndex: LabelIndex)
    case brTable(BrTable)
    case `return`
    case call(functionIndex: UInt32)
    case callIndirect(tableIndex: TableIndex, typeIndex: TypeIndex)
    case i32Load(memarg: Memarg)
    case i64Load(memarg: Memarg)
    case f32Load(memarg: Memarg)
    case f64Load(memarg: Memarg)
    case i32Load8S(memarg: Memarg)
    case i32Load8U(memarg: Memarg)
    case i32Load16S(memarg: Memarg)
    case i32Load16U(memarg: Memarg)
    case i64Load8S(memarg: Memarg)
    case i64Load8U(memarg: Memarg)
    case i64Load16S(memarg: Memarg)
    case i64Load16U(memarg: Memarg)
    case i64Load32S(memarg: Memarg)
    case i64Load32U(memarg: Memarg)
    case i32Store(memarg: Memarg)
    case i64Store(memarg: Memarg)
    case f32Store(memarg: Memarg)
    case f64Store(memarg: Memarg)
    case i32Store8(memarg: Memarg)
    case i32Store16(memarg: Memarg)
    case i64Store8(memarg: Memarg)
    case i64Store16(memarg: Memarg)
    case i64Store32(memarg: Memarg)
    case memorySize
    case memoryGrow
    case memoryInit(DataIndex)
    case memoryDataDrop(DataIndex)
    case memoryCopy
    case memoryFill
    case numericConst(Value)
    case numericIntUnary(NumericInstruction.IntUnary)
    case numericFloatUnary(NumericInstruction.FloatUnary)
    case numericBinary(NumericInstruction.Binary)
    case numericIntBinary(NumericInstruction.IntBinary)
    case numericFloatBinary(NumericInstruction.FloatBinary)
    case numericConversion(NumericInstruction.Conversion)
    case drop
    case select
    case refNull(ReferenceType)
    case refIsNull
    case refFunc(FunctionIndex)
    case tableGet(TableIndex)
    case tableSet(TableIndex)
    case tableSize(TableIndex)
    case tableGrow(TableIndex)
    case tableFill(TableIndex)
    case tableCopy(dest: TableIndex, src: TableIndex)
    case tableInit(TableIndex, ElementIndex)
    case tableElementDrop(ElementIndex)
    case localGet(index: LocalIndex)
    case localSet(index: LocalIndex)
    case localTee(index: LocalIndex)
    case globalGet(index: GlobalIndex)
    case globalSet(index: GlobalIndex)
}
