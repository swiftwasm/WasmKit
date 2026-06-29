// "FileSystem" trait can be turned off to support embedded platforms
#if FileSystem

    import struct SystemPackage.FileDescriptor
    import struct SystemPackage.FilePath

    #if os(Windows)
        import ucrt
    #endif

    extension Parser where Stream == FileHandleStream {

        /// Initialize a new parser with the given file handle
        ///
        /// - Parameters:
        ///   - fileHandle: The file handle to the WebAssembly binary file to parse
        ///   - features: Enabled WebAssembly features for parsing
        public init(fileHandle: FileDescriptor, features: WasmFeatureSet = .default) throws {
            self.init(stream: try FileHandleStream(fileHandle: fileHandle), features: features)
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
            self.init(stream: try FileHandleStream(fileHandle: fileHandle), features: features)
        }
    }

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
                throw WasmParserError("I/O error: \(error)", offset: currentIndex)
            }
            endOffset = startOffset + bytes.count
        }

        @discardableResult
        public func consumeAny() throws(WasmParserError) -> UInt8 {
            guard let consumed = try peek() else {
                throw WasmParserError(message: .unexpectedEnd, offset: currentIndex)
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
                throw WasmParserError("I/O error: \(error)", offset: currentIndex)
            }
            guard data.count == bytesToRead else {
                throw WasmParserError(kind: .parserUnexpectedEnd(expected: nil), offset: currentIndex)
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

#endif
