enum StreamError<Element>: Swift.Error, Equatable where Element: Hashable {
    case unexpectedEnd(expected: Set<Element>?)
    case unexpected(Element, index: Int, expected: Set<Element>?)
}
