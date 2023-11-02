enum Instruction: Equatable {
    case control(ControlInstruction)
    case memory(MemoryInstruction)
    case numeric(NumericInstruction)
    case parametric(ParametricInstruction)
    case reference(ReferenceInstruction)
    case table(TableInstruction)
    case variable(VariableInstruction)
    case pseudo(PseudoInstruction)
}

extension Instruction: CustomStringConvertible {
    var description: String {
        switch self {
        case let .numeric(n):
            return n.description
        case let .variable(v):
            return v.description
        case let .control(c):
            return String(reflecting: c)
        case let .pseudo(p):
            return String(reflecting: p)
        case let .memory(m):
            return String(reflecting: m)
        case let .parametric(p):
            return String(reflecting: p)
        case let .reference(r):
            return String(reflecting: r)
        case let .table(t):
            return String(reflecting: t)
        }
    }
}
