public enum Error<Element>: Swift.Error where Element: Hashable {
    case unexpectedEnd
    case unexpected(Element, expected: Set<Element>?)
}

extension Error: Equatable {
    public static func == (lhs: Error<Element>, rhs: Error<Element>) -> Bool {
        switch (lhs, rhs) {
        case (.unexpectedEnd, .unexpectedEnd):
            return true
        case let (.unexpected(l1, l2), .unexpected(r1, r2)):
            return l1 == r1 && l2 == r2
        default:
            return false
        }
    }
}
