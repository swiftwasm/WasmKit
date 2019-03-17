/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#stack>

protocol Stackable {}

struct Stack {
    fileprivate final class Entry {
        var value: Stackable
        var next: Entry?

        init(value: Stackable, next: Entry?) {
            self.value = value
            self.next = next
        }
    }

    fileprivate var _top: Entry?

    var top: Stackable? {
        return _top?.value
    }

    mutating func push(_ entry: Stackable) {
        _top = Entry(value: entry, next: _top)
    }

    func peek() -> Stackable? {
        return top
    }

    @discardableResult
    mutating func pop() -> Stackable? {
        let value = _top?.value
        _top = _top?.next
        return value
    }
}

extension Stack {
    func peek<T: Stackable>(_: T.Type) throws -> T {
        guard let value = top as? T else {
            throw Trap.stackTypeMismatch(expected: T.self, actual: Swift.type(of: top))
        }
        return value
    }

    @discardableResult
    mutating func pop<T: Stackable>(_: T.Type) throws -> T {
        let popped = pop()
        guard let value = popped as? T else {
            throw Trap.stackTypeMismatch(expected: T.self, actual: Swift.type(of: popped))
        }
        return value
    }

    mutating func pop<T: Stackable>(_ type: T.Type, count: Int) throws -> [T] {
        var values: [T] = []
        for _ in 0 ..< count {
            values.insert(try pop(type), at: 0)
        }
        return values
    }

    mutating func push(_ entries: [Stackable]) {
        for entry in entries {
            push(entry)
        }
    }
}

extension Stack {
    func get<T: Stackable>(current type: T.Type) throws -> T {
        return try get(type, index: 0)
    }

    func get<T: Stackable>(_ type: T.Type, index: Int) throws -> T {
        var currentIndex: Int = -1
        var entry: Entry? = _top
        repeat {
            defer { entry = entry?.next }
            guard let value = entry?.value as? T else {
                continue
            }
            currentIndex += 1
            if currentIndex == index {
                return value
            }
        } while entry != nil
        throw Trap.stackNotFound(type, index: index)
    }
}

extension Stack: CustomDebugStringConvertible {
    var debugDescription: String {
        var debugDescription = ""

        var entry: Stack.Entry? = _top
        guard entry != nil else {
            print("(empty)", to: &debugDescription)
            return debugDescription
        }

        while let value = entry?.value {
            defer { entry = entry?.next }
            dump(value, to: &debugDescription)
        }

        return debugDescription
    }
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#id4>
extension Value: Stackable {}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#labels>
// sourcery: AutoEquatable
struct Label: Stackable {
    let arity: Int
    let continuation: [Instruction]
}

/// - Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#frames>
// sourcery: AutoEquatable
final class Frame: Stackable {
    let arity: Int
    let module: ModuleInstance
    var locals: [Value]

    init(arity: Int, module: ModuleInstance, locals: [Value]) {
        self.arity = arity
        self.module = module
        self.locals = locals
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

extension Stack {
    internal func entries() -> [Stackable] {
        var entries = [Stackable]()
        var entry = _top
        while let value = entry?.value {
            entries.append(value)
            entry = entry?.next
        }
        return entries
    }
}
