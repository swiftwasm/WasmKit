enum Instruction: Equatable {
    case unreachable
    case nop
    case block(endRef: ExpressionRef, type: BlockType)
    case loop(type: BlockType)
    case ifThen(endRef: ExpressionRef, type: BlockType)
    case ifThenElse(elseRef: ExpressionRef, endRef: ExpressionRef, type: BlockType)
    case end
    case `else`
    case br(labelIndex: LabelIndex)
    case brIf(labelIndex: LabelIndex)
    case brTable(Instruction.BrTable)
    case `return`
    case call(functionIndex: UInt32)
    case callIndirect(tableIndex: TableIndex, typeIndex: TypeIndex)
    case endOfFunction
    case endOfExecution
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
    case numericFloatUnary(NumericInstruction.FloatUnary)
    case numericIntBinary(NumericInstruction.IntBinary)
    case numericFloatBinary(NumericInstruction.FloatBinary)
    case numericConversion(NumericInstruction.Conversion)
    case i32Add
    case i64Add
    case f32Add
    case f64Add
    case i32Sub
    case i64Sub
    case f32Sub
    case f64Sub
    case i32Mul
    case i64Mul
    case f32Mul
    case f64Mul
    case i32Eq
    case i64Eq
    case f32Eq
    case f64Eq
    case i32Ne
    case i64Ne
    case f32Ne
    case f64Ne
    case i32LtS
    case i64LtS
    case i32LtU
    case i64LtU
    case i32GtS
    case i64GtS
    case i32GtU
    case i64GtU
    case i32LeS
    case i64LeS
    case i32LeU
    case i64LeU
    case i32GeS
    case i64GeS
    case i32GeU
    case i64GeU
    case i32Clz
    case i64Clz
    case i32Ctz
    case i64Ctz
    case i32Popcnt
    case i64Popcnt
    case i32Eqz
    case i64Eqz
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
