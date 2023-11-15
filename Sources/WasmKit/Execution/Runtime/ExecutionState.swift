/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
struct ExecutionState {
    var stack = Stack()
    /// Index of an instruction to be executed in the current function.
    var programCounter = 0

    var isStackEmpty: Bool {
        stack.top == nil
    }
}

extension ExecutionState {
    mutating func execute(_ instruction: Instruction, runtime: Runtime) throws {
        switch instruction {
        case let .control(instruction):
            return try instruction.execute(runtime: runtime, execution: &self)

        case let .memory(instruction):
            try instruction.execute(&stack, runtime.store)

        case let .numeric(instruction):
            try instruction.execute(&stack)

        case let .parametric(instruction):
            try instruction.execute(&stack)

        case let .reference(instruction):
            try instruction.execute(&stack)

        case let .table(instruction):
            try instruction.execute(runtime: runtime, execution: &self)

        case let .variable(instruction):
            try instruction.execute(&stack, &runtime.store.globals)
        case .pseudo:
            // Structured pseudo instructions (end/else) should not appear at runtime
            throw Trap.unreachable
        }

        programCounter += 1
    }

    mutating func branch(labelIndex: Int) throws {
        let label = try stack.getLabel(index: Int(labelIndex))
        let values = try stack.popValues(count: label.arity)

        var lastLabel: Label?
        for _ in 0...labelIndex {
            stack.discardTopValues()
            lastLabel = try stack.popLabel()
        }

        stack.push(values: values)
        programCounter = lastLabel!.continuation
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#entering-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    mutating func enter(_ expression: Expression, continuation: Int, arity: Int) {
        let exit = programCounter + 1
        let label = Label(arity: arity, expression: expression, continuation: continuation, exit: exit)
        stack.push(label: label)
        programCounter = label.expression.instructions.startIndex
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#exiting-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    mutating func exit(label: Label) throws {
        let values = try stack.popTopValues()
        let lastLabel = try stack.popLabel()
        assert(lastLabel == label)
        stack.push(values: values)
        programCounter = label.exit
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    mutating func invoke(functionAddress address: FunctionAddress, runtime: Runtime) throws {
        runtime.interceptor?.onEnterFunction(address, store: runtime.store)

        switch try runtime.store.function(at: address) {
        case let .host(function):
            let parameters = try stack.popValues(count: function.type.parameters.count)
            let caller = Caller(runtime: runtime, instance: stack.currentFrame.module)
            stack.push(values: try function.implementation(caller, parameters))

            programCounter += 1

        case let .wasm(function, body: body):
            let locals = function.code.locals.map { $0.defaultValue }
            let expression = body

            let arguments = try stack.popValues(count: function.type.parameters.count)

            let arity = function.type.results.count
            try stack.push(frame: .init(arity: arity, module: function.module, locals: arguments + locals, address: address))

            self.enter(
                expression, continuation: programCounter + 1,
                arity: arity
            )
        }
    }

    public mutating func step(runtime: Runtime) throws {
        if let label = stack.currentLabel {
            if programCounter < label.expression.instructions.count {
                try execute(stack.currentLabel.expression.instructions[programCounter], runtime: runtime)
            } else {
                try self.exit(label: label)
            }
        } else {
            if let address = stack.currentFrame.address {
                runtime.interceptor?.onExitFunction(address, store: runtime.store)
            }
            let values = try stack.popValues(count: stack.currentFrame.arity)
            try stack.popFrame()
            stack.push(values: values)
        }
    }

    public mutating func run(runtime: Runtime) throws {
        while stack.currentFrame != nil {
            try step(runtime: runtime)
        }
    }
}
