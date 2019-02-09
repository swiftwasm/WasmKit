public enum Error<Element>: Swift.Error, Equatable where Element: Hashable {
    case unexpectedEnd
    case unexpected(Element, expected: Set<Element>?)
}
