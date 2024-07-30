/* Direct threaded code by Swift with tail-call & variable-width-instruction */
import _Exp3CShim

typealias Reg = UInt16
typealias Imm = UInt32

struct Regs {
    let storage: UnsafeMutablePointer<Int32>
    subscript(_ reg: Reg) -> Int32 {
        get { storage[Int(reg)] }
        nonmutating set { storage[Int(reg)] = newValue }
    }
}

struct ProgramCounter {
    var pointer: UnsafeRawPointer
    mutating func getAndAdvance<T>(_: T.Type = T.self) -> T {
        let value = pointer.assumingMemoryBound(to: T.self).pointee
        pointer = pointer.advanced(by: MemoryLayout<T>.size)
        return value
    }
    mutating func getInstruction() -> InstExec { getAndAdvance() }
    mutating func getReg() -> Reg { getAndAdvance() }
    mutating func getImm() -> Imm { getAndAdvance() }
    mutating func getOp() -> Op { getAndAdvance() }
    mutating func advance(_ offset: Int32) {
        pointer = pointer.advanced(by: Int(offset))
    }
}


typealias InstExec = @convention(c) (_ pc: UnsafeRawPointer, _ regs: UnsafeMutablePointer<Int32>) -> Void

enum ExecResult {
    case `continue`
    case end
}

@inline(__always)
func execNext(_ pc: UnsafeRawPointer, _ regs: UnsafeMutablePointer<Int32>) {
    var pc = ProgramCounter(pointer: pc)
    let inst = pc.getInstruction()
    return inst(pc.pointer, regs)
}

let randomGet: InstExec = { pc, regs in
    var pc = ProgramCounter(pointer: pc)
    let regs = Regs(storage: regs)
    let reg = pc.getOp().randomGet
    regs[reg] = Int32.random(in: 0..<255)
    return execNext(pc.pointer, regs.storage)
}

let brIf: InstExec = { pc, regs in
    var pc = ProgramCounter(pointer: pc)
    let regs = Regs(storage: regs)
    let op = pc.getOp().brIf
    if regs[op.cond] != 0 {
        pc.advance(op.offset)
    }
    return execNext(pc.pointer, regs.storage)
}

let i32AddImm: InstExec = { pc, regs in
    var pc = ProgramCounter(pointer: pc)
    let regs = Regs(storage: regs)
    let op = pc.getOp().i32AddImm
    regs[op.result] = Int32(op.lhs) + regs[op.rhs]
    return execNext(pc.pointer, regs.storage)
}

let i32Ltu: InstExec = { pc, regs in
    var pc = ProgramCounter(pointer: pc)
    let regs = Regs(storage: regs)
    let op = pc.getOp().i32Ltu
    regs[op.result] = regs[op.lhs] < op.rhs ? 1 : 0
    return execNext(pc.pointer, regs.storage)
}

let endOfFunction: InstExec = { pc, regs in
    return
}

func _start(pc: ProgramCounter, regs: Regs) {
    var pc = pc
    pc.getInstruction()(pc.pointer, regs.storage)
}

struct Builder {
    var bytes: [UInt8]

    mutating func append<T>(_ value: T) {
        let baseOffset = bytes.count
        bytes.append(contentsOf: Array(repeating: 0, count: MemoryLayout<T>.size))
        bytes.withUnsafeMutableBufferPointer { buffer in
            let pointer = UnsafeMutableRawPointer(
                buffer.baseAddress!.advanced(by: baseOffset)
            ).assumingMemoryBound(to: T.self)
            pointer.pointee = value
        }
    }
    mutating func appendInst(_ inst: InstExec) {
        append(inst)
    }
    mutating func appendOp(_ op: Op) {
        append(op)
    }
}

enum Instruction: Equatable {
    case randomGet(Reg)
    case brIf(Reg, offset: Int32)
    case i32AddImm(lhs: Imm, rhs: Reg, result: Reg)
    case i32Ltu(lhs: Reg, rhs: Imm, result: Reg)
    case endOfFunction
}

let xReg: Reg = 0
let iReg: Reg = 1
let condReg: Reg = 2


let iseq: [Instruction] = [
    /* [0] */ .randomGet(xReg),
    /* [1] */ .i32AddImm(lhs: 1, rhs: iReg, result: iReg),
    /* [2] */ .i32AddImm(lhs: 1, rhs: xReg, result: xReg),
    /* [3] */ .i32Ltu(lhs: iReg, rhs: 10000000, result: condReg),
    /* [4] */ .brIf(condReg, offset: -3),
    /* [5] */ .endOfFunction,
]

var builder = Builder(bytes: [])
var offsetTable: [Int] = []
for (instIndex, inst) in iseq.enumerated() {
    offsetTable.append(builder.bytes.count)
    switch inst {
    case let .randomGet(reg):
        builder.appendInst(randomGet)
        builder.appendOp(Op(randomGet: reg))
    case let .brIf(reg, offset):
        builder.appendInst(brIf)
        let instOffset = instIndex + Int(offset)
        let byteOffset = offsetTable[instOffset] - (builder.bytes.count + MemoryLayout<Op>.size)
        builder.appendOp(Op(brIf: .init(cond: reg, offset: Int32(byteOffset))))
    case let .i32AddImm(lhs, rhs, result):
        builder.appendInst(i32AddImm)
        builder.appendOp(Op(i32AddImm: .init(lhs: lhs, rhs: rhs, result: result)))
    case let .i32Ltu(lhs, rhs, result):
        builder.appendInst(i32Ltu)
        builder.appendOp(Op(i32Ltu: .init(rhs: rhs, lhs: lhs, result: result)))
    case .endOfFunction:
        builder.appendInst(endOfFunction)
    }
}

var regs: [Int32] = [0, 0, 0]

builder.bytes.withUnsafeBufferPointer { iseqBytes in
    let pc = ProgramCounter(pointer: UnsafeRawPointer(iseqBytes.baseAddress!))
    regs.withUnsafeMutableBufferPointer {
        _start(pc: pc, regs: Regs(storage: $0.baseAddress!))
    }
}
