/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#parametric-instructions>
extension ExecutionState {
    mutating func drop(runtime: Runtime) throws {
        _ = try stack.popValue()
    }
    mutating func select(runtime: Runtime) throws {
        try doSelect()
    }
    mutating func typedSelect(runtime: Runtime, types: [ValueType]) throws {
        try doSelect()
    }

    private mutating func doSelect() throws {
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
