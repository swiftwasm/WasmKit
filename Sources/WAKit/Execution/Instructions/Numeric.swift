/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions>

extension Runtime {
    func execute(numeric instruction: NumericInstruction.Constant) throws {
        switch instruction {
        case let .const(value as I32):
            stack.push(value)
        case let .const(value as I64):
            stack.push(value)
        case let .const(value as F32):
            stack.push(value)
        case let .const(value as F64):
            stack.push(value)
        case let .const(value):
            throw Trap.invalidTypeForInstruction(type(of: value), instruction)
        }
    }

    func execute(numeric instruction: NumericInstruction.Unary) throws {
        let value = try stack.pop(instruction.type)

        let result: Value
        switch value {
        case let value as I32:
            result = try operate(I32.self, instruction, value)
        case let value as I64:
            result = try operate(I64.self, instruction, value)
        case let value as F32:
            result = try operate(F32.self, instruction, value)
        case let value as F64:
            result = try operate(F64.self, instruction, value)
        default:
            throw Trap.unimplemented("\(instruction)")
        }

        stack.push(result)
    }

    func execute(numeric instruction: NumericInstruction.Binary) throws {
        let value2 = try stack.pop(instruction.type)
        let value1 = try stack.pop(instruction.type)

        let result: Value
        switch (value1, value2) {
        case let (value1, value2) as (I32, I32):
            result = try operate(I32.self, instruction, value1, value2)
        case let (value1, value2) as (I64, I64):
            result = try operate(I64.self, instruction, value1, value2)
        case let (value1, value2) as (F32, F32):
            result = try operate(F32.self, instruction, value1, value2)
        case let (value1, value2) as (F64, F64):
            result = try operate(F64.self, instruction, value1, value2)
        default:
            throw Trap.unimplemented("\(instruction)")
        }

        stack.push(result)
    }

    func execute(numeric instruction: NumericInstruction.Conversion) throws {
        let (type1, type2) = instruction.types
        let value = try stack.pop(type1)

        let result: Value
        switch value {
        case let value as I32:
            result = try operate(I32.self, type2, instruction, value)
        case let value as I64:
            result = try operate(I64.self, type2, instruction, value)
        case let value as F32:
            result = try operate(F32.self, type2, instruction, value)
        case let value as F64:
            result = try operate(F64.self, type2, instruction, value)
        default:
            throw Trap.unimplemented("\(instruction)")
        }

        stack.push(result)
    }
}

extension Runtime {
    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _ instruction: NumericInstruction.Unary,
        _: V
    ) throws -> Value where V.RawValue: RawUnsignedInteger {
        throw Trap.unimplemented("\(instruction)")
    }

    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _ instruction: NumericInstruction.Unary,
        _: V
    ) throws -> Value where V.RawValue: RawFloatingPoint {
        throw Trap.unimplemented("\(instruction)")
    }
}

extension Runtime {
    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _ instruction: NumericInstruction.Binary,
        _ value1: V, _ value2: V
    ) throws -> Value where V.RawValue: RawUnsignedInteger {
        switch instruction {
        case .add:
            let (result, _) = value1.rawValue.addingReportingOverflow(value2.rawValue)
            return V(V.RawValue(result))
        case .sub:
            throw Trap.unimplemented("\(instruction)")
        case .mul:
            throw Trap.unimplemented("\(instruction)")
        case .divS:
            throw Trap.unimplemented("\(instruction)")
        case .divU:
            throw Trap.unimplemented("\(instruction)")
        case .remS:
            throw Trap.unimplemented("\(instruction)")
        case .remU:
            throw Trap.unimplemented("\(instruction)")
        case .and:
            throw Trap.unimplemented("\(instruction)")
        case .or:
            throw Trap.unimplemented("\(instruction)")
        case .xor:
            throw Trap.unimplemented("\(instruction)")
        case .shl:
            throw Trap.unimplemented("\(instruction)")
        case .shrS:
            throw Trap.unimplemented("\(instruction)")
        case .shrU:
            throw Trap.unimplemented("\(instruction)")
        case .rotl:
            throw Trap.unimplemented("\(instruction)")
        case .rotr:
            throw Trap.unimplemented("\(instruction)")
        case .div:
            throw Trap.unimplemented("\(instruction)")
        case .min:
            throw Trap.unimplemented("\(instruction)")
        case .max:
            throw Trap.unimplemented("\(instruction)")
        case .copysign:
            throw Trap.unimplemented("\(instruction)")
        case .eq:
            throw Trap.unimplemented("\(instruction)")
        case .ne:
            throw Trap.unimplemented("\(instruction)")
        case .ltS:
            return I32(value1.signed < value2.signed ? 1 : 0)
        case .ltU:
            throw Trap.unimplemented("\(instruction)")
        case .gtS:
            return I32(value1.signed > value2.signed ? 1 : 0)
        case .gtU:
            throw Trap.unimplemented("\(instruction)")
        case .leS:
            throw Trap.unimplemented("\(instruction)")
        case .leU:
            throw Trap.unimplemented("\(instruction)")
        case .geS:
            throw Trap.unimplemented("\(instruction)")
        case .geU:
            throw Trap.unimplemented("\(instruction)")
        case .lt:
            throw Trap.unimplemented("\(instruction)")
        case .gt:
            throw Trap.unimplemented("\(instruction)")
        case .le:
            throw Trap.unimplemented("\(instruction)")
        case .ge:
            throw Trap.unimplemented("\(instruction)")
        }
    }

    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _ instruction: NumericInstruction.Binary,
        _: V, _: V
    ) throws -> Value where V.RawValue: RawFloatingPoint {
        throw Trap.unimplemented("\(instruction)")
    }
}

extension Runtime {
    fileprivate func operate<V1: RawRepresentableValue, V2: Value>(
        _: V1.Type,
        _: V2.Type,
        _ instruction: NumericInstruction.Conversion,
        _: V1
    ) throws -> V2 {
        throw Trap.unimplemented("\(instruction)")
    }
}
