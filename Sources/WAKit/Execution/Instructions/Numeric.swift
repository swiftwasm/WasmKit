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
            throw Trap.unimplemented()
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
            throw Trap.unimplemented()
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
            throw Trap.unimplemented()
        }

        stack.push(result)
    }
}

extension Runtime {
    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _: NumericInstruction.Unary,
        _: V
    ) throws -> Value where V.RawValue: RawUnsignedInteger {
        throw Trap.unimplemented()
    }

    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _: NumericInstruction.Unary,
        _: V
    ) throws -> Value where V.RawValue: RawFloatingPoint {
        throw Trap.unimplemented()
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
            throw Trap.unimplemented()
        case .mul:
            throw Trap.unimplemented()
        case .divS:
            throw Trap.unimplemented()
        case .divU:
            throw Trap.unimplemented()
        case .remS:
            throw Trap.unimplemented()
        case .remU:
            throw Trap.unimplemented()
        case .and:
            throw Trap.unimplemented()
        case .or:
            throw Trap.unimplemented()
        case .xor:
            throw Trap.unimplemented()
        case .shl:
            throw Trap.unimplemented()
        case .shrS:
            throw Trap.unimplemented()
        case .shrU:
            throw Trap.unimplemented()
        case .rotl:
            throw Trap.unimplemented()
        case .rotr:
            throw Trap.unimplemented()
        case .div:
            throw Trap.unimplemented()
        case .min:
            throw Trap.unimplemented()
        case .max:
            throw Trap.unimplemented()
        case .copysign:
            throw Trap.unimplemented()
        case .eq:
            throw Trap.unimplemented()
        case .ne:
            throw Trap.unimplemented()
        case .ltS:
            return I32(value1.signed < value2.signed ? 1 : 0)
        case .ltU:
            throw Trap.unimplemented()
        case .gtS:
            return I32(value1.signed > value2.signed ? 1 : 0)
        case .gtU:
            throw Trap.unimplemented()
        case .leS:
            throw Trap.unimplemented()
        case .leU:
            throw Trap.unimplemented()
        case .geS:
            throw Trap.unimplemented()
        case .geU:
            throw Trap.unimplemented()
        case .lt:
            throw Trap.unimplemented()
        case .gt:
            throw Trap.unimplemented()
        case .le:
            throw Trap.unimplemented()
        case .ge:
            throw Trap.unimplemented()
        }
    }

    fileprivate func operate<V: RawRepresentableValue>(
        _: V.Type,
        _: NumericInstruction.Binary,
        _: V, _: V
    ) throws -> Value where V.RawValue: RawFloatingPoint {
        throw Trap.unimplemented()
    }
}

extension Runtime {
    fileprivate func operate<V1: RawRepresentableValue, V2: Value>(
        _: V1.Type,
        _: V2.Type,
        _: NumericInstruction.Conversion,
        _: V1
    ) throws -> V2 {
        throw Trap.unimplemented()
    }
}
