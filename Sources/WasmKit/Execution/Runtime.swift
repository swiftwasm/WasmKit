import WasmParser

/// A container to manage execution state of one or more module instances.
public final class Runtime {
    public let store: Store
    let engine: Engine
    var interceptor: EngineInterceptor? {
        engine.interceptor
    }
    var funcTypeInterner: Interner<FunctionType> {
        engine.funcTypeInterner
    }
    var configuration: EngineConfiguration {
        engine.configuration
    }

    var hostFunctions: [HostFunction] = []
    private var hostGlobals: [Global] = []
    /// This property is separate from `registeredModuleInstances`, as host exports
    /// won't have a corresponding module instance.
    fileprivate var availableExports: [String: [String: ExternalValue]] = [:]

    /// Initializes a new instant of a WebAssembly interpreter runtime.
    /// - Parameter hostModules: Host module names mapped to their corresponding ``HostModule`` definitions.
    /// - Parameter interceptor: An optional runtime interceptor to intercept execution of instructions.
    /// - Parameter configuration: An optional runtime configuration to customize the runtime behavior.
    public init(
        hostModules: [String: HostModule] = [:],
        interceptor: EngineInterceptor? = nil,
        configuration: EngineConfiguration = EngineConfiguration()
    ) {
        self.engine = Engine(configuration: configuration, interceptor: interceptor)
        store = Store(engine: engine)

        for (moduleName, hostModule) in hostModules {
            registerUniqueHostModule(hostModule, as: moduleName, engine: engine)
        }
    }

    func resolveType(_ type: InternedFuncType) -> FunctionType {
        return funcTypeInterner.resolve(type)
    }
    func internType(_ type: FunctionType) -> InternedFuncType {
        return funcTypeInterner.intern(type)
    }
}

extension Runtime {
    public func instantiate(module: Module) throws -> Instance {
        let instance = try module.instantiate(
            store: store,
            externalValues: getExternalValues(module, runtime: self)
        )

        return Instance(handle: instance, store: store)
    }

    /// Legacy compatibility method to register a module instance with a name.
    public func register(_ instance: Instance, as name: String) throws {
        guard availableExports[name] == nil else {
            throw ImportError.moduleInstanceAlreadyRegistered(name)
        }

        availableExports[name] = instance.exports
    }

    /// Legacy compatibility method to register a host module with a name.
    public func register(_ hostModule: HostModule, as name: String) throws {
        guard availableExports[name] == nil else {
            throw ImportError.moduleInstanceAlreadyRegistered(name)
        }

        registerUniqueHostModule(hostModule, as: name, engine: engine)
    }

    /// Register the given host module assuming that the given name is not registered yet.
    func registerUniqueHostModule(_ hostModule: HostModule, as name: String, engine: Engine) {
        var moduleExports = [String: ExternalValue]()

        for (globalName, global) in hostModule.globals {
            moduleExports[globalName] = .global(global)
            hostGlobals.append(global)
        }

        for (functionName, function) in hostModule.functions {
            moduleExports[functionName] = .function(
                Function(
                    handle: store.allocator.allocate(hostFunction: function, engine: engine),
                    store: store
                )
            )
            hostFunctions.append(function)
        }

        for (memoryName, memoryAddr) in hostModule.memories {
            moduleExports[memoryName] = .memory(memoryAddr)
        }

        availableExports[name] = moduleExports
    }

    func getExternalValues(_ module: Module, runtime: Runtime) throws -> [ExternalValue] {
        var result = [ExternalValue]()

        for i in module.imports {
            guard let moduleExports = availableExports[i.module], let external = moduleExports[i.name] else {
                throw ImportError.unknownImport(moduleName: i.module, externalName: i.name)
            }

            switch (i.descriptor, external) {
            case let (.function(typeIndex), .function(externalFunc)):
                let type = externalFunc.handle.type
                guard runtime.internType(module.types[Int(typeIndex)]) == type else {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.table(tableType), .table(table)):
                if let max = table.handle.limits.max, max < tableType.limits.min {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.memory(memoryType), .memory(memory)):
                if let max = memory.handle.limit.max, max < memoryType.min {
                    throw ImportError.incompatibleImportType
                }
                result.append(external)

            case let (.global(globalType), .global(global))
                where globalType == global.handle.globalType:
                result.append(external)

            default:
                throw ImportError.incompatibleImportType
            }
        }

        return result
    }
}

extension Runtime {
    @available(*, unavailable, message: "Runtime doesn't manage execution state anymore. Use Execution.step instead")
    public func step() throws {
        fatalError()
    }

    @available(*, unavailable, message: "Runtime doesn't manage execution state anymore. Use Execution.step instead")
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
        return try function.invoke(arguments)
    }

    @available(*, unavailable, message: "Use `Function.invoke` instead")
    public func invoke(_ address: FunctionAddress, with parameters: [Value] = []) throws -> [Value] {
        fatalError()
    }
}

protocol ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) throws -> Reference
    func globalValue(_ index: GlobalIndex) throws -> Value
}

extension InternalInstance: ConstEvaluationContextProtocol {
    func functionRef(_ index: FunctionIndex) throws -> Reference {
        return try .function(from: self.functions[validating: Int(index)])
    }
    func globalValue(_ index: GlobalIndex) throws -> Value {
        return try self.globals[validating: Int(index)].value
    }
}

struct ConstEvaluationContext: ConstEvaluationContextProtocol {
    let functions: ImmutableArray<InternalFunction>
    var globals: [Value]
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
