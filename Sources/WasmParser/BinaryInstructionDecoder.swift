// swift-format-ignore-file
//// Automatically generated by Utilities/Sources/WasmGen.swift
//// DO NOT EDIT DIRECTLY

import WasmTypes

protocol BinaryInstructionDecoder {
    /// Claim the next byte to be decoded
    func claimNextByte() throws -> UInt8
    /// Visit unknown instruction
    func visitUnknown(_ opcode: [UInt8]) throws
    /// Decode `block` immediates
    mutating func visitBlock() throws -> BlockType
    /// Decode `loop` immediates
    mutating func visitLoop() throws -> BlockType
    /// Decode `if` immediates
    mutating func visitIf() throws -> BlockType
    /// Decode `br` immediates
    mutating func visitBr() throws -> UInt32
    /// Decode `br_if` immediates
    mutating func visitBrIf() throws -> UInt32
    /// Decode `br_table` immediates
    mutating func visitBrTable() throws -> BrTable
    /// Decode `call` immediates
    mutating func visitCall() throws -> UInt32
    /// Decode `call_indirect` immediates
    mutating func visitCallIndirect() throws -> (typeIndex: UInt32, tableIndex: UInt32)
    /// Decode `typedSelect` immediates
    mutating func visitTypedSelect() throws -> ValueType
    /// Decode `local.get` immediates
    mutating func visitLocalGet() throws -> UInt32
    /// Decode `local.set` immediates
    mutating func visitLocalSet() throws -> UInt32
    /// Decode `local.tee` immediates
    mutating func visitLocalTee() throws -> UInt32
    /// Decode `global.get` immediates
    mutating func visitGlobalGet() throws -> UInt32
    /// Decode `global.set` immediates
    mutating func visitGlobalSet() throws -> UInt32
    /// Decode `load` category immediates
    mutating func visitLoad(_: Instruction.Load) throws -> MemArg
    /// Decode `store` category immediates
    mutating func visitStore(_: Instruction.Store) throws -> MemArg
    /// Decode `memory.size` immediates
    mutating func visitMemorySize() throws -> UInt32
    /// Decode `memory.grow` immediates
    mutating func visitMemoryGrow() throws -> UInt32
    /// Decode `i32.const` immediates
    mutating func visitI32Const() throws -> Int32
    /// Decode `i64.const` immediates
    mutating func visitI64Const() throws -> Int64
    /// Decode `f32.const` immediates
    mutating func visitF32Const() throws -> IEEE754.Float32
    /// Decode `f64.const` immediates
    mutating func visitF64Const() throws -> IEEE754.Float64
    /// Decode `ref.null` immediates
    mutating func visitRefNull() throws -> ReferenceType
    /// Decode `ref.func` immediates
    mutating func visitRefFunc() throws -> UInt32
    /// Decode `memory.init` immediates
    mutating func visitMemoryInit() throws -> UInt32
    /// Decode `data.drop` immediates
    mutating func visitDataDrop() throws -> UInt32
    /// Decode `memory.copy` immediates
    mutating func visitMemoryCopy() throws -> (dstMem: UInt32, srcMem: UInt32)
    /// Decode `memory.fill` immediates
    mutating func visitMemoryFill() throws -> UInt32
    /// Decode `table.init` immediates
    mutating func visitTableInit() throws -> (elemIndex: UInt32, table: UInt32)
    /// Decode `elem.drop` immediates
    mutating func visitElemDrop() throws -> UInt32
    /// Decode `table.copy` immediates
    mutating func visitTableCopy() throws -> (dstTable: UInt32, srcTable: UInt32)
    /// Decode `table.fill` immediates
    mutating func visitTableFill() throws -> UInt32
    /// Decode `table.get` immediates
    mutating func visitTableGet() throws -> UInt32
    /// Decode `table.set` immediates
    mutating func visitTableSet() throws -> UInt32
    /// Decode `table.grow` immediates
    mutating func visitTableGrow() throws -> UInt32
    /// Decode `table.size` immediates
    mutating func visitTableSize() throws -> UInt32
}
extension BinaryInstructionDecoder {
    @usableFromInline
    mutating func parseBinaryInstruction<V: InstructionVisitor>(visitor: inout V) throws -> Bool {
        let opcode0 = try claimNextByte()
        switch opcode0 {
        case 0x00:
            try visitor.visitUnreachable()
        case 0x01:
            try visitor.visitNop()
        case 0x02:
            let (blockType) = try visitBlock()
            try visitor.visitBlock(blockType: blockType)
        case 0x03:
            let (blockType) = try visitLoop()
            try visitor.visitLoop(blockType: blockType)
        case 0x04:
            let (blockType) = try visitIf()
            try visitor.visitIf(blockType: blockType)
        case 0x05:
            try visitor.visitElse()
        case 0x0B:
            try visitor.visitEnd()
            return true
        case 0x0C:
            let (relativeDepth) = try visitBr()
            try visitor.visitBr(relativeDepth: relativeDepth)
        case 0x0D:
            let (relativeDepth) = try visitBrIf()
            try visitor.visitBrIf(relativeDepth: relativeDepth)
        case 0x0E:
            let (targets) = try visitBrTable()
            try visitor.visitBrTable(targets: targets)
        case 0x0F:
            try visitor.visitReturn()
        case 0x10:
            let (functionIndex) = try visitCall()
            try visitor.visitCall(functionIndex: functionIndex)
        case 0x11:
            let (typeIndex, tableIndex) = try visitCallIndirect()
            try visitor.visitCallIndirect(typeIndex: typeIndex, tableIndex: tableIndex)
        case 0x1A:
            try visitor.visitDrop()
        case 0x1B:
            try visitor.visitSelect()
        case 0x1C:
            let (type) = try visitTypedSelect()
            try visitor.visitTypedSelect(type: type)
        case 0x20:
            let (localIndex) = try visitLocalGet()
            try visitor.visitLocalGet(localIndex: localIndex)
        case 0x21:
            let (localIndex) = try visitLocalSet()
            try visitor.visitLocalSet(localIndex: localIndex)
        case 0x22:
            let (localIndex) = try visitLocalTee()
            try visitor.visitLocalTee(localIndex: localIndex)
        case 0x23:
            let (globalIndex) = try visitGlobalGet()
            try visitor.visitGlobalGet(globalIndex: globalIndex)
        case 0x24:
            let (globalIndex) = try visitGlobalSet()
            try visitor.visitGlobalSet(globalIndex: globalIndex)
        case 0x25:
            let (table) = try visitTableGet()
            try visitor.visitTableGet(table: table)
        case 0x26:
            let (table) = try visitTableSet()
            try visitor.visitTableSet(table: table)
        case 0x28:
            let (memarg) = try visitLoad(.i32Load)
            try visitor.visitLoad(.i32Load, memarg: memarg)
        case 0x29:
            let (memarg) = try visitLoad(.i64Load)
            try visitor.visitLoad(.i64Load, memarg: memarg)
        case 0x2A:
            let (memarg) = try visitLoad(.f32Load)
            try visitor.visitLoad(.f32Load, memarg: memarg)
        case 0x2B:
            let (memarg) = try visitLoad(.f64Load)
            try visitor.visitLoad(.f64Load, memarg: memarg)
        case 0x2C:
            let (memarg) = try visitLoad(.i32Load8S)
            try visitor.visitLoad(.i32Load8S, memarg: memarg)
        case 0x2D:
            let (memarg) = try visitLoad(.i32Load8U)
            try visitor.visitLoad(.i32Load8U, memarg: memarg)
        case 0x2E:
            let (memarg) = try visitLoad(.i32Load16S)
            try visitor.visitLoad(.i32Load16S, memarg: memarg)
        case 0x2F:
            let (memarg) = try visitLoad(.i32Load16U)
            try visitor.visitLoad(.i32Load16U, memarg: memarg)
        case 0x30:
            let (memarg) = try visitLoad(.i64Load8S)
            try visitor.visitLoad(.i64Load8S, memarg: memarg)
        case 0x31:
            let (memarg) = try visitLoad(.i64Load8U)
            try visitor.visitLoad(.i64Load8U, memarg: memarg)
        case 0x32:
            let (memarg) = try visitLoad(.i64Load16S)
            try visitor.visitLoad(.i64Load16S, memarg: memarg)
        case 0x33:
            let (memarg) = try visitLoad(.i64Load16U)
            try visitor.visitLoad(.i64Load16U, memarg: memarg)
        case 0x34:
            let (memarg) = try visitLoad(.i64Load32S)
            try visitor.visitLoad(.i64Load32S, memarg: memarg)
        case 0x35:
            let (memarg) = try visitLoad(.i64Load32U)
            try visitor.visitLoad(.i64Load32U, memarg: memarg)
        case 0x36:
            let (memarg) = try visitStore(.i32Store)
            try visitor.visitStore(.i32Store, memarg: memarg)
        case 0x37:
            let (memarg) = try visitStore(.i64Store)
            try visitor.visitStore(.i64Store, memarg: memarg)
        case 0x38:
            let (memarg) = try visitStore(.f32Store)
            try visitor.visitStore(.f32Store, memarg: memarg)
        case 0x39:
            let (memarg) = try visitStore(.f64Store)
            try visitor.visitStore(.f64Store, memarg: memarg)
        case 0x3A:
            let (memarg) = try visitStore(.i32Store8)
            try visitor.visitStore(.i32Store8, memarg: memarg)
        case 0x3B:
            let (memarg) = try visitStore(.i32Store16)
            try visitor.visitStore(.i32Store16, memarg: memarg)
        case 0x3C:
            let (memarg) = try visitStore(.i64Store8)
            try visitor.visitStore(.i64Store8, memarg: memarg)
        case 0x3D:
            let (memarg) = try visitStore(.i64Store16)
            try visitor.visitStore(.i64Store16, memarg: memarg)
        case 0x3E:
            let (memarg) = try visitStore(.i64Store32)
            try visitor.visitStore(.i64Store32, memarg: memarg)
        case 0x3F:
            let (memory) = try visitMemorySize()
            try visitor.visitMemorySize(memory: memory)
        case 0x40:
            let (memory) = try visitMemoryGrow()
            try visitor.visitMemoryGrow(memory: memory)
        case 0x41:
            let (value) = try visitI32Const()
            try visitor.visitI32Const(value: value)
        case 0x42:
            let (value) = try visitI64Const()
            try visitor.visitI64Const(value: value)
        case 0x43:
            let (value) = try visitF32Const()
            try visitor.visitF32Const(value: value)
        case 0x44:
            let (value) = try visitF64Const()
            try visitor.visitF64Const(value: value)
        case 0x45:
            try visitor.visitI32Eqz()
        case 0x46:
            try visitor.visitCmp(.i32Eq)
        case 0x47:
            try visitor.visitCmp(.i32Ne)
        case 0x48:
            try visitor.visitCmp(.i32LtS)
        case 0x49:
            try visitor.visitCmp(.i32LtU)
        case 0x4A:
            try visitor.visitCmp(.i32GtS)
        case 0x4B:
            try visitor.visitCmp(.i32GtU)
        case 0x4C:
            try visitor.visitCmp(.i32LeS)
        case 0x4D:
            try visitor.visitCmp(.i32LeU)
        case 0x4E:
            try visitor.visitCmp(.i32GeS)
        case 0x4F:
            try visitor.visitCmp(.i32GeU)
        case 0x50:
            try visitor.visitI64Eqz()
        case 0x51:
            try visitor.visitCmp(.i64Eq)
        case 0x52:
            try visitor.visitCmp(.i64Ne)
        case 0x53:
            try visitor.visitCmp(.i64LtS)
        case 0x54:
            try visitor.visitCmp(.i64LtU)
        case 0x55:
            try visitor.visitCmp(.i64GtS)
        case 0x56:
            try visitor.visitCmp(.i64GtU)
        case 0x57:
            try visitor.visitCmp(.i64LeS)
        case 0x58:
            try visitor.visitCmp(.i64LeU)
        case 0x59:
            try visitor.visitCmp(.i64GeS)
        case 0x5A:
            try visitor.visitCmp(.i64GeU)
        case 0x5B:
            try visitor.visitCmp(.f32Eq)
        case 0x5C:
            try visitor.visitCmp(.f32Ne)
        case 0x5D:
            try visitor.visitCmp(.f32Lt)
        case 0x5E:
            try visitor.visitCmp(.f32Gt)
        case 0x5F:
            try visitor.visitCmp(.f32Le)
        case 0x60:
            try visitor.visitCmp(.f32Ge)
        case 0x61:
            try visitor.visitCmp(.f64Eq)
        case 0x62:
            try visitor.visitCmp(.f64Ne)
        case 0x63:
            try visitor.visitCmp(.f64Lt)
        case 0x64:
            try visitor.visitCmp(.f64Gt)
        case 0x65:
            try visitor.visitCmp(.f64Le)
        case 0x66:
            try visitor.visitCmp(.f64Ge)
        case 0x67:
            try visitor.visitUnary(.i32Clz)
        case 0x68:
            try visitor.visitUnary(.i32Ctz)
        case 0x69:
            try visitor.visitUnary(.i32Popcnt)
        case 0x6A:
            try visitor.visitBinary(.i32Add)
        case 0x6B:
            try visitor.visitBinary(.i32Sub)
        case 0x6C:
            try visitor.visitBinary(.i32Mul)
        case 0x6D:
            try visitor.visitBinary(.i32DivS)
        case 0x6E:
            try visitor.visitBinary(.i32DivU)
        case 0x6F:
            try visitor.visitBinary(.i32RemS)
        case 0x70:
            try visitor.visitBinary(.i32RemU)
        case 0x71:
            try visitor.visitBinary(.i32And)
        case 0x72:
            try visitor.visitBinary(.i32Or)
        case 0x73:
            try visitor.visitBinary(.i32Xor)
        case 0x74:
            try visitor.visitBinary(.i32Shl)
        case 0x75:
            try visitor.visitBinary(.i32ShrS)
        case 0x76:
            try visitor.visitBinary(.i32ShrU)
        case 0x77:
            try visitor.visitBinary(.i32Rotl)
        case 0x78:
            try visitor.visitBinary(.i32Rotr)
        case 0x79:
            try visitor.visitUnary(.i64Clz)
        case 0x7A:
            try visitor.visitUnary(.i64Ctz)
        case 0x7B:
            try visitor.visitUnary(.i64Popcnt)
        case 0x7C:
            try visitor.visitBinary(.i64Add)
        case 0x7D:
            try visitor.visitBinary(.i64Sub)
        case 0x7E:
            try visitor.visitBinary(.i64Mul)
        case 0x7F:
            try visitor.visitBinary(.i64DivS)
        case 0x80:
            try visitor.visitBinary(.i64DivU)
        case 0x81:
            try visitor.visitBinary(.i64RemS)
        case 0x82:
            try visitor.visitBinary(.i64RemU)
        case 0x83:
            try visitor.visitBinary(.i64And)
        case 0x84:
            try visitor.visitBinary(.i64Or)
        case 0x85:
            try visitor.visitBinary(.i64Xor)
        case 0x86:
            try visitor.visitBinary(.i64Shl)
        case 0x87:
            try visitor.visitBinary(.i64ShrS)
        case 0x88:
            try visitor.visitBinary(.i64ShrU)
        case 0x89:
            try visitor.visitBinary(.i64Rotl)
        case 0x8A:
            try visitor.visitBinary(.i64Rotr)
        case 0x8B:
            try visitor.visitUnary(.f32Abs)
        case 0x8C:
            try visitor.visitUnary(.f32Neg)
        case 0x8D:
            try visitor.visitUnary(.f32Ceil)
        case 0x8E:
            try visitor.visitUnary(.f32Floor)
        case 0x8F:
            try visitor.visitUnary(.f32Trunc)
        case 0x90:
            try visitor.visitUnary(.f32Nearest)
        case 0x91:
            try visitor.visitUnary(.f32Sqrt)
        case 0x92:
            try visitor.visitBinary(.f32Add)
        case 0x93:
            try visitor.visitBinary(.f32Sub)
        case 0x94:
            try visitor.visitBinary(.f32Mul)
        case 0x95:
            try visitor.visitBinary(.f32Div)
        case 0x96:
            try visitor.visitBinary(.f32Min)
        case 0x97:
            try visitor.visitBinary(.f32Max)
        case 0x98:
            try visitor.visitBinary(.f32Copysign)
        case 0x99:
            try visitor.visitUnary(.f64Abs)
        case 0x9A:
            try visitor.visitUnary(.f64Neg)
        case 0x9B:
            try visitor.visitUnary(.f64Ceil)
        case 0x9C:
            try visitor.visitUnary(.f64Floor)
        case 0x9D:
            try visitor.visitUnary(.f64Trunc)
        case 0x9E:
            try visitor.visitUnary(.f64Nearest)
        case 0x9F:
            try visitor.visitUnary(.f64Sqrt)
        case 0xA0:
            try visitor.visitBinary(.f64Add)
        case 0xA1:
            try visitor.visitBinary(.f64Sub)
        case 0xA2:
            try visitor.visitBinary(.f64Mul)
        case 0xA3:
            try visitor.visitBinary(.f64Div)
        case 0xA4:
            try visitor.visitBinary(.f64Min)
        case 0xA5:
            try visitor.visitBinary(.f64Max)
        case 0xA6:
            try visitor.visitBinary(.f64Copysign)
        case 0xA7:
            try visitor.visitConversion(.i32WrapI64)
        case 0xA8:
            try visitor.visitConversion(.i32TruncF32S)
        case 0xA9:
            try visitor.visitConversion(.i32TruncF32U)
        case 0xAA:
            try visitor.visitConversion(.i32TruncF64S)
        case 0xAB:
            try visitor.visitConversion(.i32TruncF64U)
        case 0xAC:
            try visitor.visitConversion(.i64ExtendI32S)
        case 0xAD:
            try visitor.visitConversion(.i64ExtendI32U)
        case 0xAE:
            try visitor.visitConversion(.i64TruncF32S)
        case 0xAF:
            try visitor.visitConversion(.i64TruncF32U)
        case 0xB0:
            try visitor.visitConversion(.i64TruncF64S)
        case 0xB1:
            try visitor.visitConversion(.i64TruncF64U)
        case 0xB2:
            try visitor.visitConversion(.f32ConvertI32S)
        case 0xB3:
            try visitor.visitConversion(.f32ConvertI32U)
        case 0xB4:
            try visitor.visitConversion(.f32ConvertI64S)
        case 0xB5:
            try visitor.visitConversion(.f32ConvertI64U)
        case 0xB6:
            try visitor.visitConversion(.f32DemoteF64)
        case 0xB7:
            try visitor.visitConversion(.f64ConvertI32S)
        case 0xB8:
            try visitor.visitConversion(.f64ConvertI32U)
        case 0xB9:
            try visitor.visitConversion(.f64ConvertI64S)
        case 0xBA:
            try visitor.visitConversion(.f64ConvertI64U)
        case 0xBB:
            try visitor.visitConversion(.f64PromoteF32)
        case 0xBC:
            try visitor.visitConversion(.i32ReinterpretF32)
        case 0xBD:
            try visitor.visitConversion(.i64ReinterpretF64)
        case 0xBE:
            try visitor.visitConversion(.f32ReinterpretI32)
        case 0xBF:
            try visitor.visitConversion(.f64ReinterpretI64)
        case 0xC0:
            try visitor.visitUnary(.i32Extend8S)
        case 0xC1:
            try visitor.visitUnary(.i32Extend16S)
        case 0xC2:
            try visitor.visitUnary(.i64Extend8S)
        case 0xC3:
            try visitor.visitUnary(.i64Extend16S)
        case 0xC4:
            try visitor.visitUnary(.i64Extend32S)
        case 0xD0:
            let (type) = try visitRefNull()
            try visitor.visitRefNull(type: type)
        case 0xD1:
            try visitor.visitRefIsNull()
        case 0xD2:
            let (functionIndex) = try visitRefFunc()
            try visitor.visitRefFunc(functionIndex: functionIndex)
        case 0xFC:

            let opcode1 = try claimNextByte()
            switch opcode1 {
            case 0x00:
                try visitor.visitConversion(.i32TruncSatF32S)
            case 0x01:
                try visitor.visitConversion(.i32TruncSatF32U)
            case 0x02:
                try visitor.visitConversion(.i32TruncSatF64S)
            case 0x03:
                try visitor.visitConversion(.i32TruncSatF64U)
            case 0x04:
                try visitor.visitConversion(.i64TruncSatF32S)
            case 0x05:
                try visitor.visitConversion(.i64TruncSatF32U)
            case 0x06:
                try visitor.visitConversion(.i64TruncSatF64S)
            case 0x07:
                try visitor.visitConversion(.i64TruncSatF64U)
            case 0x08:
                let (dataIndex) = try visitMemoryInit()
                try visitor.visitMemoryInit(dataIndex: dataIndex)
            case 0x09:
                let (dataIndex) = try visitDataDrop()
                try visitor.visitDataDrop(dataIndex: dataIndex)
            case 0x0A:
                let (dstMem, srcMem) = try visitMemoryCopy()
                try visitor.visitMemoryCopy(dstMem: dstMem, srcMem: srcMem)
            case 0x0B:
                let (memory) = try visitMemoryFill()
                try visitor.visitMemoryFill(memory: memory)
            case 0x0C:
                let (elemIndex, table) = try visitTableInit()
                try visitor.visitTableInit(elemIndex: elemIndex, table: table)
            case 0x0D:
                let (elemIndex) = try visitElemDrop()
                try visitor.visitElemDrop(elemIndex: elemIndex)
            case 0x0E:
                let (dstTable, srcTable) = try visitTableCopy()
                try visitor.visitTableCopy(dstTable: dstTable, srcTable: srcTable)
            case 0x0F:
                let (table) = try visitTableGrow()
                try visitor.visitTableGrow(table: table)
            case 0x10:
                let (table) = try visitTableSize()
                try visitor.visitTableSize(table: table)
            case 0x11:
                let (table) = try visitTableFill()
                try visitor.visitTableFill(table: table)
            default:
                try visitUnknown([opcode0, opcode1])
            }
        default:
            try visitUnknown([opcode0])
        }
        return false
    }
}
