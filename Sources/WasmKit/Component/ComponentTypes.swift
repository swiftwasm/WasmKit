/// Error type raised from Component Model operations
public struct ComponentError<Content: Sendable>: Error {
    /// The content of the error
    public let content: Content

    /// Initialize a new error with the given content
    public init(_ content: Content) {
        self.content = content
    }
}

extension ComponentError: Equatable where Content: Equatable {}
extension ComponentError: Hashable where Content: Hashable {}
