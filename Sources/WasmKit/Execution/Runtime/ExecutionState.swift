/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
struct ExecutionState {
    var stack = Stack()
    /// Index of an instruction to be executed in the current function.
    var programCounter = 0

    var isStackEmpty: Bool {
        stack.isEmpty
    }
}

extension ExecutionState: CustomStringConvertible {
    var description: String {
        var result = "======== PC=\(programCounter) =========\n"
        result += "\n\(stack.debugDescription)"

        return result
    }
}

extension ExecutionState {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#entering-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    @inline(__always)
    mutating func enter(jumpTo targetPC: Int, continuation: Int, arity: Int, pushPopValues: Int = 0) {
        stack.pushLabel(
            arity: arity,
            continuation: continuation,
            popPushValues: pushPopValues
        )
        programCounter = targetPC
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#exiting-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    mutating func exit(label: Label) throws {
        stack.exit(label: label)
        programCounter += 1
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    mutating func invoke(functionAddress address: FunctionAddress, runtime: Runtime) throws {
        // runtime.interceptor?.onEnterFunction(address, store: runtime.store)

        switch try runtime.store.function(at: address) {
        case let .host(function):
            let parameters = stack.popValues(count: function.type.parameters.count)
            let moduleInstance = runtime.store.module(address: stack.currentFrame.module)
            let caller = Caller(runtime: runtime, instance: moduleInstance)
            stack.push(values: try function.implementation(caller, Array(parameters)))

            programCounter += 1

        case let .wasm(function, body: body):
            let expression = body

            let arity = function.type.results.count
            try stack.pushFrame(
                iseq: expression,
                arity: arity,
                module: function.module,
                argc: function.type.parameters.count,
                defaultLocals: function.code.defaultLocals,
                returnPC: programCounter + 1,
                address: address
            )
            programCounter = 0
        }
    }

    mutating func run(runtime: Runtime) throws {
        while let frame = stack.currentFrame {
            // Regular path
            let inst = frame.iseq.instructions[programCounter]
            try doExecute(inst, runtime: runtime)
        }
    }

    func currentModule(store: Store) -> ModuleInstance {
        store.module(address: stack.currentFrame.module)
    }
}

extension ExecutionState {
    mutating func pseudo(runtime: Runtime, pseudoInstruction: PseudoInstruction) throws {
        fatalError("Unimplemented instruction: pseudo")
    }
}
