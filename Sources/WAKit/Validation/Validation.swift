struct ValidationError: Error {
    let diagnostic: String
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/conventions.html#contexts>
public protocol ValidationContext {
    func type(index: TypeIndex) -> FunctionType
    func functionType(index: FunctionIndex) -> FunctionType
    func tableType(index: TableIndex) -> TableType
    func memoryType(index: MemoryIndex) -> MemoryType
    func globalType(index: GlobalIndex) -> GlobalType
}

extension Module: ValidationContext {
    public func type(index: TypeIndex) -> FunctionType {
        return types[Int(index)]
    }

    public func functionType(index: FunctionIndex) -> FunctionType {
        let typeIndex = functions[Int(index)].type
        return types[Int(typeIndex)]
    }

    public func tableType(index: TableIndex) -> TableType {
        return tables[Int(index)].type
    }

    public func memoryType(index: MemoryIndex) -> MemoryType {
        return memories[Int(index)].type
    }

    public func globalType(index: GlobalIndex) -> GlobalType {
        return globals[Int(index)].type
    }
}

public protocol Validatable {
    func validate(context: ValidationContext) throws
}

extension Module: Validatable {
    public func validate(context: ValidationContext) throws {
        for function in functions {
            try function.validate(context: context)
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#types>

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#limits>
extension Limits: Validatable {
    public func validate(context _: ValidationContext) throws {
        if let max = max {
            guard min < max else {
                throw ValidationError(diagnostic: "size minimum must not be greater than maximum")
            }
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#function-types>
extension FunctionType: Validatable {
    public func validate(context _: ValidationContext) throws {
        guard results.count <= 1 else {
            throw ValidationError(diagnostic: "func type returns multiple values but the multi-value feature is not enabled")
        }
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#table-types>
extension TableType: Validatable {
    public func validate(context: ValidationContext) throws {
        try limits.validate(context: context)
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/types.html#global-types>
extension GlobalType: Validatable {
    public func validate(context _: ValidationContext) throws {}
}

extension Function: Validatable {
    public func validate(context: ValidationContext) throws {
        try body.validate(functionType: context.type(index: type), context: context)
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/instructions.html#instructions>

/// - Note:
/// <https://webassembly.github.io/spec/core/valid/instructions.html#expressions>
extension Expression {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/valid/instructions.html#instruction-sequences>
    func validate(functionType: FunctionType, context: ValidationContext) throws {
        var validator = ExpressionValidator(functionType: functionType)
        for instruction in instructions {
            try instruction.validator(&validator, instruction, context)
        }
    }
}

struct ExpressionValidator {
    struct ControlFrame {
        let opcode: InstructionCode
        let startTypes: [ValueType]
        let endTypes: [ValueType]
        /// the height of the operand stack at the start of the block (used to check that operands do not underflow the current block)
        let height: Int
        /// a flag recording whether the remainder of the block is unreachable (used to handle stack-polymorphic typing after branches).
        var unreachable: Bool
    }

    enum ValueTypeOrUnknown: Equatable {
        case known(ValueType)
        case unknown

        static func == (lhs: ValueTypeOrUnknown, rhs: ValueTypeOrUnknown) -> Bool {
            switch (lhs, rhs) {
            case let (.known(lhs), .known(rhs)):
                return lhs === rhs
            case (.unknown, .unknown):
                return true
            default:
                return false
            }
        }
    }

    private var valueStack: [ValueTypeOrUnknown] = []
    private(set) var controlStack: [ControlFrame]
    private var noKnownValue: Bool {
        // The height of value stack reached the height at the start of the block
        // No value in the current control frame
        return valueStack.count == controlStack.last!.height
    }

    private(set) var `return`: ResultType

    init(functionType: FunctionType) {
        self.return = functionType.results
        controlStack = [
            ControlFrame(
                opcode: .block,
                startTypes: functionType.parameters,
                endTypes: functionType.results,
                height: 0,
                unreachable: false
            ),
        ]
    }

    mutating func popValue(typeHint: ValueTypeOrUnknown? = nil) throws -> ValueTypeOrUnknown {
        if noKnownValue, controlStack[0].unreachable {
            return .unknown
        }
        guard !noKnownValue else {
            throw ValidationError(diagnostic: "type mismatch: expected \(typeHint.map(String.init(describing:)) ?? "something") but nothing on stack")
        }
        return valueStack.popLast()!
    }

    @discardableResult
    mutating func popValue(_ expect: ValueTypeOrUnknown) throws -> ValueTypeOrUnknown {
        let actual = try popValue()
        guard actual == expect || actual == .unknown || expect == .unknown else {
            throw ValidationError(diagnostic: "type mismatch: expected \(expect), found \(actual)")
        }
        return actual
    }

    @discardableResult
    mutating func popValue(_ expect: ValueType) throws -> ValueTypeOrUnknown {
        return try popValue(.known(expect))
    }

    @discardableResult
    mutating func popValues(_ types: [ValueType]) throws -> [ValueType] {
        for type in types.reversed() {
            _ = try popValue(.known(type))
        }
        return types
    }

    mutating func pushValue(_ type: ValueType) {
        pushValue(.known(type))
    }

    mutating func pushValue(_ type: ValueTypeOrUnknown) {
        valueStack.append(type)
    }

    mutating func pushValues(_ types: [ValueTypeOrUnknown]) {
        valueStack.append(contentsOf: types)
    }

    mutating func pushValues(_ types: [ValueType]) {
        valueStack.append(contentsOf: types.map(ValueTypeOrUnknown.known))
    }

    mutating func pushControlFrame(opcode: InstructionCode, input: [ValueType], output: [ValueType]) {
        let frame = ControlFrame(
            opcode: opcode, startTypes: input, endTypes: output,
            height: valueStack.count, unreachable: false
        )
        controlStack.append(frame)
        pushValues(input.map(ValueTypeOrUnknown.known))
    }

    mutating func popControlFrame() throws -> ControlFrame {
        guard let frame = controlStack.popLast() else {
            throw ValidationError(diagnostic: "too much control frame pops")
        }
        try popValues(frame.endTypes)
        guard valueStack.count == frame.height else {
            throw ValidationError(diagnostic: "type mismatch: values remaining on stack at end of block")
        }
        return frame
    }

    func labelTypes(frame: ControlFrame) -> [ValueType] {
        if frame.opcode == .loop {
            return frame.startTypes
        } else {
            return frame.endTypes
        }
    }

    mutating func unreachable() {
        var frame = controlStack[controlStack.count - 1]
        valueStack.removeLast(valueStack.count - frame.height)
        frame.unreachable = true
        controlStack[controlStack.count - 1] = frame
    }
}
