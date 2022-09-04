/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions>

extension InstructionFactory {
    func const<V: RawRepresentableValue>(_ value: V) -> Instruction {
        makeInstruction { pc, _, stack in
            stack.push(value)
            return .jump(pc + 1)
        }
    }

    func numeric(unary instruction: NumericInstruction.Unary) -> Instruction {
        makeInstruction { pc, _, stack in
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
                fatalError("Invalid type \(value) for instruction \(instruction)")
            }

            stack.push(result)
            return .jump(pc + 1)
        }
    }

    func numeric(binary instruction: NumericInstruction.Binary) -> Instruction {
        makeInstruction { pc, _, stack in
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
                fatalError("Invalid types \(value1) and \(value2) for instruction \(instruction)")
            }

            stack.push(result)
            return .jump(pc + 1)
        }
    }

    func numeric(conversion instruction: NumericInstruction.Conversion) -> Instruction {
        makeInstruction { pc, _, stack in
            let (type1, type2) = instruction.types
            let value = try stack.pop(type1)

            let result = try operate(type1, type2, instruction, value)

            stack.push(result)
            return .jump(pc + 1)
        }
    }
}

fileprivate func operate<V: RawRepresentableValue>(
    _ type: V.Type,
    _ instruction: NumericInstruction.Unary,
    _ value: V
) throws -> Value where V.RawValue: RawUnsignedInteger {
    switch instruction {
    case .clz:
        return V(V.RawValue(value.rawValue.leadingZeroBitCount))
    case .ctz:
        return V(V.RawValue(value.rawValue.trailingZeroBitCount))
    case .popcnt:
        return V(V.RawValue(value.rawValue.nonzeroBitCount))

    case .eqz:
        return value.rawValue == 0 ? I32(1) : I32(0)
    default:
        fatalError("Invalid type \(type) for instruction \(instruction)")
    }
}

fileprivate func operate<V: RawRepresentableValue>(
    _ type: V.Type,
    _ instruction: NumericInstruction.Unary,
    _ value: V
) throws -> Value where V.RawValue: RawFloatingPoint {
    let result: V.RawValue
    switch instruction {
    case .abs:
        result = abs(value.rawValue)
    case .neg:
        result = -value.rawValue
    case .ceil:
        result = abs(value.rawValue.nextUp)
    case .floor:
        result = abs(value.rawValue.nextDown)
    case .trunc:
        result = abs(value.rawValue.rounded(.towardZero))
    case .nearest:
        result = abs(value.rawValue.rounded(.toNearestOrEven))
    case .sqrt:
        result = value.rawValue.squareRoot()

    default:
        fatalError("Invalid type \(type) for instruction \(instruction)")
    }
    return V(result)
}

fileprivate func operate<V: RawRepresentableValue>(
    _ type: V.Type,
    _ instruction: NumericInstruction.Binary,
    _ value1: V, _ value2: V
) throws -> Value where V.RawValue: RawUnsignedInteger {
    switch instruction {
    case .add:
        return V(value1.rawValue &+ value2.rawValue)
    case .sub:
        return V(value1.rawValue &- value2.rawValue)
    case .mul:
        return V(value1.rawValue &* value2.rawValue)

    case .eq:
        return value1.rawValue == value2.rawValue ? I32(1) : I32(0)
    case .ne:
        return value1.rawValue != value2.rawValue ? I32(1) : I32(0)

    case .divS:
        guard value2 != 0 else { throw Trap.integerDividedByZero }
        let (signed, overflow) = value1.signed.dividedReportingOverflow(by: value2.signed)
        guard !overflow else { throw Trap.integerOverflowed }
        return V(signed.unsigned)
    case .divU:
        guard value2 != 0 else { throw Trap.integerDividedByZero }
        let (result, overflow) = value1.rawValue.dividedReportingOverflow(by: value2.rawValue)
        guard !overflow else { throw Trap.integerOverflowed }
        return V(result)
    case .remS:
        guard value2 != 0 else { throw Trap.integerDividedByZero }
        let (signed, overflow) = value1.signed.remainderReportingOverflow(dividingBy: value2.signed)
        guard !overflow else { throw Trap.integerOverflowed }
        return V(signed.unsigned)
    case .remU:
        guard value2 != 0 else { throw Trap.integerDividedByZero }
        let (result, overflow) = value1.rawValue.remainderReportingOverflow(dividingBy: value2.rawValue)
        guard !overflow else { throw Trap.integerOverflowed }
        return V(result)
    case .and:
        return V(value1.rawValue & value2.rawValue)
    case .or:
        return V(value1.rawValue | value2.rawValue)
    case .xor:
        return V(value1.rawValue ^ value2.rawValue)
    case .shl:
        let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
        return V(value1.rawValue << shift)
    case .shrS:
        let shift = value2.signed % V.RawValue.Signed(V.RawValue.Signed.bitWidth)
        return V((value1.signed >> shift).unsigned)
    case .shrU:
        let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
        return V(value1.rawValue >> shift)
    case .rotl:
        let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
        return V(value1.rawValue.rotl(shift))
    case .rotr:
        let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
        return V(value1.rawValue.rotr(shift))

    case .ltS:
        return value1.signed < value2.signed ? I32(1) : I32(0)
    case .ltU:
        return value1.rawValue < value2.rawValue ? I32(1) : I32(0)
    case .gtS:
        return value1.signed > value2.signed ? I32(1) : I32(0)
    case .gtU:
        return value1.rawValue > value2.rawValue ? I32(1) : I32(0)
    case .leS:
        return value1.signed <= value2.signed ? I32(1) : I32(0)
    case .leU:
        return value1.rawValue <= value2.rawValue ? I32(1) : I32(0)
    case .geS:
        return value1.signed >= value2.signed ? I32(1) : I32(0)
    case .geU:
        return value1.rawValue >= value2.rawValue ? I32(1) : I32(0)

    default:
        fatalError("Invalid type \(type) for instruction \(instruction)")
    }
}

fileprivate func operate<V: RawRepresentableValue>(
    _ type: V.Type,
    _ instruction: NumericInstruction.Binary,
    _ value1: V, _ value2: V
) throws -> Value where V.RawValue: RawFloatingPoint {
    switch instruction {
    case .add:
        return V(value1.rawValue + value2.rawValue)
    case .sub:
        return V(value1.rawValue - value2.rawValue)
    case .mul:
        return V(value1.rawValue * value2.rawValue)

    case .eq:
        return value1.rawValue == value2.rawValue ? I32(1) : I32(0)
    case .ne:
        return value1.rawValue == value2.rawValue ? I32(0) : I32(1)

    case .div:
        guard value2 != 0 else { throw Trap.integerDividedByZero }
        return V(value1.rawValue / value2.rawValue)
    case .min:
        return V(min(value1.rawValue, value2.rawValue))
    case .max:
        return V(max(value1.rawValue, value2.rawValue))
    case .copysign:
        return V(value1.rawValue.sign == value2.rawValue.sign ? value1.rawValue : -value1.rawValue)
    case .lt:
        return value1.rawValue < value2.rawValue ? I32(1) : I32(0)
    case .gt:
        return value1.rawValue > value2.rawValue ? I32(1) : I32(0)
    case .le:
        return value1.rawValue <= value2.rawValue ? I32(1) : I32(0)
    case .ge:
        return value1.rawValue >= value2.rawValue ? I32(1) : I32(0)

    default:
        fatalError("Invalid type \(type) for instruction \(instruction)")
    }
}

fileprivate func operate<Source: Value, Target: Value>(
    _ target: Source.Type,
    _ source: Target.Type,
    _ instruction: NumericInstruction.Conversion,
    _ value: Source
) throws -> Value {
    switch instruction {
    case .truncS:
        switch value {
        case let value as F32 where target is I32.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I32(Int32(value.rawValue))
        case let value as F64 where target is I32.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I32(Int32(value.rawValue))
        case let value as F32 where target is I64.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I64(Int64(value.rawValue))
        case let value as F64 where target is I64.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I64(Int64(value.rawValue))
        default:
            fatalError("unsupported operand types passed to truncS")
        }

    case .truncU:
        switch value {
        case let value as F32 where target is I32.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I32(UInt32(value.rawValue))
        case let value as F64 where target is I32.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I32(UInt32(value.rawValue))
        case let value as F32 where target is I64.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I64(UInt64(value.rawValue))
        case let value as F64 where target is I64.Type:
            guard !value.rawValue.isNaN else {
                throw Trap.invalidConversionToInteger
            }
            return I64(UInt64(value.rawValue))
        default:
            fatalError("unsupported operand types passed to truncS")
        }
        
    default:
        throw Trap.unimplemented("\(instruction)")
    }
}
