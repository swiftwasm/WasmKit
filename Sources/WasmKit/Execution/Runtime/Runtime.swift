import WasmParser

/// A container to manage execution state of one or more module instances.
public final class Runtime {
    public let store: Store
    let funcTypeInterner: Interner<FunctionType>

    /// Initializes a new instant of a WebAssembly interpreter runtime.
    /// - Parameter hostModules: Host module names mapped to their corresponding ``HostModule`` definitions.
    public init(hostModules: [String: HostModule] = [:]) {
        self.funcTypeInterner = Interner<FunctionType>()
        store = Store(funcTypeInterner: funcTypeInterner)

        for (moduleName, hostModule) in hostModules {
            store.registerUniqueHostModule(hostModule, as: moduleName, runtime: self)
        }
    }

    func resolveType(_ type: InternedFuncType) -> FunctionType {
        return funcTypeInterner.resolve(type)
    }
    func internType(_ type: FunctionType) -> InternedFuncType {
        return funcTypeInterner.intern(type)
    }
}

@_documentation(visibility: internal)
@available(*, unavailable, message: "Interceptors are not supported anymore for performance reasons")
public protocol RuntimeInterceptor {
    func onEnterFunction(_ function: Function, store: Store)
    func onExitFunction(_ function: Function, store: Store)
}

extension Runtime {
    public func instantiate(module: Module) throws -> Instance {
        let instance = try instantiate(
            module: module,
            externalValues: store.getExternalValues(module, runtime: self)
        )

        return Instance(handle: instance, allocator: store.allocator)
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#instantiation>
    func instantiate(module: Module, externalValues: [ExternalValue]) throws -> InternalInstance {
        // Step 3 of instantiation algorithm, according to Wasm 2.0 spec.
        guard module.imports.count == externalValues.count else {
            throw InstantiationError.importsAndExternalValuesMismatch
        }

        // Step 4.
        let isValid = zip(module.imports, externalValues).map { i, e -> Bool in
            switch (i.descriptor, e) {
            case (.function, .function),
                (.table, .table),
                (.memory, .memory),
                (.global, .global):
                return true
            default: return false
            }
        }.reduce(true) { $0 && $1 }

        guard isValid else {
            throw InstantiationError.importsAndExternalValuesMismatch
        }

        // Steps 5-8.

        // Step 9.
        // Process `elem.init` evaluation during allocation

        // Step 11.
        let instance = try store.allocator.allocate(
            module: module, runtime: self,
            externalValues: externalValues
        )

        if let nameSection = module.customSections.first(where: { $0.name == "name" }) {
            // FIXME?: Just ignore parsing error of name section for now.
            // Should emit warning instead of just discarding it?
            try? store.nameRegistry.register(instance: instance, nameSection: nameSection)
        }

        // Step 12-13.

        // Steps 14-15.
        do {
            for element in module.elements {
                guard case let .active(tableIndex, offset) = element.mode else { continue }
                let offsetValue = try offset.evaluate(context: instance)
                let table = instance.tables[Int(tableIndex)]
                try table.withValue { table in
                    guard let offset = offsetValue.maybeAddressOffset(table.limits.isMemory64) else {
                        throw InstantiationError.unsupported(
                            "Expect \(ValueType.addressType(isMemory64: table.limits.isMemory64)) offset of active element segment but got \(offsetValue)"
                        )
                    }
                    let references = try element.evaluateInits(context: instance)
                    try table.initialize(
                        elements: references, from: 0, to: Int(offset), count: references.count
                    )
                }
            }
        } catch Trap.undefinedElement, Trap.tableSizeOverflow, Trap.outOfBoundsTableAccess {
            throw InstantiationError.outOfBoundsTableAccess
        } catch {
            throw error
        }

        // Step 16.
        do {
            for case let .active(data) in module.data {
                let offsetValue = try data.offset.evaluate(context: instance)
                let memory = instance.memories[Int(data.index)]
                try memory.withValue { memory in
                    guard let offset = offsetValue.maybeAddressOffset(memory.limit.isMemory64) else {
                        throw InstantiationError.unsupported(
                            "Expect \(ValueType.addressType(isMemory64: memory.limit.isMemory64)) offset of active data segment but got \(offsetValue)"
                        )
                    }
                    try memory.write(offset: Int(offset), bytes: data.initializer)
                }
            }
        } catch Trap.outOfBoundsMemoryAccess {
            throw InstantiationError.outOfBoundsMemoryAccess
        } catch {
            throw error
        }

        // Step 17.
        if let startIndex = module.start {
            let startFunction = instance.functions[Int(startIndex)]
            _ = try startFunction.invoke([], runtime: self)
        }

        return instance
    }
}

extension Runtime {
    @available(*, unavailable, message: "Runtime doesn't manage execution state anymore. Use ExecutionState.step instead")
    public func step() throws {
        fatalError()
    }

    @available(*, unavailable, message: "Runtime doesn't manage execution state anymore. Use ExecutionState.step instead")
    public func run() throws {
        fatalError()
    }

    /// Returns the value of a global variable in a module instance.
    ///
    /// Deprecated: Use ``Instance``'s ``Instance/export(_:)`` and ``Global``'s ``Global/value`` instead.
    ///
    /// ```swift
    /// guard case let .global(myGlobal) = instance.export("myGlobal") else { ... }
    /// let value = myGlobal.value
    /// ```
    @available(*, deprecated, message: "Use `Instance.export` and `Global.value` instead")
    public func getGlobal(_ instance: Instance, globalName: String) throws -> Value {
        guard case let .global(global) = instance.export(globalName) else {
            throw Trap._raw("no global export with name \(globalName) in a module instance \(instance)")
        }
        return global.value
    }

    /// Invokes a function in a given module instance.
    public func invoke(_ instance: Instance, function: String, with arguments: [Value] = []) throws -> [Value] {
        guard case let .function(function)? = instance.export(function) else {
            throw Trap.exportedFunctionNotFound(instance, name: function)
        }
        return try function.invoke(arguments, runtime: self)
    }

    @available(*, unavailable, message: "Use `Function.invoke` instead")
    public func invoke(_ address: FunctionAddress, with parameters: [Value] = []) throws -> [Value] {
        fatalError()
    }
}

protocol ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) -> Reference
    func globalValue(_ index: GlobalIndex) -> Value
}

extension InternalInstance: ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) -> Reference {
        return .function(from: self.functions[Int(index)])
    }
    func globalValue(_ index: GlobalIndex) -> Value {
        return self.globals[Int(index)].value
    }
}

struct ConstEvaluationContext: ConstEvaluationContextProtocol {
    let functions: ImmutableArray<InternalFunction>
    var globals: [Value]
    func functionRef(_ index: FunctionIndex) -> Reference {
        return .function(from: self.functions[Int(index)])
    }
    func globalValue(_ index: GlobalIndex) -> Value {
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
            return context.globalValue(globalIndex)
        case .refNull(let type):
            switch type {
            case .externRef: return .ref(.extern(nil))
            case .funcRef: return .ref(.function(nil))
            }
        case .refFunc(let functionIndex):
            return .ref(context.functionRef(functionIndex))
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
                return context.functionRef(index)
            case .refNull(.funcRef):
                return .function(nil)
            case .refNull(.externRef):
                return .extern(nil)
            case .globalGet(let index):
                let value = context.globalValue(index)
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
