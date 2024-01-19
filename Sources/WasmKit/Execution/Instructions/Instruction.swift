enum Instruction: Equatable {

    static func control(_ x: Instruction) -> Instruction { x }
    static func numeric(_ x: Instruction) -> Instruction { x }
    static func parametric(_ x: Instruction) -> Instruction { x }
    static func variable(_ x: Instruction) -> Instruction { x }
    static func reference(_ x: Instruction) -> Instruction { x }

    case unreachable
    case nop
    case block(expression: Expression, type: ResultType)
    case loop(expression: Expression, type: ResultType)
    case `if`(thenExpr: Expression, elseExpr: Expression, type: ResultType)
    case br(labelIndex: LabelIndex)
    case brIf(labelIndex: LabelIndex)
    case brTable(labelIndices: [LabelIndex], defaultIndex: LabelIndex)
    case `return`
    case call(functionIndex: UInt32)
    case callIndirect(tableIndex: TableIndex, typeIndex: TypeIndex)

    struct Memarg: Equatable {
        let offset: UInt64
        let align: UInt32
    }

    case memoryLoad(memarg: Memarg, bitWidth: UInt8, type: NumericType, isSigned: Bool = true)
    case memoryStore(memarg: Memarg, bitWidth: UInt8, type: ValueType)
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
    case typedSelect(types: [ValueType])

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

    case pseudo(PseudoInstruction)
}
