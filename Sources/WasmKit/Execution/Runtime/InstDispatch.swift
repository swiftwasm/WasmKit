// This file is generated by Utilities/generate_inst_dispatch.swift
extension ExecutionState {
    @inline(__always)
    mutating func doExecute(_ instruction: Instruction, runtime: Runtime, stack: inout Stack) throws -> Bool {
        switch instruction {
        case .globalGet(let globalGetOperand):
            try self.globalGet(runtime: runtime, stack: &stack, globalGetOperand: globalGetOperand)
        case .globalSet(let globalSetOperand):
            try self.globalSet(runtime: runtime, stack: &stack, globalSetOperand: globalSetOperand)
        case .copyStack(let copyStackOperand):
            self.copyStack(runtime: runtime, stack: &stack, copyStackOperand: copyStackOperand)
        case .unreachable:
            try self.unreachable(runtime: runtime, stack: &stack)
            return true
        case .nop:
            try self.nop(runtime: runtime, stack: &stack)
            return true
        case .ifThen(let ifOperand):
            self.ifThen(runtime: runtime, stack: &stack, ifOperand: ifOperand)
            return true
        case .end:
            self.end(runtime: runtime, stack: &stack)
            return true
        case .`else`(let endRef):
            self.`else`(runtime: runtime, stack: &stack, endRef: endRef)
            return true
        case .br(let offset):
            try self.br(runtime: runtime, stack: &stack, offset: offset)
            return false
        case .brIf(let brIfOperand):
            try self.brIf(runtime: runtime, stack: &stack, brIfOperand: brIfOperand)
            return false
        case .brIfNot(let brIfOperand):
            try self.brIfNot(runtime: runtime, stack: &stack, brIfOperand: brIfOperand)
            return false
        case .brTable(let brTableOperand):
            try self.brTable(runtime: runtime, stack: &stack, brTableOperand: brTableOperand)
            return false
        case .`return`(let returnOperand):
            try self.`return`(runtime: runtime, stack: &stack, returnOperand: returnOperand)
            return false
        case .call(let callOperand):
            try self.call(runtime: runtime, stack: &stack, callOperand: callOperand)
            return false
        case .callIndirect(let callIndirectOperand):
            try self.callIndirect(runtime: runtime, stack: &stack, callIndirectOperand: callIndirectOperand)
            return false
        case .endOfFunction(let returnOperand):
            try self.endOfFunction(runtime: runtime, stack: &stack, returnOperand: returnOperand)
            return false
        case .endOfExecution:
            try self.endOfExecution(runtime: runtime, stack: &stack)
            return false
        case .i32Load(let loadOperand):
            try self.i32Load(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load(let loadOperand):
            try self.i64Load(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .f32Load(let loadOperand):
            try self.f32Load(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .f64Load(let loadOperand):
            try self.f64Load(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i32Load8S(let loadOperand):
            try self.i32Load8S(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i32Load8U(let loadOperand):
            try self.i32Load8U(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i32Load16S(let loadOperand):
            try self.i32Load16S(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i32Load16U(let loadOperand):
            try self.i32Load16U(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load8S(let loadOperand):
            try self.i64Load8S(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load8U(let loadOperand):
            try self.i64Load8U(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load16S(let loadOperand):
            try self.i64Load16S(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load16U(let loadOperand):
            try self.i64Load16U(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load32S(let loadOperand):
            try self.i64Load32S(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i64Load32U(let loadOperand):
            try self.i64Load32U(runtime: runtime, stack: &stack, loadOperand: loadOperand)
        case .i32Store(let storeOperand):
            try self.i32Store(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .i64Store(let storeOperand):
            try self.i64Store(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .f32Store(let storeOperand):
            try self.f32Store(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .f64Store(let storeOperand):
            try self.f64Store(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .i32Store8(let storeOperand):
            try self.i32Store8(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .i32Store16(let storeOperand):
            try self.i32Store16(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .i64Store8(let storeOperand):
            try self.i64Store8(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .i64Store16(let storeOperand):
            try self.i64Store16(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .i64Store32(let storeOperand):
            try self.i64Store32(runtime: runtime, stack: &stack, storeOperand: storeOperand)
        case .memorySize(let memorySizeOperand):
            self.memorySize(runtime: runtime, stack: &stack, memorySizeOperand: memorySizeOperand)
        case .memoryGrow(let memoryGrowOperand):
            try self.memoryGrow(runtime: runtime, stack: &stack, memoryGrowOperand: memoryGrowOperand)
        case .memoryInit(let memoryInitOperand):
            try self.memoryInit(runtime: runtime, stack: &stack, memoryInitOperand: memoryInitOperand)
        case .memoryDataDrop(let dataIndex):
            self.memoryDataDrop(runtime: runtime, stack: &stack, dataIndex: dataIndex)
        case .memoryCopy(let memoryCopyOperand):
            try self.memoryCopy(runtime: runtime, stack: &stack, memoryCopyOperand: memoryCopyOperand)
        case .memoryFill(let memoryFillOperand):
            try self.memoryFill(runtime: runtime, stack: &stack, memoryFillOperand: memoryFillOperand)
        case .numericConst(let constOperand):
            self.numericConst(runtime: runtime, stack: &stack, constOperand: constOperand)
        case .numericFloatUnary(let floatUnary, let unaryOperand):
            self.numericFloatUnary(runtime: runtime, stack: &stack, floatUnary: floatUnary, unaryOperand: unaryOperand)
        case .numericIntBinary(let intBinary, let binaryOperand):
            try self.numericIntBinary(runtime: runtime, stack: &stack, intBinary: intBinary, binaryOperand: binaryOperand)
        case .numericFloatBinary(let floatBinary, let binaryOperand):
            self.numericFloatBinary(runtime: runtime, stack: &stack, floatBinary: floatBinary, binaryOperand: binaryOperand)
        case .numericConversion(let conversion, let unaryOperand):
            try self.numericConversion(runtime: runtime, stack: &stack, conversion: conversion, unaryOperand: unaryOperand)
        case .i32Add(let binaryOperand):
            self.i32Add(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64Add(let binaryOperand):
            self.i64Add(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f32Add(let binaryOperand):
            self.f32Add(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f64Add(let binaryOperand):
            self.f64Add(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32Sub(let binaryOperand):
            self.i32Sub(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64Sub(let binaryOperand):
            self.i64Sub(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f32Sub(let binaryOperand):
            self.f32Sub(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f64Sub(let binaryOperand):
            self.f64Sub(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32Mul(let binaryOperand):
            self.i32Mul(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64Mul(let binaryOperand):
            self.i64Mul(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f32Mul(let binaryOperand):
            self.f32Mul(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f64Mul(let binaryOperand):
            self.f64Mul(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32Eq(let binaryOperand):
            self.i32Eq(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64Eq(let binaryOperand):
            self.i64Eq(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f32Eq(let binaryOperand):
            self.f32Eq(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f64Eq(let binaryOperand):
            self.f64Eq(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32Ne(let binaryOperand):
            self.i32Ne(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64Ne(let binaryOperand):
            self.i64Ne(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f32Ne(let binaryOperand):
            self.f32Ne(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .f64Ne(let binaryOperand):
            self.f64Ne(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32LtS(let binaryOperand):
            self.i32LtS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64LtS(let binaryOperand):
            self.i64LtS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32LtU(let binaryOperand):
            self.i32LtU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64LtU(let binaryOperand):
            self.i64LtU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32GtS(let binaryOperand):
            self.i32GtS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64GtS(let binaryOperand):
            self.i64GtS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32GtU(let binaryOperand):
            self.i32GtU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64GtU(let binaryOperand):
            self.i64GtU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32LeS(let binaryOperand):
            self.i32LeS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64LeS(let binaryOperand):
            self.i64LeS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32LeU(let binaryOperand):
            self.i32LeU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64LeU(let binaryOperand):
            self.i64LeU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32GeS(let binaryOperand):
            self.i32GeS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64GeS(let binaryOperand):
            self.i64GeS(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32GeU(let binaryOperand):
            self.i32GeU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i64GeU(let binaryOperand):
            self.i64GeU(runtime: runtime, stack: &stack, binaryOperand: binaryOperand)
        case .i32Clz(let unaryOperand):
            self.i32Clz(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i64Clz(let unaryOperand):
            self.i64Clz(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i32Ctz(let unaryOperand):
            self.i32Ctz(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i64Ctz(let unaryOperand):
            self.i64Ctz(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i32Popcnt(let unaryOperand):
            self.i32Popcnt(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i64Popcnt(let unaryOperand):
            self.i64Popcnt(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i32Eqz(let unaryOperand):
            self.i32Eqz(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .i64Eqz(let unaryOperand):
            self.i64Eqz(runtime: runtime, stack: &stack, unaryOperand: unaryOperand)
        case .select(let selectOperand):
            try self.select(runtime: runtime, stack: &stack, selectOperand: selectOperand)
        case .refNull(let refNullOperand):
            self.refNull(runtime: runtime, stack: &stack, refNullOperand: refNullOperand)
        case .refIsNull(let refIsNullOperand):
            self.refIsNull(runtime: runtime, stack: &stack, refIsNullOperand: refIsNullOperand)
        case .refFunc(let refFuncOperand):
            self.refFunc(runtime: runtime, stack: &stack, refFuncOperand: refFuncOperand)
        case .tableGet(let tableGetOperand):
            try self.tableGet(runtime: runtime, stack: &stack, tableGetOperand: tableGetOperand)
        case .tableSet(let tableSetOperand):
            try self.tableSet(runtime: runtime, stack: &stack, tableSetOperand: tableSetOperand)
        case .tableSize(let tableSizeOperand):
            self.tableSize(runtime: runtime, stack: &stack, tableSizeOperand: tableSizeOperand)
        case .tableGrow(let tableGrowOperand):
            self.tableGrow(runtime: runtime, stack: &stack, tableGrowOperand: tableGrowOperand)
        case .tableFill(let tableFillOperand):
            try self.tableFill(runtime: runtime, stack: &stack, tableFillOperand: tableFillOperand)
        case .tableCopy(let tableCopyOperand):
            try self.tableCopy(runtime: runtime, stack: &stack, tableCopyOperand: tableCopyOperand)
        case .tableInit(let tableInitOperand):
            try self.tableInit(runtime: runtime, stack: &stack, tableInitOperand: tableInitOperand)
        case .tableElementDrop(let elementIndex):
            self.tableElementDrop(runtime: runtime, stack: &stack, elementIndex: elementIndex)
        }
        programCounter += 1
        return true
    }
}

extension Instruction {
    var name: String {
        switch self {
        case .globalGet: return "globalGet"
        case .globalSet: return "globalSet"
        case .copyStack: return "copyStack"
        case .unreachable: return "unreachable"
        case .nop: return "nop"
        case .ifThen: return "ifThen"
        case .end: return "end"
        case .`else`: return "`else`"
        case .br: return "br"
        case .brIf: return "brIf"
        case .brIfNot: return "brIfNot"
        case .brTable: return "brTable"
        case .`return`: return "`return`"
        case .call: return "call"
        case .callIndirect: return "callIndirect"
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
