struct Expression {
    let instructions: [Instruction]

    init(instructions: [Instruction] = []) {
        self.instructions = instructions
    }
}

extension Expression: Equatable {
    static func == (lhs: Expression, rhs: Expression) -> Bool {
        guard lhs.instructions.count == rhs.instructions.count else {
            return false
        }
        for (l, r) in zip(lhs.instructions, rhs.instructions) {
            guard l.isEqual(to: r) else { return false }
        }
        return true
    }
}

protocol Instruction {
    var isConstant: Bool { get }

    func isEqual(to another: Instruction) -> Bool
}

extension Instruction where Self: Equatable {
    func isEqual(to another: Instruction) -> Bool {
        guard let another = another as? Self else { return false }
        return self == another
    }
}

/// Pseudo Instructions
enum PseudoInstruction: Instruction, Equatable {
    case end

    var isConstant: Bool {
        return false
    }
}

/// Control Instructions
/// - SeeAlso: https://webassembly.github.io/spec/core/binary/instructions.html#control-instructions
enum ControlInstruction: Instruction, Equatable {
    case unreachable
    case nop
    case block(ResultType, Expression)
    case loop(ResultType, Expression)
    case `if`(ResultType, Expression, Expression)
    case br(LabelIndex)
    case brIf(LabelIndex)
    case brTable([LabelIndex])
    case `return`
    case call(FunctionIndex)
    case callIndirect(TypeIndex)

    var isConstant: Bool {
        return false
    }
}

/// Parametric Instructions
/// - SeeAlso: https://webassembly.github.io/spec/core/binary/instructions.html#parametric-instructions
enum ParametricInstruction: Instruction, Equatable {
    case drop
    case select

    var isConstant: Bool {
        return false
    }
}

/// Variable Instructions
/// - SeeAlso: https://webassembly.github.io/spec/core/binary/instructions.html#variable-instructions
enum VariableInstruction: Instruction, Equatable {
    case getLocal(LabelIndex)
    case setLocal(LabelIndex)
    case teeLocal(LabelIndex)
    case getGlobal(GlobalIndex)
    case setGlobal(GlobalIndex)

    var isConstant: Bool {
        return false
    }
}

/// Memory Instructions
/// - SeeAlso: https://webassembly.github.io/spec/core/binary/instructions.html#memory-instructions

enum MemoryInstruction: Instruction, Equatable {
    struct MemoryArgument: Equatable {
        let min: UInt32
        let max: UInt32
    }

    case currentMemory
    case growMemory

    case load(ValueType, MemoryArgument)
    case load8s(ValueType, MemoryArgument)
    case load8u(ValueType, MemoryArgument)
    case load16s(ValueType, MemoryArgument)
    case load16u(ValueType, MemoryArgument)
    case load32s(ValueType, MemoryArgument)
    case load32u(ValueType, MemoryArgument)
    case store(ValueType, MemoryArgument)
    case store8(ValueType, MemoryArgument)
    case store16(ValueType, MemoryArgument)
    case store32(ValueType, MemoryArgument)

    var isConstant: Bool {
        return false
    }
}

/// Numeric Instructions
/// - SeeAlso: https://webassembly.github.io/spec/core/binary/instructions.html#numeric-instructions
enum NumericInstruction: Instruction, Equatable {
    case const(Value)

    case eqz(ValueType)
    case eq(ValueType)
    case ne(ValueType)
    case ltS(ValueType)
    case ltU(ValueType)
    case lt(ValueType)
    case gtS(ValueType)
    case gtU(ValueType)
    case gt(ValueType)
    case leS(ValueType)
    case leU(ValueType)
    case le(ValueType)
    case geS(ValueType)
    case geU(ValueType)
    case ge(ValueType)

    case clz(ValueType)
    case ctz(ValueType)
    case popcnt(ValueType)
    case add(ValueType)
    case sub(ValueType)
    case mul(ValueType)
    case divS(ValueType)
    case divU(ValueType)
    case remS(ValueType)
    case remU(ValueType)
    case and(ValueType)
    case or(ValueType)
    case xor(ValueType)
    case shl(ValueType)
    case shrS(ValueType)
    case shrU(ValueType)
    case rotl(ValueType)
    case rotr(ValueType)

    case abs(ValueType)
    case neg(ValueType)
    case ceil(ValueType)
    case floor(ValueType)
    case trunc(ValueType)
    case nearest(ValueType)
    case sqrt(ValueType)
    case div(ValueType)
    case min(ValueType)
    case max(ValueType)
    case copysign(ValueType)

    case wrap(ValueType, ValueType)
    case extendS(ValueType, ValueType)
    case extendU(ValueType, ValueType)
    case truncS(ValueType, ValueType)
    case truncU(ValueType, ValueType)
    case convertS(ValueType, ValueType)
    case convertU(ValueType, ValueType)
    case demote(ValueType, ValueType)
    case promote(ValueType, ValueType)
    case reinterpret(ValueType, ValueType)

    var isConstant: Bool {
        switch self {
        case .const:
            return true
        default:
            return false
        }
    }
}
