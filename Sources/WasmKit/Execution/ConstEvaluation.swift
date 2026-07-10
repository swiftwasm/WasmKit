import WasmParser

protocol ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) throws -> Reference
    func globalValue(_ index: GlobalIndex) throws -> Value
}

struct ConstEvaluationContext: ConstEvaluationContextProtocol {
    let functions: ImmutableArray<InternalFunction>
    var globals: [Value]
    let onFunctionReferenced: ((InternalFunction) -> Void)?

    init(
        functions: ImmutableArray<InternalFunction>,
        globals: [Value],
        onFunctionReferenced: ((InternalFunction) -> Void)? = nil
    ) {
        self.functions = functions
        self.globals = globals
        self.onFunctionReferenced = onFunctionReferenced
    }

    init(instance: InternalInstance, moduleImports: ModuleImports) {
        // Constant expressions can only reference imported globals
        let externalGlobals = instance.globals
            .prefix(moduleImports.numberOfGlobals)
            .map { $0.value }
        self.init(functions: instance.functions, globals: Array(externalGlobals))
    }

    func functionRef(_ index: FunctionIndex) throws -> Reference {
        let function = try self.functions[validating: Int(index)]
        self.onFunctionReferenced?(function)
        return .function(from: function)
    }
    func globalValue(_ index: GlobalIndex) throws -> Value {
        guard index < globals.count else {
            throw GlobalEntity.createOutOfBoundsError(index: Int(index), count: globals.count)
        }
        return self.globals[Int(index)]
    }
}

extension ConstExpression {
    func evaluate<C: ConstEvaluationContextProtocol>(context: C, expectedType: WasmTypes.ValueType) throws -> Value {
        let result = try self._evaluate(context: context)
        try result.checkType(expectedType)
        return result
    }

    private func _evaluate<C: ConstEvaluationContextProtocol>(context: C) throws -> Value {
        guard self.last == .end else {
            throw WasmKitError(message: .expectedEndAtOffsetExpression)
        }
        // Evaluate the expression as a small stack machine: a sequence of const-safe instructions
        // terminated by `end`. Extended constant expressions allow more than one instruction; anything
        // not handled below throws.
        var stack: [Value] = []
        for constInst in self.dropLast() {
            switch constInst {
            case .i32Const(let value): stack.append(.i32(UInt32(bitPattern: value)))
            case .i64Const(let value): stack.append(.i64(UInt64(bitPattern: value)))
            case .f32Const(let value): stack.append(.f32(value.bitPattern))
            case .f64Const(let value): stack.append(.f64(value.bitPattern))
            case .v128Const(let value): stack.append(.v128(value))
            case .globalGet(let globalIndex):
                stack.append(try context.globalValue(globalIndex))
            case .refNull(let type):
                switch type {
                case .externRef: stack.append(.ref(.extern(nil)))
                case .funcRef: stack.append(.ref(.function(nil)))
                case .exnRef: stack.append(.ref(.exception(nil)))
                default:
                    throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                }
            case .refFunc(let functionIndex):
                stack.append(.ref(try context.functionRef(functionIndex)))
            case .binary(let op):
                // Extended-const arithmetic: i32/i64 add/sub/mul. Other binary ops fall to the inner default.
                switch op {
                case .i32Add, .i32Sub, .i32Mul:
                    let (lhs, rhs) = try Self.popI32Pair(&stack, op)
                    switch op {
                    case .i32Add: stack.append(.i32(lhs.add(rhs)))
                    case .i32Sub: stack.append(.i32(lhs.sub(rhs)))
                    default: stack.append(.i32(lhs.mul(rhs)))  // .i32Mul
                    }
                case .i64Add, .i64Sub, .i64Mul:
                    let (lhs, rhs) = try Self.popI64Pair(&stack, op)
                    switch op {
                    case .i64Add: stack.append(.i64(lhs.add(rhs)))
                    case .i64Sub: stack.append(.i64(lhs.sub(rhs)))
                    default: stack.append(.i64(lhs.mul(rhs)))  // .i64Mul
                    }
                default:
                    throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                }
            default:
                throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
            }
        }
        guard stack.count == 1 else {
            throw WasmKitError(message: .invalidConstExpressionArity(count: stack.count))
        }
        return stack[0]
    }

    /// Pops the two `i32` operands of a binary const-arithmetic instruction (right operand first, so the
    /// result is `lhs op rhs`). Throws on stack underflow or non-`i32` operands.
    private static func popI32Pair(_ stack: inout [Value], _ op: WasmParser.Instruction.Binary) throws -> (UInt32, UInt32) {
        guard stack.count >= 2, case .i32(let rhs) = stack.removeLast(), case .i32(let lhs) = stack.removeLast()
        else { throw WasmKitError(message: .illegalConstExpressionInstruction(.binary(op))) }
        return (lhs, rhs)
    }

    /// Pops the two `i64` operands of a binary const-arithmetic instruction (right operand first, so the
    /// result is `lhs op rhs`). Throws on stack underflow or non-`i64` operands.
    private static func popI64Pair(_ stack: inout [Value], _ op: WasmParser.Instruction.Binary) throws -> (UInt64, UInt64) {
        guard stack.count >= 2, case .i64(let rhs) = stack.removeLast(), case .i64(let lhs) = stack.removeLast()
        else { throw WasmKitError(message: .illegalConstExpressionInstruction(.binary(op))) }
        return (lhs, rhs)
    }
}

extension WasmParser.ElementSegment {
    func evaluateInits<C: ConstEvaluationContextProtocol>(context: C) throws -> [Reference] {
        return try self.initializer.map { expression -> Reference in
            let result = try Self._evaluateInits(context: context, expression: expression)
            try result.checkType(self.type)
            return result
        }
    }
    static func _evaluateInits<C: ConstEvaluationContextProtocol>(
        context: C, expression: ConstExpression
    ) throws -> Reference {
        switch expression[0] {
        case .refFunc(let index):
            return try context.functionRef(index)
        case .refNull(.funcRef):
            return .function(nil)
        case .refNull(.externRef):
            return .extern(nil)
        case .refNull(.exnRef):
            return .exception(nil)
        case .globalGet(let index):
            let value = try context.globalValue(index)
            switch value {
            case .ref(.function(let addr)):
                return .function(addr)
            default:
                throw WasmKitError(message: .unexpectedGlobalValueType)
            }
        default:
            throw WasmKitError(message: .unexpectedElementInitializer(expression: "\(expression)"))
        }
    }
}
