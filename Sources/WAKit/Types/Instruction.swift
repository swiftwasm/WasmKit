struct Expression: Equatable {
    let instructions: [Instruction]

    init(instructions: [Instruction] = []) {
        self.instructions = instructions
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.instructions == rhs.instructions
    }
}

protocol Instruction {
    func isEqual(to another: Instruction) -> Bool
}

extension Instruction where Self: Equatable {
    func isEqual(to another: Instruction) -> Bool {
        guard let another = another as? Self else { return false }
        return self == another
    }
}

extension Array where Element == Instruction {
    static func == (lhs: [Instruction], rhs: [Instruction]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        for (l, r) in zip(lhs, rhs) {
            guard l.isEqual(to: r) else { return false }
        }
        return true
    }
}

/// Pseudo Instructions
enum PseudoInstruction: Instruction, Equatable {
    case end
}

/// Control Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#control-instructions>
// sourcery: AutoEquatable
enum ControlInstruction: Instruction {
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
}

/// Parametric Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#parametric-instructions>
enum ParametricInstruction: Instruction, Equatable {
    case drop
    case select
}

/// Variable Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#variable-instructions>
enum VariableInstruction: Instruction, Equatable {
    case getLocal(LabelIndex)
    case setLocal(LabelIndex)
    case teeLocal(LabelIndex)
    case getGlobal(GlobalIndex)
    case setGlobal(GlobalIndex)
}

/// Memory Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#memory-instructions>
// sourcery: AutoEquatable
enum MemoryInstruction: Instruction {
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
}

/// Numeric Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#numeric-instructions>
enum NumericInstruction {
    enum Constant: Instruction, Equatable {
        case const(Value)
    }

    // sourcery: AutoEquatable
    enum Unary: Instruction {
        case clz(IntValueType)
        case ctz(IntValueType)
        case popcnt(IntValueType)

        case abs(FloatValueType)
        case neg(FloatValueType)
        case ceil(FloatValueType)
        case floor(FloatValueType)
        case trunc(FloatValueType)
        case nearest(FloatValueType)
        case sqrt(FloatValueType)
    }

    // sourcery: AutoEquatable
    enum Binary: Instruction {
        case add(ValueType)
        case sub(ValueType)
        case mul(ValueType)

        case divS(IntValueType)
        case divU(IntValueType)
        case remS(IntValueType)
        case remU(IntValueType)
        case and(IntValueType)
        case or(IntValueType)
        case xor(IntValueType)
        case shl(IntValueType)
        case shrS(IntValueType)
        case shrU(IntValueType)
        case rotl(IntValueType)
        case rotr(IntValueType)

        case div(FloatValueType)
        case min(FloatValueType)
        case max(FloatValueType)
        case copysign(FloatValueType)
    }

    // sourcery: AutoEquatable
    enum Test: Instruction {
        case eqz(IntValueType)
    }

    // sourcery: AutoEquatable
    enum Comparison: Instruction {
        case eq(ValueType)
        case ne(ValueType)

        case ltS(IntValueType)
        case ltU(IntValueType)
        case gtS(IntValueType)
        case gtU(IntValueType)
        case leS(IntValueType)
        case leU(IntValueType)
        case geS(IntValueType)
        case geU(IntValueType)

        case lt(FloatValueType)
        case gt(FloatValueType)
        case le(FloatValueType)
        case ge(FloatValueType)
    }

    // sourcery: AutoEquatable
    enum Conversion: Instruction {
        case wrap(IntValueType, IntValueType)
        case extendS(IntValueType, IntValueType)
        case extendU(IntValueType, IntValueType)
        case truncS(IntValueType, FloatValueType)
        case truncU(IntValueType, FloatValueType)
        case convertS(FloatValueType, IntValueType)
        case convertU(FloatValueType, IntValueType)
        case demote(FloatValueType, FloatValueType)
        case promote(FloatValueType, FloatValueType)
        case reinterpret(ValueType, ValueType)
    }
}
