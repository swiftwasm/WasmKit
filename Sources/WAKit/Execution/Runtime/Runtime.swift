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
        // TODO: validate module and external values
        // TODO: initialize globals

        let instance = store.allocate(module: module, externalValues: externalValues)

//        store.initializeElements(stack: stack)
//        store.initializeData(stack: stack)

        if let startIndex = module.start {
            try invoke(functionAddress: instance.functionAddresses[Int(startIndex)])
        }

        return instance
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    public func invoke(functionAddress address: FunctionAddress, with parameters: [Value]) throws -> [Value] {
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

    func invoke(functionAddress address: FunctionAddress) throws {
        let function = store.functions[address]
        guard case let .some(parameterTypes, resultTypes) = function.type else {
            throw Trap._raw("any type is not allowed here")
        }

        let locals = function.code.locals.map { $0.init() }
        let expression = function.code.body

        let parameters = (0 ..< parameterTypes.count).compactMap { _ in stack.pop() as? Value }
        assert(parameters.count == parameterTypes.count)

        let frame = Frame(arity: resultTypes.count, module: function.module, locals: parameters + locals)
        stack.push(frame)

        let blockInstruction = ControlInstruction.block(parameterTypes, expression)
        _ = try execute(blockInstruction)

        let values = try (0 ..< frame.arity).map { _ in try stack.pop(Value.self) }

        assert((try? stack.get(current: Frame.self)) == frame)
        _ = try stack.pop(Frame.self)

        stack.push(values)
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
        case let instruction as ControlInstruction:
            result = try execute(control: instruction)
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
        case let instruction as VariableInstruction:
            try execute(variable: instruction)
            result = .continue
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
            let values = try (0 ..< label.arity).map { _ in try stack.pop(Value.self) }
            let _label = try stack.pop(Label.self)
            assert(label == _label)
            stack.push(values)

        case .break:
            _ = try execute(label.continuation)

        case .return:
            throw Trap.unimplemented()
        }
    }
}
