import struct SystemPackage.FileDescriptor

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

    private func readMoreIfNeeded() throws(WasmParserError) {
        guard Int(endOffset) == currentIndex else { return }
        startOffset = currentIndex

        do {
            let data = try fileHandle.read(upToCount: bufferLength)

            bytes = [UInt8](data)
        } catch {
            throw WasmParserError(kind: .unclassified(error), offset: currentIndex)
        }
        endOffset = startOffset + bytes.count
    }

    @discardableResult
    public func consumeAny() throws(WasmParserError) -> UInt8 {
        guard let consumed = try peek() else {
            throw WasmParserError(.unexpectedEnd, offset: currentIndex)
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    @discardableResult
    public func consume(_ expected: Set<UInt8>) throws(WasmParserError) -> UInt8 {
        guard let consumed = try peek() else {
            throw WasmParserError(kind: .unexpectedEnd(expected: Set(expected)), offset: currentIndex)
        }
        guard expected.contains(consumed) else {
            throw WasmParserError(kind: .unexpectedByte(
                consumed,
                index: currentIndex,
                expected: Set(expected)
            ), offset: currentIndex)
        }
        currentIndex = bytes.index(after: currentIndex)
        return consumed
    }

    public func consume(count: Int) throws(WasmParserError) -> ArraySlice<UInt8> {
        let bytesToRead = currentIndex + count - endOffset

        guard bytesToRead > 0 else {
            let bytesIndex = currentIndex - startOffset
            let result = bytes[bytesIndex..<bytesIndex + count]
            currentIndex = currentIndex + count
            return result
        }

        let data: [UInt8]
        do {
            data = try fileHandle.read(upToCount: bytesToRead)
        } catch {
            throw WasmParserError(kind: .unclassified(error), offset: currentIndex)
        }
        guard data.count == bytesToRead else {
            throw WasmParserError(kind: .unexpectedEnd(expected: nil), offset: currentIndex)
        }

        bytes.append(contentsOf: [UInt8](data))
        endOffset = endOffset + data.count

        let bytesIndex = currentIndex - startOffset
        let result = bytes[bytesIndex..<bytesIndex + count]

        currentIndex = endOffset

        return result
    }

    public func peek() throws(WasmParserError) -> UInt8? {
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
