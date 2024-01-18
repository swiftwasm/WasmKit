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
        values.last!
    }

    var isEmpty: Bool {
        self.frames.isEmpty && self.labels.isEmpty && self.values.isEmpty
    }

    mutating func push(value: Value) {
        values.append(value)
    }

    mutating func push(values: some Sequence<Value>) {
        self.values.append(contentsOf: values)
    }

    mutating func pushLabel(arity: Int, expression: Expression, continuation: Int, exit: Int) -> Label {
        let label = Label(
            arity: arity,
            expression: expression,
            continuation: continuation,
            exit: exit,
            baseValueIndex: self.values.count
        )
        labels.append(label)
        return label
    }

    @discardableResult
    mutating func pushFrame(
        arity: Int, module: ModuleInstance, locals: [Value], address: FunctionAddress? = nil
    ) throws -> Frame {
        // TODO: Stack overflow check can be done at the entry of expression
        guard (frames.count + labels.count + values.count) < limit else {
            throw Trap.callStackExhausted
        }

        let baseStackAddress = BaseStackAddress(valueIndex: self.values.endIndex, labelIndex: self.labels.endIndex)
        let frame = Frame(arity: arity, module: module, locals: locals, baseStackAddress: baseStackAddress, address: address)
        frames.append(frame)
        return frame
    }

    func numberOfLabelsInCurrentFrame() -> Int {
        self.labels.count - currentFrame.baseStackAddress.labelIndex
    }

    func numberOfValuesInCurrentLabel() -> Int {
        self.values.count - currentLabel.baseValueIndex
    }

    mutating func exit(label: Label) {
        // labelIndex = 0 means jumping to the current head label
        self.labels.removeLast()
    }

    @discardableResult
    mutating func unwindLabels(upto labelIndex: Int) -> Label? {
        if self.labels.count == labelIndex + 1 {
            self.labels.removeAll()
            self.values.removeAll()
            return nil
        }
        // labelIndex = 0 means jumping to the current head label
        let labelToRemove = self.labels[self.labels.count - labelIndex - 1]
        self.labels.removeLast(labelIndex + 1)
        if self.values.count > labelToRemove.baseValueIndex {
            self.values.removeLast(self.values.count - labelToRemove.baseValueIndex)
        }
        return labelToRemove
    }

    mutating func discardFrameStack(frame: Frame) -> Label? {
        if frame.baseStackAddress.labelIndex == 0 {
            // The end of top level execution
            self.labels.removeAll()
            self.values.removeAll()
            return nil
        }
        let labelToRemove = self.labels[frame.baseStackAddress.labelIndex]
        self.labels.removeLast(self.labels.count - frame.baseStackAddress.labelIndex)
        self.values.removeLast(self.values.count - frame.baseStackAddress.valueIndex)
        return labelToRemove
    }

    mutating func popValue() throws -> Value {
        // TODO: Check too many pop
        return self.values.removeLast()
    }

    mutating func popTopValues() throws -> ArraySlice<Value> {
        guard let currentLabel = self.currentLabel else {
            let values = self.values
            self.values = []
            return ArraySlice(values)
        }
        guard currentLabel.baseValueIndex < self.values.endIndex else {
            return []
        }
        let values = self.values[currentLabel.baseValueIndex..<self.values.endIndex]
        self.values.removeLast(self.values.count - currentLabel.baseValueIndex)
        return values
    }

    mutating func popValues(count: Int) throws -> ArraySlice<Value> {
        guard count > 0 else { return [] }
        let values = self.values[self.values.endIndex-count..<self.values.endIndex]
        self.values.removeLast(count)
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

        for (index, value) in values.enumerated() {
            result += "VALUE[\(index)]: \(value)\n"
        }
        result += "==================================================\n"

        return result
    }
}
