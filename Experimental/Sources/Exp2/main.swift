/*
 Switch threaded code by Swift
 NOTE: The switch-case jump is effectively lowered into token threaded code
 */
typealias Reg = UInt16
typealias Imm = UInt32

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
    /* [4] */ .brIf(condReg, offset: -4),
    /* [5] */ .endOfFunction,
]

struct Regs {
    let storage: UnsafeMutablePointer<Int32>
    subscript(_ reg: Reg) -> Int32 {
        get { storage[Int(reg)] }
        nonmutating set { storage[Int(reg)] = newValue }
    }
}

@inline(never)
func enter(iseq: UnsafePointer<Instruction>, regs: Regs) {
    var pc = iseq
    var inst: Instruction
    while true {
        inst = pc.pointee
        switch inst {
        case .randomGet(let reg):
            regs[reg] = Int32.random(in: 0..<255)
        case .brIf(let reg, let offset):
            if regs[reg] != 0 {
                pc = pc.advanced(by: Int(offset))
            }
        case .i32AddImm(let lhs, let rhs, let result):
            regs[result] = Int32(lhs) + regs[rhs]
        case .i32Ltu(let lhs, let rhs, let result):
            regs[result] = regs[lhs] < rhs ? 1 : 0
        case .endOfFunction:
            return
        }
        pc = pc.advanced(by: 1)
    }
}

var regs: [Int32] = [0, 0, 0]

iseq.withUnsafeBufferPointer { iseq in
    regs.withUnsafeMutableBufferPointer {
        enter(iseq: iseq.baseAddress!, regs: Regs(storage: $0.baseAddress!))
    }
}
