/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>

public struct Stack {
    public enum Element: Equatable {
        case value(Value)
        case label(Label)
        case frame(Frame)
    }

    private(set) var limit = UInt16.max
    private var values = [Value]()
    private var numberOfValues: Int = 0
    private var labels = [Label]() {
        didSet {
            self.currentLabel = self.labels.last
        }
    }
    private var frames = [Frame]() {
        didSet {
            self.currentFrame = self.frames.last
        }
    }
    var currentFrame: Frame!
    var currentLabel: Label!
    var topValue: Value {
        values[numberOfValues - 1]
    }

    var isEmpty: Bool {
        self.frames.isEmpty && self.labels.isEmpty && self.numberOfValues == 0
    }

    mutating func push(value: Value) {
        if self.numberOfValues < self.values.count {
            self.values[self.numberOfValues] = value
        } else {
            self.values.append(value)
        }
        self.numberOfValues += 1
    }

    mutating func push(values: some RandomAccessCollection<Value>) {
        let numberOfReplaceableSlots = self.values.count - self.numberOfValues
        if numberOfReplaceableSlots >= values.count {
            self.values.replaceSubrange(self.numberOfValues..<self.numberOfValues+values.count, with: values)
        } else if numberOfReplaceableSlots > 0 {
            let rangeToReplace = self.numberOfValues..<self.values.count
            self.values.replaceSubrange(rangeToReplace, with: values.prefix(numberOfReplaceableSlots))
            self.values.append(contentsOf: values.dropFirst(numberOfReplaceableSlots))
        } else {
            self.values.append(contentsOf: values)
        }
        self.numberOfValues += values.count
    }

    mutating func pushLabel(arity: Int, expression: Expression, continuation: Int, exit: Int) -> Label {
        let label = Label(
            arity: arity,
            expression: expression,
            continuation: continuation,
            exit: exit,
            baseValueIndex: self.numberOfValues
        )
        labels.append(label)
        return label
    }

    @discardableResult
    mutating func pushFrame(
        arity: Int, module: ModuleInstance, locals: [Value], address: FunctionAddress? = nil
    ) throws -> Frame {
        // TODO: Stack overflow check can be done at the entry of expression
        guard (frames.count + labels.count + numberOfValues) < limit else {
            throw Trap.callStackExhausted
        }

        let baseStackAddress = BaseStackAddress(valueIndex: self.numberOfValues, labelIndex: self.labels.endIndex)
        let frame = Frame(arity: arity, module: module, locals: locals, baseStackAddress: baseStackAddress, address: address)
        frames.append(frame)
        return frame
    }

    func numberOfLabelsInCurrentFrame() -> Int {
        self.labels.count - currentFrame.baseStackAddress.labelIndex
    }

    func numberOfValuesInCurrentLabel() -> Int {
        self.numberOfValues - currentLabel.baseValueIndex
    }

    mutating func exit(label: Label) {
        // labelIndex = 0 means jumping to the current head label
        self.labels.removeLast()
    }

    mutating func exit(frame: Frame) -> Label? {
        if numberOfValuesInCurrentLabel() == frame.arity {
            // Skip pop/push traffic
        } else {
            let results = popValues(count: frame.arity)
            self.numberOfValues = frame.baseStackAddress.valueIndex
            push(values: results)
        }
        if frame.baseStackAddress.labelIndex == 0 {
            self.labels.removeAll()
            self.numberOfValues = 0
            return nil
        }
        let labelToRemove = self.labels[frame.baseStackAddress.labelIndex]
        self.labels.removeLast(self.labels.count - frame.baseStackAddress.labelIndex)
        return labelToRemove
    }

    @discardableResult
    mutating func unwindLabels(upto labelIndex: Int) -> Label? {
        if self.labels.count == labelIndex + 1 {
            self.labels.removeAll()
            self.numberOfValues = 0
            return nil
        }
        // labelIndex = 0 means jumping to the current head label
        let labelToRemove = self.labels[self.labels.count - labelIndex - 1]
        self.labels.removeLast(labelIndex + 1)
        if self.numberOfValues > labelToRemove.baseValueIndex {
            self.numberOfValues = labelToRemove.baseValueIndex
        }
        return labelToRemove
    }

    mutating func discardFrameStack(frame: Frame) -> Label? {
        if frame.baseStackAddress.labelIndex == 0 {
            // The end of top level execution
            self.labels.removeAll()
            self.numberOfValues = 0
            return nil
        }
        let labelToRemove = self.labels[frame.baseStackAddress.labelIndex]
        self.labels.removeLast(self.labels.count - frame.baseStackAddress.labelIndex)
        self.numberOfValues = frame.baseStackAddress.valueIndex
        return labelToRemove
    }

    mutating func popValue() throws -> Value {
        // TODO: Check too many pop
        let value = self.values[self.numberOfValues-1]
        self.numberOfValues -= 1
        return value
    }

    mutating func popTopValues() throws -> ArraySlice<Value> {
        guard let currentLabel = self.currentLabel else {
            let values = self.values[..<self.numberOfValues]
            self.numberOfValues = 0
            return values
        }
        guard currentLabel.baseValueIndex < self.numberOfValues else {
            return []
        }
        let values = self.values[currentLabel.baseValueIndex..<self.numberOfValues]
        self.numberOfValues = currentLabel.baseValueIndex
        return values
    }

    mutating func popValues(count: Int) -> ArraySlice<Value> {
        guard count > 0 else { return [] }
        let values = self.values[self.numberOfValues-count..<self.numberOfValues]
        self.numberOfValues -= count
        return values
    }

    mutating func popFrame() throws {
        guard self.frames.popLast() != nil else {
            throw Trap.stackOverflow
        }
        // _ = discardFrameStack(frame: popped)
    }

    func getLabel(index: Int) throws -> Label {
        return self.labels[self.labels.count - index - 1]
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
    /// The base index of Wasm value stack
    let valueIndex: Int
    /// The base index of Wasm label stack
    let labelIndex: Int
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#frames>
public final class Frame {
    let arity: Int
    let module: ModuleInstance
    let baseStackAddress: BaseStackAddress
    var locals: [Value]
    /// An optional function address for debugging/profiling purpose
    let address: FunctionAddress?

    init(arity: Int, module: ModuleInstance, locals: [Value], baseStackAddress: BaseStackAddress, address: FunctionAddress? = nil) {
        self.arity = arity
        self.module = module
        self.locals = locals
        self.baseStackAddress = baseStackAddress
        self.address = address
    }
}

extension Frame: Equatable {
    public static func == (_ lhs: Frame, _ rhs: Frame) -> Bool {
        lhs.module === rhs.module && lhs.arity == rhs.arity && lhs.locals == rhs.locals
    }
}

extension Frame {
    func localGet(index: UInt32) throws -> Value {
        guard locals.indices.contains(Int(index)) else {
            throw Trap.localIndexOutOfRange(index: index)
        }
        return locals[Int(index)]
    }

    func localSet(index: UInt32, value: Value) throws {
        guard locals.indices.contains(Int(index)) else {
            throw Trap.localIndexOutOfRange(index: index)
        }
        locals[Int(index)] = value
    }
}

extension Frame: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[A=\(arity), L=\(locals), BA=\(baseStackAddress), F=\(address?.description ?? "nil")]"
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

        for (index, value) in values[..<numberOfValues].enumerated() {
            result += "VALUE[\(index)]: \(value)\n"
        }
        result += "==================================================\n"

        return result
    }
}
