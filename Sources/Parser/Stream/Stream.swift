public protocol Stream {
    associatedtype Element: Hashable

    var currentIndex: Int { get }

    func consumeAny() throws -> Element
    func consume(_ expected: Set<Element>) throws -> Element
    func consume(count: Int) throws -> [Element]

    func peek() -> Element?
}

extension Stream {
    public func consume(_ expected: Element) throws -> Element {
        return try consume(Set([expected]))
    }

    public func consume(count: Int) throws -> [Element] {
        return try (0 ..< count).map { _ in try consumeAny() }
    }

    public func hasReachedEnd() throws -> Bool {
        return peek() == nil
    }
}
