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

struct UntypedValue: Equatable {
    let storage: UInt64

    static var `default`: UntypedValue {
        UntypedValue(storage: 0)
    }

    private static var isNullMaskPattern: UInt64 { (0x1 << 63) }

    init(signed value: Int32) {
        self = .i32(UInt32(bitPattern: value))
    }
    init(signed value: Int64) {
        self = .i64(UInt64(bitPattern: value))
    }
    static func i32(_ value: UInt32) -> UntypedValue {
        return UntypedValue(storage: UInt64(value))
    }
    static func i64(_ value: UInt64) -> UntypedValue {
        return UntypedValue(storage: value)
    }
    static func rawF32(_ value: UInt32) -> UntypedValue {
        return UntypedValue(storage: UInt64(value))
    }
    static func rawF64(_ value: UInt64) -> UntypedValue {
        return UntypedValue(storage: value)
    }
    static func f32(_ value: Float32) -> UntypedValue {
        return rawF32(value.bitPattern)
    }
    static func f64(_ value: Float64) -> UntypedValue {
        return rawF64(value.bitPattern)
    }

    init(storage32: UInt32) {
        self.storage = UInt64(storage32)
    }

    init(storage: UInt64) {
        self.storage = storage
    }

    init(_ value: Value) {
        func encodeOptionalInt(_ value: Int?) -> UInt64 {
            guard let value = value else { return Self.isNullMaskPattern }
            let unsigned = UInt64(bitPattern: Int64(value))
            precondition(unsigned & Self.isNullMaskPattern == 0)
            return unsigned
        }
        switch value {
        case .i32(let value): self = .i32(value)
        case .i64(let value): self = .i64(value)
        case .f32(let value): self = .rawF32(value)
        case .f64(let value): self = .rawF64(value)
        case .ref(.function(let value)), .ref(.extern(let value)):
            storage = encodeOptionalInt(value)
        }
    }

    var i32: UInt32 {
        return UInt32(truncatingIfNeeded: storage & 0x00000000ffffffff)
    }

    var i64: UInt64 {
        return storage
    }

    var rawF32: UInt32 {
        return i32
    }

    var rawF64: UInt64 {
        return i64
    }

    var f32: Float32 {
        return Float32(bitPattern: i32)
    }

    var f64: Float64 {
        return Float64(bitPattern: i64)
    }

    var isNullRef: Bool {
        return storage & Self.isNullMaskPattern != 0
    }

    func asReference(_ type: ReferenceType) -> Reference {
        func decodeOptionalInt() -> Int? {
            guard storage & Self.isNullMaskPattern == 0 else { return nil }
            return Int(storage)
        }
        switch type {
        case .funcRef:
            return .function(decodeOptionalInt())
        case .externRef:
            return .extern(decodeOptionalInt())
        }
    }

    func asAddressOffset() -> UInt64 {
        // NOTE: It's ok to load address offset as i64 because
        //       it's always evaluated as unsigned and the higher
        //       32-bits of i32 are always zero.
        return i64
    }
    func asAddressOffset(_ isMemory64: Bool) -> UInt64 {
        return asAddressOffset()
    }

    func cast(to type: ValueType) -> Value {
        switch type {
        case .i32: return .i32(i32)
        case .i64: return .i64(i64)
        case .f32: return .f32(rawF32)
        case .f64: return .f64(rawF64)
        case .ref(let referenceType):
            return .ref(asReference(referenceType))
        }
    }
}
