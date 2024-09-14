import _CWasmKit

/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``ExecutionState``
/// even though the invocation happens during another invocation.
struct ExecutionState {
    /// The reference to the ``Runtime`` associated with the execution.
    let runtime: RuntimeRef
    /// The end of the VM stack space.
    private var stackEnd: UnsafeMutablePointer<StackSlot>
    /// The error trap thrown during execution.
    /// This property must not be assigned to be non-nil more than once.
    private var trap: UnsafeRawPointer? = nil

    /// Executes the given closure with a new execution state associated with
    /// the given ``Runtime`` instance.
    static func with<T>(
        runtime: RuntimeRef,
        body: (inout ExecutionState, Sp) throws -> T
    ) rethrows -> T {
        let limit = Int(UInt16.max)
        let valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
        defer {
            valueStack.deallocate()
        }
        var context = ExecutionState(runtime: runtime, stackEnd: valueStack.advanced(by: limit))
        return try body(&context, valueStack)
    }

    /// Gets the current instance from the stack pointer.
    @inline(__always)
    func currentInstance(sp: Sp) -> InternalInstance {
        InternalInstance(bitPattern: UInt(sp[-3].i64)).unsafelyUnwrapped
    }

    /// Pushes a new call frame to the VM stack.
    @inline(__always)
    mutating func pushFrame(
        iseq: InstructionSequence,
        instance: InternalInstance,
        numberOfNonParameterLocals: Int,
        sp: Sp, returnPC: Pc,
        spAddend: VReg
    ) throws -> Sp {
        let newSp = sp.advanced(by: Int(spAddend))
        guard newSp.advanced(by: iseq.maxStackHeight) < stackEnd else {
            throw Trap.callStackExhausted
        }
        // Initialize the locals with zeros (all types of value have the same representation)
        newSp.initialize(repeating: UntypedValue.default.storage, count: numberOfNonParameterLocals)
        newSp[-1] = UInt64(UInt(bitPattern: sp))
        newSp[-2] = UInt64(UInt(bitPattern: returnPC))
        newSp[-3] = UInt64(UInt(bitPattern: instance.bitPattern))
        return newSp
    }

    /// Pops the current frame from the VM stack.
    @inline(__always)
    mutating func popFrame(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) {
        let oldSp = sp
        sp = Sp(bitPattern: UInt(oldSp[-1])).unsafelyUnwrapped
        pc = Pc(bitPattern: UInt(oldSp[-2])).unsafelyUnwrapped
        let toInstance = InternalInstance(bitPattern: UInt(oldSp[-3])).unsafelyUnwrapped
        let fromInstance = InternalInstance(bitPattern: UInt(sp[-3]))
        CurrentMemory.mayUpdateCurrentInstance(instance: toInstance, from: fromInstance, md: &md, ms: &ms)
    }
}

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

/// A slot of VM stack
typealias StackSlot = UInt64

/// A slot of code sequence
typealias CodeSlot = UInt64

/// The "m"emory "d"ata storage intended to be bound to a physical register.
/// Stores the base address of the default memory of the current execution context.
typealias Md = UnsafeMutableRawPointer?
/// The "m"emory "s"ize intended to be bound to a physical register.
/// Stores the size of the default memory of the current execution context.
typealias Ms = Int
/// The "s"tack "p"ointer intended to be bound to a physical register.
/// Stores the base address of the current frame's register storage.
typealias Sp = UnsafeMutablePointer<StackSlot>
/// The program counter pointing to the current instruction.
/// - Note: This pointer is mutable to allow patching the instruction during execution.
///         For example, "compile" VM instruction lazily compiles the callee function and
///         replaces the instruction with the "internalCall" instruction to bypass
///         "is compiled" check on the next execution.
typealias Pc = UnsafeMutablePointer<CodeSlot>

extension Pc {
    /// Reads a value from the current program counter and advances the pointer.
    mutating func read<T>(_: T.Type = T.self) -> T {
        assert(MemoryLayout<T>.stride == 8)
        let value = self.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        self += 1
        return value
    }
}

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
    return try ExecutionState.with(runtime: runtime) { (stack, sp) in
        // Advance the stack pointer to be able to reference negative indices
        // for saving slots.
        let sp = sp.advanced(by: FrameHeaderLayout.numberOfSavingSlots)
        for (index, argument) in arguments.enumerated() {
            sp[VReg(index)] = UntypedValue(argument)
        }

        try withUnsafeTemporaryAllocation(of: CodeSlot.self, capacity: 2) { rootISeq in
            switch runtime.value.configuration.threadingModel {
            case .direct:
                rootISeq[0] = Instruction.endOfExecution.handler
            case .token:
                rootISeq[0] = UInt64(Instruction.endOfExecution.rawIndex)
            }
            try stack.execute(
                sp: sp,
                pc: rootISeq.baseAddress!,
                handle: handle,
                type: type
            )
        }
        return type.results.enumerated().map { (i, type) in
            sp[VReg(i)].cast(to: type)
        }
    }
}

extension ExecutionState {
    /// A namespace for the "current memory" (Md and Ms) management.
    enum CurrentMemory {
        /// Assigns the current memory to the given internal memory.
        @inline(__always)
        private static func assign(md: inout Md, ms: inout Ms, memory: InternalMemory) {
            memory.withValue { assign(md: &md, ms: &ms, memory: &$0) }
        }

        /// Assigns the current memory to the given memory entity.
        @inline(__always)
        static func assign(md: inout Md, ms: inout Ms, memory: inout MemoryEntity) {
            md = UnsafeMutableRawPointer(memory.data._baseAddressIfContiguous)
            ms = memory.data.count
        }

        /// Assigns the current memory to nil.
        @inline(__always)
        private static func assignNil(md: inout Md, ms: inout Ms) {
            md = nil
            ms = 0
        }

        /// Updates the current memory if the instance has changed.
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

        /// Updates the current memory if the instance has the default memory instance.
        @inline(__always)
        static func mayUpdateCurrentInstance(instance: InternalInstance, md: inout Md, ms: inout Ms) {
            guard let memory = instance.memories.first else {
                assignNil(md: &md, ms: &ms)
                return
            }
            CurrentMemory.assign(md: &md, ms: &ms, memory: memory)
        }
    }

    /// A ``Error`` thrown when the execution normally ends.
    struct EndOfExecution: Error {}

    /// The entry point for the execution of the WebAssembly function.
    @inline(never)
    mutating func execute(
        sp: Sp, pc: Pc,
        handle: InternalFunction,
        type: FunctionType
    ) throws {
        var sp: Sp = sp, md: Md = nil, ms: Ms = 0, pc = pc
        (pc, sp) = try invoke(
            function: handle,
            callerInstance: nil,
            callLike: Instruction.CallLikeOperand(
                spAddend: FrameHeaderLayout.size(of: type)
            ),
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        do {
            switch self.runtime.value.configuration.threadingModel {
            case .direct:
                try runDirectThreaded(sp: sp, pc: pc, md: md, ms: ms)
            case .token:
                try runTokenThreaded(sp: &sp, pc: &pc, md: &md, ms: &ms)
            }
        } catch is EndOfExecution {
            return
        }
    }

    /// Starts the main execution loop using the direct threading model.
    @inline(never)
    mutating func runDirectThreaded(
        sp: Sp, pc: Pc, md: Md, ms: Ms
    ) throws {
        var pc = pc
        let handler = pc.read(wasmkit_tc_exec.self)
        wasmkit_tc_start(handler, sp, pc, md, ms, &self)
        if let error = self.trap {
            throw unsafeBitCast(error, to: Error.self)
        }
    }

    /// Starts the main execution loop using the token threading model.
    /// Be careful when modifying this function as it is performance-critical.
    @inline(__always)
    mutating func runTokenThreaded(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) throws {
#if WASMKIT_ENGINE_STATS
        var stats: [String: Int] = [:]
        defer {
            for (name, count) in stats.sorted(by: { $0.value < $1.value }) {
                print(count, name)
            }
        }
#endif
        var inst: UInt64
        while true {
            inst = pc.read(UInt64.self)
#if WASMKIT_ENGINE_STATS
            stats[inst.name, default: 0] += 1
#endif
            try doExecute(inst, sp: &sp, pc: &pc, md: &md, ms: &ms)
        }
    }

    /// Sets the error trap thrown during execution.
    ///
    /// - Note: This function is called by C instruction handlers at most once.
    /// It's used only when direct threading is enabled.
    /// - Parameter trap: The error trap thrown during execution.
    @_silgen_name("wasmkit_execution_state_set_error")
    mutating func setError(_ trap: UnsafeRawPointer) {
        precondition(self.trap == nil)
        self.trap = trap
    }

    /// Returns the new program counter and stack pointer.
    @inline(never)
    mutating func invoke(
        function: InternalFunction,
        callerInstance: InternalInstance?,
        callLike: Instruction.CallLikeOperand,
        sp: Sp, pc: Pc, md: inout Md, ms: inout Ms
    ) throws -> (Pc, Sp) {
        if function.isWasm {
            let function = function.wasm
            let iseq = try function.withValue {
                try $0.ensureCompiled(context: &self)
            }

            let newSp = try pushFrame(
                iseq: iseq,
                instance: function.instance,
                numberOfNonParameterLocals: function.numberOfNonParameterLocals,
                sp: sp,
                returnPC: pc,
                spAddend: callLike.spAddend
            )
            ExecutionState.CurrentMemory.mayUpdateCurrentInstance(
                instance: function.instance,
                from: callerInstance, md: &md, ms: &ms
            )
            return (iseq.baseAddress, newSp)
        } else {
            let function = function.host
            let resolvedType = runtime.value.resolveType(function.type)
            let layout = FrameHeaderLayout(type: resolvedType)
            let parameters = resolvedType.parameters.enumerated().map { (i, type) in
                sp[callLike.spAddend + layout.paramReg(i)].cast(to: type)
            }
            let instance = self.currentInstance(sp: sp)
            let caller = Caller(
                instanceHandle: instance,
                runtime: runtime.value
            )
            let results = try function.implementation(caller, Array(parameters))
            for (index, result) in results.enumerated() {
                sp[callLike.spAddend + layout.returnReg(index)] = UntypedValue(result)
            }
            return (pc, sp)
        }
    }
}

extension Sp {
    subscript<R: FixedWidthInteger>(_ index: R) -> UntypedValue {
        get {
            return UntypedValue(storage: self[Int(index)])
        }
        nonmutating set {
            return self[Int(index)] = newValue.storage
        }
    }
    private func read<T: FixedWidthInteger, R: FixedWidthInteger>(_ index: R) -> T {
        return self.advanced(by: Int(index)).withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
    private func write<R: FixedWidthInteger>(_ index: R, _ value: UntypedValue) {
        self[Int(index)] = value
    }
    subscript<R: FixedWidthInteger>(i32 index: R) -> UInt32 {
        get { return read(index) }
        nonmutating set { write(index, .i32(newValue)) }
    }
    subscript<R: FixedWidthInteger>(i64 index: R) -> UInt64 {
        get { return read(index) }
        nonmutating set { write(index, .i64(newValue)) }
    }
    subscript<R: FixedWidthInteger>(f32 index: R) -> Float32 {
        get { return Float32(bitPattern: read(index)) }
        nonmutating set { write(index, .f32(newValue)) }
    }
    subscript<R: FixedWidthInteger>(f64 index: R) -> Float64 {
        get { return Float64(bitPattern: read(index)) }
        nonmutating set { write(index, .f64(newValue)) }
    }
}
