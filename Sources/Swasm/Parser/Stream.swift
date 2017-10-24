public protocol StreamIndex: Equatable, CustomStringConvertible {}
extension Int: StreamIndex {}

public protocol Stream {
    associatedtype Token
    associatedtype Index: StreamIndex

    var position: Index { get }

    @discardableResult
    mutating func pop() throws -> Token?
}

public protocol PeekableStream: Stream {
    func peek() throws -> Token?
}

public struct UnicodeStream: PeekableStream {

    public let unicodeScalars: String.UnicodeScalarView

    public var position: Int {
        return index.encodedOffset
    }

    private var index: String.Index

    init(_ string: String, from initialIndex: String.Index? = nil) {
        self.unicodeScalars = string.unicodeScalars
        self.index = initialIndex ?? string.startIndex
    }

    public func peek() -> UnicodeScalar? {
        guard unicodeScalars.indices.contains(index) else { return nil }
        return unicodeScalars[index]
    }

    @discardableResult
    public mutating func pop() -> UnicodeScalar? {
        guard unicodeScalars.indices.contains(index) else { return nil }
        index = unicodeScalars.index(after: index)
        return unicodeScalars[index]
    }
}
