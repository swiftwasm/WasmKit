/* Direct threaded code by Swift with C interop */

import _Exp7CShim

typealias Reg = UInt16
typealias Imm = UInt32

extension Inst {
    struct RandomGetOp {
        let reg: Reg
        let pad1: UInt16 = 0
        let pad2: UInt32 = 0
    }
    struct I32AddImmOp {
        let lhs: Imm
        let rhs: Reg
        let result: Reg
    }
    struct I32LtuOp {
        let rhs: Imm
        let lhs: Reg
        let result: Reg
    }
    struct BrIfOp {
        let cond: Reg
        let offset: Int32
    }
    struct EndOfFunctionOp {
        let pad1: UInt64 = 0
    }
    static func randomGet(_ reg: Reg) -> Inst {
        return Inst(
            ty: Int(_Exp7CShim.randomGet.rawValue),
            op: unsafeBitCast(RandomGetOp(reg: reg), to: OpStorage.self)
        )
    }
    static func i32AddImm(lhs: Imm, rhs: Reg, result: Reg) -> Inst {
        return Inst(
            ty: Int(_Exp7CShim.i32AddImm.rawValue),
            op: unsafeBitCast(I32AddImmOp(lhs: lhs, rhs: rhs, result: result), to: OpStorage.self)
        )
    }
    static func i32Ltu(lhs: Reg, rhs: Imm, result: Reg) -> Inst {
        return Inst(
            ty: Int(_Exp7CShim.i32Ltu.rawValue),
            op: unsafeBitCast(I32LtuOp(rhs: rhs, lhs: lhs, result: result), to: OpStorage.self)
        )
    }
    static func brIf(cond: Reg, offset: Int32) -> Inst {
        return Inst(
            ty: Int(_Exp7CShim.brIf.rawValue),
            op: unsafeBitCast(BrIfOp(cond: cond, offset: offset), to: OpStorage.self)
        )
    }
    static func endOfFunction() -> Inst {
        return Inst(
            ty: Int(_Exp7CShim.endOfFunction.rawValue),
            op: unsafeBitCast(EndOfFunctionOp(), to: OpStorage.self)
        )
    }
}

struct OperandView<Op> {
    let pointer: UnsafeRawPointer

    var pointee: Op {
        pointer.assumingMemoryBound(to: Op.self).pointee
    }

    func advanced<U>(by keyPath: KeyPath<Op, U>) -> UnsafePointer<U> {
        pointer.advanced(by: MemoryLayout.offset(of: keyPath).unsafelyUnwrapped)
            .assumingMemoryBound(to: U.self)
    }
}

extension UnsafePointer<Inst> {
    func op<T>(_: T.Type) -> OperandView<T> {
        OperandView(pointer: UnsafeRawPointer(self).advanced(by: Inst_op_offset()))
    }
}

let xReg: Reg = 0
let iReg: Reg = 1
let condReg: Reg = 2
var iseq: [Inst] = [
    .randomGet(xReg),
    .i32AddImm(lhs: 1, rhs: iReg, result: iReg),
    .i32AddImm(lhs: 1, rhs: xReg, result: xReg),
    .i32Ltu(lhs: iReg, rhs: 10000000, result: condReg),
    .brIf(cond: condReg, offset: -4),
    .endOfFunction(),
]

var regs: [Int32] = [0, 0, 0]
enter(nil, nil)

for (i, inst) in iseq.enumerated() {
    withUnsafePointer(to: labelTable) {
        $0.withMemoryRebound(
            to: UnsafeRawPointer.self, capacity: Int(numberOfInstTypes.rawValue)
        ) { table -> Void in
            iseq[i].ty = Int(bitPattern: table.advanced(by: inst.ty).pointee)
        }
    }
}

typealias InstExec = @convention(c) (_ pc: UnsafePointer<Inst>, _ regs: UnsafeMutablePointer<Int32>) -> UnsafePointer<Inst>

@_cdecl("handle_randomGet")
@inline(__always)
func handle_randomGet(pc: UnsafePointer<Inst>, regs: UnsafeMutablePointer<Int32>) -> UnsafePointer<Inst> {
    let reg = pc.op(Inst.RandomGetOp.self).advanced(by: \.reg).pointee
    regs[Int(reg)] = Int32.random(in: 0..<255)
    return pc
}

@_cdecl("handle_i32AddImm")
@inline(__always)
func handle_i32AddImm(pc: UnsafePointer<Inst>, regs: UnsafeMutablePointer<Int32>) -> UnsafePointer<Inst> {
    let op = pc.op(Inst.I32AddImmOp.self).pointee
    regs[Int(op.result)] = Int32(op.lhs) + regs[Int(op.rhs)]
    return pc
}

@_cdecl("handle_i32Ltu")
@inline(__always)
func handle_i32Ltu(pc: UnsafePointer<Inst>, regs: UnsafeMutablePointer<Int32>) -> UnsafePointer<Inst> {
    let op = pc.op(Inst.I32LtuOp.self).pointee
    regs[Int(op.result)] = regs[Int(op.lhs)] < op.rhs ? 1 : 0
    return pc
}

@_cdecl("handle_brIf")
@inline(__always)
func handle_brIf(pc: UnsafePointer<Inst>, regs: UnsafeMutablePointer<Int32>) -> UnsafePointer<Inst> {
    let op = pc.op(Inst.BrIfOp.self)
    let cond = op.advanced(by: \.cond).pointee
    if regs[Int(cond)] != 0 {
        let offset = op.advanced(by: \.offset).pointee
        return pc.advanced(by: Int(offset))
    }
    return pc
}

regs.withUnsafeMutableBufferPointer { regs in
    enter(iseq, regs.baseAddress!)
}
