// "FileSystem" trait can be turned off to support embedded platforms
#if FileSystem

    import struct SystemPackage.FileDescriptor
    import struct SystemPackage.FilePath

    #if os(Windows)
        import ucrt
    #endif

    extension Parser where Source == FileHandleStreamSource {

        /// Initialize a new parser with the given file handle
        ///
        /// - Parameters:
        ///   - fileHandle: The file handle to the WebAssembly binary file to parse
        ///   - features: Enabled WebAssembly features for parsing
        public init(fileHandle: FileDescriptor, features: WasmFeatureSet = .default) throws {
            self.init(stream: try FileHandleStreamSource(fileHandle: fileHandle), features: features)
        }

        /// Initialize a new parser with the given file path
        ///
        /// - Parameters:
        ///   - filePath: The file path to the WebAssembly binary file to parse
        ///   - features: Enabled WebAssembly features for parsing
        public init(filePath: FilePath, features: WasmFeatureSet = .default) throws {
            #if os(Windows)
                // TODO: Upstream `O_BINARY` to `SystemPackage
                let accessMode = FileDescriptor.AccessMode(
                    rawValue: FileDescriptor.AccessMode.readOnly.rawValue | O_BINARY
                )
            #else
                let accessMode: FileDescriptor.AccessMode = .readOnly
            #endif
            let fileHandle = try FileDescriptor.open(filePath, accessMode)
            self.init(stream: try FileHandleStreamSource(fileHandle: fileHandle), features: features)
        }
    }

    public final class FileHandleStreamSource: ByteStreamSource {
        private let fileHandle: FileDescriptor
        private let bufferLength: Int

        private var bufferEndOffset: Int = 0
        private var bufferStartOffset: Int = 0
        private var bytes: [UInt8] = []

        public init(fileHandle: FileDescriptor, bufferLength: Int = 1024 * 8) throws {
            self.fileHandle = fileHandle
            self.bufferLength = bufferLength

            try readMoreIfNeeded(offset: 0)
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
                let data: [UInt8]
                do {
                    data = try fileHandle.read(upToCount: bytesToRead)
                } catch {
                    throw WasmParserError("I/O error: \(error)", offset: startOffset)
                }
                // Fewer bytes than requested means the stream ended early; that is
                // an out-of-range read, which `ByteStream` reports as needed.
                guard data.count == bytesToRead else {
                    return nil
                }

                bytes.append(contentsOf: [UInt8](data))
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

            do {
                let data = try fileHandle.read(upToCount: bufferLength)

                bytes = [UInt8](data)
            } catch {
                throw WasmParserError("I/O error: \(error)", offset: offset)
            }
            bufferEndOffset = bufferStartOffset + bytes.count
        }
    }

    extension FileDescriptor {
        fileprivate func read(upToCount maxLength: Int) throws -> [UInt8] {
            try [UInt8](unsafeUninitializedCapacity: maxLength) { buffer, outCount in
                outCount = try read(into: UnsafeMutableRawBufferPointer(buffer))
            }
        }
    }

#endif
