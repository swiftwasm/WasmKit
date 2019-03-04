/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions>

typealias NumericValue = Value & Numeric

extension Runtime {
    private func operate<V: Value.Int & RawRepresentable, Result>(
        _ v: V,
        operation: (V.RawValue) -> Result
    ) -> Result { return operation(v.rawValue) }

    private func operate<V: Value.Int & RawRepresentable, Result>(
        _ v1: V,
        _ v2: V,
        operation: (V.RawValue, V.RawValue) -> Result
    ) -> Result { return operation(v1.rawValue, v2.rawValue) }

    func execute(numeric instruction: NumericInstruction.Constant) throws {
        switch instruction {
        case let .const(value):
            stack.push(value)
        }
    }

    func execute(numeric instruction: NumericInstruction.Unary) throws {
        let popped = stack.pop()
        guard let value = popped as? Value else {
            throw Trap.stackTypeMismatch(expected: Value.self, actual: type(of: popped))
        }

        let result: Value

        switch (instruction, value) {
        case let (.clz(_ as Value.Int32.Type), value as Value.Int32),
             let (.ctz(_ as Value.Int32.Type), value as Value.Int32),
             let (.popcnt(_ as Value.Int32.Type), value as Value.Int32):
            result = try instruction.execute(v: value)
        case let (.clz(_ as Value.Int64.Type), value as Value.Int64),
             let (.ctz(_ as Value.Int64.Type), value as Value.Int64),
             let (.popcnt(_ as Value.Int64.Type), value as Value.Int64):
            result = try instruction.execute(v: value)
        case let (.abs(_ as Value.Float32.Type), value as Value.Float32),
             let (.neg(_ as Value.Float32.Type), value as Value.Float32),
             let (.ceil(_ as Value.Float32.Type), value as Value.Float32),
             let (.floor(_ as Value.Float32.Type), value as Value.Float32),
             let (.trunc(_ as Value.Float32.Type), value as Value.Float32),
             let (.nearest(_ as Value.Float32.Type), value as Value.Float32),
             let (.sqrt(_ as Value.Float32.Type), value as Value.Float32):
            result = try instruction.execute(v: value)
        default:
            throw Trap.unimplemented()
        }

        stack.push(result)
    }
}

extension NumericInstruction.Unary {
    func execute<V: IntValue>(v: V) throws -> V {
        switch self {
        case .clz:
            return V(V.RawValue(v.rawValue.leadingZeroBitCount))
        default:
            throw Trap.unimplemented()
        }
    }

    func execute<V: FloatValue>(v: V) throws -> V {
        switch self {
        case .abs:
            return V(V.RawValue(v.rawValue.magnitude))
        default:
            throw Trap.unimplemented()
        }
    }
}
