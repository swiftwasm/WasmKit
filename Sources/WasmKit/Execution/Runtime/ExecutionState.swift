typealias ProgramCounter = UnsafePointer<Instruction>

/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
struct ExecutionState {
    /// Index of an instruction to be executed in the current function.
    var programCounter: ProgramCounter
    var reachedEndOfExecution: Bool = false
    var currentMemory: CurrentMemory

    fileprivate init(programCounter: ProgramCounter) {
        self.programCounter = programCounter
        self.currentMemory = CurrentMemory()
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
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    @inline(__always)
    mutating func invoke(
        functionAddress address: FunctionAddress,
        runtime: Runtime,
        stack: inout StackContext,
        callerModule: ModuleAddress? = nil,
        callLike: Instruction.CallLikeOperand = Instruction.CallLikeOperand(spAddend: 0)
    ) throws {
        #if DEBUG
            runtime.interceptor?.onEnterFunction(address, store: runtime.store)
        #endif

        switch try runtime.store.function(at: address) {
        case let .host(function):
            let parameters = (0..<function.type.parameters.count).map {
                stack[callLike.spAddend + UInt16($0)]
            }
            let moduleInstance = runtime.store.module(address: stack.currentFrame.module)
            let caller = Caller(runtime: runtime, instance: moduleInstance)
            let results = try function.implementation(caller, Array(parameters))
            for (index, result) in results.enumerated() {
                stack[callLike.spAddend + UInt16(index)] = result
            }
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
                returnPC: programCounter.advanced(by: 1), spAddend: callLike.spAddend,
                address: address
            )
            programCounter = expression.baseAddress
            // TODO(optimize):
            // If the callee is known to be a function defined within the same module,
            // a special `callInternal` instruction can skip updating the current instance
            if callerModule != function.module {
                mayUpdateCurrentInstance(instanceAddr: function.module, store: runtime.store)
            }
        }
    }

    struct CurrentMemory {
        let baseAddress: UnsafeMutablePointer<UInt8>?
        let count: Int

        var buffer: UnsafeMutableRawBufferPointer {
            UnsafeMutableRawBufferPointer(UnsafeMutableBufferPointer(start: baseAddress, count: count))
        }

        init(baseAddress: UnsafeMutablePointer<UInt8>?, count: Int) {
            self.baseAddress = baseAddress
            self.count = count
        }
        init() {
            self.init(baseAddress: nil, count: 0)
        }
    }

    struct FrameBase {
        let pointer: UnsafeMutablePointer<Value>
        subscript(_ index: Instruction.Register) -> Value {
            get {
                return pointer[Int(index)]
            }
            nonmutating set {
                return pointer[Int(index)] = newValue
            }
        }
    }

    mutating func run(runtime: Runtime, stack: inout StackContext) throws {
        mayUpdateCurrentInstance(store: runtime.store, stack: stack)
        while !reachedEndOfExecution {
            // Regular path
            var frameBase = stack.frameBase
            var inst: Instruction
            // `doExecute` returns false when current frame *may* be updated
            repeat {
                inst = programCounter.pointee
            } while try doExecute(inst, currentMemory: currentMemory, runtime: runtime, context: &stack, stack: frameBase)
        }
    }

    mutating func mayUpdateCurrentInstance(store: Store, stack: StackContext) {
        guard let instanceAddr = stack.currentFrame?.module else {
            currentMemory = CurrentMemory(baseAddress: nil, count: 0)
            return
        }
        mayUpdateCurrentInstance(instanceAddr: instanceAddr, store: store)
    }
    mutating func mayUpdateCurrentInstance(instanceAddr: ModuleAddress, store: Store) {
        currentMemory = resolveCurrentMemory(instanceAddr: instanceAddr, store: store)
    }
    func resolveCurrentMemory(instanceAddr: ModuleAddress, store: Store) -> CurrentMemory {
        let instance = store.module(address: instanceAddr)
        guard let memoryAddr = instance.memoryAddresses.first else {
            return CurrentMemory()
        }
        let memory = store.memory(at: memoryAddr).data
        let baseAddress = memory._baseAddressIfContiguous
        return CurrentMemory(baseAddress: baseAddress, count: memory.count)
    }
    func currentModule(store: Store, stack: inout StackContext) -> ModuleInstance {
        store.module(address: stack.currentFrame.module)
    }
}
