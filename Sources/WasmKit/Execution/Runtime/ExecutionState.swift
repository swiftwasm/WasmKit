typealias ProgramCounter = UnsafePointer<Instruction>

/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
struct ExecutionState {
    /// Index of an instruction to be executed in the current function.
    var programCounter: ProgramCounter
    var reachedEndOfExecution: Bool = false

    fileprivate init(programCounter: ProgramCounter) {
        self.programCounter = programCounter
    }
}

@_transparent
func withExecution<Return>(_ body: (inout ExecutionState) throws -> Return) rethrows -> Return {
    try withUnsafeTemporaryAllocation(of: Instruction.self, capacity: 1) { rootISeq in
        rootISeq.baseAddress?.pointee = .endOfExecution
        // NOTE: unwinding a function jump into previous frame's PC + 1, so initial PC is -1ed
        var execution = ExecutionState(programCounter: rootISeq.baseAddress! - 1)
        return try body(&execution)
    }
}

extension ExecutionState: CustomStringConvertible {
    var description: String {
        let result = "======== PC=\(programCounter) =========\n"

        return result
    }
}

extension ExecutionState {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#entering-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    @inline(__always)
    mutating func enter(jumpTo targetPC: ProgramCounter, continuation: ProgramCounter, stack: inout Stack, arity: Int, pushPopValues: Int = 0) {
        stack.pushLabel(
            arity: arity,
            continuation: continuation,
            popPushValues: pushPopValues
        )
        programCounter = targetPC
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#exiting-xref-syntax-instructions-syntax-instr-mathit-instr-ast-with-label-l>
    mutating func exitLabel(stack: inout Stack) throws {
        stack.exitLabel()
        programCounter += 1
    }

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    mutating func invoke(functionAddress address: FunctionAddress, runtime: Runtime, stack: inout Stack) throws {
        #if DEBUG
        runtime.interceptor?.onEnterFunction(address, store: runtime.store)
        #endif

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
                returnPC: programCounter.advanced(by: 1),
                address: address
            )
            programCounter = expression.baseAddress
        }
    }

    mutating func run(runtime: Runtime, stack: inout Stack) throws {
        while !reachedEndOfExecution {
            let locals = stack.currentLocalsPointer
            // Regular path
            var inst: Instruction
            // `doExecute` returns false when current frame *may* be updated
            repeat {
                inst = programCounter.pointee
            } while try doExecute(inst, runtime: runtime, stack: &stack, locals: locals)
        }
    }

    func currentModule(store: Store, stack: inout Stack) -> ModuleInstance {
        store.module(address: stack.currentFrame.module)
    }
}

extension ExecutionState {
    mutating func pseudo(runtime: Runtime, pseudoInstruction: PseudoInstruction) throws {
        fatalError("Unimplemented instruction: pseudo")
    }
}
