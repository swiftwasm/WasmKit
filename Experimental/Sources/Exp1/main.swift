/* Switch threaded code by Swift + Stack machine */

typealias Reg = UInt16
typealias Imm = UInt32

enum Instruction: Equatable {
    case randomGet
    case brIf(offset: Int32)
    case i32Add
    case i32Ltu
    case endOfFunction
    case regGet(Reg)
    case regSet(Reg)
    case const(Imm)
}

let xReg: Reg = 0
let iReg: Reg = 1
let iseq: [Instruction] = [
    /* [00] */ .randomGet,
    /* [01] */ .regSet(xReg),
    /* [02] */ .regGet(iReg),
    /* [03] */ .const(1),
    /* [04] */ .i32Add,
    /* [05] */ .regSet(iReg),
    /* [06] */ .regGet(xReg),
    /* [07] */ .const(1),
    /* [08] */ .i32Add,
    /* [09] */ .regSet(xReg),
    /* [10] */ .regGet(iReg),
    /* [11] */ .const(10000000),
    /* [12] */ .i32Ltu,
    /* [13] */ .brIf(offset: -11),
    /* [14] */ .endOfFunction,
]

struct Regs {
    let storage: UnsafeMutableBufferPointer<Int32>
    subscript(_ reg: Reg) -> Int32 {
        get { storage[Int(reg)] }
        nonmutating set { storage[Int(reg)] = newValue }
    }
}

struct Stack {
    var values: [Int32]

    mutating func pop() -> Int32 {
        values.popLast()!
    }
    mutating func push(_ value: Int32) {
        values.append(value)
    }
}

func _start(iseq: UnsafePointer<Instruction>, regs: Regs, stack: inout Stack) {
    var pc = iseq
    var inst: Instruction
    while true {
        inst = pc.pointee
        switch inst {
        case .randomGet:
            stack.push(Int32.random(in: 0..<255))
        case .brIf(let offset):
            if stack.pop() != 0 {
                pc = pc.advanced(by: Int(offset))
                continue
            }
        case .i32Add:
            stack.push(stack.pop() + stack.pop())
        case .i32Ltu:
            let (rhs, lhs) = (stack.pop(), stack.pop())
            stack.push(lhs < rhs ? 1 : 0)
        case .regGet(let reg):
            stack.push(regs[reg])
        case .regSet(let reg):
            regs[reg] = stack.pop()
        case .const(let value):
            stack.push(Int32(value))
        case .endOfFunction:
            return
        }
        pc = pc.advanced(by: 1)
    }
}

var regs: [Int32] = [0, 0, 0]
var stack = Stack(values: [])

iseq.withUnsafeBufferPointer { iseq in
    regs.withUnsafeMutableBufferPointer {
        _start(iseq: iseq.baseAddress!, regs: Regs(storage: $0), stack: &stack)
    }
}
