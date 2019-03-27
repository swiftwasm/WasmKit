public final class Runtime {
    let store: Store
    var stack: Stack

    public init() {
        stack = Stack()
        store = Store()
    }
}

extension Runtime {
    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#instantiation>
    public func instantiate(module: Module, externalValues: [ExternalValue]) throws -> ModuleInstance {
        guard module.imports.count == externalValues.count else {
            throw Trap.importsAndExternalValuesMismatch
        }

        let isValid = zip(module.imports, externalValues).map { (i, e) -> Bool in
            switch (i.descripter, e) {
            case (.function, .function),
                 (.table, .table),
                 (.memory, .memory),
                 (.global, .global): return true
            default: return false
            }
        }.reduce(true) { $0 && $1 }

        guard isValid else {
            throw Trap.importsAndExternalValuesMismatch
        }

        let initialGlobals = try evaluateGlobals(module: module, externalValues: externalValues)

        let instance = store.allocate(
            module: module,
            externalValues: externalValues,
            initialGlobals: initialGlobals
        )

        let frame = Frame(arity: 0, module: instance, locals: [])
        stack.push(frame)

        for element in module.elements {
            let tableInstance = store.tables[Int(element.index)]
            let offset = try Int(execute(element.offset, resultType: I32.self).rawValue)
            let end = offset + element.initializer.count
            guard
                tableInstance.elements.indices.contains(offset),
                tableInstance.elements.indices.contains(end)
            else { throw Trap.tableOutOfRange }
            tableInstance.elements.replaceSubrange(offset ..< end, with: element.initializer.map { instance.functionAddresses[Int($0)] })
        }

        for data in module.data {
            let memoryInstance = store.memories[Int(data.index)]
            let offset = try Int(execute(data.offset, resultType: I32.self).rawValue)
            let end = Int(offset) + data.initializer.count
            guard
                memoryInstance.data.indices.contains(offset),
                memoryInstance.data.indices.contains(end)
            else { throw Trap.memoryOverflow }
            memoryInstance.data.replaceSubrange(offset ..< end, with: data.initializer)
        }

        try stack.pop(Frame.self)

        if let startIndex = module.start {
            try invoke(functionAddress: instance.functionAddresses[Int(startIndex)])
        }

        return instance
    }

    private func evaluateGlobals(module: Module, externalValues: [ExternalValue]) throws -> [Value] {
        let globalModuleInstance = ModuleInstance()
        globalModuleInstance.globalAddresses = externalValues.compactMap {
            guard case let .global(address) = $0 else { return nil }
            return address
        }
        let frame = Frame(arity: 0, module: globalModuleInstance, locals: [])
        stack.push(frame)

        let globalInitializers = try module.globals.map { global in
            try execute(global.initializer, resultType: global.type.valueType)
        }

        try stack.pop(Frame.self)

        return globalInitializers
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    func invoke(functionAddress address: FunctionAddress) throws {
        let function = store.functions[address]
        guard case let .some(parameterType, resultType) = function.type else {
            throw Trap._raw("any type is not allowed here")
        }

        let locals = function.code.locals.map { $0.init() }
        let expression = function.code.body

        let parameters = try stack.pop(Value.self, count: parameterType.count)

        let frame = Frame(arity: resultType.count, module: function.module, locals: parameters + locals)
        stack.push(frame)

        let values = try enterBlock(expression, resultType: resultType)

        assert((try? stack.get(current: Frame.self)) == frame)
        _ = try stack.pop(Frame.self)

        stack.push(values)
    }
}

extension Runtime {
    public func invoke(_ moduleInstance: ModuleInstance, function: String, with parameters: [Value] = []) throws -> [Value] {
        guard case let .function(address)? = moduleInstance.exports[function] else {
            throw Trap.exportedFunctionNotFound(moduleInstance, name: function)
        }
        return try invoke(functionAddress: address, with: parameters)
    }

    func invoke(functionAddress address: FunctionAddress, with parameters: [Value]) throws -> [Value] {
        let function = store.functions[address]
        guard case let .some(parameterTypes, _) = function.type else {
            throw Trap._raw("any type is not allowed here")
        }

        guard parameterTypes.count == parameters.count else {
            throw Trap._raw("numbers of parameters don't match")
        }

        assert(zip(parameterTypes, parameters).reduce(true) { acc, types in
            acc && type(of: types.1) == types.0
        })

        stack.push(parameters)

        try invoke(functionAddress: address)

        var results: [Value] = []
        while stack.peek() is Value {
            let value = try stack.pop(Value.self)
            results.append(value)
        }
        return results
    }
}

extension Runtime {
    func enterBlock(_ expression: Expression, resultType: ResultType) throws -> [Value] {
        guard !expression.instructions.isEmpty else {
            return []
        }

        let label = Label(
            arity: resultType.count,
            continuation: expression.instructions.indices.upperBound,
            range: ClosedRange(expression.instructions.indices)
        )

        stack.push(label)

        var address: Int = 0
        while address <= label.range.upperBound {
            while let currentLabel = try? stack.get(current: Label.self), currentLabel.range.upperBound < address {
                try exitBlock(label: currentLabel)
            }

            let action = try expression.execute(address: address, store: store, stack: &stack)

            switch action {
            case let .jump(newAddress):
                address = newAddress

            case let .invoke(functionIndex):
                let currentFrame = try stack.get(current: Frame.self)
                guard currentFrame.module.functionAddresses.indices.contains(functionIndex) else {
                    throw Trap.invalidFunctionIndex(functionIndex)
                }
                let functionAddress = currentFrame.module.functionAddresses[functionIndex]
                try invoke(functionAddress: functionAddress)
                address += 1
            }
        }

        let values = try (0 ..< resultType.count).map { _ in try stack.pop(Value.self) }

        let _label = try stack.pop(Label.self)
        guard label == _label else {
            throw Trap.poppedLabelMismatch
        }

        return values
    }

    func execute<V: Value>(_ expression: Expression, resultType: V.Type) throws -> V {
        let values = try enterBlock(expression, resultType: [resultType])
        guard let value = values.first as? V, values.count == 1 else {
            preconditionFailure()
        }
        return value
    }

    func exitBlock(label: Label) throws {
        var values: [Value] = []
        while stack.peek() is Value {
            values.append(try stack.pop(Value.self))
        }

        let _label = try stack.pop(Label.self)
        assert(label == _label)

        stack.push(values)
    }
}
