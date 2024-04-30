/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>
struct Stack {
    enum Element: Equatable {
        case value(Value)
        case frame(Frame)
    }

    private var limit: UInt16 { UInt16.max }
    private var valueStack: ValueStack
    private var numberOfValues: Int { valueStack.count }
    private var frames: FixedSizeStack<Frame>
    var currentFrame: Frame!

    var isEmpty: Bool {
        self.frames.isEmpty && self.numberOfValues == 0
    }

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
        address: FunctionAddress? = nil
    ) throws {
        // TODO: Stack overflow check can be done at the entry of expression
        guard (frames.count + numberOfValues) < limit else {
            throw Trap.callStackExhausted
        }
        let valueFrameIndex = self.numberOfValues - argc
        if let defaultLocals {
            valueStack.push(values: defaultLocals)
        }
        let baseStackAddress = BaseStackAddress(
            valueFrameIndex: valueFrameIndex,
            // Consume argment values from value stack
            valueIndex: self.numberOfValues
        )
        let frame = Frame(arity: arity, module: module, baseStackAddress: baseStackAddress, iseq: iseq, returnPC: returnPC, address: address)
        frames.push(frame)
        self.currentFrame = frame
    }

    mutating func popFrame() {
        let popped = self.frames.pop()
        self.currentFrame = self.frames.peek()
        self.valueStack.truncate(length: popped.baseStackAddress.valueFrameIndex)
    }

    mutating func popValues(count: Int) -> Array<Value> {
        self.valueStack.popValues(count: count)
    }
    mutating func popValue() -> Value {
        self.valueStack.popValue()
    }
    mutating func push(values: [Value]) {
        self.valueStack.push(values: values)
    }
    mutating func push(value: Value) {
        self.valueStack.push(value: value)
    }
    mutating func copyValues(copyCount: Int, popCount: Int) {
        self.valueStack.copyValues(copyCount: copyCount, popCount: popCount)
    }

    var topValue: Value {
        self.valueStack.topValue
    }

    var currentLocalsPointer: UnsafeMutablePointer<Value> {
        self.valueStack.baseAddress.advanced(by: currentFrame?.baseStackAddress.valueFrameIndex ?? 0)
    }
}

struct ValueStack {
    private let values: UnsafeMutableBufferPointer<Value>
    private var nextPointer: UnsafeMutablePointer<Value>
    var baseAddress: UnsafeMutablePointer<Value> {
        values.baseAddress!
    }

    init(capacity: Int) {
        self.values = .allocate(capacity: capacity)
        self.nextPointer = self.values.baseAddress!
    }

    func deallocate() {
        self.values.deallocate()
    }

    var count: Int { nextPointer - values.baseAddress! }

    var topValue: Value {
        nextPointer.advanced(by: -1).pointee
    }

    subscript(_ index: Int) -> Value {
        get { values[index] }
        set {
            values[index] = newValue
        }
    }

    mutating func push(value: Value) {
        self.nextPointer.pointee = value
        self.nextPointer = self.nextPointer.advanced(by: 1)
    }

    mutating func push(values: [Value]) {
        values.withUnsafeBufferPointer { copyingBuffer in
            self.push(values: copyingBuffer)
        }
    }

    mutating func push(values copyingBuffer: UnsafeBufferPointer<Value>) {
        let rawBuffer = UnsafeMutableRawBufferPointer(
            start: self.nextPointer,
            count: MemoryLayout<Value>.stride * copyingBuffer.count
        )
        rawBuffer.copyMemory(from: UnsafeRawBufferPointer(copyingBuffer))
        self.nextPointer = nextPointer.advanced(by: copyingBuffer.count)
    }

    mutating func popValue() -> Value {
        // TODO: Check too many pop
        self.nextPointer = nextPointer.advanced(by: -1)
        let value = self.nextPointer.pointee
        return value
    }

    mutating func truncate(length: Int) {
        self.nextPointer = self.values.baseAddress!.advanced(by: length)
    }
    mutating func popValues(count: Int) -> Array<Value> {
        guard count > 0 else { return [] }
        var values = [Value]()
        values.reserveCapacity(count)
        for idx in self.count-count..<self.count {
            values.append(self.values[idx])
        }
        self.nextPointer = self.nextPointer.advanced(by: -count)
        return values
    }
    mutating func copyValues(copyCount: Int, popCount: Int) {
        let newNextPointer = self.nextPointer - popCount
        (newNextPointer - copyCount).moveUpdate(from: self.nextPointer - copyCount, count: copyCount)
        self.nextPointer = newNextPointer
    }
}

extension ValueStack: Sequence {
    func makeIterator() -> UnsafeMutableBufferPointer<Value>.SubSequence.Iterator {
        self.values[..<count].makeIterator()
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
}

extension FixedSizeStack: Sequence {
    func makeIterator() -> UnsafeMutableBufferPointer<Element>.SubSequence.Iterator {
        self.buffer[..<numberOfElements].makeIterator()
    }
}

struct BaseStackAddress {
    /// Locals are placed between `valueFrameIndex..<valueIndex`
    let valueFrameIndex: Int
    /// The base index of Wasm value stack
    let valueIndex: Int
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

extension Frame: CustomDebugStringConvertible {
    var debugDescription: String {
        "[A=\(arity), BA=\(baseStackAddress), F=\(address?.description ?? "nil")]"
    }
}

extension Stack: CustomDebugStringConvertible {
    public var debugDescription: String {
        var result = ""

        result += "==================================================\n"
        for (index, frame) in frames.enumerated() {
            result += "FRAME[\(index)]: \(frame.debugDescription)\n"
        }
        result += "==================================================\n"

        for (index, value) in valueStack.enumerated() {
            result += "VALUE[\(index)]: \(value)\n"
        }
        result += "==================================================\n"

        return result
    }
}
