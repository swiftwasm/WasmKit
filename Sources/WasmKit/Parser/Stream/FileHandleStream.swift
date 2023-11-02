import Foundation

final class FileHandleStream: ByteStream {
    private(set) var currentIndex: Int = 0

    private let fileHandle: FileHandle
    private let bufferLength: Int

    private var endOffset: Int = 0
    private var startOffset: Int = 0
    private var bytes: [UInt8] = []

    init(fileHandle: FileHandle, bufferLength: Int = 1024 * 8) throws {
        self.fileHandle = fileHandle
        self.bufferLength = bufferLength

        try readMoreIfNeeded()
    }

    private func readMoreIfNeeded() throws {
        guard Int(endOffset) == currentIndex else { return }
        startOffset = currentIndex

        let data = try fileHandle.read(upToCount: bufferLength) ?? Foundation.Data()

        bytes = [UInt8](data)
        endOffset = startOffset + bytes.count
    }

    @discardableResult
    func consumeAny() throws -> UInt8 {
        guard let consumed = try peek() else {
            throw WasmParserError.unexpectedEnd
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    func consume(_ expected: Set<UInt8>) throws -> UInt8 {
        guard let consumed = try peek() else {
            throw StreamError<UInt8>.unexpectedEnd(expected: Set(expected))
        }
        guard expected.contains(consumed) else {
            throw StreamError<Element>.unexpected(consumed, index: currentIndex, expected: Set(expected))
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    func consume(count: Int) throws -> ArraySlice<UInt8> {
        let bytesToRead = currentIndex + count - endOffset

        guard bytesToRead > 0 else {
            let bytesIndex = currentIndex - startOffset
            let result = bytes[bytesIndex..<bytesIndex + count]
            currentIndex = currentIndex + count
            return result
        }

        guard let data = try fileHandle.read(upToCount: bytesToRead), data.count == bytesToRead else {
            throw StreamError<UInt8>.unexpectedEnd(expected: nil)
        }

        bytes.append(contentsOf: [UInt8](data))
        endOffset = endOffset + data.count

        let bytesIndex = currentIndex - startOffset
        let result = bytes[bytesIndex..<bytesIndex + count]

        currentIndex = endOffset

        return result
    }

    func peek() throws -> UInt8? {
        try readMoreIfNeeded()

        let index = currentIndex - startOffset
        guard bytes.indices.contains(index) else {
            return nil
        }

        return bytes[index]
    }
}
