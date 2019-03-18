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
            let offset = try Int(evaluate(expression: element.offset, resultType: I32.self).rawValue)
            let end = offset + element.initializer.count
            guard
                tableInstance.elements.indices.contains(offset),
                tableInstance.elements.indices.contains(end)
            else { throw Trap.tableOutOfRange }
            tableInstance.elements.replaceSubrange(offset ..< end, with: element.initializer.map { instance.functionAddresses[Int($0)] })
        }

        for data in module.data {
            let memoryInstance = store.memories[Int(data.index)]
            let offset = try Int(evaluate(expression: data.offset, resultType: I32.self).rawValue)
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

        let globalInitializers = try module.globals.map {
            try evaluate(expression: $0.initializer, resultType: Value.self)
        }

        try stack.pop(Frame.self)

        return globalInitializers
    }

    private func initializeElements(module: Module, instance _: ModuleInstance) throws -> [Int] {
        return try module.elements.map {
            try Int(evaluate(expression: $0.offset, resultType: I32.self).rawValue)
        }
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    func invoke(functionAddress address: FunctionAddress) throws {
        let function = store.functions[address]
        guard case let .some(parameterTypes, resultTypes) = function.type else {
            throw Trap._raw("any type is not allowed here")
        }

        let locals = function.code.locals.map { $0.init() }
        let expression = function.code.body

        let parameters = try stack.pop(Value.self, count: parameterTypes.count)

        let frame = Frame(arity: resultTypes.count, module: function.module, locals: parameters + locals)
        stack.push(frame)

        let blockInstruction = ControlInstruction.block(resultTypes, expression)
        _ = try execute(blockInstruction)

        let values = try stack.pop(Value.self, count: frame.arity)

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
    enum ExecutionResult {
        case `continue`
        case `break`(LabelIndex)
        case `return`
    }

    func execute(_ instruction: Instruction) throws -> ExecutionResult {
        let result: ExecutionResult

        switch instruction {
        case let instruction as NumericInstruction.Constant:
            try execute(numeric: instruction)
            result = .continue
        case let instruction as NumericInstruction.Unary:
            try execute(numeric: instruction)
            result = .continue
        case let instruction as NumericInstruction.Binary:
            try execute(numeric: instruction)
            result = .continue
        case let instruction as NumericInstruction.Conversion:
            try execute(numeric: instruction)
            result = .continue
        case let instruction as ParametricInstruction:
            try execute(parametric: instruction)
            result = .continue
        case let instruction as VariableInstruction:
            try execute(variable: instruction)
            result = .continue
        case let instruction as MemoryInstruction:
            try execute(memory: instruction)
            result = .continue
        case let instruction as ControlInstruction:
            result = try execute(control: instruction)
        default:
            throw Trap.unimplemented("\(instruction)")
        }

        return result
    }

    private func execute(_ instructions: [Instruction]) throws -> ExecutionResult {
        var result: ExecutionResult = .continue
        RunLoop: for instruction in instructions {
            result = try execute(instruction)
            switch result {
            case .continue:
                continue
            case .break, .return:
                break RunLoop
            }
        }
        return result
    }

    func enterBlock(instructions: [Instruction], label: Label) throws {
        stack.push(label)

        let result = try execute(instructions)

        switch result {
        case .continue:
            var values: [Value] = []
            while stack.peek() is Value {
                values.append(try stack.pop(Value.self))
            }
            let _label = try stack.pop(Label.self)
            guard label == _label else { throw Trap.labelMismatch }
            stack.push(values)

        case .break:
            _ = try execute(label.continuation)

        case .return:
            throw Trap.unimplemented()
        }
    }

    func evaluate<V: Value>(expression: Expression, resultType: V.Type) throws -> V {
        _ = try execute(expression.instructions)
        return try stack.pop(resultType)
    }
}
