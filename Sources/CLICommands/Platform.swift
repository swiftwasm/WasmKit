// Minimal file helpers for CLI commands. This intentionally duplicates a
// sliver of platform code found elsewhere in the package: the WASI module's
// platform layer is an implementation detail of WASI and is not shared as a
// utility.
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(Windows)
    import ucrt
#endif

enum CLIFile {
    struct Error: Swift.Error, CustomStringConvertible {
        let description: String
    }

    /// An opened file exposing the raw platform descriptor for
    /// descriptor-based APIs. The handle owns the descriptor; call
    /// ``close()`` exactly once.
    struct Handle {
        /// The raw platform descriptor, for APIs that borrow it.
        let rawValue: CInt

        /// Reads up to `maxLength` bytes from the current offset. A shorter
        /// result means end-of-file.
        func read(upToCount maxLength: Int) throws -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: maxLength)
            let count = try buffer.withUnsafeMutableBytes { raw -> Int in
                guard let base = raw.baseAddress, raw.count > 0 else { return 0 }
                #if os(Windows)
                    return try Int(_throwingErrno { _read(rawValue, base, UInt32(min(raw.count, Int(Int32.max)))) })
                #else
                    return try _throwingErrno { _cliRead(rawValue, base, raw.count) }
                #endif
            }
            buffer.removeLast(maxLength - count)
            return buffer
        }

        func seekToStart() throws {
            #if os(Windows)
                _ = try _throwingErrno { _lseeki64(rawValue, 0, SEEK_SET) }
            #else
                _ = try _throwingErrno { lseek(rawValue, 0, SEEK_SET) }
            #endif
        }

        /// Writes all of `bytes` at the current offset.
        func writeAll(_ bytes: [UInt8]) throws {
            try bytes.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return }
                var written = 0
                while written < raw.count {
                    #if os(Windows)
                        written += try Int(_throwingErrno { _write(rawValue, base + written, UInt32(min(raw.count - written, Int(Int32.max)))) })
                    #else
                        written += try _throwingErrno { _cliWrite(rawValue, base + written, raw.count - written) }
                    #endif
                }
            }
        }

        func close() throws {
            #if os(Windows)
                _ = try _throwingErrno { _close(rawValue) }
            #else
                _ = try _throwingErrno { _cliClose(rawValue) }
            #endif
        }
    }

    static func openRead(_ path: String) throws -> Handle {
        #if os(Windows)
            var fd: CInt = -1
            let err = path.withCString(encodedAs: UTF16.self) { widePath in
                _wsopen_s(&fd, widePath, _O_RDONLY | _O_BINARY, _SH_DENYNO, 0)
            }
            guard err == 0 else {
                throw Error(description: "Failed to open file: \(path) (\(_errnoMessage(err)))")
            }
            return Handle(rawValue: fd)
        #else
            let fd = path.withCString { _cliOpen($0, O_RDONLY, 0) }
            guard fd >= 0 else {
                throw Error(description: "Failed to open file: \(path) (\(_errnoMessage(errno)))")
            }
            return Handle(rawValue: fd)
        #endif
    }

    static func createWrite(_ path: String) throws -> Handle {
        #if os(Windows)
            var fd: CInt = -1
            let err = path.withCString(encodedAs: UTF16.self) { widePath in
                _wsopen_s(&fd, widePath, _O_WRONLY | _O_CREAT | _O_TRUNC | _O_BINARY, _SH_DENYNO, _S_IREAD | _S_IWRITE)
            }
            guard err == 0 else {
                throw Error(description: "Failed to create file: \(path) (\(_errnoMessage(err)))")
            }
            return Handle(rawValue: fd)
        #else
            let fd = path.withCString { _cliOpen($0, O_WRONLY | O_CREAT | O_TRUNC, 0o644) }
            guard fd >= 0 else {
                throw Error(description: "Failed to create file: \(path) (\(_errnoMessage(errno)))")
            }
            return Handle(rawValue: fd)
        #endif
    }

    private static func _errnoMessage(_ error: CInt) -> String {
        guard let message = strerror(error) else { return "errno \(error)" }
        return String(cString: message)
    }
}

/// Runs `body` until it returns a non-negative value, retrying on `EINTR`,
/// and throws a descriptive error on failure.
@discardableResult
private func _throwingErrno<I: FixedWidthInteger>(_ body: () -> I) throws -> I {
    while true {
        let result = body()
        if result >= 0 { return result }
        #if os(Windows)
            var errnoValue: CInt = 0
            _get_errno(&errnoValue)
        #else
            let errnoValue = errno
        #endif
        if errnoValue == EINTR { continue }
        let message = strerror(errnoValue).map { String(cString: $0) } ?? "errno \(errnoValue)"
        throw CLIFile.Error(description: "I/O error: \(message)")
    }
}

#if !os(Windows)
    // Unshadowed libc entry points.
    private func _cliOpen(_ path: UnsafePointer<CChar>, _ oflag: CInt, _ mode: mode_t) -> CInt {
        open(path, oflag, mode)
    }
    private func _cliRead(_ fd: CInt, _ buffer: UnsafeMutableRawPointer, _ count: Int) -> Int {
        read(fd, buffer, count)
    }
    private func _cliWrite(_ fd: CInt, _ buffer: UnsafeRawPointer, _ count: Int) -> Int {
        write(fd, buffer, count)
    }
    private func _cliClose(_ fd: CInt) -> CInt {
        close(fd)
    }
#endif
