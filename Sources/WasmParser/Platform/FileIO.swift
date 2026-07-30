// Minimal platform shim for the read-only file access needed by
// `FileHandleStreamSource`. Not a general-purpose file API: WasmParser only
// ever opens a binary for sequential reading.
#if FileSystem

    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #elseif canImport(Android)
        import Android
    #elseif canImport(WASILibc)
        import WASILibc
    #elseif os(Windows)
        import ucrt
    #endif

    enum FileIO {
        /// Opens the file at `path` for reading in binary mode and returns a
        /// platform file descriptor owned by the caller.
        static func openForReading(path: String) throws(WasmParserError) -> CInt {
            #if os(Windows)
                var fd: CInt = -1
                let error = path.withCString(encodedAs: UTF16.self) { widePath in
                    _wsopen_s(&fd, widePath, _O_RDONLY | _O_BINARY, _SH_DENYNO, 0)
                }
                guard error == 0 else {
                    throw WasmParserError("failed to open file \(path): \(errorMessage(error))", offset: 0)
                }
                return fd
            #else
                while true {
                    let fd = path.withCString { open($0, O_RDONLY) }
                    if fd >= 0 { return fd }
                    if errno == EINTR { continue }
                    throw WasmParserError("failed to open file \(path): \(errorMessage(errno))", offset: 0)
                }
            #endif
        }

        /// Reads up to `maxLength` bytes from the current offset of `fd`.
        /// A result shorter than `maxLength` means end-of-file was reached.
        static func readBytes(_ fd: CInt, upToCount maxLength: Int) throws(WasmParserError) -> [UInt8] {
            var result = [UInt8](repeating: 0, count: maxLength)
            let readCount = result.withUnsafeMutableBytes { rawRead(fd, into: $0) }
            guard readCount >= 0 else {
                throw WasmParserError("I/O error: \(errorMessage(CInt(-readCount)))", offset: 0)
            }
            result.removeLast(maxLength - readCount)
            return result
        }

        /// Returns the number of bytes read (>= 0), or a negative errno value
        /// on failure.
        private static func rawRead(_ fd: CInt, into buffer: UnsafeMutableRawBufferPointer) -> Int {
            guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
            #if os(Windows)
                let count = _read(fd, base, UInt32(min(buffer.count, Int(Int32.max))))
                if count >= 0 { return Int(count) }
                var error: CInt = 0
                _get_errno(&error)
                return -Int(error)
            #else
                while true {
                    let count = read(fd, base, buffer.count)
                    if count >= 0 { return Int(count) }
                    if errno == EINTR { continue }
                    return -Int(errno)
                }
            #endif
        }

        /// Closes a file descriptor previously returned by `openForReading`.
        /// Errors are ignored; the descriptor was opened read-only, so no
        /// buffered data can be lost.
        static func closeFile(_ fd: CInt) {
            #if os(Windows)
                _ = _close(fd)
            #else
                _ = close(fd)
            #endif
        }

        private static func errorMessage(_ error: CInt) -> String {
            guard let message = strerror(error) else { return "errno \(error)" }
            return String(cString: message)
        }
    }

#endif
