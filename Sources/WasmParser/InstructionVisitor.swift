// swift-format-ignore-file
//// Automatically generated by Utilities/Sources/WasmGen.swift
//// DO NOT EDIT DIRECTLY

import WasmTypes

public enum Instruction: Equatable {
    public enum Load: Equatable {
        case i32Load
        case i64Load
        case f32Load
        case f64Load
        case i32Load8S
        case i32Load8U
        case i32Load16S
        case i32Load16U
        case i64Load8S
        case i64Load8U
        case i64Load16S
        case i64Load16U
        case i64Load32S
        case i64Load32U
    }
    public enum Store: Equatable {
        case i32Store
        case i64Store
        case f32Store
        case f64Store
        case i32Store8
        case i32Store16
        case i64Store8
        case i64Store16
        case i64Store32
    }
    public enum Cmp: Equatable {
        case i32Eq
        case i32Ne
        case i32LtS
        case i32LtU
        case i32GtS
        case i32GtU
        case i32LeS
        case i32LeU
        case i32GeS
        case i32GeU
        case i64Eq
        case i64Ne
        case i64LtS
        case i64LtU
        case i64GtS
        case i64GtU
        case i64LeS
        case i64LeU
        case i64GeS
        case i64GeU
        case f32Eq
        case f32Ne
        case f32Lt
        case f32Gt
        case f32Le
        case f32Ge
        case f64Eq
        case f64Ne
        case f64Lt
        case f64Gt
        case f64Le
        case f64Ge
    }
    public enum Unary: Equatable {
        case i32Clz
        case i32Ctz
        case i32Popcnt
        case i64Clz
        case i64Ctz
        case i64Popcnt
        case f32Abs
        case f32Neg
        case f32Ceil
        case f32Floor
        case f32Trunc
        case f32Nearest
        case f32Sqrt
        case f64Abs
        case f64Neg
        case f64Ceil
        case f64Floor
        case f64Trunc
        case f64Nearest
        case f64Sqrt
        case i32Extend8S
        case i32Extend16S
        case i64Extend8S
        case i64Extend16S
        case i64Extend32S
    }
    public enum Binary: Equatable {
        case i32Add
        case i32Sub
        case i32Mul
        case i32DivS
        case i32DivU
        case i32RemS
        case i32RemU
        case i32And
        case i32Or
        case i32Xor
        case i32Shl
        case i32ShrS
        case i32ShrU
        case i32Rotl
        case i32Rotr
        case i64Add
        case i64Sub
        case i64Mul
        case i64DivS
        case i64DivU
        case i64RemS
        case i64RemU
        case i64And
        case i64Or
        case i64Xor
        case i64Shl
        case i64ShrS
        case i64ShrU
        case i64Rotl
        case i64Rotr
        case f32Add
        case f32Sub
        case f32Mul
        case f32Div
        case f32Min
        case f32Max
        case f32Copysign
        case f64Add
        case f64Sub
        case f64Mul
        case f64Div
        case f64Min
        case f64Max
        case f64Copysign
    }
    public enum Conversion: Equatable {
        case i32WrapI64
        case i32TruncF32S
        case i32TruncF32U
        case i32TruncF64S
        case i32TruncF64U
        case i64ExtendI32S
        case i64ExtendI32U
        case i64TruncF32S
        case i64TruncF32U
        case i64TruncF64S
        case i64TruncF64U
        case f32ConvertI32S
        case f32ConvertI32U
        case f32ConvertI64S
        case f32ConvertI64U
        case f32DemoteF64
        case f64ConvertI32S
        case f64ConvertI32U
        case f64ConvertI64S
        case f64ConvertI64U
        case f64PromoteF32
        case i32ReinterpretF32
        case i64ReinterpretF64
        case f32ReinterpretI32
        case f64ReinterpretI64
        case i32TruncSatF32S
        case i32TruncSatF32U
        case i32TruncSatF64S
        case i32TruncSatF64U
        case i64TruncSatF32S
        case i64TruncSatF32U
        case i64TruncSatF64S
        case i64TruncSatF64U
    }
    case `unreachable`
    case `nop`
    case `block`(blockType: BlockType)
    case `loop`(blockType: BlockType)
    case `if`(blockType: BlockType)
    case `else`
    case `end`
    case `br`(relativeDepth: UInt32)
    case `brIf`(relativeDepth: UInt32)
    case `brTable`(targets: BrTable)
    case `return`
    case `call`(functionIndex: UInt32)
    case `callIndirect`(typeIndex: UInt32, tableIndex: UInt32)
    case `returnCall`(functionIndex: UInt32)
    case `returnCallIndirect`(typeIndex: UInt32, tableIndex: UInt32)
    case `drop`
    case `select`
    case `typedSelect`(type: ValueType)
    case `localGet`(localIndex: UInt32)
    case `localSet`(localIndex: UInt32)
    case `localTee`(localIndex: UInt32)
    case `globalGet`(globalIndex: UInt32)
    case `globalSet`(globalIndex: UInt32)
    case `load`(Instruction.Load, memarg: MemArg)
    case `store`(Instruction.Store, memarg: MemArg)
    case `memorySize`(memory: UInt32)
    case `memoryGrow`(memory: UInt32)
    case `i32Const`(value: Int32)
    case `i64Const`(value: Int64)
    case `f32Const`(value: IEEE754.Float32)
    case `f64Const`(value: IEEE754.Float64)
    case `refNull`(type: ReferenceType)
    case `refIsNull`
    case `refFunc`(functionIndex: UInt32)
    case `i32Eqz`
    case `cmp`(Instruction.Cmp)
    case `i64Eqz`
    case `unary`(Instruction.Unary)
    case `binary`(Instruction.Binary)
    case `conversion`(Instruction.Conversion)
    case `memoryInit`(dataIndex: UInt32)
    case `dataDrop`(dataIndex: UInt32)
    case `memoryCopy`(dstMem: UInt32, srcMem: UInt32)
    case `memoryFill`(memory: UInt32)
    case `tableInit`(elemIndex: UInt32, table: UInt32)
    case `elemDrop`(elemIndex: UInt32)
    case `tableCopy`(dstTable: UInt32, srcTable: UInt32)
    case `tableFill`(table: UInt32)
    case `tableGet`(table: UInt32)
    case `tableSet`(table: UInt32)
    case `tableGrow`(table: UInt32)
    case `tableSize`(table: UInt32)
    case `callRef`(functionIndex: UInt32)
    case `returnCallRef`(functionIndex: UInt32)
    case `asNonNull`
    case `brOnNull`(functionIndex: UInt32)
    case `brOnNonNull`(functionIndex: UInt32)
}

/// A visitor that visits all instructions by a single visit method.
public protocol AnyInstructionVisitor: InstructionVisitor {
    /// Visiting any instruction.
    mutating func visit(_ instruction: Instruction) throws
}

extension AnyInstructionVisitor {
    public mutating func visitUnreachable() throws { return try self.visit(.unreachable) }
    public mutating func visitNop() throws { return try self.visit(.nop) }
    public mutating func visitBlock(blockType: BlockType) throws { return try self.visit(.block(blockType: blockType)) }
    public mutating func visitLoop(blockType: BlockType) throws { return try self.visit(.loop(blockType: blockType)) }
    public mutating func visitIf(blockType: BlockType) throws { return try self.visit(.if(blockType: blockType)) }
    public mutating func visitElse() throws { return try self.visit(.else) }
    public mutating func visitEnd() throws { return try self.visit(.end) }
    public mutating func visitBr(relativeDepth: UInt32) throws { return try self.visit(.br(relativeDepth: relativeDepth)) }
    public mutating func visitBrIf(relativeDepth: UInt32) throws { return try self.visit(.brIf(relativeDepth: relativeDepth)) }
    public mutating func visitBrTable(targets: BrTable) throws { return try self.visit(.brTable(targets: targets)) }
    public mutating func visitReturn() throws { return try self.visit(.return) }
    public mutating func visitCall(functionIndex: UInt32) throws { return try self.visit(.call(functionIndex: functionIndex)) }
    public mutating func visitCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws { return try self.visit(.callIndirect(typeIndex: typeIndex, tableIndex: tableIndex)) }
    public mutating func visitReturnCall(functionIndex: UInt32) throws { return try self.visit(.returnCall(functionIndex: functionIndex)) }
    public mutating func visitReturnCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws { return try self.visit(.returnCallIndirect(typeIndex: typeIndex, tableIndex: tableIndex)) }
    public mutating func visitDrop() throws { return try self.visit(.drop) }
    public mutating func visitSelect() throws { return try self.visit(.select) }
    public mutating func visitTypedSelect(type: ValueType) throws { return try self.visit(.typedSelect(type: type)) }
    public mutating func visitLocalGet(localIndex: UInt32) throws { return try self.visit(.localGet(localIndex: localIndex)) }
    public mutating func visitLocalSet(localIndex: UInt32) throws { return try self.visit(.localSet(localIndex: localIndex)) }
    public mutating func visitLocalTee(localIndex: UInt32) throws { return try self.visit(.localTee(localIndex: localIndex)) }
    public mutating func visitGlobalGet(globalIndex: UInt32) throws { return try self.visit(.globalGet(globalIndex: globalIndex)) }
    public mutating func visitGlobalSet(globalIndex: UInt32) throws { return try self.visit(.globalSet(globalIndex: globalIndex)) }
    public mutating func visitLoad(_ load: Instruction.Load, memarg: MemArg) throws { return try self.visit(.load(load, memarg: memarg)) }
    public mutating func visitStore(_ store: Instruction.Store, memarg: MemArg) throws { return try self.visit(.store(store, memarg: memarg)) }
    public mutating func visitMemorySize(memory: UInt32) throws { return try self.visit(.memorySize(memory: memory)) }
    public mutating func visitMemoryGrow(memory: UInt32) throws { return try self.visit(.memoryGrow(memory: memory)) }
    public mutating func visitI32Const(value: Int32) throws { return try self.visit(.i32Const(value: value)) }
    public mutating func visitI64Const(value: Int64) throws { return try self.visit(.i64Const(value: value)) }
    public mutating func visitF32Const(value: IEEE754.Float32) throws { return try self.visit(.f32Const(value: value)) }
    public mutating func visitF64Const(value: IEEE754.Float64) throws { return try self.visit(.f64Const(value: value)) }
    public mutating func visitRefNull(type: ReferenceType) throws { return try self.visit(.refNull(type: type)) }
    public mutating func visitRefIsNull() throws { return try self.visit(.refIsNull) }
    public mutating func visitRefFunc(functionIndex: UInt32) throws { return try self.visit(.refFunc(functionIndex: functionIndex)) }
    public mutating func visitI32Eqz() throws { return try self.visit(.i32Eqz) }
    public mutating func visitCmp(_ cmp: Instruction.Cmp) throws { return try self.visit(.cmp(cmp)) }
    public mutating func visitI64Eqz() throws { return try self.visit(.i64Eqz) }
    public mutating func visitUnary(_ unary: Instruction.Unary) throws { return try self.visit(.unary(unary)) }
    public mutating func visitBinary(_ binary: Instruction.Binary) throws { return try self.visit(.binary(binary)) }
    public mutating func visitConversion(_ conversion: Instruction.Conversion) throws { return try self.visit(.conversion(conversion)) }
    public mutating func visitMemoryInit(dataIndex: UInt32) throws { return try self.visit(.memoryInit(dataIndex: dataIndex)) }
    public mutating func visitDataDrop(dataIndex: UInt32) throws { return try self.visit(.dataDrop(dataIndex: dataIndex)) }
    public mutating func visitMemoryCopy(dstMem: UInt32, srcMem: UInt32) throws { return try self.visit(.memoryCopy(dstMem: dstMem, srcMem: srcMem)) }
    public mutating func visitMemoryFill(memory: UInt32) throws { return try self.visit(.memoryFill(memory: memory)) }
    public mutating func visitTableInit(elemIndex: UInt32, table: UInt32) throws { return try self.visit(.tableInit(elemIndex: elemIndex, table: table)) }
    public mutating func visitElemDrop(elemIndex: UInt32) throws { return try self.visit(.elemDrop(elemIndex: elemIndex)) }
    public mutating func visitTableCopy(dstTable: UInt32, srcTable: UInt32) throws { return try self.visit(.tableCopy(dstTable: dstTable, srcTable: srcTable)) }
    public mutating func visitTableFill(table: UInt32) throws { return try self.visit(.tableFill(table: table)) }
    public mutating func visitTableGet(table: UInt32) throws { return try self.visit(.tableGet(table: table)) }
    public mutating func visitTableSet(table: UInt32) throws { return try self.visit(.tableSet(table: table)) }
    public mutating func visitTableGrow(table: UInt32) throws { return try self.visit(.tableGrow(table: table)) }
    public mutating func visitTableSize(table: UInt32) throws { return try self.visit(.tableSize(table: table)) }
    public mutating func visitCallRef(functionIndex: UInt32) throws { return try self.visit(.callRef(functionIndex: functionIndex)) }
    public mutating func visitReturnCallRef(functionIndex: UInt32) throws { return try self.visit(.returnCallRef(functionIndex: functionIndex)) }
    public mutating func visitAsNonNull() throws { return try self.visit(.asNonNull) }
    public mutating func visitBrOnNull(functionIndex: UInt32) throws { return try self.visit(.brOnNull(functionIndex: functionIndex)) }
    public mutating func visitBrOnNonNull(functionIndex: UInt32) throws { return try self.visit(.brOnNonNull(functionIndex: functionIndex)) }
}

/// A visitor for WebAssembly instructions.
///
/// The visitor pattern is used while parsing WebAssembly expressions to allow for easy extensibility.
/// See the expression parsing method ``Code/parseExpression(visitor:)``
public protocol InstructionVisitor {
    /// Visiting `unreachable` instruction.
    mutating func visitUnreachable() throws
    /// Visiting `nop` instruction.
    mutating func visitNop() throws
    /// Visiting `block` instruction.
    mutating func visitBlock(blockType: BlockType) throws
    /// Visiting `loop` instruction.
    mutating func visitLoop(blockType: BlockType) throws
    /// Visiting `if` instruction.
    mutating func visitIf(blockType: BlockType) throws
    /// Visiting `else` instruction.
    mutating func visitElse() throws
    /// Visiting `end` instruction.
    mutating func visitEnd() throws
    /// Visiting `br` instruction.
    mutating func visitBr(relativeDepth: UInt32) throws
    /// Visiting `br_if` instruction.
    mutating func visitBrIf(relativeDepth: UInt32) throws
    /// Visiting `br_table` instruction.
    mutating func visitBrTable(targets: BrTable) throws
    /// Visiting `return` instruction.
    mutating func visitReturn() throws
    /// Visiting `call` instruction.
    mutating func visitCall(functionIndex: UInt32) throws
    /// Visiting `call_indirect` instruction.
    mutating func visitCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws
    /// Visiting `return_call` instruction.
    mutating func visitReturnCall(functionIndex: UInt32) throws
    /// Visiting `return_call_indirect` instruction.
    mutating func visitReturnCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws
    /// Visiting `drop` instruction.
    mutating func visitDrop() throws
    /// Visiting `select` instruction.
    mutating func visitSelect() throws
    /// Visiting `typedSelect` instruction.
    mutating func visitTypedSelect(type: ValueType) throws
    /// Visiting `local.get` instruction.
    mutating func visitLocalGet(localIndex: UInt32) throws
    /// Visiting `local.set` instruction.
    mutating func visitLocalSet(localIndex: UInt32) throws
    /// Visiting `local.tee` instruction.
    mutating func visitLocalTee(localIndex: UInt32) throws
    /// Visiting `global.get` instruction.
    mutating func visitGlobalGet(globalIndex: UInt32) throws
    /// Visiting `global.set` instruction.
    mutating func visitGlobalSet(globalIndex: UInt32) throws
    /// Visiting `load` category instruction.
    mutating func visitLoad(_: Instruction.Load, memarg: MemArg) throws
    /// Visiting `store` category instruction.
    mutating func visitStore(_: Instruction.Store, memarg: MemArg) throws
    /// Visiting `memory.size` instruction.
    mutating func visitMemorySize(memory: UInt32) throws
    /// Visiting `memory.grow` instruction.
    mutating func visitMemoryGrow(memory: UInt32) throws
    /// Visiting `i32.const` instruction.
    mutating func visitI32Const(value: Int32) throws
    /// Visiting `i64.const` instruction.
    mutating func visitI64Const(value: Int64) throws
    /// Visiting `f32.const` instruction.
    mutating func visitF32Const(value: IEEE754.Float32) throws
    /// Visiting `f64.const` instruction.
    mutating func visitF64Const(value: IEEE754.Float64) throws
    /// Visiting `ref.null` instruction.
    mutating func visitRefNull(type: ReferenceType) throws
    /// Visiting `ref.is_null` instruction.
    mutating func visitRefIsNull() throws
    /// Visiting `ref.func` instruction.
    mutating func visitRefFunc(functionIndex: UInt32) throws
    /// Visiting `i32.eqz` instruction.
    mutating func visitI32Eqz() throws
    /// Visiting `cmp` category instruction.
    mutating func visitCmp(_: Instruction.Cmp) throws
    /// Visiting `i64.eqz` instruction.
    mutating func visitI64Eqz() throws
    /// Visiting `unary` category instruction.
    mutating func visitUnary(_: Instruction.Unary) throws
    /// Visiting `binary` category instruction.
    mutating func visitBinary(_: Instruction.Binary) throws
    /// Visiting `conversion` category instruction.
    mutating func visitConversion(_: Instruction.Conversion) throws
    /// Visiting `memory.init` instruction.
    mutating func visitMemoryInit(dataIndex: UInt32) throws
    /// Visiting `data.drop` instruction.
    mutating func visitDataDrop(dataIndex: UInt32) throws
    /// Visiting `memory.copy` instruction.
    mutating func visitMemoryCopy(dstMem: UInt32, srcMem: UInt32) throws
    /// Visiting `memory.fill` instruction.
    mutating func visitMemoryFill(memory: UInt32) throws
    /// Visiting `table.init` instruction.
    mutating func visitTableInit(elemIndex: UInt32, table: UInt32) throws
    /// Visiting `elem.drop` instruction.
    mutating func visitElemDrop(elemIndex: UInt32) throws
    /// Visiting `table.copy` instruction.
    mutating func visitTableCopy(dstTable: UInt32, srcTable: UInt32) throws
    /// Visiting `table.fill` instruction.
    mutating func visitTableFill(table: UInt32) throws
    /// Visiting `table.get` instruction.
    mutating func visitTableGet(table: UInt32) throws
    /// Visiting `table.set` instruction.
    mutating func visitTableSet(table: UInt32) throws
    /// Visiting `table.grow` instruction.
    mutating func visitTableGrow(table: UInt32) throws
    /// Visiting `table.size` instruction.
    mutating func visitTableSize(table: UInt32) throws
    /// Visiting `call_ref` instruction.
    mutating func visitCallRef(functionIndex: UInt32) throws
    /// Visiting `return_call_ref` instruction.
    mutating func visitReturnCallRef(functionIndex: UInt32) throws
    /// Visiting `as_non_null` instruction.
    mutating func visitAsNonNull() throws
    /// Visiting `br_on_null` instruction.
    mutating func visitBrOnNull(functionIndex: UInt32) throws
    /// Visiting `br_on_non_null` instruction.
    mutating func visitBrOnNonNull(functionIndex: UInt32) throws
}

extension InstructionVisitor {
    /// Visits an instruction.
    public mutating func visit(_ instruction: Instruction) throws {
        switch instruction {
        case .unreachable: return try visitUnreachable()
        case .nop: return try visitNop()
        case let .block(blockType): return try visitBlock(blockType: blockType)
        case let .loop(blockType): return try visitLoop(blockType: blockType)
        case let .if(blockType): return try visitIf(blockType: blockType)
        case .else: return try visitElse()
        case .end: return try visitEnd()
        case let .br(relativeDepth): return try visitBr(relativeDepth: relativeDepth)
        case let .brIf(relativeDepth): return try visitBrIf(relativeDepth: relativeDepth)
        case let .brTable(targets): return try visitBrTable(targets: targets)
        case .return: return try visitReturn()
        case let .call(functionIndex): return try visitCall(functionIndex: functionIndex)
        case let .callIndirect(typeIndex, tableIndex): return try visitCallIndirect(typeIndex: typeIndex, tableIndex: tableIndex)
        case let .returnCall(functionIndex): return try visitReturnCall(functionIndex: functionIndex)
        case let .returnCallIndirect(typeIndex, tableIndex): return try visitReturnCallIndirect(typeIndex: typeIndex, tableIndex: tableIndex)
        case .drop: return try visitDrop()
        case .select: return try visitSelect()
        case let .typedSelect(type): return try visitTypedSelect(type: type)
        case let .localGet(localIndex): return try visitLocalGet(localIndex: localIndex)
        case let .localSet(localIndex): return try visitLocalSet(localIndex: localIndex)
        case let .localTee(localIndex): return try visitLocalTee(localIndex: localIndex)
        case let .globalGet(globalIndex): return try visitGlobalGet(globalIndex: globalIndex)
        case let .globalSet(globalIndex): return try visitGlobalSet(globalIndex: globalIndex)
        case let .load(load, memarg): return try visitLoad(load, memarg: memarg)
        case let .store(store, memarg): return try visitStore(store, memarg: memarg)
        case let .memorySize(memory): return try visitMemorySize(memory: memory)
        case let .memoryGrow(memory): return try visitMemoryGrow(memory: memory)
        case let .i32Const(value): return try visitI32Const(value: value)
        case let .i64Const(value): return try visitI64Const(value: value)
        case let .f32Const(value): return try visitF32Const(value: value)
        case let .f64Const(value): return try visitF64Const(value: value)
        case let .refNull(type): return try visitRefNull(type: type)
        case .refIsNull: return try visitRefIsNull()
        case let .refFunc(functionIndex): return try visitRefFunc(functionIndex: functionIndex)
        case .i32Eqz: return try visitI32Eqz()
        case let .cmp(cmp): return try visitCmp(cmp)
        case .i64Eqz: return try visitI64Eqz()
        case let .unary(unary): return try visitUnary(unary)
        case let .binary(binary): return try visitBinary(binary)
        case let .conversion(conversion): return try visitConversion(conversion)
        case let .memoryInit(dataIndex): return try visitMemoryInit(dataIndex: dataIndex)
        case let .dataDrop(dataIndex): return try visitDataDrop(dataIndex: dataIndex)
        case let .memoryCopy(dstMem, srcMem): return try visitMemoryCopy(dstMem: dstMem, srcMem: srcMem)
        case let .memoryFill(memory): return try visitMemoryFill(memory: memory)
        case let .tableInit(elemIndex, table): return try visitTableInit(elemIndex: elemIndex, table: table)
        case let .elemDrop(elemIndex): return try visitElemDrop(elemIndex: elemIndex)
        case let .tableCopy(dstTable, srcTable): return try visitTableCopy(dstTable: dstTable, srcTable: srcTable)
        case let .tableFill(table): return try visitTableFill(table: table)
        case let .tableGet(table): return try visitTableGet(table: table)
        case let .tableSet(table): return try visitTableSet(table: table)
        case let .tableGrow(table): return try visitTableGrow(table: table)
        case let .tableSize(table): return try visitTableSize(table: table)
        case let .callRef(functionIndex): return try visitCallRef(functionIndex: functionIndex)
        case let .returnCallRef(functionIndex): return try visitReturnCallRef(functionIndex: functionIndex)
        case .asNonNull: return try visitAsNonNull()
        case let .brOnNull(functionIndex): return try visitBrOnNull(functionIndex: functionIndex)
        case let .brOnNonNull(functionIndex): return try visitBrOnNonNull(functionIndex: functionIndex)
        }
    }
}

// MARK: - Placeholder implementations
extension InstructionVisitor {
    public mutating func visitUnreachable() throws {}
    public mutating func visitNop() throws {}
    public mutating func visitBlock(blockType: BlockType) throws {}
    public mutating func visitLoop(blockType: BlockType) throws {}
    public mutating func visitIf(blockType: BlockType) throws {}
    public mutating func visitElse() throws {}
    public mutating func visitEnd() throws {}
    public mutating func visitBr(relativeDepth: UInt32) throws {}
    public mutating func visitBrIf(relativeDepth: UInt32) throws {}
    public mutating func visitBrTable(targets: BrTable) throws {}
    public mutating func visitReturn() throws {}
    public mutating func visitCall(functionIndex: UInt32) throws {}
    public mutating func visitCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws {}
    public mutating func visitReturnCall(functionIndex: UInt32) throws {}
    public mutating func visitReturnCallIndirect(typeIndex: UInt32, tableIndex: UInt32) throws {}
    public mutating func visitDrop() throws {}
    public mutating func visitSelect() throws {}
    public mutating func visitTypedSelect(type: ValueType) throws {}
    public mutating func visitLocalGet(localIndex: UInt32) throws {}
    public mutating func visitLocalSet(localIndex: UInt32) throws {}
    public mutating func visitLocalTee(localIndex: UInt32) throws {}
    public mutating func visitGlobalGet(globalIndex: UInt32) throws {}
    public mutating func visitGlobalSet(globalIndex: UInt32) throws {}
    public mutating func visitLoad(_ load: Instruction.Load, memarg: MemArg) throws {}
    public mutating func visitStore(_ store: Instruction.Store, memarg: MemArg) throws {}
    public mutating func visitMemorySize(memory: UInt32) throws {}
    public mutating func visitMemoryGrow(memory: UInt32) throws {}
    public mutating func visitI32Const(value: Int32) throws {}
    public mutating func visitI64Const(value: Int64) throws {}
    public mutating func visitF32Const(value: IEEE754.Float32) throws {}
    public mutating func visitF64Const(value: IEEE754.Float64) throws {}
    public mutating func visitRefNull(type: ReferenceType) throws {}
    public mutating func visitRefIsNull() throws {}
    public mutating func visitRefFunc(functionIndex: UInt32) throws {}
    public mutating func visitI32Eqz() throws {}
    public mutating func visitCmp(_ cmp: Instruction.Cmp) throws {}
    public mutating func visitI64Eqz() throws {}
    public mutating func visitUnary(_ unary: Instruction.Unary) throws {}
    public mutating func visitBinary(_ binary: Instruction.Binary) throws {}
    public mutating func visitConversion(_ conversion: Instruction.Conversion) throws {}
    public mutating func visitMemoryInit(dataIndex: UInt32) throws {}
    public mutating func visitDataDrop(dataIndex: UInt32) throws {}
    public mutating func visitMemoryCopy(dstMem: UInt32, srcMem: UInt32) throws {}
    public mutating func visitMemoryFill(memory: UInt32) throws {}
    public mutating func visitTableInit(elemIndex: UInt32, table: UInt32) throws {}
    public mutating func visitElemDrop(elemIndex: UInt32) throws {}
    public mutating func visitTableCopy(dstTable: UInt32, srcTable: UInt32) throws {}
    public mutating func visitTableFill(table: UInt32) throws {}
    public mutating func visitTableGet(table: UInt32) throws {}
    public mutating func visitTableSet(table: UInt32) throws {}
    public mutating func visitTableGrow(table: UInt32) throws {}
    public mutating func visitTableSize(table: UInt32) throws {}
    public mutating func visitCallRef(functionIndex: UInt32) throws {}
    public mutating func visitReturnCallRef(functionIndex: UInt32) throws {}
    public mutating func visitAsNonNull() throws {}
    public mutating func visitBrOnNull(functionIndex: UInt32) throws {}
    public mutating func visitBrOnNonNull(functionIndex: UInt32) throws {}
}

