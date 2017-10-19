public protocol Stream {
    associatedtype Token
    associatedtype Offset: ExpressibleByIntegerLiteral
    func next(offset: Offset) -> Token?
    mutating func advance()
}

extension Stream {
    func next() -> Token? {
        return next(offset: 0)
    }
}

public struct UnicodeStream: Stream {

    public let unicodeScalars: String.UnicodeScalarView
    private var index: String.Index

    init(_ string: String, from initialIndex: String.Index? = nil) {
        self.unicodeScalars = string.unicodeScalars
        self.index = initialIndex ?? string.startIndex
    }

    public func next(offset: String.IndexDistance) -> UnicodeScalar? {
        guard unicodeScalars.indices.contains(index) else { return nil }

        let lastIndex = unicodeScalars.index(before: unicodeScalars.endIndex)
        guard let index = unicodeScalars.index(index, offsetBy: offset, limitedBy: lastIndex) else { return nil }
        return unicodeScalars[index]
    }

    public mutating func advance() {
        index = unicodeScalars.index(after: index)
    }
}
