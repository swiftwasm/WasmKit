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
    var currentGlobalCache: CurrentGlobalCache

    fileprivate init(programCounter: ProgramCounter) {
        self.programCounter = programCounter
        self.currentMemory = CurrentMemory()
        self.currentGlobalCache = CurrentGlobalCache()
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
            let parameters = function.type.parameters.enumerated().map { (i, type) in
                stack[callLike.spAddend + Instruction.Register(i)].cast(to: type)
            }
            let moduleInstance = runtime.store.module(address: stack.currentFrame.module)
            let caller = Caller(runtime: runtime, instance: moduleInstance)
            let results = try function.implementation(caller, Array(parameters))
            for (index, result) in results.enumerated() {
                stack[callLike.spAddend + Instruction.Register(index)] = UntypedValue(result)
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
                numberOfNonParameterLocals: function.code.numberOfNonParameterLocals,
                returnPC: programCounter.advanced(by: 1), spAddend: callLike.spAddend,
                address: address
            )
            programCounter = expression.baseAddress
            // TODO(optimize):
            // If the callee is known to be a function defined within the same module,
            // a special `callInternal` instruction can skip updating the current instance
            mayUpdateCurrentInstance(instanceAddr: function.module, store: runtime.store, from: callerModule)
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

    struct CurrentGlobalCache {
        private let _0: UnsafeMutablePointer<GlobalInstance>?
        init(instance: ModuleInstance, store: Store) {
            guard instance.globalAddresses.count > 0 else {
                _0 = nil
                return
            }
            let _0Addr = instance.globalAddresses[0]
            self._0 = store.globals._baseAddressIfContiguous?.advanced(by: _0Addr)
        }
        init() {
            self._0 = nil
        }

        func get(index: GlobalIndex, runtime: Runtime, context: inout StackContext) -> Value {
            if index == 0 {
                return _0!.pointee.value
            }
            let address = Int(currentModule(store: runtime.store, stack: &context).globalAddresses[Int(index)])
            let globals = runtime.store.globals
            let value = globals[address].value
            return value
        }

        func set(index: GlobalIndex, value: UntypedValue, runtime: Runtime, context: inout StackContext) {
            if index == 0 {
                _0!.pointee.assign(value)
                return
            }
            let address = Int(currentModule(store: runtime.store, stack: &context).globalAddresses[Int(index)])
            runtime.store.globals[address].assign(value)
        }
    }

    struct FrameBase {
        let pointer: UnsafeMutablePointer<UntypedValue>

        subscript(_ index: Instruction.Register) -> UntypedValue {
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
            let frameBase = stack.frameBase
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

    mutating func mayUpdateCurrentInstance(
        instanceAddr: ModuleAddress,
        store: Store,
        from lastInstanceAddr: ModuleAddress?
    ) {
        if lastInstanceAddr != instanceAddr {
            mayUpdateCurrentInstance(instanceAddr: instanceAddr, store: store)
        }
    }
    mutating func mayUpdateCurrentInstance(instanceAddr: ModuleAddress, store: Store) {
        let instance = store.module(address: instanceAddr)
        currentMemory = resolveCurrentMemory(instance: instance, store: store)
        currentGlobalCache = CurrentGlobalCache(instance: instance, store: store)
    }
    private func resolveCurrentMemory(instance: ModuleInstance, store: Store) -> CurrentMemory {
        guard let memoryAddr = instance.memoryAddresses.first else {
            return CurrentMemory()
        }
        let memory = store.memory(at: memoryAddr).data
        let baseAddress = memory._baseAddressIfContiguous
        return CurrentMemory(baseAddress: baseAddress, count: memory.count)
    }
}

func currentModule(store: Store, stack: inout StackContext) -> ModuleInstance {
    store.module(address: stack.currentFrame.module)
}
