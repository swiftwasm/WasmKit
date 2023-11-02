/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>

public struct Stack {
    public enum Element: Equatable {
        case value(Value)
        case label(Label)
        case frame(Frame)
    }

    private(set) var limit = UInt16.max
    private(set) var elements = [Element]()
    private(set) var currentFrame: Frame!
    private(set) var currentLabel: Label!

    var top: Element? { elements.last }

    mutating func push(value: Value) {
        elements.append(.value(value))
    }

    mutating func push(values: some Sequence<Value>) {
        for value in values {
            push(value: value)
        }
    }

    mutating func push(label: Label) {
        currentLabel = label
        elements.append(.label(label))
    }

    mutating func push(frame: Frame) throws {
        guard elements.count < limit else {
            throw Trap.callStackExhausted
        }

        currentFrame = frame
        elements.append(.frame(frame))
    }

    @discardableResult
    mutating func pop() -> Element? {
        guard !elements.isEmpty else { return nil }

        return elements.removeLast()
    }

    mutating func popLabel() throws -> Label {
        guard let popped = pop() else {
            throw Trap.stackOverflow
        }

        guard case let .label(label) = popped else {
            throw Trap.stackTypeMismatch(expected: Label.self, actual: popped)
        }

        // Check if more labels are left on the stack, and a single element left can't be a label, it must be a frame.
        guard elements.count > 1 else {
            currentLabel = nil
            return label
        }

        loop: for i in stride(from: elements.count - 1, to: 0, by: -1) {
            switch elements[i] {
            case .frame:
                currentLabel = nil
                break loop

            case let .label(l):
                currentLabel = l
                break loop

            case .value:
                continue
            }
        }

        return label
    }

    mutating func discardTopValues() {
        while case .value = top {
            pop()
        }
    }

    mutating func popValue() throws -> Value {
        if case let .value(v) = top {
            elements.removeLast()
            return v
        } else {
            guard
                let i = elements.lastIndex(where: { if case .value = $0 { return true } else { return false } }),
                case let .value(v) = elements.remove(at: i)
            else {
                throw Trap.stackOverflow
            }

            return v
        }
    }

    mutating func popTopValues() throws -> [Value] {
        var values = [Value]()
        while case .value = top {
            try values.insert(popValue(), at: 0)
        }

        return values
    }

    mutating func popValues(count: Int) throws -> [Value] {
        var values = [Value]()
        for _ in 0..<count {
            try values.insert(popValue(), at: 0)
        }
        return values
    }

    mutating func popFrame() throws {
        guard let popped = pop() else {
            throw Trap.stackOverflow
        }

        guard case .frame = popped else {
            throw Trap.stackTypeMismatch(expected: Frame.self, actual: popped)
        }

        for i in stride(from: elements.count - 1, to: -1, by: -1) {
            switch elements[i] {
            case let .frame(f):
                currentFrame = f
                return

            case let .label(l):
                if currentLabel == nil {
                    currentLabel = l
                }

            case .value:
                continue
            }
        }

        currentLabel = nil
        currentFrame = nil
    }

    func getLabel(index: Int) throws -> Label {
        var currentIndex: Int = -1
        var entryIndex = elements.endIndex - 1
        repeat {
            defer { entryIndex -= 1 }
            guard case let .label(label) = elements[entryIndex] else {
                continue
            }
            currentIndex += 1
            if currentIndex == index {
                return label
            }
        } while entryIndex >= 0
        throw Trap.stackElementNotFound(Label.self, index: index)
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
}

/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#frames>
public final class Frame {
    let arity: Int
    let module: ModuleInstance
    var locals: [Value]
    /// An optional function address for debugging/profiling purpose
    let address: FunctionAddress?

    init(arity: Int, module: ModuleInstance, locals: [Value], address: FunctionAddress? = nil) {
        self.arity = arity
        self.module = module
        self.locals = locals
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
