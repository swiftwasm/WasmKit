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
            try invoke(function: instance.functionAddresses[Int(startIndex)])
        }

        return instance
    }

    /// - Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    public func invoke(function address: FunctionAddress, parameters: [Value] = []) throws {
        let function = store.functions[address.rawValue]
        guard case let .some(parameterTypes, resultTypes) = function.type else {
            throw Trap._raw("any type is not allowed here")
        }

        guard parameterTypes.count == parameters.count else {
            throw Trap._raw("numbers of parameters don't match")
        }

        for (t1, t2) in zip(parameterTypes, parameters) {
            precondition(type(of: t2) == t1)
        }

        stack.push(parameters)

        let locals = function.code.locals.map { $0.init() }
        let expression = function.code.body

        let values = (0 ..< parameterTypes.count).compactMap { _ in stack.pop() as? Value }
        precondition(values.count == parameterTypes.count)

        let frame = Frame(arity: resultTypes.count, module: function.module, locals: values + locals)
        stack.push(frame)

        let blockInstruction = ControlInstruction.block(parameterTypes, expression)
        try execute(blockInstruction)
    }
}

extension Runtime {
    func execute(_ instructions: [Instruction]) throws {
        for instruction in instructions {
            try execute(instruction)
        }
    }

    func execute(_ instruction: Instruction) throws {
        switch instruction {
        case let instruction as ControlInstruction:
            try execute(control: instruction)
        case let instruction as NumericInstruction.Constant:
            try execute(numeric: instruction)
        case let instruction as NumericInstruction.Unary:
            try execute(numeric: instruction)
        case let instruction as VariableInstruction:
            try execute(variable: instruction)
        default:
            throw Trap.unimplemented()
        }
    }
}
