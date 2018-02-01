struct Configuration: AutoEquatable {
    let store: Store
    let thread: Thread
}

struct Thread: AutoEquatable {
    let frame: Frame
    let instructions: Expression
}

enum ExecutionError: Error {
    case unexecutable(Instruction)
    case genericError
}

protocol Executable {
    func execute(stack: inout Stack) throws
}

extension Executable {
    func execute(stack: inout Stack) throws -> Result {
        try execute(stack: &stack)
        let value = try stack.popValue()
        return Result.value(value)
    }
}

extension Expression {
    func execute(stack: inout Stack) throws {
        for instruction in instructions {
            guard let i = instruction as? Executable else {
                throw ExecutionError.unexecutable(instruction)
            }
            try i.execute(stack: &stack)
        }
    }
}

extension PseudoInstruction: Executable {
    func execute(stack _: inout Stack) throws {
        // noop
    }
}

extension NumericInstruction: Executable {
    private func execute(stack: inout Stack) throws -> Value {
        switch self {
        case let .const(value):
            return value

        case let .eqz(type):
            let v = try stack.popValue(of: type)
            return type.value(v == type.value(0) ? 1 : 0)

        case let .eq(type):
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(v2 == v1 ? 1 : 0)

        case let .ne(type):
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(v2 != v1 ? 1 : 0)

        case let .ltS(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type).signed()
            let v2 = try stack.popValue(of: type).signed()
            return type.value(try v2 < v1 ? 1 : 0)

        case let .ltU(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 < v1 ? 1 : 0)

        case let .lt(type):
            guard type.isFloat else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 < v1 ? 1 : 0)

        case let .gtS(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type).signed()
            let v2 = try stack.popValue(of: type).signed()
            return type.value(try v2 > v1 ? 1 : 0)

        case let .gtU(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 > v1 ? 1 : 0)

        case let .gt(type):
            guard type.isFloat else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 > v1 ? 1 : 0)

        case let .leS(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type).signed()
            let v2 = try stack.popValue(of: type).signed()
            return type.value(try v2 <= v1 ? 1 : 0)

        case let .leU(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 <= v1 ? 1 : 0)

        case let .le(type):
            guard type.isFloat else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 <= v1 ? 1 : 0)

        case let .geS(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type).signed()
            let v2 = try stack.popValue(of: type).signed()
            return type.value(try v2 >= v1 ? 1 : 0)

        case let .geU(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 >= v1 ? 1 : 0)

        case let .ge(type):
            guard type.isFloat else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return type.value(try v2 >= v1 ? 1 : 0)

        case let .clz(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v = try stack.popValue(of: type)
            return type.value(try v.leadingZeroBitCount())

        case let .ctz(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v = try stack.popValue(of: type)
            return type.value(try v.trailingZeroBitCount())

        case let .popcnt(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v = try stack.popValue(of: type)
            return type.value(try v.nonzeroBitCount())

        case let .add(type):
            guard type.isInteger else {
                throw ExecutionError.genericError
            }
            let v1 = try stack.popValue(of: type)
            let v2 = try stack.popValue(of: type)
            return try v1 + v2

        default:
            throw ExecutionError.genericError
        }
    }

    func execute(stack: inout Stack) throws {
        stack.push(.value(try execute(stack: &stack)))
    }
}

extension ControlInstruction: Executable {
    func execute(stack: inout Stack) throws {
        switch self {
        case let .block(_, expression):
            stack.push(.label(.empty))
            try expression.execute(stack: &stack)
        default:
            throw ExecutionError.genericError
        }
    }
}
