typealias ProgramCounter = UnsafeMutablePointer<Instruction>

/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
struct ExecutionState {
    /// Index of an instruction to be executed in the current function.
    var programCounter: ProgramCounter
    var reachedEndOfExecution: Bool = false
    let runtime: RuntimeRef

    fileprivate init(programCounter: ProgramCounter, runtime: RuntimeRef) {
        self.programCounter = programCounter
        self.runtime = runtime
    }
}


typealias Md = UnsafeMutableRawPointer?
typealias Ms = Int
typealias Sp = ExecutionState.FrameBase

@inline(never)
func executeWasm(
    runtime: Runtime,
    function handle: InternalFunction,
    type: FunctionType,
    arguments: [Value],
    callerInstance: InternalInstance
) throws -> [Value] {
    var stack = StackContext()
    defer { stack.deallocate() }
    for (index, argument) in arguments.enumerated() {
        stack.frameBase[Instruction.Register(index)] = UntypedValue(argument)
    }
    let runtime = RuntimeRef(runtime)
    try withUnsafeTemporaryAllocation(of: Instruction.self, capacity: 1) { rootISeq in
        rootISeq.baseAddress?.pointee = .endOfExecution
        // NOTE: unwinding a function jump into previous frame's PC + 1, so initial PC is -1ed
        try ExecutionState.execute(
            programCounter: rootISeq.baseAddress! - 1,
            runtime: runtime,
            handle: handle,
            type: type,
            stack: &stack
        )
    }
    return type.results.enumerated().map { (i, type) in
        stack.frameBase[Instruction.Register(i)].cast(to: type)
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
        function: InternalFunction,
        stack: inout StackContext,
        callerInstance: InternalInstance?,
        callLike: Instruction.CallLikeOperand = Instruction.CallLikeOperand(spAddend: 0),
        md: inout Md, ms: inout Ms
    ) throws {
        #if DEBUG
            // runtime.interceptor?.onEnterFunction(address, store: runtime.store)
        #endif

        try function.execute(
            stack: &stack,
            executionState: &self,
            callerInstance: callerInstance,
            callLike: callLike,
            md: &md, ms: &ms
        )
    }

    struct CurrentMemory {
        @inline(__always)
        static func assign(md: inout Md, ms: inout Ms, memory: InternalMemory) {
            md = UnsafeMutableRawPointer(memory.data._baseAddressIfContiguous)
            ms = memory.data.count
        }

        @inline(__always)
        static func assignNil(md: inout Md, ms: inout Ms) {
            md = nil
            ms = 0
        }

        @inline(__always)
        static func mayUpdateCurrentInstance(stack: StackContext, md: inout Md, ms: inout Ms) {
            guard let instance = stack.currentFrame?.instance else {
                assignNil(md: &md, ms: &ms)
                return
            }
            mayUpdateCurrentInstance(instance: instance, md: &md, ms: &ms)
        }

        @inline(__always)
        static func mayUpdateCurrentInstance(
            instance: InternalInstance,
            from lastInstance: InternalInstance?,
            md: inout Md, ms: inout Ms
        ) {
            if lastInstance != instance {
                mayUpdateCurrentInstance(instance: instance, md: &md, ms: &ms)
            }
        }
        @inline(__always)
        static func mayUpdateCurrentInstance(instance: InternalInstance, md: inout Md, ms: inout Ms) {
            guard let memory = instance.memories.first else {
                assignNil(md: &md, ms: &ms)
                return
            }
            CurrentMemory.assign(md: &md, ms: &ms, memory: memory)
        }
    }

    struct CurrentGlobalCache {
        private let _0: InternalGlobal?
        init(instance: InternalInstance) {
            self._0 = instance.globals.first
        }
        init() {
            self._0 = nil
        }

        func get(index: GlobalIndex, context: inout StackContext) -> Value {
            if index == 0 {
                return _0!.value
            }
            let instance = context.currentFrame.instance
            let global = instance.globals[Int(index)]
            return global.value
        }

        func set(index: GlobalIndex, value: UntypedValue, context: inout StackContext) {
            if index == 0 {
                _0!.withValue { $0.assign(value) }
                return
            }
            let instance = context.currentFrame.instance
            let global = instance.globals[Int(index)]
            global.withValue { $0.assign(value) }
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

    @inline(never)
    static func execute(
        programCounter: ProgramCounter,
        runtime: RuntimeRef,
        handle: InternalFunction,
        type: FunctionType,
        stack: inout StackContext
    ) throws {
        var md: Md = nil, ms: Ms = 0
        var execution = ExecutionState(programCounter: programCounter, runtime: runtime)
        try execution.invoke(
            function: handle,
            stack: &stack,
            callerInstance: nil,
            callLike: Instruction.CallLikeOperand(
                spAddend: StackLayout.paramResultSize(type: type)
            ),
            md: &md, ms: &ms
        )
        try execution.run(stack: &stack, md: &md, ms: &ms)
    }

    @inline(__always)
    mutating func run(stack: inout StackContext, md: inout Md, ms: inout Ms) throws {
        CurrentMemory.mayUpdateCurrentInstance(stack: stack, md: &md, ms: &ms)
        while !reachedEndOfExecution {
            // Regular path
            let sp = stack.frameBase
            var inst: Instruction
            // `doExecute` returns false when current frame *may* be updated
            repeat {
                inst = programCounter.pointee
            } while try doExecute(inst, md: &md, ms: &ms, context: &stack, sp: sp)
        }
    }
}

extension InternalFunction {
    @inline(__always)
    func execute(
        stack: inout StackContext,
        executionState: inout ExecutionState,
        callerInstance: InternalInstance?,
        callLike: Instruction.CallLikeOperand,
        md: inout Md, ms: inout Ms
    ) throws {
        if self.isWasm {
            let function = wasm
            let iseq = try function.withValue {
                try $0.ensureCompiled(executionState: &executionState)
            }
            
            try stack.pushFrame(
                iseq: iseq,
                instance: function.instance,
                numberOfNonParameterLocals: function.numberOfNonParameterLocals,
                returnPC: executionState.programCounter.advanced(by: 1),
                spAddend: callLike.spAddend
            )
            executionState.programCounter = iseq.baseAddress
            // TODO(optimize):
            // If the callee is known to be a function defined within the same module,
            // a special `callInternal` instruction can skip updating the current instance
            ExecutionState.CurrentMemory.mayUpdateCurrentInstance(
                instance: function.instance,
                from: callerInstance, md: &md, ms: &ms
            )
        } else {
            let function = host
            let runtime = executionState.runtime
            let resolvedType = runtime.value.resolveType(function.type)
            let layout = StackLayout(type: resolvedType)
            let parameters = resolvedType.parameters.enumerated().map { (i, type) in
                stack.frameBase[callLike.spAddend + layout.paramReg(i)].cast(to: type)
            }
            let instance = stack.currentFrame.instance
            let caller = Caller(
                instanceHandle: instance,
                runtime: runtime.value
            )
            let results = try function.implementation(caller, Array(parameters))
            for (index, result) in results.enumerated() {
                stack.frameBase[callLike.spAddend + layout.returnReg(index)] = UntypedValue(result)
            }
            executionState.programCounter += 1
        }
    }
}
