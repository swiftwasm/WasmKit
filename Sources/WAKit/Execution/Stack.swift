protocol Stackable {}

final class Stack {
    private final class Entry {
        var value: Stackable
        var next: Entry?

        init(value: Stackable, next: Entry?) {
            self.value = value
            self.next = next
        }
    }

    private var _top: Entry?

    var top: Stackable? {
        return _top?.value
    }

    func push(entry: Stackable) {
        _top = Entry(value: entry, next: _top)
    }

    func pop() -> Stackable? {
        let value = _top?.value
        _top = _top?.next
        return value
    }
}
