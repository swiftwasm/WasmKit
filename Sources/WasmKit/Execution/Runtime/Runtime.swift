import WasmParser

/// A container to manage execution state of one or more module instances.
public final class Runtime {
    public let store: Store
    let interceptor: RuntimeInterceptor?

    /// Initializes a new instant of a WebAssembly interpreter runtime.
    /// - Parameter hostModules: Host module names mapped to their corresponding ``HostModule`` definitions.
    public init(hostModules: [String: HostModule] = [:], interceptor: RuntimeInterceptor? = nil) {
        store = Store(hostModules)
        self.interceptor = interceptor
    }
}

@_documentation(visibility: internal)
public protocol RuntimeInterceptor {
    func onEnterFunction(_ address: FunctionAddress, store: Store)
    func onExitFunction(_ address: FunctionAddress, store: Store)
}

/// Execute the given block with a temporary translator for const expression evaluation
private func withTemporaryTranslator<R>(module: Module, _ body: (inout InstructionTranslator) throws -> R) rethrows -> R {
    let allocator = ISeqAllocator()
    var translator = InstructionTranslator(
        allocator: allocator, module: module.translatorContext,
        type: .init(parameters: [], results: []),
        locals: []
    )
    return try body(&translator)
}

extension Runtime {
    public func instantiate(module: Module, name: String? = nil) throws -> ModuleInstance {
        let instance = try instantiate(module: module, externalValues: store.getExternalValues(module))

        if let name {
            store.namedModuleInstances[name] = instance
        }

        return instance
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#instantiation>
    func instantiate(module: Module, externalValues: [ExternalValue]) throws -> ModuleInstance {
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
        let initialGlobals = try evaluateGlobals(module: module, externalValues: externalValues)

        // Step 9.
        // Process `elem.init` evaluation during allocation

        // Step 11.
        let instance = try store.allocate(
            module: module,
            externalValues: externalValues,
            initialGlobals: initialGlobals
        )

        // Step 12-13.

        // Steps 14-15.
        do {
            for (elementIndex, element) in module.elements.enumerated() {
                let elementIndex = UInt32(elementIndex)
                switch element.mode {
                case let .active(tableIndex, offsetExpression):
                    try withTemporaryTranslator(module: module) { translator in
                        guard offsetExpression.last == .end else {
                            throw InstantiationError.unsupported("Expect `end` at the end of offset expression")
                        }
                        for instruction in offsetExpression.dropLast() {
                            try translator.visit(instruction)
                        }
                        translator.visitI32Const(value: 0)
                        translator.visitI32Const(value: Int32(element.initializer.count))
                        try translator.visitTableInit(elemIndex: elementIndex, table: tableIndex)
                        translator.visitElemDrop(elemIndex: elementIndex)
                        try translator.visitEnd()
                        try evaluateConstExpr(translator.finalize(), instance: instance)
                    }

                case .declarative:
                    try withTemporaryTranslator(module: module) { translator in
                        translator.visitElemDrop(elemIndex: elementIndex)
                        try translator.visitEnd()
                        try evaluateConstExpr(translator.finalize(), instance: instance)
                    }

                case .passive:
                    continue
                }
            }
        } catch Trap.undefinedElement, Trap.tableSizeOverflow, Trap.outOfBoundsTableAccess {
            throw InstantiationError.outOfBoundsTableAccess
        } catch {
            throw error
        }

        // Step 16.
        do {
            for case let (dataIndex, .active(data)) in module.data.enumerated() {
                assert(data.index == 0)
                try withTemporaryTranslator(module: module) { translator in
                    guard data.offset.last == .end else {
                        throw InstantiationError.unsupported("Expect `end` at the end of offset expression")
                    }
                    for instruction in data.offset.dropLast() {
                        try translator.visit(instruction)
                    }
                    translator.visitI32Const(value: 0)
                    translator.visitI32Const(value: Int32(data.initializer.count))
                    try translator.visitMemoryInit(dataIndex: UInt32(dataIndex))
                    translator.visitDataDrop(dataIndex: UInt32(dataIndex))
                    try translator.visitEnd()
                    try evaluateConstExpr(translator.finalize(), instance: instance)
                }
            }
        } catch Trap.outOfBoundsMemoryAccess {
            throw InstantiationError.outOfBoundsMemoryAccess
        } catch {
            throw error
        }

        // Step 17.
        if let startIndex = module.start {
            try withExecution { initExecution in
                var stack = Stack()
                defer { stack.deallocate() }
                try initExecution.invoke(functionAddress: instance.functionAddresses[Int(startIndex)], runtime: self, stack: &stack)
                try initExecution.run(runtime: self, stack: &stack)
            }
        }

        return instance
    }

    private func evaluateGlobals(module: Module, externalValues: [ExternalValue]) throws -> [Value] {
        try store.withTemporaryModuleInstance { globalModuleInstance in
            for externalValue in externalValues {
                switch externalValue {
                case let .global(address):
                    globalModuleInstance.globalAddresses.append(address)
                case let .function(address):
                    globalModuleInstance.functionAddresses.append(address.address)
                default:
                    continue
                }
            }

            globalModuleInstance.types = module.types

            for function in module.functions {
                let address = store.allocate(function: function, module: globalModuleInstance)
                globalModuleInstance.functionAddresses.append(address)
            }

            let globalInitializers = try module.internalGlobals.map { global in
                try global.initializer.evaluate(instance: globalModuleInstance, store: store)
            }

            return globalInitializers
        }
    }

    func evaluateConstExpr(_ iseq: InstructionSequence, instance: ModuleInstance, arity: Int = 0) throws {
        try evaluateConstExpr(iseq, instance: instance, arity: arity, body: { _, _ in })
    }

    func evaluateConstExpr<T>(
        _ iseq: InstructionSequence,
        instance: ModuleInstance,
        arity: Int = 0,
        body: (inout ExecutionState, inout Stack) throws -> T
    ) throws -> T {
        try withExecution { initExecution in
            var stack = Stack()
            defer { stack.deallocate() }
            try stack.pushFrame(
                iseq: iseq,
                arity: arity,
                module: instance.selfAddress,
                argc: 0,
                defaultLocals: nil,
                returnPC: initExecution.programCounter + 1,
                spAddend: 0
            )
            initExecution.programCounter = iseq.baseAddress
            try initExecution.run(runtime: self, stack: &stack)
            return try body(&initExecution, &stack)
        }
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

    public func getGlobal(_ moduleInstance: ModuleInstance, globalName: String) throws -> Value {
        guard case let .global(address) = moduleInstance.exportInstances.first(where: { $0.name == globalName })?.value else {
            throw Trap._raw("no global export with name \(globalName) in a module instance \(moduleInstance)")
        }

        return store.globals[address].value
    }

    public func invoke(_ moduleInstance: ModuleInstance, function: String, with arguments: [Value] = []) throws -> [Value] {
        guard case let .function(function)? = moduleInstance.exports[function] else {
            throw Trap.exportedFunctionNotFound(moduleInstance, name: function)
        }
        return try function.invoke(arguments, runtime: self)
    }

    /// Invokes a function of the given address with the given parameters.
    public func invoke(_ address: FunctionAddress, with parameters: [Value] = []) throws -> [Value] {
        try Function(address: address).invoke(parameters, runtime: self)
    }
}

extension ConstExpression {
    fileprivate func evaluate(instance: ModuleInstance, store: Store) throws -> Value {
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
            let address = instance.globalAddresses[Int(globalIndex)]
            return store.globals[address].value
        case .refNull(let type):
            switch type {
            case .externRef: return .ref(.extern(nil))
            case .funcRef: return .ref(.function(nil))
            }
        case .refFunc(let functionIndex):
            let address = instance.functionAddresses[Int(functionIndex)]
            return .ref(.function(address))
        default:
            throw InstantiationError.unsupported("illegal const expression instruction: \(constInst)")
        }
    }
}
