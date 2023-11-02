/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
enum ParametricInstruction: Equatable {
    case drop
    case select
    case typedSelect([ValueType])

    func execute(_ stack: inout Stack) throws {
        switch self {
        case .drop:
            _ = try stack.popValue()

        case .select, .typedSelect:
            let flagValue = try stack.popValue()
            guard case let .i32(flag) = flagValue else {
                throw Trap.stackValueTypesMismatch(expected: .i32, actual: flagValue.type)
            }
            let value2 = try stack.popValue()
            let value1 = try stack.popValue()
            if flag != 0 {
                stack.push(value: value1)
            } else {
                stack.push(value: value2)
            }
        }
    }
}
