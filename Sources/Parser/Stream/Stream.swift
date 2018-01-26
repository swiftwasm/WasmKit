public protocol Stream {
    associatedtype Element: Hashable
    associatedtype Index

    var currentIndex: Index { get }

    @discardableResult
    func consumeAny() throws -> Element

    @discardableResult
    func consume(_ expected: Set<Element>) throws -> Element

    func peek() throws -> Element?
}

extension Stream {
    public func consume(_ expected: Element) throws {
        try consume(Set([expected]))
    }

    public func consume(_ expected: [Element]) throws {
        for e in expected {
            try consume(e)
        }
    }

    public func hasReachedEnd() throws -> Bool {
        return try peek() == nil
    }
}
