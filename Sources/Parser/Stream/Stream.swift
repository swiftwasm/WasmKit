public protocol Stream {
    associatedtype Element: Hashable
    associatedtype Index

    var currentIndex: Index { get }

    @discardableResult
    func consumeAny() throws -> Element

    @discardableResult
    func consume(_ expected: Set<Element>) throws -> Element

    func peek() throws -> Element
}

extension Stream {
    @discardableResult
    public func consume(_ expected: Element) throws -> Element {
        return try consume(Set([expected]))
    }

    @discardableResult
    public func consume(_ expected: [Element]) throws -> [Element] {
        return try expected.map { try consume($0) }
    }

    public func hasReachedEnd() throws -> Bool {
        return (try? peek()) == nil
    }
}
