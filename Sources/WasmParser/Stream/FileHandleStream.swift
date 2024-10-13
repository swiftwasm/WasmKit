import SystemPackage

public final class FileHandleStream: ByteStream {
    private(set) public var currentIndex: Int = 0

    private let fileHandle: FileDescriptor
    private let bufferLength: Int

    private var endOffset: Int = 0
    private var startOffset: Int = 0
    private var bytes: [UInt8] = []

    public init(fileHandle: FileDescriptor, bufferLength: Int = 1024 * 8) throws {
        self.fileHandle = fileHandle
        self.bufferLength = bufferLength

        try readMoreIfNeeded()
    }

    private func readMoreIfNeeded() throws {
        guard Int(endOffset) == currentIndex else { return }
        startOffset = currentIndex

        let data = try fileHandle.read(upToCount: bufferLength)

        bytes = [UInt8](data)
        endOffset = startOffset + bytes.count
    }

    @discardableResult
    public func consumeAny() throws -> UInt8 {
        guard let consumed = try peek() else {
            throw WasmParserError(.unexpectedEnd, offset: currentIndex)
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws -> UInt8 {
        guard let consumed = try peek() else {
            throw StreamError<UInt8>.unexpectedEnd(expected: Set(expected))
        }
        guard expected.contains(consumed) else {
            throw StreamError<Element>.unexpected(consumed, index: currentIndex, expected: Set(expected))
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func consume(count: Int) throws -> ArraySlice<UInt8> {
        let bytesToRead = currentIndex + count - endOffset

        guard bytesToRead > 0 else {
            let bytesIndex = currentIndex - startOffset
            let result = bytes[bytesIndex..<bytesIndex + count]
            currentIndex = currentIndex + count
            return result
        }

        let data = try fileHandle.read(upToCount: bytesToRead)
        guard data.count == bytesToRead else {
            throw StreamError<UInt8>.unexpectedEnd(expected: nil)
        }

        bytes.append(contentsOf: [UInt8](data))
        endOffset = endOffset + data.count

        let bytesIndex = currentIndex - startOffset
        let result = bytes[bytesIndex..<bytesIndex + count]

        currentIndex = endOffset

        return result
    }

    public func peek() throws -> UInt8? {
        try readMoreIfNeeded()

        let index = currentIndex - startOffset
        guard bytes.indices.contains(index) else {
            return nil
        }

        return bytes[index]
    }
}

extension FileDescriptor {
    fileprivate func read(upToCount maxLength: Int) throws -> [UInt8] {
        try [UInt8](unsafeUninitializedCapacity: maxLength) { buffer, outCount in
            outCount = try read(into: UnsafeMutableRawBufferPointer(buffer))
        }
    }
}
