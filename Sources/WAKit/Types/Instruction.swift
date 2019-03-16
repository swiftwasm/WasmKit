struct Expression: Equatable {
    let instructions: [Instruction]

    init(instructions: [Instruction] = []) {
        self.instructions = instructions
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.instructions == rhs.instructions
    }
}

public protocol Instruction {
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
    case `else`
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
    case brTable([LabelIndex], LabelIndex)
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
    case localGet(LabelIndex)
    case localSet(LabelIndex)
    case localTee(LabelIndex)
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
    // sourcery: AutoEquatable
    enum Constant: Instruction {
        case const(Value)
    }

    // sourcery: AutoEquatable
    enum Unary: Instruction {
        case clz(ValueType)
        case ctz(ValueType)
        case popcnt(ValueType)

        case abs(ValueType)
        case neg(ValueType)
        case ceil(ValueType)
        case floor(ValueType)
        case trunc(ValueType)
        case nearest(ValueType)
        case sqrt(ValueType)

        case eqz(ValueType)

        var type: ValueType {
            switch self {
            case let .clz(type),
                 let .ctz(type),
                 let .popcnt(type),
                 let .abs(type),
                 let .neg(type),
                 let .ceil(type),
                 let .floor(type),
                 let .trunc(type),
                 let .nearest(type),
                 let .sqrt(type),
                 let .eqz(type):
                return type
            }
        }
    }

    // sourcery: AutoEquatable
    enum Binary: Instruction {
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

        case div(ValueType)
        case min(ValueType)
        case max(ValueType)
        case copysign(ValueType)

        case eq(ValueType)
        case ne(ValueType)

        case ltS(ValueType)
        case ltU(ValueType)
        case gtS(ValueType)
        case gtU(ValueType)
        case leS(ValueType)
        case leU(ValueType)
        case geS(ValueType)
        case geU(ValueType)

        case lt(ValueType)
        case gt(ValueType)
        case le(ValueType)
        case ge(ValueType)

        var type: ValueType {
            switch self {
            case let .add(type),
                 let .sub(type),
                 let .mul(type),
                 let .divS(type),
                 let .divU(type),
                 let .remS(type),
                 let .remU(type),
                 let .and(type),
                 let .or(type),
                 let .xor(type),
                 let .shl(type),
                 let .shrS(type),
                 let .shrU(type),
                 let .rotl(type),
                 let .rotr(type),
                 let .div(type),
                 let .min(type),
                 let .max(type),
                 let .copysign(type),
                 let .eq(type),
                 let .ne(type),
                 let .ltS(type),
                 let .ltU(type),
                 let .gtS(type),
                 let .gtU(type),
                 let .leS(type),
                 let .leU(type),
                 let .geS(type),
                 let .geU(type),
                 let .lt(type),
                 let .gt(type),
                 let .le(type),
                 let .ge(type):
                return type
            }
        }
    }

    // sourcery: AutoEquatable
    enum Conversion: Instruction {
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

        var types: (ValueType, ValueType) {
            switch self {
            case let .wrap(type1, type2),
                 let .extendS(type1, type2),
                 let .extendU(type1, type2),
                 let .truncS(type1, type2),
                 let .truncU(type1, type2),
                 let .convertS(type1, type2),
                 let .convertU(type1, type2),
                 let .demote(type1, type2),
                 let .promote(type1, type2),
                 let .reinterpret(type1, type2):
                return (type1, type2)
            }
        }
    }
}
