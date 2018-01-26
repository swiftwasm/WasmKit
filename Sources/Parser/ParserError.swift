public enum Error<Element>: Swift.Error where Element: Hashable {
    case unexpectedEnd
    case unexpected(Element, expected: Set<Element>?)
}
