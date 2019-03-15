import Foundation

public final class FileHandleStream: ByteStream {
    public var currentIndex: Int = 0

    private let fileHandle: FileHandle
    private let bufferLength: Int

    private var endOffset: Int = 0
    private var startOffset: Int = 0
    private var bytes: [UInt8] = []

    public init(fileHandle: FileHandle, bufferLength: Int = 256) {
        self.fileHandle = fileHandle
        self.bufferLength = bufferLength
    }

    private func readMoreIfNeeded() {
        guard Int(endOffset) == currentIndex else { return }
        startOffset = currentIndex
        bytes = [UInt8](fileHandle.readData(ofLength: bufferLength))
        endOffset = startOffset + bytes.count
    }

    @discardableResult
    public func consumeAny() throws -> UInt8 {
        guard let consumed = peek() else {
            throw StreamError<UInt8>.unexpectedEnd(expected: nil)
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws -> UInt8 {
        guard let consumed = peek() else {
            throw StreamError<UInt8>.unexpectedEnd(expected: Set(expected))
        }
        guard expected.contains(consumed) else {
            throw StreamError<Element>.unexpected(consumed, index: currentIndex, expected: Set(expected))
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func peek() -> UInt8? {
        readMoreIfNeeded()

        let index = currentIndex - startOffset
        guard bytes.indices.contains(index) else {
            return nil
        }

        return bytes[index]
    }
}
