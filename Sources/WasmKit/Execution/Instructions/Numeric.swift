/// > Note:
/// <https://webassembly.github.io/spec/core/exec/instructions.html#numeric-instructions>
extension ExecutionState {
    @inline(__always)
    mutating func const32(sp: Sp, const32Operand: Instruction.Const32Operand) {
        sp[const32Operand.result] = UntypedValue(storage32: const32Operand.value)
    }
    @inline(__always)
    mutating func const64(sp: Sp, pc: Pc, const64Operand: Instruction.Const64Operand) -> Pc {
        sp[VReg(const64Operand.result)] = const64Operand.value
        return pc
    }

    mutating func numericConversion(sp: Sp, conversionOperand: Instruction.ConversionOperand) throws {
        let value = sp[conversionOperand.unary.input]
        sp[conversionOperand.unary.result] = UntypedValue(try conversionOperand.operation(value))
    }
}

enum NumericInstruction {}

/// Numeric Instructions
extension NumericInstruction {
    public enum Conversion: Equatable {
        case truncSaturatingSigned(IntValueType, FloatValueType)
        case truncSaturatingUnsigned(IntValueType, FloatValueType)
        case convertSigned(FloatValueType, IntValueType)
        case convertUnsigned(FloatValueType, IntValueType)
        case demote
        case promote
        case reinterpret(NumericType, NumericType)

        func callAsFunction(
            _ value: UntypedValue
        ) throws -> Value {
            switch self {
            case let .truncSaturatingSigned(target, source):
                switch (target, source) {
                case (.i32, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int32.max) > rawValue else {
                            return .i32(Int32.max.unsigned)
                        }

                        guard rawValue >= Float32(Int32.min) else {
                            return .i32(Int32.min.unsigned)
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case (.i32, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = Int32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int32.max) > rawValue else {
                            return .i32(Int32.max.unsigned)
                        }

                        guard rawValue >= Float64(Int32.min) else {
                            return .i32(Int32.min.unsigned)
                        }
                        return .i32(Int32(rawValue).unsigned)
                    }

                    return .i32(result.unsigned)

                case (.i64, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(Int64.max) > rawValue else {
                            return .i64(Int64.max.unsigned)
                        }

                        guard rawValue >= Float32(Int64.min) else {
                            return .i64(Int64.min.unsigned)
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)

                case (.i64, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = Int64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(Int64.max) > rawValue else {
                            return .i64(Int64.max.unsigned)
                        }

                        guard rawValue >= Float64(Int64.min) else {
                            return .i64(Int64.min.unsigned)
                        }
                        return .i64(Int64(rawValue).unsigned)
                    }

                    return .i64(result.unsigned)
                }

            case let .truncSaturatingUnsigned(target, source):
                switch (target, source) {
                case (.i32, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt32.max) > rawValue else {
                            return .i32(UInt32.max)
                        }

                        guard rawValue >= Float32(UInt32.min) else {
                            return .i32(UInt32.min)
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return .i32(result)

                case (.i32, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i32(0) }
                    guard let result = UInt32(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt32.max) > rawValue else {
                            return .i32(UInt32.max)
                        }

                        guard rawValue >= Float64(UInt32.min) else {
                            return .i32(UInt32.min)
                        }
                        return .i32(UInt32(rawValue))
                    }

                    return .i32(result)

                case (.i64, .f32):
                    var rawValue = Float32(bitPattern: value.rawF32)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float32(UInt64.max) > rawValue else {
                            return .i64(UInt64.max)
                        }

                        guard rawValue >= Float32(UInt64.min) else {
                            return .i64(UInt64.min)
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return .i64(result)

                case (.i64, .f64):
                    var rawValue = Float64(bitPattern: value.rawF64)
                    guard !rawValue.isNaN else { return .i64(0) }
                    guard let result = UInt64(exactly: rawValue) else {
                        rawValue.round(.towardZero)
                        guard Float64(UInt64.max) > rawValue else {
                            return .i64(UInt64.max)
                        }

                        guard rawValue >= Float64(UInt64.min) else {
                            return .i64(UInt64.min)
                        }
                        return .i64(UInt64(rawValue))
                    }

                    return .i64(result)
                }

            case let .convertSigned(target, source):
                switch (target, source) {
                case (.f32, .i32):
                    return .fromFloat32(Float32(value.i32.signed))

                case (.f32, .i64):
                    return .fromFloat32(Float32(value.i64.signed))

                case (.f64, .i32):
                    return .fromFloat64(Float64(value.i32.signed))

                case (.f64, .i64):
                    return .fromFloat64(Float64(value.rawF64.signed))
                }

            case let .convertUnsigned(target, source):
                switch (target, source) {
                case (.f32, .i32):
                    return .fromFloat32(Float32(value.i32))

                case (.f32, .i64):
                    return .fromFloat32(Float32(value.i64))

                case (.f64, .i32):
                    return .fromFloat64(Float64(value.i32))

                case (.f64, .i64):
                    return .fromFloat64(Float64(value.i64))
                }

            case .demote:
                return .fromFloat32(Float32(Float64(bitPattern: value.rawF64)))
            case .promote:
                return .fromFloat64(Float64(Float32(bitPattern: value.rawF32)))
            case let .reinterpret(target, source):
                switch (target, source) {
                case (.int(.i32), .f32):
                    return .i32(value.rawF32)

                case (.int(.i64), .f64):
                    return .i64(value.rawF64)

                case (.float(.f32), .i32):
                    return .f32(value.i32)

                case (.float(.f64), .i64):
                    return .f64(value.i64)
                default:
                    fatalError("unsupported operand types passed to instruction \(self)")
                }
            }
        }
    }
}
