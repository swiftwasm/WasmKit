// https://webassembly.github.io/spec/core/exec/runtime.html#results
enum Result: AutoEquatable {
    case value(Value)
    case trap
}

// https://webassembly.github.io/spec/core/exec/runtime.html#store
final class Store: AutoEquatable {
    var functions: [FunctionInstance] = []
    var tables: [TableInstance] = []
    var memories: [MemoryInstance] = []
    var globals: [GlobalInstance] = []
}

// https://webassembly.github.io/spec/core/exec/runtime.html#addresses
public typealias Address = Int
public typealias FunctionAddress = Address
public typealias TableAddress = Address
public typealias MemoryAddress = Address
public typealias GlobalAddress = Address

// https://webassembly.github.io/spec/core/exec/runtime.html#module-instances
public final class ModuleInstance: AutoEquatable {
    var types: [FunctionType] = []
    var functionAddresses: [FunctionAddress] = []
    var tableAddresses: [TableAddress] = []
    var memoryAddresses: [MemoryAddress] = []
    var globalAddresses: [GlobalAddress] = []
    var exports: [ExportInstance] = []
}

// https://webassembly.github.io/spec/core/exec/runtime.html#function-instances
final class FunctionInstance: AutoEquatable {
    var type: FunctionType
    var module: ModuleInstance
    var code: Function

    init(type: FunctionType, module: ModuleInstance, code: Function) {
        self.type = type
        self.module = module
        self.code = code
    }
}

// https://webassembly.github.io/spec/core/exec/runtime.html#table-instances
final class TableInstance: AutoEquatable {
    // sourcery: arrayEquality
    var elements: [FunctionAddress?]
    var max: UInt32?

    init(elements: [FunctionAddress?], max: UInt32?) {
        self.elements = elements
        self.max = max
    }
}

// https://webassembly.github.io/spec/core/exec/runtime.html#memory-instances
final class MemoryInstance: AutoEquatable {
    var data: [UInt8]
    var max: UInt32?

    init(data: [UInt8], max: UInt32?) {
        self.data = data
        self.max = max
    }
}

// https://webassembly.github.io/spec/core/exec/runtime.html#global-instances
final class GlobalInstance: AutoEquatable {
    var value: Value
    var mutability: Mutability

    init(value: Value, mutability: Mutability) {
        self.value = value
        self.mutability = mutability
    }
}

// https://webassembly.github.io/spec/core/exec/runtime.html#export-instances
final class ExportInstance: AutoEquatable {
    var name: String
    var value: ExternalValue

    init(name: String, value: ExternalValue) {
        self.name = name
        self.value = value
    }
}

// https://webassembly.github.io/spec/core/exec/runtime.html#external-values
public enum ExternalValue: AutoEquatable {
    case function(FunctionAddress)
    case table(TableAddress)
    case memory(MemoryAddress)
    case global(GlobalAddress)
}

// https://webassembly.github.io/spec/core/exec/runtime.html#stack
struct Stack: AutoEquatable {
    enum Element: AutoEquatable {
        case value(Value)
        case label(Expression)
        case activation(Frame)
    }

    private var elements: [Element] = []

    public var count: Int {
        return elements.count
    }

    mutating func push(_ element: Element) {
        elements.append(element)
    }

    mutating func pop() -> Element? {
        return elements.popLast()
    }

    mutating func popValue(of type: ValueType? = nil) throws -> Value {
        guard case let .value(v)? = pop() else {
            throw ExecutionError.genericError
        }
        if let type = type, !v.isA(type) {
            throw ExecutionError.genericError
        }
        return v
    }

    func peek() -> Element? {
        return elements.last
    }

    func currentFrame() -> Frame? {
        for element in elements.reversed() {
            if case let .activation(frame) = element {
                return frame
            }
        }
        return nil
    }
}

// https://webassembly.github.io/spec/core/exec/runtime.html#syntax-frame
struct Frame: AutoEquatable {
    let module: ModuleInstance
    let locals: [Value]
}

// https://webassembly.github.io/spec/core/exec/runtime.html#administrative-instructions
enum AdministrativeInstruction: Instruction, AutoEquatable {
    case trap
    case invoke(FunctionAddress)
    case initElem(TableAddress, UInt32, [FunctionIndex])
    case initData(MemoryAddress, UInt32, [UInt8])
    case label(Expression, Expression)
    case frame(Frame, Expression)

    var isConstant: Bool {
        return false
    }
}
