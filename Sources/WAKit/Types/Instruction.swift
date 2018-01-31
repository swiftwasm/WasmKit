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
enum PseudoInstruction: Instruction, AutoEquatable {
    case end

    var isConstant: Bool {
        return false
    }
}

/// Control Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#control-instructions
enum ControlInstruction: Instruction, AutoEquatable {
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
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#parametric-instructions
enum ParametricInstruction: Instruction, AutoEquatable {
    case drop
    case select

    var isConstant: Bool {
        return false
    }
}

/// Variable Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#variable-instructions
enum VariableInstruction: Instruction, AutoEquatable {
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
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#memory-instructions
enum MemoryInstruction: Instruction, AutoEquatable {
    typealias MemoryArgument = (UInt32, UInt32)

    case currentMemory
    case growMemory

    case load(Value.Type, MemoryArgument)
    case load8s(IntegerValue.Type, MemoryArgument)
    case load8u(IntegerValue.Type, MemoryArgument)
    case load16s(IntegerValue.Type, MemoryArgument)
    case load16u(IntegerValue.Type, MemoryArgument)
    case load32s(IntegerValue.Type, MemoryArgument)
    case load32u(IntegerValue.Type, MemoryArgument)
    case store(Value.Type, MemoryArgument)
    case store8(IntegerValue.Type, MemoryArgument)
    case store16(IntegerValue.Type, MemoryArgument)
    case store32(IntegerValue.Type, MemoryArgument)

    var isConstant: Bool {
        return false
    }
}

/// Numeric Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#numeric-instructions
enum NumericInstruction: Instruction, AutoEquatable {
    case constI32(Int32)
    case constI64(Int64)
    case constF32(Float32)
    case constF64(Float64)

    case eqz(IntegerValue.Type)
    case eq(Value.Type)
    case ne(Value.Type)
    case ltS(IntegerValue.Type)
    case ltU(IntegerValue.Type)
    case lt(Value.Type)
    case gtS(IntegerValue.Type)
    case gtU(IntegerValue.Type)
    case gt(Value.Type)
    case leS(IntegerValue.Type)
    case leU(IntegerValue.Type)
    case le(Value.Type)
    case geS(IntegerValue.Type)
    case geU(IntegerValue.Type)
    case ge(Value.Type)

    case clz(IntegerValue.Type)
    case ctz(IntegerValue.Type)
    case popcnt(Value.Type)
    case add(Value.Type)
    case sub(Value.Type)
    case mul(Value.Type)
    case divS(IntegerValue.Type)
    case divU(IntegerValue.Type)
    case remS(IntegerValue.Type)
    case remU(IntegerValue.Type)
    case and(Value.Type)
    case or(Value.Type)
    case xor(Value.Type)
    case shl(Value.Type)
    case shrS(IntegerValue.Type)
    case shrU(IntegerValue.Type)
    case rotl(Value.Type)
    case rotr(Value.Type)

    case abs(FloatingPointValue.Type)
    case neg(FloatingPointValue.Type)
    case ceil(FloatingPointValue.Type)
    case floor(FloatingPointValue.Type)
    case trunc(FloatingPointValue.Type)
    case nearest(FloatingPointValue.Type)
    case sqrt(FloatingPointValue.Type)
    case div(FloatingPointValue.Type)
    case min(FloatingPointValue.Type)
    case max(FloatingPointValue.Type)
    case copysign(FloatingPointValue.Type)

    case wrap(IntegerValue.Type, IntegerValue.Type)
    case extendS(IntegerValue.Type, Value.Type)
    case extendU(IntegerValue.Type, Value.Type)
    case truncS(IntegerValue.Type, Value.Type)
    case truncU(IntegerValue.Type, Value.Type)
    case convertS(FloatingPointValue.Type, IntegerValue.Type)
    case convertU(FloatingPointValue.Type, IntegerValue.Type)
    case demote(FloatingPointValue.Type, Value.Type)
    case promote(FloatingPointValue.Type, Value.Type)
    case reinterpret(Value.Type, Value.Type)

    var isConstant: Bool {
        switch self {
        case .constI32,
             .constI64,
             .constF32,
             .constF64:
            return true
        default:
            return false
        }
    }
}
