public protocol ByteStream: Stream where Element == UInt8 {}

public final class StaticByteStream: ByteStream {
    public let bytes: ArraySlice<UInt8>
    public var currentIndex: Int

    public init(bytes: [UInt8]) {
        self.bytes = ArraySlice(bytes)
        currentIndex = bytes.startIndex
    }

    public init(bytes: ArraySlice<UInt8>) {
        self.bytes = bytes
        currentIndex = bytes.startIndex
    }

    @discardableResult
    public func consumeAny() throws -> UInt8 {
        guard currentIndex < self.bytes.endIndex else {
            throw StreamError<Element>.unexpectedEnd(expected: nil)
        }

        let consumed = bytes[currentIndex]
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws -> UInt8 {
        guard currentIndex < self.bytes.endIndex else {
            throw StreamError<Element>.unexpectedEnd(expected: Set(expected))
        }

        let consumed = bytes[currentIndex]
        guard expected.contains(consumed) else {
            throw StreamError<Element>.unexpected(consumed, index: currentIndex, expected: Set(expected))
        }

        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func consume(count: Int) throws -> ArraySlice<UInt8> {
        guard count > 0 else { return [] }
        let updatedIndex = currentIndex + count

        guard updatedIndex - 1 < bytes.endIndex else {
            throw StreamError<Element>.unexpectedEnd(expected: nil)
        }

        defer { currentIndex = updatedIndex }

        return bytes[currentIndex..<updatedIndex]
    }

    public func peek() -> UInt8? {
        guard currentIndex < self.bytes.endIndex else {
            return nil
        }
        return bytes[currentIndex]
    }
}
