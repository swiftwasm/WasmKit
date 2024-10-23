@usableFromInline
enum StreamError<Element>: Swift.Error, Equatable where Element: Hashable {
    case unexpectedEnd(expected: Set<Element>?)
    case unexpected(Element, index: Int, expected: Set<Element>?)
}

public protocol Stream {
    associatedtype Element: Hashable

    var currentIndex: Int { get }

    func consumeAny() throws -> Element
    func consume(_ expected: Set<Element>) throws -> Element
    func consume(count: Int) throws -> ArraySlice<Element>

    func peek() throws -> Element?
}

extension Stream {
    func consume(_ expected: Element) throws -> Element {
        try consume(Set([expected]))
    }

    @usableFromInline
    func hasReachedEnd() throws -> Bool {
        try peek() == nil
    }
}
