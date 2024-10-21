import _CWasmKit

/// An execution state of an invocation of exported function.
///
/// Each new invocation through exported function has a separate ``Execution``
/// even though the invocation happens during another invocation.
struct Execution {
    /// The reference to the ``Store`` associated with the execution.
    let store: StoreRef
    /// The end of the VM stack space.
    private var stackEnd: UnsafeMutablePointer<StackSlot>
    /// The error trap thrown during execution.
    /// This property must not be assigned to be non-nil more than once.
    /// - Note: If the trap is set, it must be released manually.
    private var trap: UnsafeRawPointer? = nil

    /// Executes the given closure with a new execution state associated with
    /// the given ``Store`` instance.
    static func with<T>(
        store: StoreRef,
        body: (inout Execution, Sp) throws -> T
    ) rethrows -> T {
        let limit = store.value.engine.configuration.stackSize / MemoryLayout<StackSlot>.stride
        let valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
        defer {
            valueStack.deallocate()
        }
        var context = Execution(store: store, stackEnd: valueStack.advanced(by: limit))
        defer {
            if let trap = context.trap {
                // Manually release the error object because the trap is caught in C and
                // held as a raw pointer.
                wasmkit_swift_errorRelease(trap)
            }
        }
        return try body(&context, valueStack)
    }

    /// Gets the current instance from the stack pointer.
    @inline(__always)
    func currentInstance(sp: Sp) -> InternalInstance {
        sp.currentInstance.unsafelyUnwrapped
    }

    /// An iterator for the call frames in the VM stack.
    struct FrameIterator: IteratorProtocol {
        struct Element {
            let pc: Pc
        }

        /// The stack pointer currently traversed.
        private var sp: Sp?

        init(sp: Sp) {
            self.sp = sp
        }

        mutating func next() -> Element? {
            guard let sp = self.sp else {
                // Reached the root frame, whose stack pointer is nil.
                return nil
            }
            let pc = sp.returnPC
            self.sp = sp.previousSP
            return Element(pc: pc)
        }
    }

    /// Returns an iterator for the call frames in the VM stack.
    ///
    /// - Parameter sp: The stack pointer of the current frame.
    /// - Returns: An iterator for the call frames in the VM stack.
    static func frames(sp: Sp) -> FrameIterator {
        return FrameIterator(sp: sp)
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
            throw Trap(.callStackExhausted)
        }
        // Initialize the locals with zeros (all types of value have the same representation)
        newSp.initialize(repeating: UntypedValue.default.storage, count: numberOfNonParameterLocals)
        if let constants = iseq.constants.baseAddress {
            let count = iseq.constants.count
            newSp.advanced(by: numberOfNonParameterLocals).withMemoryRebound(to: UntypedValue.self, capacity: count) {
                $0.initialize(from: constants, count: count)
            }
        }
        newSp.previousSP = sp
        newSp.returnPC = returnPC
        newSp.currentInstance = instance
        return newSp
    }

    /// Pops the current frame from the VM stack.
    @inline(__always)
    mutating func popFrame(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) {
        let oldSp = sp
        sp = oldSp.previousSP.unsafelyUnwrapped
        pc = oldSp.returnPC
        let toInstance = oldSp.currentInstance.unsafelyUnwrapped
        let fromInstance = sp.currentInstance
        CurrentMemory.mayUpdateCurrentInstance(instance: toInstance, from: fromInstance, md: &md, ms: &ms)
    }
}

/// An unmanaged reference to a ``Store`` instance.
/// - Note: This is used to avoid ARC overhead during VM execution.
struct StoreRef {
    private let _value: Unmanaged<Store>

    var value: Store {
        _value.takeUnretainedValue()
    }

    init(_ value: __shared Store) {
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

extension Sp {
    subscript<R: FixedWidthInteger>(_ index: R) -> UntypedValue {
        get {
            return UntypedValue(storage: self[Int(index)])
        }
        nonmutating set {
            self[Int(index)] = newValue.storage
            return
        }
    }

    subscript<R: ShiftedVReg>(_ index: R) -> UntypedValue {
        get {
            return UntypedValue(storage: read(shifted: index))
        }
        nonmutating set {
            write(shifted: index, newValue)
        }
    }

    private func read<T: FixedWidthInteger, R: ShiftedVReg>(shifted index: R) -> T {
        return UnsafeRawPointer(self).advanced(by: Int(index.value)).withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
    private func read<T: FixedWidthInteger, R: FixedWidthInteger>(_ index: R) -> T {
        return self.advanced(by: Int(index)).withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee
        }
    }
    private func write<R: ShiftedVReg>(shifted index: R, _ value: UntypedValue) {
        UnsafeMutableRawPointer(self).advanced(by: Int(index.value)).storeBytes(of: value.storage, as: UInt64.self)
    }
    private func write<R: FixedWidthInteger>(_ index: R, _ value: UntypedValue) {
        self[Int(index)] = value
    }

    subscript<R: ShiftedVReg>(i32 index: R) -> UInt32 {
        get { return read(shifted: index) }
        nonmutating set { write(shifted: index, .i32(newValue)) }
    }
    subscript<R: ShiftedVReg>(i64 index: R) -> UInt64 {
        get { return read(shifted: index) }
        nonmutating set { write(shifted: index, .i64(newValue)) }
    }
    subscript<R: ShiftedVReg>(f32 index: R) -> Float32 {
        get { return Float32(bitPattern: read(shifted: index)) }
        nonmutating set { write(shifted: index, .f32(newValue)) }
    }
    subscript<R: ShiftedVReg>(f64 index: R) -> Float64 {
        get { return Float64(bitPattern: read(shifted: index)) }
        nonmutating set { write(shifted: index, .f64(newValue)) }
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

    // MARK: - Special slots

    /// The current instance of the execution context.
    fileprivate var currentInstance: InternalInstance? {
        get { return InternalInstance(bitPattern: UInt(self[-3].i64)) }
        nonmutating set { self[-3] = UInt64(UInt(bitPattern: newValue?.bitPattern ?? 0)) }
    }

    /// The return program counter of the current frame.
    fileprivate var returnPC: Pc {
        get { return Pc(bitPattern: UInt(self[-2]))! }
        nonmutating set { self[-2] = UInt64(UInt(bitPattern: newValue)) }
    }

    /// The previous stack pointer of the current frame.
    fileprivate var previousSP: Sp? {
        get { return Sp(bitPattern: UInt(self[-1])) }
        nonmutating set { self[-1] = UInt64(UInt(bitPattern: newValue)) }
    }
}

extension Pc {
    /// Reads a value from the current program counter and advances the pointer.
    mutating func read<T>(_: T.Type = T.self) -> T {
        assert(MemoryLayout<T>.stride == 8)
        let value = self.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        self += 1
        return value
    }

    func next() -> (Pc, CodeSlot) {
        return (self.advanced(by: 1), pointee)
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
    store: Store,
    function handle: InternalFunction,
    type: FunctionType,
    arguments: [Value],
    callerInstance: InternalInstance
) throws -> [Value] {
    // NOTE: `runtime` variable must not outlive this function
    let store = StoreRef(store)
    return try Execution.with(store: store) { (stack, sp) in
        // Advance the stack pointer to be able to reference negative indices
        // for saving slots.
        let sp = sp.advanced(by: FrameHeaderLayout.numberOfSavingSlots)
        sp.previousSP = nil  // Mark root stack pointer as nil.
        for (index, argument) in arguments.enumerated() {
            sp[VReg(index)] = UntypedValue(argument)
        }

        try withUnsafeTemporaryAllocation(of: CodeSlot.self, capacity: 2) { rootISeq in
            rootISeq[0] = Instruction.endOfExecution.headSlot(
                threadingModel: store.value.engine.configuration.threadingModel
            )
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

extension Execution {
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
        var sp: Sp = sp
        var md: Md = nil
        var ms: Ms = 0
        var pc = pc
        (pc, sp) = try invoke(
            function: handle,
            callerInstance: nil,
            spAddend: FrameHeaderLayout.size(of: type),
            sp: sp, pc: pc, md: &md, ms: &ms
        )
        do {
            switch self.store.value.engine.configuration.threadingModel {
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

    #if EngineStats
        /// A helper structure for collecting instruction statistics.
        /// - Note: This is used only when the `EngineStats` flag is enabled.
        struct StatsCollector {
            struct Trigram: Hashable {
                var a: UInt64
                var b: UInt64
                var c: UInt64
            }

            struct CircularBuffer<T> {
                private var buffer: [T?]
                private var index: Int = 0

                init(capacity: Int) {
                    buffer = Array(repeating: nil, count: capacity)
                }

                /// Accesses the element at the specified position counted from the oldest element.
                subscript(_ index: Int) -> T? {
                    get {
                        return buffer[(self.index + index) % buffer.count]
                    }
                    set {
                        buffer[(self.index + index) % buffer.count] = newValue
                    }
                }

                mutating func append(_ value: T) {
                    buffer[index] = value
                    index = (index + 1) % buffer.count
                }
            }

            /// A dictionary that stores the count of each trigram pattern.
            private var countByTrigram: [Trigram: Int] = [:]
            /// A circular buffer that stores the last three instructions.
            private var buffer = CircularBuffer<UInt64>(capacity: 3)

            /// Tracks the given instruction index. This function is called for each instruction execution.
            mutating func track(_ opcode: UInt64) {
                buffer.append(opcode)
                if let a = buffer[0], let b = buffer[1], let c = buffer[2] {
                    let trigram = Trigram(a: a, b: b, c: c)
                    countByTrigram[trigram, default: 0] += 1
                }
            }

            func dump<TargetStream: TextOutputStream>(target: inout TargetStream, limit: Int) {
                print("Instruction statistics:", to: &target)
                for (trigram, count) in countByTrigram.sorted(by: { $0.value > $1.value }).prefix(limit) {
                    print("  \(Instruction.name(opcode: trigram.a)) -> \(Instruction.name(opcode: trigram.b)) -> \(Instruction.name(opcode: trigram.c)) = \(count)", to: &target)
                }
            }

            /// Dumps the instruction statistics to the standard error output stream.
            func dump(limit: Int = 10) {
                var target = _Stderr()
                dump(target: &target, limit: limit)
            }
        }
    #endif

    /// Starts the main execution loop using the token threading model.
    /// Be careful when modifying this function as it is performance-critical.
    @inline(__always)
    mutating func runTokenThreaded(sp: inout Sp, pc: inout Pc, md: inout Md, ms: inout Ms) throws {
        #if EngineStats
            var stats = StatsCollector()
            defer { stats.dump() }
        #endif
        var opcode = pc.read(OpcodeID.self)
        while true {
            #if EngineStats
                stats.track(inst)
            #endif
            opcode = try doExecute(opcode, sp: &sp, pc: &pc, md: &md, ms: &ms)
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
        spAddend: VReg,
        sp: Sp, pc: Pc, md: inout Md, ms: inout Ms
    ) throws -> (Pc, Sp) {
        if function.isWasm {
            let function = function.wasm
            let iseq = try function.ensureCompiled(store: store)

            let newSp = try pushFrame(
                iseq: iseq,
                instance: function.instance,
                numberOfNonParameterLocals: function.numberOfNonParameterLocals,
                sp: sp,
                returnPC: pc,
                spAddend: spAddend
            )
            Execution.CurrentMemory.mayUpdateCurrentInstance(
                instance: function.instance,
                from: callerInstance, md: &md, ms: &ms
            )
            return (iseq.baseAddress, newSp)
        } else {
            let function = function.host
            let resolvedType = store.value.engine.resolveType(function.type)
            let layout = FrameHeaderLayout(type: resolvedType)
            let parameters = resolvedType.parameters.enumerated().map { (i, type) in
                sp[spAddend + layout.paramReg(i)].cast(to: type)
            }
            let instance = self.currentInstance(sp: sp)
            let caller = Caller(
                instanceHandle: instance,
                store: store.value
            )
            let results = try function.implementation(caller, Array(parameters))
            for (index, result) in results.enumerated() {
                sp[spAddend + layout.returnReg(index)] = UntypedValue(result)
            }
            return (pc, sp)
        }
    }
}
