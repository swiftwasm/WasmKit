import WasmParser

protocol ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) throws -> Reference
    func globalValue(_ index: GlobalIndex) throws -> Value
    /// Maps the module's type indices to canonical type IDs.
    var canonicalizer: TypeCanonicalizer { get }
    /// Where `struct.new` and the `array.new` instructions allocate.
    var gcHeap: GCHeap { get }
    var resourceLimiter: any ResourceLimiter { get }
}

struct ConstEvaluationContext: ConstEvaluationContextProtocol {
    let functions: ImmutableArray<InternalFunction>
    /// The globals a constant expression may read, which depends on where it appears.
    var globals: [InternalGlobal]
    let canonicalizer: TypeCanonicalizer
    let gcHeap: GCHeap
    let resourceLimiter: any ResourceLimiter
    let onFunctionReferenced: ((InternalFunction) -> Void)?

    init(
        functions: ImmutableArray<InternalFunction>,
        globals: [InternalGlobal],
        canonicalizer: TypeCanonicalizer,
        gcHeap: GCHeap,
        resourceLimiter: any ResourceLimiter,
        onFunctionReferenced: ((InternalFunction) -> Void)? = nil
    ) {
        self.functions = functions
        self.globals = globals
        self.canonicalizer = canonicalizer
        self.gcHeap = gcHeap
        self.resourceLimiter = resourceLimiter
        self.onFunctionReferenced = onFunctionReferenced
    }

    /// A context for element and data segment offsets, which may read every global.
    init(instance: InternalInstance, store: Store) {
        self.init(
            functions: instance.functions, globals: Array(instance.globals), canonicalizer: instance.typeCanonicalizer,
            gcHeap: store.allocator.gcHeap, resourceLimiter: store.resourceLimiter)
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
        let global = self.globals[Int(index)]
        guard global.globalType.mutability == .constant else {
            throw WasmKitError(message: .mutableGlobalInConstExpression(index: index))
        }
        return global.value
    }
}

extension ConstExpression {
    func evaluate<C: ConstEvaluationContextProtocol>(context: C, expectedType: WasmTypes.ValueType) throws -> Value {
        let result = try self._evaluate(context: context)
        try result.checkType(expectedType, heap: context.gcHeap)
        return result
    }

    fileprivate func _evaluate<C: ConstEvaluationContextProtocol>(context: C) throws -> Value {
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
                let type = ReferenceType(isNullable: true, heapType: try context.canonicalizer.canonicalize(type))
                stack.append(.ref(UntypedValue.nullReference.asReference(type)))
            case .refI31:
                guard case .i32(let value) = stack.popLast() else {
                    throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                }
                stack.append(.ref(.any(AnyRef(i31: value))))
            case .structNew(let typeIndex), .structNewDefault(let typeIndex):
                let id = try context.canonicalizer.canonicalID(of: typeIndex).id
                guard let layout = context.gcHeap.typeRegistry.entry(id).structLayout else {
                    throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                }
                let object = try context.gcHeap.allocateStruct(type: id, layout: layout, resourceLimiter: context.resourceLimiter)
                if case .structNew = constInst {
                    let fields = try Self.popValues(&stack, count: layout.fields.count, constInst)
                    for (field, value) in zip(layout.fields, fields) {
                        let (lo, hi) = value.slotBits
                        field.storage.store(lo: lo, hi: hi, to: context.gcHeap.address(object) + field.offset)
                    }
                }
                stack.append(.ref(.any(AnyRef(storage: UInt64(object)))))
            case .arrayNew(let typeIndex), .arrayNewDefault(let typeIndex), .arrayNewFixed(let typeIndex, _):
                let id = try context.canonicalizer.canonicalID(of: typeIndex).id
                guard let element = context.gcHeap.typeRegistry.entry(id).arrayElement else {
                    throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                }
                let values: [Value]
                switch constInst {
                case .arrayNewFixed(_, let size):
                    values = try Self.popValues(&stack, count: Int(size), constInst)
                default:
                    guard case .i32(let length) = stack.popLast() else {
                        throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                    }
                    let value = constInst == .arrayNew(typeIndex: typeIndex) ? try Self.popValues(&stack, count: 1, constInst)[0] : nil
                    values = value.map { [Value](repeating: $0, count: Int(length)) } ?? []
                    if value == nil {
                        let array = try context.gcHeap.allocateArray(
                            type: id, element: element, count: length, resourceLimiter: context.resourceLimiter)
                        stack.append(.ref(.any(AnyRef(storage: UInt64(array)))))
                        continue
                    }
                }
                let array = try context.gcHeap.allocateArray(
                    type: id, element: element, count: UInt32(values.count), resourceLimiter: context.resourceLimiter)
                for (index, value) in values.enumerated() {
                    let (lo, hi) = value.slotBits
                    element.store(lo: lo, hi: hi, to: context.gcHeap.arrayElement(array, at: UInt32(index), element: element))
                }
                stack.append(.ref(.any(AnyRef(storage: UInt64(array)))))
            case .anyConvertExtern, .externConvertAny:
                guard case .ref(let reference) = stack.popLast() else {
                    throw WasmKitError(message: .illegalConstExpressionInstruction(constInst))
                }
                // The conversions keep the reference's bits.
                let type = ReferenceType(isNullable: true, heapType: constInst == .anyConvertExtern ? .abstract(.any) : .externRef)
                stack.append(.ref(UntypedValue(.ref(reference)).asReference(type)))
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

    /// Pops `count` values, returning them in the order they were pushed.
    private static func popValues(_ stack: inout [Value], count: Int, _ instruction: WasmParser.Instruction) throws -> [Value] {
        guard stack.count >= count else {
            throw WasmKitError(message: .illegalConstExpressionInstruction(instruction))
        }
        let values = [Value](stack.suffix(count))
        stack.removeLast(count)
        return values
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
    /// Evaluates the segment's items, checking each against `type`, the
    /// segment's canonical element type.
    func evaluateInits<C: ConstEvaluationContextProtocol>(context: C, type: ReferenceType) throws -> [Reference] {
        return try self.initializer.map { expression -> Reference in
            let result = try Self._evaluateInits(context: context, expression: expression)
            try result.checkType(type, heap: context.gcHeap)
            return result
        }
    }
    static func _evaluateInits<C: ConstEvaluationContextProtocol>(
        context: C, expression: ConstExpression
    ) throws -> Reference {
        // A segment of function indices holds each item as a lone `ref.func`, without `end`.
        let expression = expression.last == .end ? expression : expression + [.end]
        guard case .ref(let reference) = try expression._evaluate(context: context) else {
            throw WasmKitError(message: .unexpectedElementInitializer(expression: "\(expression)"))
        }
        return reference
    }
}

/// What the static type of a constant expression depends on, with every type
/// canonical.
struct ConstExpressionTypeContext {
    let canonicalizer: TypeCanonicalizer
    let typeRegistry: TypeRegistry
    let functions: ImmutableArray<InternalFunction>
    /// The types of the globals a constant expression may read.
    var globalTypes: [GlobalType]
}

extension ConstExpression {
    /// Checks that the expression's static type is a subtype of `expectedType`.
    ///
    /// Evaluation checks the resulting value too, but a null value does not
    /// tell which null it is: `ref.null func` must not initialize a
    /// `(ref null $t)`. Malformed expressions are left for evaluation to report.
    func checkType(_ expectedType: ValueType, context: ConstExpressionTypeContext) throws(WasmKitError) {
        guard let type = try staticType(context: context) else { return }
        guard type.isSubtype(of: expectedType, in: context.typeRegistry) else {
            throw WasmKitError(message: .expectTypeButGot(expected: "\(expectedType)", got: "\(type)"))
        }
    }

    /// The type of the value the expression produces, or `nil` if the
    /// expression is not a well-formed constant expression.
    private func staticType(context: ConstExpressionTypeContext) throws(WasmKitError) -> ValueType? {
        var stack: [ValueType] = []
        for instruction in self {
            switch instruction {
            case .end: break
            case .i32Const: stack.append(.i32)
            case .i64Const: stack.append(.i64)
            case .f32Const: stack.append(.f32)
            case .f64Const: stack.append(.f64)
            case .v128Const: stack.append(.v128)
            case .globalGet(let index):
                guard Int(index) < context.globalTypes.count else { return nil }
                stack.append(context.globalTypes[Int(index)].valueType)
            case .refNull(let heapType):
                stack.append(.ref(ReferenceType(isNullable: true, heapType: try context.canonicalizer.canonicalize(heapType))))
            case .refI31:
                guard stack.popLast() != nil else { return nil }
                stack.append(.ref(ReferenceType(isNullable: false, heapType: .abstract(.i31))))
            case .structNew(let typeIndex), .structNewDefault(let typeIndex), .arrayNew(let typeIndex),
                .arrayNewDefault(let typeIndex), .arrayNewFixed(let typeIndex, _):
                let id = try context.canonicalizer.canonicalID(of: typeIndex).id
                let operands: Int
                switch (instruction, context.typeRegistry.subType(id).body) {
                case (.structNew, .structType(let structType)): operands = structType.fields.count
                case (.structNewDefault, .structType): operands = 0
                case (.arrayNew, .arrayType): operands = 2
                case (.arrayNewDefault, .arrayType): operands = 1
                case (.arrayNewFixed(_, let size), .arrayType): operands = Int(size)
                default: return nil
                }
                // Evaluation checks the operands.
                guard stack.count >= operands else { return nil }
                stack.removeLast(operands)
                stack.append(.ref(ReferenceType(isNullable: false, heapType: .concrete(typeIndex: id))))
            case .anyConvertExtern, .externConvertAny:
                guard case .ref(let operand) = stack.popLast() else { return nil }
                let target: HeapType = instruction == .anyConvertExtern ? .abstract(.any) : .externRef
                stack.append(.ref(ReferenceType(isNullable: operand.isNullable, heapType: target)))
            case .refFunc(let index):
                guard Int(index) < context.functions.count else { return nil }
                let function = context.functions[Int(index)]
                stack.append(.ref(ReferenceType(isNullable: false, heapType: .concrete(typeIndex: function.type.id))))
            case .binary(.i32Add), .binary(.i32Sub), .binary(.i32Mul), .binary(.i64Add), .binary(.i64Sub), .binary(.i64Mul):
                // Evaluation checks the operand types.
                guard let result = stack.popLast(), stack.popLast() != nil else { return nil }
                stack.append(result)
            default:
                return nil
            }
        }
        return stack.count == 1 ? stack[0] : nil
    }
}

extension Value {
    /// The value's bits as one value slot holds them, and a second for a `v128`.
    var slotBits: (lo: UInt64, hi: UInt64) {
        if case .v128(let value) = self {
            let storage = V128Storage(value)
            return (storage.lo, storage.hi)
        }
        return (UntypedValue(self).storage, 0)
    }
}
