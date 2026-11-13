// Minimal file helpers for CLI commands, built on C stdio, which is portable
// across every supported platform (including wasi-libc, whose open(2) flag
// macros don't import into Swift). This intentionally duplicates a sliver of
// IO code found elsewhere in the package: the WASI module's platform layer is
// an implementation detail of WASI and is not shared as a utility.
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
#elseif os(WASI)
    import WASILibc
#endif

// wasi-libc's and Bionic's `FILE` is an incomplete type, which Swift imports
// as an opaque pointer rather than a pointee type.
#if os(WASI) || os(Android)
    private typealias CFILEPointer = OpaquePointer
#else
    private typealias CFILEPointer = UnsafeMutablePointer<FILE>
#endif

enum CLIFile {
    struct Error: Swift.Error, CustomStringConvertible {
        let description: String
    }

    /// An opened file exposing the raw platform descriptor for
    /// descriptor-based APIs. The handle owns the stream; call ``close()``
    /// exactly once.
    struct Handle {
        fileprivate let stream: CFILEPointer

        /// The raw platform descriptor, for APIs that borrow it. Callers
        /// must reposition via ``seekToStart()`` (not raw seeks) so the
        /// stream and descriptor stay in sync.
        var rawValue: CInt {
            #if os(Windows)
                return _fileno(stream)
            #else
                return fileno(stream)
            #endif
        }

        /// Reads up to `maxLength` bytes from the current offset. A shorter
        /// result means end-of-file.
        func read(upToCount maxLength: Int) throws -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: maxLength)
            let count = buffer.withUnsafeMutableBytes { raw -> Int in
                guard let base = raw.baseAddress, raw.count > 0 else { return 0 }
                return fread(base, 1, raw.count, stream)
            }
            guard count == maxLength || ferror(stream) == 0 else {
                throw Error(description: "I/O error: \(_errnoMessage())")
            }
            buffer.removeLast(maxLength - count)
            return buffer
        }

        /// Repositions both the stream and the underlying descriptor to the
        /// start of the file.
        func seekToStart() throws {
            guard fseek(stream, 0, CInt(SEEK_SET)) == 0 else {
                throw Error(description: "I/O error: \(_errnoMessage())")
            }
        }

        /// Writes all of `bytes` at the current offset and flushes.
        func writeAll(_ bytes: [UInt8]) throws {
            let written = bytes.withUnsafeBytes { raw -> Int in
                guard let base = raw.baseAddress, raw.count > 0 else { return 0 }
                return fwrite(base, 1, raw.count, stream)
            }
            guard written == bytes.count, fflush(stream) == 0 else {
                throw Error(description: "I/O error: \(_errnoMessage())")
            }
        }

        func close() throws {
            guard fclose(stream) == 0 else {
                throw Error(description: "I/O error: \(_errnoMessage())")
            }
        }
    }

    static func openRead(_ path: String) throws -> Handle {
        try Handle(stream: _open(path, mode: "rb", what: "open"))
    }

    static func createWrite(_ path: String) throws -> Handle {
        try Handle(stream: _open(path, mode: "wb", what: "create"))
    }

    private static func _open(_ path: String, mode: String, what: String) throws -> CFILEPointer {
        #if os(Windows)
            // Use the wide-character variant so non-ASCII paths survive.
            let stream = path.withCString(encodedAs: UTF16.self) { widePath in
                mode.withCString(encodedAs: UTF16.self) { wideMode in
                    _wfopen(widePath, wideMode)
                }
            }
        #else
            let stream = path.withCString { fopen($0, mode) }
        #endif
        guard let stream else {
            throw Error(description: "Failed to \(what) file: \(path) (\(_errnoMessage()))")
        }
        return stream
    }

    fileprivate static func _errnoMessage() -> String {
        #if os(Windows)
            var errnoValue: CInt = 0
            _get_errno(&errnoValue)
        #else
            let errnoValue = errno
        #endif
        guard let message = strerror(errnoValue) else { return "errno \(errnoValue)" }
        return String(cString: message)
    }
}
