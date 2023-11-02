public struct ComponentError<Content>: Error {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

extension ComponentError: Equatable where Content: Equatable {}
extension ComponentError: Hashable where Content: Hashable {}
