/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
typealias ExecutionState = StackContext

/// An unmanaged reference to a runtime.
/// - Note: This is used to avoid ARC overhead during VM execution.
struct RuntimeRef {
    private let _value: Unmanaged<Runtime>

    var value: Runtime {
        _value.takeUnretainedValue()
    }

    var store: Store {
        value.store
    }

    init(_ value: __shared Runtime) {
        self._value = .passUnretained(value)
    }
}

/// The "m"emory "d"ata storage intended to be bound to a physical register.
/// Stores the base address of the default memory of the current execution context.
typealias Md = UnsafeMutableRawPointer?
/// The "m"emory "s"ize intended to be bound to a physical register.
/// Stores the size of the default memory of the current execution context.
typealias Ms = Int
/// The "s"tack "p"ointer intended to be bound to a physical register.
/// Stores the base address of the current frame's register storage.
typealias Sp = UnsafeMutablePointer<UntypedValue>
/// The program counter pointing to the current instruction.
/// - Note: This pointer is mutable to allow patching the instruction during execution.
///         For example, "compile" VM instruction lazily compiles the callee function and
///         replaces the instruction with the "internalCall" instruction to bypass
///         "is compiled" check on the next execution.
typealias Pc = UnsafeMutablePointer<Instruction>

/// Executes a WebAssembly function.
///
/// - Parameters:
///   - runtime: The runtime instance.
///   - function: The function to be executed.
///   - type: The function type.
///   - arguments: The arguments to be passed to the function.
///   - callerInstance: The instance that called the function.
/// - Returns: The result values of the function.
@inline(never)
func executeWasm(
    runtime: Runtime,
    function handle: InternalFunction,
    type: FunctionType,
    arguments: [Value],
    callerInstance: InternalInstance
) throws -> [Value] {
    // NOTE: `runtime` variable must not outlive this function
    let runtime = RuntimeRef(runtime)
    return try StackContext.withContext(runtime: runtime) { (stack, sp) in
        for (index, argument) in arguments.enumerated() {
            sp[Instruction.Register(index)] = UntypedValue(argument)
        }
        try withUnsafeTemporaryAllocation(of: Instruction.self, capacity: 1) { rootISeq in
            rootISeq.baseAddress?.pointee = .endOfExecution
            // NOTE: unwinding a function jump into previous frame's PC + 1, so initial PC is -1ed
            try ExecutionState.execute(
                sp: sp,
                pc: rootISeq.baseAddress! - 1,
                handle: handle,
                type: type,
                stack: &stack
            )
        }
        return type.results.enumerated().map { (i, type) in
            sp[Instruction.Register(i)].cast(to: type)
        }
    }
}

extension ExecutionState {
    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address>
    @inline(never)
    mutating func invoke(
        function: InternalFunction,
        callerInstance: InternalInstance?,
        callLike: Instruction.CallLikeOperand,
        sp: Sp, pc: Pc, md: inout Md, ms: inout Ms
    ) throws -> (Pc, Sp) {
        return try function.execute(
            executionState: &self,
            callerInstance: callerInstance,
            callLike: callLike,
            sp: sp, pc: pc, md: &md, ms: &ms
        )
    }

    struct CurrentMemory {
        @inline(__always)
        static func assign(md: inout Md, ms: inout Ms, memory: InternalMemory) {
            memory.withValue { assign(md: &md, ms: &ms, memory: &$0) }
        }

        @inline(__always)
        static func assign(md: inout Md, ms: inout Ms, memory: inout MemoryEntity) {
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

    @inline(never)
    static func execute(
        sp: Sp, pc: Pc,
        handle: InternalFunction,
        type: FunctionType,
        stack: inout StackContext
    ) throws {
        var sp: Sp = sp, md: Md = nil, ms: Ms = 0, pc = pc
        (pc, sp) = try stack.invoke(
            function: handle,
            callerInstance: nil,
            callLike: Instruction.CallLikeOperand(
                spAddend: StackLayout.frameHeaderSize(type: type)
            ),
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        try stack.run(sp: &sp, pc: &pc, md: &md, ms: &ms)
    }

    /// The main execution loop. Be careful when modifying this function as it is performance-critical.
    @inline(__always)
    mutating func run(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) throws {
        CurrentMemory.mayUpdateCurrentInstance(stack: self, md: &md, ms: &ms)
#if WASMKIT_ENGINE_STATS
        var stats: [String: Int] = [:]
        defer {
            for (name, count) in stats.sorted(by: { $0.value < $1.value }) {
                print(count, name)
            }
        }
#endif
        while !reachedEndOfExecution {
            var inst: Instruction
            repeat {
                inst = pc.pointee
#if WASMKIT_ENGINE_STATS
                stats[inst.name, default: 0] += 1
#endif
            // `doExecute` returns false when current frame *may* be updated
            } while try doExecute(inst, sp: &sp, pc: &pc, md: &md, ms: &ms)
        }
    }
}

extension InternalFunction {
    /// Returns the new program counter after the function call.
    @inline(__always)
    func execute(
        executionState: inout ExecutionState,
        callerInstance: InternalInstance?,
        callLike: Instruction.CallLikeOperand,
        sp: Sp, pc: Pc, md: inout Md, ms: inout Ms
    ) throws -> (Pc, Sp) {
        if self.isWasm {
            let function = wasm
            let iseq = try function.withValue {
                try $0.ensureCompiled(context: &executionState)
            }
            
            let newSp = try executionState.pushFrame(
                iseq: iseq,
                instance: function.instance,
                numberOfNonParameterLocals: function.numberOfNonParameterLocals,
                sp: sp,
                returnPC: pc.advanced(by: 1),
                spAddend: callLike.spAddend
            )
            ExecutionState.CurrentMemory.mayUpdateCurrentInstance(
                instance: function.instance,
                from: callerInstance, md: &md, ms: &ms
            )
            return (iseq.baseAddress, newSp)
        } else {
            let function = host
            let runtime = executionState.runtime
            let resolvedType = runtime.value.resolveType(function.type)
            let layout = StackLayout(type: resolvedType)
            let parameters = resolvedType.parameters.enumerated().map { (i, type) in
                sp[callLike.spAddend + layout.paramReg(i)].cast(to: type)
            }
            let instance = executionState.currentFrame.instance
            let caller = Caller(
                instanceHandle: instance,
                runtime: runtime.value
            )
            let results = try function.implementation(caller, Array(parameters))
            for (index, result) in results.enumerated() {
                sp[callLike.spAddend + layout.returnReg(index)] = UntypedValue(result)
            }
            return (pc.advanced(by: 1), sp)
        }
    }
}

extension Sp {
    subscript(_ index: Instruction.Register) -> UntypedValue {
        get {
            return self[Int(index)]
        }
        nonmutating set {
            return self[Int(index)] = newValue
        }
    }
    private func read<T: FixedWidthInteger>(_ index: Instruction.Register) -> T {
        return self.advanced(by: Int(index)).withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
    private func write(_ index: Instruction.Register, _ value: UntypedValue) {
        self[index] = value
    }
    subscript(i32 index: Instruction.Register) -> UInt32 {
        get { return read(index) }
        nonmutating set { write(index, .i32(newValue)) }
    }
    subscript(i64 index: Instruction.Register) -> UInt64 {
        get { return read(index) }
        nonmutating set { write(index, .i64(newValue)) }
    }
    subscript(f32 index: Instruction.Register) -> Float32 {
        get { return Float32(bitPattern: read(index)) }
        nonmutating set { write(index, .f32(newValue)) }
    }
    subscript(f64 index: Instruction.Register) -> Float64 {
        get { return Float64(bitPattern: read(index)) }
        nonmutating set { write(index, .f64(newValue)) }
    }
}
