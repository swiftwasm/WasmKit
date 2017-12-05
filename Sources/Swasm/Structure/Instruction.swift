public struct Expression {
    let instructions: [Instruction]

    init(instructions: [Instruction] = []) {
        self.instructions = instructions
    }
}

extension Expression: Equatable {
    public static func == (lhs: Expression, rhs: Expression) -> Bool {
        guard lhs.instructions.count == rhs.instructions.count else { return false }
        return zip(lhs.instructions, rhs.instructions)
            .map { l, r in l.isEqual(to: r) }
            .reduce(true) { $0 && $1 }
    }
}

public protocol Instruction {
    var isConstant: Bool { get }

    func isEqual(to another: Instruction) -> Bool
}

/// Pseudo Instructions
public enum PseudoInstruction: Instruction {
    case end

    public var isConstant: Bool {
        return false
    }

    public func isEqual(to another: Instruction) -> Bool {
        switch (self, another) {
        case (.end, PseudoInstruction.end): return true
        default: return false
        }
    }
}

/// Control Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#control-instructions
public enum ControlInstruction: Instruction {
    case unreachable
    case nop
    case block(ResultType, [Instruction])
    case loop(ResultType, [Instruction])
    case `if`(ResultType, [Instruction], [Instruction])
    case br(LabelIndex)
    case brIf(LabelIndex)
    case brTable([LabelIndex])
    case `return`
    case call(FunctionIndex)
    case callIndirect(TypeIndex)

    public var isConstant: Bool {
        return false
    }

    public func isEqual(to another: Instruction) -> Bool {
        switch (self, another) {
        case (.unreachable, ControlInstruction.unreachable),
             (.nop, ControlInstruction.nop):
            return true
        case let (.block(l1, l2), ControlInstruction.block(r1, r2)),
             let (.loop(l1, l2), ControlInstruction.loop(r1, r2)):
            return l1 == r1 && Expression(instructions: l2) == Expression(instructions: r2)
        case let (.if(l1, l2, l3), ControlInstruction.if(r1, r2, r3)):
            return l1 == r1 &&
                Expression(instructions: l2) == Expression(instructions: r2) &&
                Expression(instructions: l3) == Expression(instructions: r3)
        case let (.br(l), ControlInstruction.br(r)),
             let (.brIf(l), ControlInstruction.brIf(r)):
            return l == r
        case let (.brTable(l), ControlInstruction.brTable(r)):
            return l == r
        case (.return, ControlInstruction.return):
            return true
        case let (.call(l), ControlInstruction.call(r)),
             let (.callIndirect(l), ControlInstruction.callIndirect(r)):
            return l == r
        default:
            return false
        }
    }
}

/// Parametric Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#parametric-instructions
public enum ParametricInstruction: Instruction {
    case drop
    case select

    public var isConstant: Bool {
        return false
    }

    public func isEqual(to another: Instruction) -> Bool {
        switch (self, another) {
        case (.drop, ParametricInstruction.drop),
             (.select, ParametricInstruction.select):
            return true
        default:
            return false
        }
    }
}

/// Variable Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#variable-instructions
public enum VariableInstruction: Instruction {
    case getLocal(LabelIndex)
    case setLocal(LabelIndex)
    case teeLocal(LabelIndex)
    case getGlobal(GlobalIndex)
    case setGlobal(GlobalIndex)

    public var isConstant: Bool {
        return false
    }

    public func isEqual(to another: Instruction) -> Bool {
        switch (self, another) {
        case let (.getLocal(l), VariableInstruction.getLocal(r)),
             let (.setLocal(l), VariableInstruction.setLocal(r)),
             let (.teeLocal(l), VariableInstruction.teeLocal(r)),
             let (.getGlobal(l), VariableInstruction.getGlobal(r)),
             let (.setGlobal(l), VariableInstruction.setGlobal(r)):
            return l == r
        default:
            return false
        }
    }
}

/// Memory Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#memory-instructions
public enum MemoryInstruction: Instruction {
    public typealias MemoryArgument = (UInt32, UInt32)

    case currentMemory
    case growMemory
}

public extension MemoryInstruction {
    enum i32: Instruction {
        case load(MemoryArgument)
        case load8s(MemoryArgument)
        case load8u(MemoryArgument)
        case load16s(MemoryArgument)
        case load16u(MemoryArgument)
        case store(MemoryArgument)
        case store8(MemoryArgument)
        case store16(MemoryArgument)

        public var isConstant: Bool {
            return false
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.load(l), i32.load(r)),
                 let (.load8s(l), i32.load8s(r)),
                 let (.load8u(l), i32.load8u(r)),
                 let (.load16s(l), i32.load16s(r)),
                 let (.load16u(l), i32.load16u(r)),
                 let (.store(l), i32.store(r)),
                 let (.store8(l), i32.store8(r)),
                 let (.store16(l), i32.store16(r)):
                return l == r
            default:
                return false
            }
        }
    }
}

public extension MemoryInstruction {
    enum i64: Instruction {
        case load(MemoryArgument)
        case load8s(MemoryArgument)
        case load8u(MemoryArgument)
        case load16s(MemoryArgument)
        case load16u(MemoryArgument)
        case load32s(MemoryArgument)
        case load32u(MemoryArgument)
        case store(MemoryArgument)
        case store8(MemoryArgument)
        case store16(MemoryArgument)
        case store32(MemoryArgument)

        public var isConstant: Bool {
            return false
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.load(l), i64.load(r)),
                 let (.load8s(l), i64.load8s(r)),
                 let (.load8u(l), i64.load8u(r)),
                 let (.load16s(l), i64.load16s(r)),
                 let (.load16u(l), i64.load16u(r)),
                 let (.store(l), i64.store(r)),
                 let (.store8(l), i64.store8(r)),
                 let (.store16(l), i64.store16(r)):
                return l == r
            default:
                return false
            }
        }
    }
}

public extension MemoryInstruction {
    enum f32: Instruction {
        case load(MemoryArgument)
        case store(MemoryArgument)

        public var isConstant: Bool {
            return false
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.load(l), f32.load(r)),
                 let (.store(l), f32.store(r)):
                return l == r
            default:
                return false
            }
        }
    }
}

public extension MemoryInstruction {
    enum f64: Instruction {
        case load(MemoryArgument)
        case store(MemoryArgument)

        public var isConstant: Bool {
            return false
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.load(l), f64.load(r)),
                 let (.store(l), f64.store(r)):
                return l == r
            default:
                return false
            }
        }
    }

    var isConstant: Bool {
        return false
    }

    func isEqual(to another: Instruction) -> Bool {
        switch (self, another) {
        case (.currentMemory, MemoryInstruction.currentMemory),
             (.growMemory, MemoryInstruction.growMemory):
            return true
        default:
            return false
        }
    }
}

/// Numeric Instructions
/// - SeeAlso: https://webassembly.github.io/spec/binary/instructions.html#numeric-instructions
public enum NumericInstruction {
}

public extension NumericInstruction {
    enum i32: Instruction {
        case const(Int32)

        case eqz
        case eq
        case ne
        case ltS
        case ltU
        case gtS
        case gtU
        case leS
        case leU
        case geS
        case geU

        case clz
        case ctz
        case popcnt
        case add
        case sub
        case mul
        case divS
        case divU
        case remS
        case remU
        case and
        case or
        case xor
        case shl
        case shrS
        case shrU
        case rotl
        case rotr

        case wrapI64
        case truncSF32
        case truncUF32
        case truncSF64
        case truncUF64
        case reinterpretF32

        public var isConstant: Bool {
            return true
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.const(l), i32.const(r)):
                return l == r
            case (.eqz, i32.eqz),
                 (.eq, i32.eq),
                 (.ne, i32.ne),
                 (.ltS, i32.ltS),
                 (.ltU, i32.ltU),
                 (.gtS, i32.gtS),
                 (.gtU, i32.gtU),
                 (.leS, i32.leS),
                 (.leU, i32.leU),
                 (.geS, i32.geS),
                 (.geU, i32.geU),

                 (.clz, i32.clz),
                 (.ctz, i32.ctz),
                 (.popcnt, i32.popcnt),
                 (.add, i32.add),
                 (.sub, i32.sub),
                 (.mul, i32.mul),
                 (.divS, i32.divS),
                 (.divU, i32.divU),
                 (.remS, i32.remS),
                 (.remU, i32.remU),
                 (.and, i32.and),
                 (.or, i32.or),
                 (.xor, i32.xor),
                 (.shl, i32.shl),
                 (.shrS, i32.shrS),
                 (.shrU, i32.shrU),
                 (.rotl, i32.rotl),
                 (.rotr, i32.rotr),

                 (.wrapI64, i32.wrapI64),
                 (.truncSF32, i32.truncSF32),
                 (.truncUF32, i32.truncUF32),
                 (.truncSF64, i32.truncSF64),
                 (.truncUF64, i32.truncUF64),
                 (.reinterpretF32, i32.reinterpretF32):
                return true
            default:
                return false
            }
        }
    }
}

public extension NumericInstruction {
    enum i64: Instruction {
        case const(Int64)
        case eqz
        case eq
        case ne
        case ltS
        case ltU
        case gtS
        case gtU
        case leS
        case leU
        case geS
        case geU

        case clz
        case ctz
        case popcnt
        case add
        case sub
        case mul
        case divS
        case divU
        case remS
        case remU
        case and
        case or
        case xor
        case shl
        case shrS
        case shrU
        case rotl
        case rotr

        case wrapI64
        case extendSI32
        case extendUI32
        case truncSF32
        case truncUF32
        case truncSF64
        case truncUF64
        case reinterpretF64

        public var isConstant: Bool {
            return true
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.const(l), i64.const(r)):
                return l == r
            case (.eqz, i64.eqz),
                 (.eq, i64.eq),
                 (.ne, i64.ne),
                 (.ltS, i64.ltS),
                 (.ltU, i64.ltU),
                 (.gtS, i64.gtS),
                 (.gtU, i64.gtU),
                 (.leS, i64.leS),
                 (.leU, i64.leU),
                 (.geS, i64.geS),
                 (.geU, i64.geU),

                 (.clz, i64.clz),
                 (.ctz, i64.ctz),
                 (.popcnt, i64.popcnt),
                 (.add, i64.add),
                 (.sub, i64.sub),
                 (.mul, i64.mul),
                 (.divS, i64.divS),
                 (.divU, i64.divU),
                 (.remS, i64.remS),
                 (.remU, i64.remU),
                 (.and, i64.and),
                 (.or, i64.or),
                 (.xor, i64.xor),
                 (.shl, i64.shl),
                 (.shrS, i64.shrS),
                 (.shrU, i64.shrU),
                 (.rotl, i64.rotl),
                 (.rotr, i64.rotr),

                 (.wrapI64, i64.wrapI64),
                 (.truncSF32, i64.truncSF32),
                 (.truncUF32, i64.truncUF32),
                 (.truncSF64, i64.truncSF64),
                 (.truncUF64, i64.truncUF64),
                 (.reinterpretF64, i64.reinterpretF64):
                return true
            default:
                return false
            }
        }
    }
}

public extension NumericInstruction {
    enum f32: Instruction {
        case const(Float32)
        case eq
        case ne
        case lt
        case gt
        case le
        case ge

        case abs
        case neg
        case ceil
        case floor
        case trunc
        case nearest
        case sqrt
        case add
        case sub
        case mul
        case div
        case min
        case max
        case copysign

        case convertSI32
        case convertUI32
        case convertSI64
        case convertUI64
        case demoteF64
        case reinterpretI32

        public var isConstant: Bool {
            return true
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.const(l), f32.const(r)):
                return l == r
            case (.eq, f32.eq),
                 (.ne, f32.ne),
                 (.lt, f32.lt),
                 (.gt, f32.gt),
                 (.le, f32.le),
                 (.ge, f32.ge),

                 (.abs, f32.abs),
                 (.neg, f32.neg),
                 (.ceil, f32.ceil),
                 (.floor, f32.floor),
                 (.trunc, f32.trunc),
                 (.nearest, f32.nearest),
                 (.sqrt, f32.sqrt),
                 (.add, f32.add),
                 (.sub, f32.sub),
                 (.mul, f32.mul),
                 (.div, f32.div),
                 (.min, f32.min),
                 (.max, f32.max),
                 (.copysign, f32.copysign),

                 (.convertSI32, f32.convertSI32),
                 (.convertUI32, f32.convertUI32),
                 (.convertSI64, f32.convertSI64),
                 (.convertUI64, f32.convertUI64),
                 (.demoteF64, f32.demoteF64),
                 (.reinterpretI32, f32.reinterpretI32):
                return true
            default:
                return false
            }
        }
    }
}

public extension NumericInstruction {
    enum f64: Instruction {
        case const(Float64)
        case eq
        case ne
        case lt
        case gt
        case le
        case ge

        case abs
        case neg
        case ceil
        case floor
        case trunc
        case nearest
        case sqrt
        case add
        case sub
        case mul
        case div
        case min
        case max
        case copysign

        case convertSI32
        case convertUI32
        case convertSI64
        case convertUI64
        case promoteF32
        case reinterpretI64

        public var isConstant: Bool {
            return true
        }

        public func isEqual(to another: Instruction) -> Bool {
            switch (self, another) {
            case let (.const(l), f64.const(r)):
                return l == r
            case (.eq, f64.eq),
                 (.ne, f64.ne),
                 (.lt, f64.lt),
                 (.gt, f64.gt),
                 (.le, f64.le),
                 (.ge, f64.ge),

                 (.abs, f64.abs),
                 (.neg, f64.neg),
                 (.ceil, f64.ceil),
                 (.floor, f64.floor),
                 (.trunc, f64.trunc),
                 (.nearest, f64.nearest),
                 (.sqrt, f64.sqrt),
                 (.add, f64.add),
                 (.sub, f64.sub),
                 (.mul, f64.mul),
                 (.div, f64.div),
                 (.min, f64.min),
                 (.max, f64.max),
                 (.copysign, f64.copysign),

                 (.convertSI32, f64.convertSI32),
                 (.convertUI32, f64.convertUI32),
                 (.convertSI64, f64.convertSI64),
                 (.convertUI64, f64.convertUI64),
                 (.promoteF32, f64.promoteF32),
                 (.reinterpretI64, f64.reinterpretI64):
                return true
            default:
                return false
            }
        }
    }
}
