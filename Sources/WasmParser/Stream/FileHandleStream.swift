// "FileSystem" trait can be turned off to support embedded platforms
#if FileSystem

    extension Parser where Source == FileHandleStreamSource {

        /// Initialize a new parser with the given file handle
        ///
        /// - Parameters:
        ///   - fileHandle: A platform file descriptor for the WebAssembly binary to
        ///     parse, opened for reading in binary mode. The parser *borrows* the
        ///     descriptor: ownership stays with the caller, who must keep it open
        ///     while the parser is in use and close it afterwards. Bytes are
        ///     consumed starting from the descriptor's current offset.
        ///   - features: Enabled WebAssembly features for parsing
        public init(fileHandle: CInt, features: WasmFeatureSet = .default) throws {
            self.init(stream: try FileHandleStreamSource(fileHandle: fileHandle), features: features)
        }

        /// Initialize a new parser with the given file path
        ///
        /// The file is opened by the parser and closed when the underlying stream
        /// source is deallocated.
        ///
        /// - Parameters:
        ///   - filePath: The file path to the WebAssembly binary file to parse
        ///   - features: Enabled WebAssembly features for parsing
        public init(filePath: String, features: WasmFeatureSet = .default) throws {
            let fileHandle = try FileIO.openForReading(path: filePath)
            self.init(stream: try FileHandleStreamSource(fileHandle: fileHandle, ownsHandle: true), features: features)
        }
    }

    public final class FileHandleStreamSource: ByteStreamSource {
        private let fileHandle: CInt
        /// Whether this source is responsible for closing `fileHandle`.
        /// True only when the source opened the file itself.
        private let ownsHandle: Bool
        private let bufferLength: Int

        private var bufferEndOffset: Int = 0
        private var bufferStartOffset: Int = 0
        private var bytes: [UInt8] = []

        /// Initialize a new stream source with the given file handle
        ///
        /// - Parameters:
        ///   - fileHandle: A platform file descriptor opened for reading in binary
        ///     mode. The stream source *borrows* the descriptor: ownership stays
        ///     with the caller, who must keep it open for the lifetime of this
        ///     source and close it afterwards. Bytes are consumed starting from
        ///     the descriptor's current offset.
        ///   - bufferLength: The size of the internal read buffer
        public convenience init(fileHandle: CInt, bufferLength: Int = 1024 * 8) throws {
            try self.init(fileHandle: fileHandle, ownsHandle: false, bufferLength: bufferLength)
        }

        /// Initialize a new stream source that opens the file at `filePath`
        /// itself and closes it when the source is deallocated.
        ///
        /// - Parameters:
        ///   - filePath: The path of the file to open for reading in binary mode
        ///   - bufferLength: The size of the internal read buffer
        public convenience init(filePath: String, bufferLength: Int = 1024 * 8) throws {
            let fileHandle = try FileIO.openForReading(path: filePath)
            try self.init(fileHandle: fileHandle, ownsHandle: true, bufferLength: bufferLength)
        }

        init(fileHandle: CInt, ownsHandle: Bool, bufferLength: Int = 1024 * 8) throws {
            self.fileHandle = fileHandle
            self.ownsHandle = ownsHandle
            self.bufferLength = bufferLength

            try readMoreIfNeeded(offset: 0)
        }

        deinit {
            if ownsHandle {
                FileIO.closeFile(fileHandle)
            }
        }

        public func readByte(at offset: Int) throws(WasmParserError) -> UInt8? {
            try readMoreIfNeeded(offset: offset)

            let index = offset - bufferStartOffset
            guard bytes.indices.contains(index) else {
                return nil
            }
            return bytes[index]
        }

        public func readBytes(from startOffset: Int, to endOffset: Int) throws(WasmParserError) -> ArraySlice<UInt8>? {
            let bytesToRead = endOffset - bufferEndOffset

            if bytesToRead > 0 {
                let data = try read(upToCount: bytesToRead)
                // Fewer bytes than requested means the stream ended early; that is
                // an out-of-range read, which `ByteStream` reports as needed.
                guard data.count == bytesToRead else {
                    return nil
                }

                bytes.append(contentsOf: data)
                bufferEndOffset = bufferEndOffset + data.count
            }

            // `bytes` is indexed relative to `bufferStartOffset`, so translate the
            // absolute [startOffset, endOffset) range into buffer-local indices.
            let lowerIndex = startOffset - bufferStartOffset
            let upperIndex = endOffset - bufferStartOffset
            return bytes[lowerIndex..<upperIndex]
        }

        private func readMoreIfNeeded(offset: Int) throws(WasmParserError) {
            guard Int(bufferEndOffset) == offset else { return }
            bufferStartOffset = offset

            bytes = try read(upToCount: bufferLength)
            bufferEndOffset = bufferStartOffset + bytes.count
        }

        private func read(upToCount maxLength: Int) throws(WasmParserError) -> [UInt8] {
            try FileIO.readBytes(fileHandle, upToCount: maxLength)
        }
    }

#endif
