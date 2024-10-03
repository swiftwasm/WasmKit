import WasmParser

protocol ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) throws -> Reference
    func globalValue(_ index: GlobalIndex) throws -> Value
}

struct ConstEvaluationContext: ConstEvaluationContextProtocol {
    let functions: ImmutableArray<InternalFunction>
    var globals: [Value]

    init(functions: ImmutableArray<InternalFunction>, globals: [Value]) {
        self.functions = functions
        self.globals = globals
    }

    init(instance: InternalInstance, moduleImports: ModuleImports) {
        // Constant expressions can only reference imported globals
        let externalGlobals = instance.globals
            .prefix(moduleImports.numberOfGlobals)
            .map { $0.value }
        self.init(functions: instance.functions, globals: Array(externalGlobals))
    }

    func functionRef(_ index: FunctionIndex) throws -> Reference {
        return try .function(from: self.functions[validating: Int(index)])
    }
    func globalValue(_ index: GlobalIndex) throws -> Value {
        guard index < globals.count else {
            throw GlobalEntity.createOutOfBoundsError(index: Int(index), count: globals.count)
        }
        return self.globals[Int(index)]
    }
}

extension ConstExpression {
    func evaluate<C: ConstEvaluationContextProtocol>(context: C) throws -> Value {
        guard self.last == .end, self.count == 2 else {
            throw InstantiationError.unsupported("Expect `end` at the end of offset expression")
        }
        let constInst = self[0]
        switch constInst {
        case .i32Const(let value): return .i32(UInt32(bitPattern: value))
        case .i64Const(let value): return .i64(UInt64(bitPattern: value))
        case .f32Const(let value): return .f32(value.bitPattern)
        case .f64Const(let value): return .f64(value.bitPattern)
        case .globalGet(let globalIndex):
            return try context.globalValue(globalIndex)
        case .refNull(let type):
            switch type {
            case .externRef: return .ref(.extern(nil))
            case .funcRef: return .ref(.function(nil))
            }
        case .refFunc(let functionIndex):
            return try .ref(context.functionRef(functionIndex))
        default:
            throw InstantiationError.unsupported("illegal const expression instruction: \(constInst)")
        }
    }
}

extension WasmParser.ElementSegment {
    func evaluateInits<C: ConstEvaluationContextProtocol>(context: C) throws -> [Reference] {
        try self.initializer.map { expression -> Reference in
            switch expression[0] {
            case let .refFunc(index):
                return try context.functionRef(index)
            case .refNull(.funcRef):
                return .function(nil)
            case .refNull(.externRef):
                return .extern(nil)
            case .globalGet(let index):
                let value = try context.globalValue(index)
                switch value {
                case .ref(.function(let addr)):
                    return .function(addr)
                default:
                    throw Trap._raw("Unexpected global value type for element initializer expression")
                }
            default:
                throw Trap._raw("Unexpected element initializer expression: \(expression)")
            }
        }
    }
}
