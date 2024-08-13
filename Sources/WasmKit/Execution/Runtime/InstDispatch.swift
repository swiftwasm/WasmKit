// This file is generated by Utilities/generate_inst_dispatch.swift
extension ExecutionState {
    @inline(__always)
    mutating func doExecute(_ instruction: Instruction, md: inout Md, ms: inout Ms, context: inout StackContext, stack: FrameBase) throws -> Bool {
        switch instruction {
        case .copyStack(let copyStackOperand):
            self.copyStack(context: &context, stack: stack, copyStackOperand: copyStackOperand)
        case .globalGet(let globalGetOperand):
            try self.globalGet(context: &context, stack: stack, globalGetOperand: globalGetOperand)
        case .globalSet(let globalSetOperand):
            try self.globalSet(context: &context, stack: stack, globalSetOperand: globalSetOperand)
        case .call(let callOperand):
            try self.call(context: &context, stack: stack, md: &md, ms: &ms, callOperand: callOperand)
            return false
        case .compilingCall(let compilingCallOperand):
            try self.compilingCall(context: &context, stack: stack, compilingCallOperand: compilingCallOperand)
            return false
        case .internalCall(let internalCallOperand):
            try self.internalCall(context: &context, stack: stack, internalCallOperand: internalCallOperand)
            return false
        case .callIndirect(let callIndirectOperand):
            try self.callIndirect(context: &context, stack: stack, md: &md, ms: &ms, callIndirectOperand: callIndirectOperand)
            return false
        case .unreachable:
            try self.unreachable(context: &context, stack: stack)
            return true
        case .nop:
            try self.nop(context: &context, stack: stack)
            return true
        case .ifThen(let ifOperand):
            self.ifThen(context: &context, stack: stack, ifOperand: ifOperand)
            return true
        case .br(let offset):
            try self.br(context: &context, stack: stack, offset: offset)
            return false
        case .brIf(let brIfOperand):
            try self.brIf(context: &context, stack: stack, brIfOperand: brIfOperand)
            return false
        case .brIfNot(let brIfOperand):
            try self.brIfNot(context: &context, stack: stack, brIfOperand: brIfOperand)
            return false
        case .brTable(let brTableOperand):
            try self.brTable(context: &context, stack: stack, brTableOperand: brTableOperand)
            return false
        case .`return`(let returnOperand):
            try self.`return`(context: &context, stack: stack, md: &md, ms: &ms, returnOperand: returnOperand)
            return false
        case .endOfFunction(let returnOperand):
            try self.endOfFunction(context: &context, stack: stack, md: &md, ms: &ms, returnOperand: returnOperand)
            return false
        case .endOfExecution:
            try self.endOfExecution(context: &context, stack: stack)
            return false
        case .i32Load(let loadOperand):
            try self.i32Load(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load(let loadOperand):
            try self.i64Load(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .f32Load(let loadOperand):
            try self.f32Load(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .f64Load(let loadOperand):
            try self.f64Load(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i32Load8S(let loadOperand):
            try self.i32Load8S(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i32Load8U(let loadOperand):
            try self.i32Load8U(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i32Load16S(let loadOperand):
            try self.i32Load16S(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i32Load16U(let loadOperand):
            try self.i32Load16U(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load8S(let loadOperand):
            try self.i64Load8S(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load8U(let loadOperand):
            try self.i64Load8U(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load16S(let loadOperand):
            try self.i64Load16S(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load16U(let loadOperand):
            try self.i64Load16U(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load32S(let loadOperand):
            try self.i64Load32S(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i64Load32U(let loadOperand):
            try self.i64Load32U(context: &context, stack: stack, md: md, ms: ms, loadOperand: loadOperand)
        case .i32Store(let storeOperand):
            try self.i32Store(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .i64Store(let storeOperand):
            try self.i64Store(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .f32Store(let storeOperand):
            try self.f32Store(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .f64Store(let storeOperand):
            try self.f64Store(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .i32Store8(let storeOperand):
            try self.i32Store8(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .i32Store16(let storeOperand):
            try self.i32Store16(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .i64Store8(let storeOperand):
            try self.i64Store8(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .i64Store16(let storeOperand):
            try self.i64Store16(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .i64Store32(let storeOperand):
            try self.i64Store32(context: &context, stack: stack, md: md, ms: ms, storeOperand: storeOperand)
        case .memorySize(let memorySizeOperand):
            self.memorySize(context: &context, stack: stack, memorySizeOperand: memorySizeOperand)
        case .memoryGrow(let memoryGrowOperand):
            try self.memoryGrow(context: &context, stack: stack, md: &md, ms: &ms, memoryGrowOperand: memoryGrowOperand)
        case .memoryInit(let memoryInitOperand):
            try self.memoryInit(context: &context, stack: stack, memoryInitOperand: memoryInitOperand)
        case .memoryDataDrop(let dataIndex):
            self.memoryDataDrop(context: &context, stack: stack, dataIndex: dataIndex)
        case .memoryCopy(let memoryCopyOperand):
            try self.memoryCopy(context: &context, stack: stack, memoryCopyOperand: memoryCopyOperand)
        case .memoryFill(let memoryFillOperand):
            try self.memoryFill(context: &context, stack: stack, memoryFillOperand: memoryFillOperand)
        case .numericConst(let constOperand):
            self.numericConst(context: &context, stack: stack, constOperand: constOperand)
        case .numericFloatUnary(let floatUnary, let unaryOperand):
            self.numericFloatUnary(context: &context, stack: stack, floatUnary: floatUnary, unaryOperand: unaryOperand)
        case .numericIntBinary(let intBinary, let binaryOperand):
            try self.numericIntBinary(context: &context, stack: stack, intBinary: intBinary, binaryOperand: binaryOperand)
        case .numericFloatBinary(let floatBinary, let binaryOperand):
            self.numericFloatBinary(context: &context, stack: stack, floatBinary: floatBinary, binaryOperand: binaryOperand)
        case .numericConversion(let conversion, let unaryOperand):
            try self.numericConversion(context: &context, stack: stack, conversion: conversion, unaryOperand: unaryOperand)
        case .i32Add(let binaryOperand):
            self.i32Add(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Add(let binaryOperand):
            self.i64Add(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f32Add(let binaryOperand):
            self.f32Add(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f64Add(let binaryOperand):
            self.f64Add(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Sub(let binaryOperand):
            self.i32Sub(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Sub(let binaryOperand):
            self.i64Sub(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f32Sub(let binaryOperand):
            self.f32Sub(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f64Sub(let binaryOperand):
            self.f64Sub(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Mul(let binaryOperand):
            self.i32Mul(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Mul(let binaryOperand):
            self.i64Mul(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f32Mul(let binaryOperand):
            self.f32Mul(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f64Mul(let binaryOperand):
            self.f64Mul(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Eq(let binaryOperand):
            self.i32Eq(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Eq(let binaryOperand):
            self.i64Eq(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f32Eq(let binaryOperand):
            self.f32Eq(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f64Eq(let binaryOperand):
            self.f64Eq(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Ne(let binaryOperand):
            self.i32Ne(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Ne(let binaryOperand):
            self.i64Ne(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f32Ne(let binaryOperand):
            self.f32Ne(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .f64Ne(let binaryOperand):
            self.f64Ne(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32LtS(let binaryOperand):
            self.i32LtS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64LtS(let binaryOperand):
            self.i64LtS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32LtU(let binaryOperand):
            self.i32LtU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64LtU(let binaryOperand):
            self.i64LtU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32GtS(let binaryOperand):
            self.i32GtS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64GtS(let binaryOperand):
            self.i64GtS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32GtU(let binaryOperand):
            self.i32GtU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64GtU(let binaryOperand):
            self.i64GtU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32LeS(let binaryOperand):
            self.i32LeS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64LeS(let binaryOperand):
            self.i64LeS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32LeU(let binaryOperand):
            self.i32LeU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64LeU(let binaryOperand):
            self.i64LeU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32GeS(let binaryOperand):
            self.i32GeS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64GeS(let binaryOperand):
            self.i64GeS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32GeU(let binaryOperand):
            self.i32GeU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64GeU(let binaryOperand):
            self.i64GeU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32And(let binaryOperand):
            self.i32And(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64And(let binaryOperand):
            self.i64And(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Or(let binaryOperand):
            self.i32Or(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Or(let binaryOperand):
            self.i64Or(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Xor(let binaryOperand):
            self.i32Xor(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Xor(let binaryOperand):
            self.i64Xor(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Shl(let binaryOperand):
            self.i32Shl(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Shl(let binaryOperand):
            self.i64Shl(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32ShrS(let binaryOperand):
            self.i32ShrS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64ShrS(let binaryOperand):
            self.i64ShrS(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32ShrU(let binaryOperand):
            self.i32ShrU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64ShrU(let binaryOperand):
            self.i64ShrU(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Rotl(let binaryOperand):
            self.i32Rotl(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Rotl(let binaryOperand):
            self.i64Rotl(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Rotr(let binaryOperand):
            self.i32Rotr(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i64Rotr(let binaryOperand):
            self.i64Rotr(context: &context, stack: stack, binaryOperand: binaryOperand)
        case .i32Clz(let unaryOperand):
            self.i32Clz(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i64Clz(let unaryOperand):
            self.i64Clz(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i32Ctz(let unaryOperand):
            self.i32Ctz(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i64Ctz(let unaryOperand):
            self.i64Ctz(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i32Popcnt(let unaryOperand):
            self.i32Popcnt(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i64Popcnt(let unaryOperand):
            self.i64Popcnt(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i32Eqz(let unaryOperand):
            self.i32Eqz(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .i64Eqz(let unaryOperand):
            self.i64Eqz(context: &context, stack: stack, unaryOperand: unaryOperand)
        case .select(let selectOperand):
            try self.select(context: &context, stack: stack, selectOperand: selectOperand)
        case .refNull(let refNullOperand):
            self.refNull(context: &context, stack: stack, refNullOperand: refNullOperand)
        case .refIsNull(let refIsNullOperand):
            self.refIsNull(context: &context, stack: stack, refIsNullOperand: refIsNullOperand)
        case .refFunc(let refFuncOperand):
            self.refFunc(context: &context, stack: stack, refFuncOperand: refFuncOperand)
        case .tableGet(let tableGetOperand):
            try self.tableGet(context: &context, stack: stack, tableGetOperand: tableGetOperand)
        case .tableSet(let tableSetOperand):
            try self.tableSet(context: &context, stack: stack, tableSetOperand: tableSetOperand)
        case .tableSize(let tableSizeOperand):
            self.tableSize(context: &context, stack: stack, tableSizeOperand: tableSizeOperand)
        case .tableGrow(let tableGrowOperand):
            self.tableGrow(context: &context, stack: stack, tableGrowOperand: tableGrowOperand)
        case .tableFill(let tableFillOperand):
            try self.tableFill(context: &context, stack: stack, tableFillOperand: tableFillOperand)
        case .tableCopy(let tableCopyOperand):
            try self.tableCopy(context: &context, stack: stack, tableCopyOperand: tableCopyOperand)
        case .tableInit(let tableInitOperand):
            try self.tableInit(context: &context, stack: stack, tableInitOperand: tableInitOperand)
        case .tableElementDrop(let elementIndex):
            self.tableElementDrop(context: &context, stack: stack, elementIndex: elementIndex)
        }
        programCounter += 1
        return true
    }
}

extension Instruction {
    var name: String {
        switch self {
        case .copyStack: return "copyStack"
        case .globalGet: return "globalGet"
        case .globalSet: return "globalSet"
        case .call: return "call"
        case .compilingCall: return "compilingCall"
        case .internalCall: return "internalCall"
        case .callIndirect: return "callIndirect"
        case .unreachable: return "unreachable"
        case .nop: return "nop"
        case .ifThen: return "ifThen"
        case .br: return "br"
        case .brIf: return "brIf"
        case .brIfNot: return "brIfNot"
        case .brTable: return "brTable"
        case .`return`: return "`return`"
        case .endOfFunction: return "endOfFunction"
        case .endOfExecution: return "endOfExecution"
        case .i32Load: return "i32Load"
        case .i64Load: return "i64Load"
        case .f32Load: return "f32Load"
        case .f64Load: return "f64Load"
        case .i32Load8S: return "i32Load8S"
        case .i32Load8U: return "i32Load8U"
        case .i32Load16S: return "i32Load16S"
        case .i32Load16U: return "i32Load16U"
        case .i64Load8S: return "i64Load8S"
        case .i64Load8U: return "i64Load8U"
        case .i64Load16S: return "i64Load16S"
        case .i64Load16U: return "i64Load16U"
        case .i64Load32S: return "i64Load32S"
        case .i64Load32U: return "i64Load32U"
        case .i32Store: return "i32Store"
        case .i64Store: return "i64Store"
        case .f32Store: return "f32Store"
        case .f64Store: return "f64Store"
        case .i32Store8: return "i32Store8"
        case .i32Store16: return "i32Store16"
        case .i64Store8: return "i64Store8"
        case .i64Store16: return "i64Store16"
        case .i64Store32: return "i64Store32"
        case .memorySize: return "memorySize"
        case .memoryGrow: return "memoryGrow"
        case .memoryInit: return "memoryInit"
        case .memoryDataDrop: return "memoryDataDrop"
        case .memoryCopy: return "memoryCopy"
        case .memoryFill: return "memoryFill"
        case .numericConst: return "numericConst"
        case .numericFloatUnary: return "numericFloatUnary"
        case .numericIntBinary: return "numericIntBinary"
        case .numericFloatBinary: return "numericFloatBinary"
        case .numericConversion: return "numericConversion"
        case .i32Add: return "i32Add"
        case .i64Add: return "i64Add"
        case .f32Add: return "f32Add"
        case .f64Add: return "f64Add"
        case .i32Sub: return "i32Sub"
        case .i64Sub: return "i64Sub"
        case .f32Sub: return "f32Sub"
        case .f64Sub: return "f64Sub"
        case .i32Mul: return "i32Mul"
        case .i64Mul: return "i64Mul"
        case .f32Mul: return "f32Mul"
        case .f64Mul: return "f64Mul"
        case .i32Eq: return "i32Eq"
        case .i64Eq: return "i64Eq"
        case .f32Eq: return "f32Eq"
        case .f64Eq: return "f64Eq"
        case .i32Ne: return "i32Ne"
        case .i64Ne: return "i64Ne"
        case .f32Ne: return "f32Ne"
        case .f64Ne: return "f64Ne"
        case .i32LtS: return "i32LtS"
        case .i64LtS: return "i64LtS"
        case .i32LtU: return "i32LtU"
        case .i64LtU: return "i64LtU"
        case .i32GtS: return "i32GtS"
        case .i64GtS: return "i64GtS"
        case .i32GtU: return "i32GtU"
        case .i64GtU: return "i64GtU"
        case .i32LeS: return "i32LeS"
        case .i64LeS: return "i64LeS"
        case .i32LeU: return "i32LeU"
        case .i64LeU: return "i64LeU"
        case .i32GeS: return "i32GeS"
        case .i64GeS: return "i64GeS"
        case .i32GeU: return "i32GeU"
        case .i64GeU: return "i64GeU"
        case .i32And: return "i32And"
        case .i64And: return "i64And"
        case .i32Or: return "i32Or"
        case .i64Or: return "i64Or"
        case .i32Xor: return "i32Xor"
        case .i64Xor: return "i64Xor"
        case .i32Shl: return "i32Shl"
        case .i64Shl: return "i64Shl"
        case .i32ShrS: return "i32ShrS"
        case .i64ShrS: return "i64ShrS"
        case .i32ShrU: return "i32ShrU"
        case .i64ShrU: return "i64ShrU"
        case .i32Rotl: return "i32Rotl"
        case .i64Rotl: return "i64Rotl"
        case .i32Rotr: return "i32Rotr"
        case .i64Rotr: return "i64Rotr"
        case .i32Clz: return "i32Clz"
        case .i64Clz: return "i64Clz"
        case .i32Ctz: return "i32Ctz"
        case .i64Ctz: return "i64Ctz"
        case .i32Popcnt: return "i32Popcnt"
        case .i64Popcnt: return "i64Popcnt"
        case .i32Eqz: return "i32Eqz"
        case .i64Eqz: return "i64Eqz"
        case .select: return "select"
        case .refNull: return "refNull"
        case .refIsNull: return "refIsNull"
        case .refFunc: return "refFunc"
        case .tableGet: return "tableGet"
        case .tableSet: return "tableSet"
        case .tableSize: return "tableSize"
        case .tableGrow: return "tableGrow"
        case .tableFill: return "tableFill"
        case .tableCopy: return "tableCopy"
        case .tableInit: return "tableInit"
        case .tableElementDrop: return "tableElementDrop"
        }
    }
}
