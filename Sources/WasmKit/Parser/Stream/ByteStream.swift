protocol ByteStream: Stream where Element == UInt8 {}

final class StaticByteStream: ByteStream {
    let bytes: [UInt8]
    var currentIndex: Int

    init(bytes: [UInt8]) {
        self.bytes = bytes
        currentIndex = bytes.startIndex
    }

    @discardableResult
    func consumeAny() throws -> UInt8 {
        guard bytes.indices.contains(currentIndex) else {
            throw StreamError<Element>.unexpectedEnd(expected: nil)
        }

        let consumed = bytes[currentIndex]
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    func consume(_ expected: Set<UInt8>) throws -> UInt8 {
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

    func consume(count: Int) throws -> ArraySlice<UInt8> {
        let updatedIndex = currentIndex + count

        guard bytes.indices.contains(updatedIndex - 1) else {
            throw StreamError<Element>.unexpectedEnd(expected: nil)
        }

        defer { currentIndex = updatedIndex }

        return bytes[currentIndex..<updatedIndex]
    }

    func peek() -> UInt8? {
        guard bytes.indices.contains(currentIndex) else {
            return nil
        }
        return bytes[currentIndex]
    }
}
