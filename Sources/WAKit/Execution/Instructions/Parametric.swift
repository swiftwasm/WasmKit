/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions>
extension Runtime {
    func execute(parametric instruction: ParametricInstruction) throws {
        switch instruction {
        case .drop:
            _ = try stack.pop(Value.self)

        case .select:
            let flag = try stack.pop(I32.self)
            let value2 = try stack.pop(Value.self)
            let value1 = try stack.pop(Value.self)
            if flag != 0 {
                stack.push(value1)
            } else {
                stack.push(value2)
            }
        }
    }
}
