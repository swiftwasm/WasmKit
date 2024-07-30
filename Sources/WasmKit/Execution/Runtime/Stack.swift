/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>
struct Stack {

    private var limit: UInt16 { UInt16.max }
    private var valueStack: ValueStack
    private var frames: FixedSizeStack<Frame>
    var currentFrame: Frame!

    init() {
        let limit = UInt16.max
        self.valueStack = ValueStack(capacity: Int(limit))
        self.frames = FixedSizeStack(capacity: Int(limit))
    }

    mutating func pushFrame(
        iseq: InstructionSequence,
        arity: Int,
        module: ModuleAddress,
        argc: Int,
        defaultLocals: UnsafeBufferPointer<Value>?,
        returnPC: ProgramCounter,
        spAddend: UInt16,
        address: FunctionAddress? = nil
    ) throws {
        guard frames.count < limit else {
            throw Trap.callStackExhausted
        }
        let baseStackAddress = BaseStackAddress(
            valueFrameIndex: valueStack.frameBaseOffset
        )
        try valueStack.extend(addend: spAddend, maxStackHeight: iseq.maxStackHeight)
        if let defaultLocals {
            for (offset, value) in defaultLocals.enumerated() {
                valueStack[argc + offset] = value
            }
        }
        let frame = Frame(arity: arity, module: module, baseStackAddress: baseStackAddress, iseq: iseq, returnPC: returnPC, address: address)
        frames.push(frame)
        self.currentFrame = frame
    }

    mutating func popFrame() {
        let popped = self.frames.pop()
        self.currentFrame = self.frames.peek()
        let resultsBase = popped.baseStackAddress.valueFrameIndex
        self.valueStack.truncate(length: resultsBase)
    }

    subscript(register: Instruction.Register) -> Value {
        get { valueStack[Int(register)] }
        set { valueStack[Int(register)] = newValue }
    }

    func deallocate() {
        self.valueStack.deallocate()
        self.frames.deallocate()
    }

    var topValue: Value {
        self.valueStack.topValue
    }

    var currentLocalsPointer: UnsafeMutablePointer<Value> {
        self.valueStack.frameBase
    }
}

struct ValueStack {
    private let values: UnsafeMutableBufferPointer<Value>
    private(set) var frameBase: UnsafeMutablePointer<Value>
    var baseAddress: UnsafeMutablePointer<Value> {
        values.baseAddress!
    }

    init(capacity: Int) {
        self.values = .allocate(capacity: capacity)
        self.frameBase = self.values.baseAddress!
    }

    func deallocate() {
        self.values.deallocate()
    }

    var frameBaseOffset: Int { frameBase - values.baseAddress! }

    var topValue: Value {
        frameBase.advanced(by: -1).pointee
    }

    private func checkPrecondition(_ index: Int) {
        assert(frameBase.advanced(by: index) < values.baseAddress!.advanced(by: values.count))
    }

    subscript(_ index: Int) -> Value {
        get {
            checkPrecondition(index)
            return frameBase[index]
        }
        set {
            checkPrecondition(index)
            return frameBase[index] = newValue
        }
    }

    mutating func extend(addend: UInt16, maxStackHeight: Int) throws {
        frameBase = frameBase.advanced(by: Int(addend))
        guard frameBase.advanced(by: maxStackHeight) < values.baseAddress!.advanced(by: values.count) else {
            throw Trap.callStackExhausted
        }
    }

    mutating func truncate(length: Int) {
        self.frameBase = self.values.baseAddress!.advanced(by: length)
    }
}

struct FixedSizeStack<Element> {
    private let buffer: UnsafeMutableBufferPointer<Element>
    private var numberOfElements: Int = 0

    var isEmpty: Bool {
        numberOfElements == 0
    }

    var count: Int { numberOfElements }

    init(capacity: Int) {
        self.buffer = .allocate(capacity: capacity)
    }

    mutating func push(_ element: Element) {
        self.buffer[numberOfElements] = element
        self.numberOfElements += 1
    }

    @discardableResult
    mutating func pop() -> Element {
        let element = self.buffer[self.numberOfElements - 1]
        self.numberOfElements -= 1
        return element
    }

    mutating func pop(_ n: Int) {
        self.numberOfElements -= n
    }

    mutating func popAll() {
        self.numberOfElements = 0
    }

    func peek() -> Element! {
        guard self.numberOfElements > 0 else { return nil }
        return self.buffer[self.numberOfElements - 1]
    }

    subscript(_ index: Int) -> Element {
        self.buffer[index]
    }

    func deallocate() {
        self.buffer.deallocate()
    }
}

extension FixedSizeStack: Sequence {
    struct Iterator: IteratorProtocol {
        fileprivate var base: UnsafeMutableBufferPointer<Element>.SubSequence.Iterator

        mutating func next() -> Element? {
            base.next()
        }
    }

    func makeIterator() -> Iterator {
        Iterator(base: self.buffer[..<numberOfElements].makeIterator())
    }
}

struct BaseStackAddress {
    /// Locals are placed between `valueFrameIndex..<valueIndex`
    let valueFrameIndex: Int
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#frames>
struct Frame {
    let arity: Int
    let module: ModuleAddress
    let baseStackAddress: BaseStackAddress
    let iseq: InstructionSequence
    let returnPC: ProgramCounter
    /// An optional function address for debugging/profiling purpose
    let address: FunctionAddress?

    init(
        arity: Int,
        module: ModuleAddress,
        baseStackAddress: BaseStackAddress,
        iseq: InstructionSequence,
        returnPC: ProgramCounter,
        address: FunctionAddress? = nil
    ) {
        self.arity = arity
        self.module = module
        self.baseStackAddress = baseStackAddress
        self.iseq = iseq
        self.returnPC = returnPC
        self.address = address
    }
}

extension Frame: Equatable {
    static func == (_ lhs: Frame, _ rhs: Frame) -> Bool {
        lhs.module == rhs.module && lhs.arity == rhs.arity
    }
}
