/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>
struct StackContext {

    private var limit: UInt16 { UInt16.max }
    private var stackEnd: UnsafeMutablePointer<StackSlot>
    let runtime: RuntimeRef
    var trap: UnsafeRawPointer?

    static func withContext<T>(
        runtime: RuntimeRef,
        body: (inout StackContext, Sp) throws -> T
    ) rethrows -> T {
        let limit = Int(UInt16.max)
        let valueStack = UnsafeMutablePointer<StackSlot>.allocate(capacity: limit)
        defer {
            valueStack.deallocate()
        }
        var context = StackContext(stackEnd: valueStack.advanced(by: limit), runtime: runtime)
        return try body(&context, valueStack)
    }

    @inline(__always)
    func currentInstance(sp: Sp) -> InternalInstance {
        InternalInstance(bitPattern: UInt(sp[-3].i64)).unsafelyUnwrapped
    }

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

