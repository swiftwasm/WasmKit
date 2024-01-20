/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>

public struct Stack {
    public enum Element: Equatable {
        case value(Value)
        case label(Label)
        case frame(Frame)
    }

    private let limit = UInt16.max
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
        self.valueStack = ValueStack(capacity: Int(self.limit))
        self.frames = FixedSizeStack(capacity: Int(self.limit))
        self.labels = FixedSizeStack(capacity: Int(self.limit))
    }

    mutating func pushLabel(arity: Int, expression: Expression, continuation: Int, exit: Int) -> Label {
        let label = Label(
            arity: arity,
            expression: expression,
            continuation: continuation,
            exit: exit,
            baseValueIndex: self.numberOfValues
        )
        labels.push(label)
        return label
    }

    mutating func pushFrame(
        arity: Int, module: ModuleAddress, argc: Int, defaultLocals: [Value], address: FunctionAddress? = nil
    ) throws {
        // TODO: Stack overflow check can be done at the entry of expression
        guard (frames.count + labels.count + numberOfValues) < limit else {
            throw Trap.callStackExhausted
        }
        let valueFrameIndex = self.numberOfValues - argc
        valueStack.push(values: defaultLocals)
        let baseStackAddress = BaseStackAddress(
            valueFrameIndex: valueFrameIndex,
            // Consume argment values from value stack
            valueIndex: self.numberOfValues,
            labelIndex: self.labels.count
        )
        let frame = Frame(arity: arity, module: module, baseStackAddress: baseStackAddress, address: address)
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
        if self.labels.count == labelIndex + 1 {
            self.labels.popAll()
            self.valueStack.truncate(length: 0)
            return nil
        }
        // labelIndex = 0 means jumping to the current head label
        let labelToRemove = self.labels[self.labels.count - labelIndex - 1]
        self.labels.pop(labelIndex + 1)
        if self.numberOfValues > labelToRemove.baseValueIndex {
            self.valueStack.truncate(length: labelToRemove.baseValueIndex)
        }
        return labelToRemove
    }

    mutating func discardFrameStack(frame: Frame) -> Label? {
        if frame.baseStackAddress.labelIndex == 0 {
            // The end of top level execution
            self.labels.popAll()
            self.valueStack.truncate(length: 0)
            return nil
        }
        let labelToRemove = self.labels[frame.baseStackAddress.labelIndex]
        self.labels.pop(self.labels.count - frame.baseStackAddress.labelIndex)
        self.valueStack.truncate(length: frame.baseStackAddress.valueIndex)
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

    mutating func popFrame() throws {
        let popped = self.frames.pop()
        self.currentFrame = self.frames.peek()
        self.valueStack.truncate(length: popped.baseStackAddress.valueFrameIndex)
    }

    func getLabel(index: Int) throws -> Label {
        return self.labels[self.labels.count - index - 1]
    }

    mutating func popValues(count: Int) -> Array<Value> {
        self.valueStack.popValues(count: count)
    }
    mutating func popValue() throws -> Value {
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
    private var numberOfValues: Int = 0
    private let capacity: Int

    init(capacity: Int) {
        self.values = .allocate(capacity: capacity)
        self.capacity = capacity
    }

    func deallocate() {
        self.values.deallocate()
    }

    var count: Int { numberOfValues }

    var topValue: Value {
        values[numberOfValues - 1]
    }

    subscript(_ index: Int) -> Value {
        get { values[index] }
        set {
            values[index] = newValue
        }
    }

    mutating func push(value: Value) {
        self.values[self.numberOfValues] = value
        self.numberOfValues += 1
    }

    mutating func push(values: [Value]) {
        let rawBuffer = UnsafeMutableRawBufferPointer(
            start: self.values.baseAddress!.advanced(by: numberOfValues),
            count: MemoryLayout<Value>.stride * values.count
        )
        values.withUnsafeBufferPointer { copyingBuffer in
            rawBuffer.copyMemory(from: UnsafeRawBufferPointer(copyingBuffer))
        }
        self.numberOfValues += values.count
    }

    mutating func popValue() -> Value {
        // TODO: Check too many pop
        let value = self.values[self.numberOfValues-1]
        self.numberOfValues -= 1
        return value
    }

    mutating func truncate(length: Int) {
        self.numberOfValues = length
    }
    mutating func popValues(count: Int) -> Array<Value> {
        guard count > 0 else { return [] }
        var values = [Value]()
        values.reserveCapacity(count)
        for idx in self.numberOfValues-count..<self.numberOfValues {
            values.append(self.values[idx])
        }
        self.numberOfValues -= count
        return values
    }
}

extension ValueStack: Sequence {
    func makeIterator() -> some IteratorProtocol {
        self.values[..<numberOfValues].makeIterator()
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

    let expression: Expression

    /// Index of an instruction to jump to when this label is popped off the stack.
    let continuation: Int

    /// The index after the  of the structured control instruction associated with the label
    let exit: Int

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
    /// An optional function address for debugging/profiling purpose
    let address: FunctionAddress?

    init(arity: Int, module: ModuleAddress, baseStackAddress: BaseStackAddress, address: FunctionAddress? = nil) {
        self.arity = arity
        self.module = module
        self.baseStackAddress = baseStackAddress
        self.address = address
    }
}

extension Frame: Equatable {
    public static func == (_ lhs: Frame, _ rhs: Frame) -> Bool {
        lhs.module == rhs.module && lhs.arity == rhs.arity
    }
}

extension Stack {
    func localGet(index: UInt32) throws -> Value {
        let base = currentFrame.baseStackAddress.valueFrameIndex
        guard base + Int(index) < valueStack.count else {
            throw Trap.localIndexOutOfRange(index: index)
        }
        return valueStack[base + Int(index)]
    }

    mutating func localSet(index: UInt32, value: Value) throws {
        let base = currentFrame.baseStackAddress.valueFrameIndex
        guard base + Int(index) < valueStack.count else {
            throw Trap.localIndexOutOfRange(index: index)
        }
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
        "[A=\(arity), E=\(expression), C=\(continuation), X=\(exit), BVI=\(baseValueIndex)]"
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
