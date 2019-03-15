public protocol ByteStream: Stream where Element == UInt8 {}

public final class StaticByteStream: ByteStream {
    public let bytes: [UInt8]
    public var currentIndex: Int

    public init(bytes: [UInt8]) {
        self.bytes = bytes
        currentIndex = bytes.startIndex
    }

    @discardableResult
    public func consumeAny() throws -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw StreamError<Element>.unexpectedEnd(expected: nil)
        }

        let consumed = bytes[currentIndex]
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw StreamError<Element>.unexpectedEnd(expected: Set(expected))
        }

        let consumed = bytes[currentIndex]
        guard expected.contains(consumed) else {
            throw StreamError<Element>.unexpected(consumed, index: currentIndex, expected: Set(expected))
        }

        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func peek() -> UInt8? {
        guard bytes.indices.contains(currentIndex) else {
            return nil
        }
        return bytes[currentIndex]
    }
}
