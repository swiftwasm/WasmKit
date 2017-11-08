public protocol Stream: IteratorProtocol {
    associatedtype Index: Equatable, CustomStringConvertible
    var position: Index { get }
}

public protocol LA1Stream: Stream {
    func look() -> Element?
}

public protocol LA2Stream: LA1Stream {
    func look() -> (Element?, Element?)
}

public extension LA2Stream {
    func look() -> Element? {
        let (c1, _) = look()
        return c1
    }
}

public struct UnicodeStream: LA2Stream {
    public let unicodeScalars: String.UnicodeScalarView

    public var position: Int {
        return index.encodedOffset
    }

    private var index: String.Index

    init(_ string: String, from initialIndex: String.Index? = nil) {
        self.unicodeScalars = string.unicodeScalars
        self.index = initialIndex ?? string.unicodeScalars.startIndex
    }

    public mutating func next() -> UnicodeScalar? {
        guard unicodeScalars.indices.contains(index) else { return nil }
        let c = unicodeScalars[index]
        index = unicodeScalars.index(after: index)
        return c
    }

    public func look() -> (Unicode.Scalar?, Unicode.Scalar?) {
        guard unicodeScalars.indices.contains(index) else {
            return (nil, nil)
        }
        let c1 = unicodeScalars[index]

        let nextIndex = unicodeScalars.index(after: index)
        guard unicodeScalars.indices.contains(nextIndex) else {
            return (c1, nil)
        }
        let c2 = unicodeScalars[nextIndex]

        return (c1, c2)
    }
}
