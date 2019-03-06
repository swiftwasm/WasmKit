public protocol Stream {
    associatedtype Element: Hashable

    var currentIndex: Int { get }

    func consumeAny() throws -> Element
    func consume(_ expected: Set<Element>) throws -> Element
    func consume(sequence expected: [Element]) throws -> [Element]

    func peek() -> Element?
}

extension Stream {
    public func consume(_ expected: Element) throws -> Element {
        return try consume(Set([expected]))
    }

    public func consume(sequence expected: [Element]) throws -> [Element] {
        return try expected.map(consume)
    }

    public func hasReachedEnd() throws -> Bool {
        return peek() == nil
    }
}
