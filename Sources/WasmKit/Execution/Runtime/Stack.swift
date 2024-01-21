/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>

public struct Stack {
    public enum Element: Equatable {
        case value(Value)
        case label(Label)
        case frame(Frame)
    }

    private var limit: UInt16 { UInt16.max }
    private var valueStack: ValueStack
    private var numberOfValues: Int { valueStack.count }
    private var labels: FixedSizeStack<Label> {
        didSet {
            self.currentLabel = self.labels.peek()
        }
    }
    private var frames: FixedSizeStack<Frame>
    var currentFrame: Frame!
    var currentLabel: Label!

    var isEmpty: Bool {
        self.frames.isEmpty && self.labels.isEmpty && self.numberOfValues == 0
    }

    init() {
        let limit = UInt16.max
        self.valueStack = ValueStack(capacity: Int(limit))
        self.frames = FixedSizeStack(capacity: Int(limit))
        self.labels = FixedSizeStack(capacity: Int(limit))
    }

    @inline(__always)
    mutating func pushLabel(arity: Int, continuation: ProgramCounter, popPushValues: Int = 0) {
        let label = Label(
            arity: arity,
            continuation: continuation,
            baseValueIndex: self.numberOfValues - popPushValues
        )
        labels.push(label)
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
        guard (frames.count + labels.count + numberOfValues) < limit else {
            throw Trap.callStackExhausted
        }
        let valueFrameIndex = self.numberOfValues - argc
        if let defaultLocals {
            valueStack.push(values: defaultLocals)
        }
        let baseStackAddress = BaseStackAddress(
            valueFrameIndex: valueFrameIndex,
            // Consume argment values from value stack
            valueIndex: self.numberOfValues,
            labelIndex: self.labels.count
        )
        let frame = Frame(arity: arity, module: module, baseStackAddress: baseStackAddress, iseq: iseq, returnPC: returnPC, address: address)
        frames.push(frame)
        self.currentFrame = frame
    }

    func numberOfLabelsInCurrentFrame() -> Int {
        self.labels.count - currentFrame.baseStackAddress.labelIndex
    }

    func numberOfValuesInCurrentLabel() -> Int {
        self.numberOfValues - currentLabel.baseValueIndex
    }

    mutating func exit(label: Label) {
        // labelIndex = 0 means jumping to the current head label
        self.labels.pop()
    }

    mutating func exit(frame: Frame) -> Label? {
        let results = valueStack.popValues(count: frame.arity)
        self.valueStack.truncate(length: frame.baseStackAddress.valueFrameIndex)
        valueStack.push(values: results)
        let labelToRemove = self.labels[frame.baseStackAddress.labelIndex]
        self.labels.pop(self.labels.count - frame.baseStackAddress.labelIndex)
        return labelToRemove
    }

    @discardableResult
    mutating func unwindLabels(upto labelIndex: Int) -> Label? {
        // labelIndex = 0 means jumping to the current head label
        let labelToRemove = self.labels[self.labels.count - labelIndex - 1]
        self.labels.pop(labelIndex + 1)
        if self.numberOfValues > labelToRemove.baseValueIndex {
            self.valueStack.truncate(length: labelToRemove.baseValueIndex)
        }
        return labelToRemove
    }

    mutating func popTopValues() throws -> Array<Value> {
        guard let currentLabel = self.currentLabel else {
            return self.valueStack.popValues(count: self.valueStack.count)
        }
        guard currentLabel.baseValueIndex < self.numberOfValues else {
            return []
        }
        let values = self.valueStack.popValues(count: self.numberOfValues - currentLabel.baseValueIndex)
        return values
    }

    mutating func popFrame() {
        let popped = self.frames.pop()
        self.currentFrame = self.frames.peek()
        self.valueStack.truncate(length: popped.baseStackAddress.valueFrameIndex)
    }

    func getLabel(index: Int) -> Label {
        return self.labels[self.labels.count - index - 1]
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

    var topValue: Value {
        self.valueStack.topValue
    }
}

struct ValueStack {
    private let values: UnsafeMutableBufferPointer<Value>
    private var nextPointer: UnsafeMutablePointer<Value>
    private let capacity: Int

    init(capacity: Int) {
        self.values = .allocate(capacity: capacity)
        self.nextPointer = self.values.baseAddress!
        self.capacity = capacity
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
}

extension ValueStack: Sequence {
    func makeIterator() -> some IteratorProtocol {
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
    func makeIterator() -> some IteratorProtocol<Element> {
        self.buffer[..<numberOfElements].makeIterator()
    }
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#labels>
public struct Label: Equatable {
    let arity: Int

    /// Index of an instruction to jump to when this label is popped off the stack.
    let continuation: ProgramCounter

    let baseValueIndex: Int
}

struct BaseStackAddress {
    /// Locals are placed between `valueFrameIndex..<valueIndex`
    let valueFrameIndex: Int
    /// The base index of Wasm value stack
    let valueIndex: Int
    /// The base index of Wasm label stack
    let labelIndex: Int
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#frames>
public struct Frame {
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
    public static func == (_ lhs: Frame, _ rhs: Frame) -> Bool {
        lhs.module == rhs.module && lhs.arity == rhs.arity
    }
}

extension Stack {
    func localGet(index: UInt32) -> Value {
        let base = currentFrame.baseStackAddress.valueFrameIndex
        return valueStack[base + Int(index)]
    }

    mutating func localSet(index: UInt32, value: Value) {
        let base = currentFrame.baseStackAddress.valueFrameIndex
        valueStack[base + Int(index)] = value
    }
}

extension Frame: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[A=\(arity), BA=\(baseStackAddress), F=\(address?.description ?? "nil")]"
    }
}

extension Label: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[A=\(arity), C=\(continuation), BVI=\(baseValueIndex)]"
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

        for (index, label) in labels.enumerated() {
            result += "LABEL[\(index)]: \(label.debugDescription)\n"
        }

        result += "==================================================\n"

        for (index, value) in valueStack.enumerated() {
            result += "VALUE[\(index)]: \(value)\n"
        }
        result += "==================================================\n"

        return result
    }
}
