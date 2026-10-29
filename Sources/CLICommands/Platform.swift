// Minimal file helpers for CLI commands, built on C stdio, which is portable
// across every supported platform (including wasi-libc, whose open(2) flag
// macros don't import into Swift). This intentionally duplicates a sliver of
// IO code found elsewhere in the package: the WASI module's platform layer is
// an implementation detail of WASI and is not shared as a utility.

import WASI

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    @preconcurrency import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    @preconcurrency import Android
#elseif os(Windows)
    import CRT
    import WinSDK
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
    /// descriptor-based APIs. A handle from ``CLIFile/openRead(_:)`` or
    /// ``CLIFile/createWrite(_:)`` owns its stream; call ``close()`` exactly once.
    struct Handle {
        fileprivate let stream: CFILEPointer
        fileprivate var firstWriteErrno: CInt? = nil

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

    /// The process's standard output. Do not close it.
    static var standardOutput: Handle {
        Handle(stream: stdout)
    }

    /// Runs `body` on a handle that writes to `path`. When `path` leads to an existing file and is not
    /// itself a regular file, such as a device, a pipe or a symlink, `body` writes into it directly.
    /// Otherwise `body` writes to a new file beside `path`, which replaces `path` only once `body` and
    /// every write succeed. Throws without running `body` when `path` is a regular file the process
    /// cannot write.
    static func write(to path: String, with body: (inout Handle) throws -> Void) throws {
        switch try WriteStrategy(path: path) {
        case .inPlace:
            return try writeAndClose(createWrite(path), with: body)
        case .replaceExisting:
            // Refuses a file the process cannot write, which `rename` would replace.
            try Handle(stream: _open(path, mode: "ab", what: "write")).close()
        case .create:
            break
        }
        let random = String(UInt64.random(in: .min ... .max), radix: 36)
        let temporaryPath = "\(directoryPrefix(of: path))wasm2wat-\(random).tmp"
        let handle: Handle
        do {
            handle = try createWrite(temporaryPath)
        } catch {
            throw Error(description: "Failed to write \(path): \(error)")
        }
        do {
            try writeAndClose(handle, with: body)
            try moveFile(temporaryPath, replacing: path)
        } catch {
            throw CleanupFailure.preserving(error) { try removeFile(temporaryPath) }
        }
    }

    private static func writeAndClose(_ handle: Handle, with body: (inout Handle) throws -> Void) throws {
        var handle = handle
        try withThrowing {
            try body(&handle)
            try handle.flush()
        } defer: {
            try handle.close()
        }
    }

    static func directoryPrefix(of path: String) -> String {
        let scalars = path.unicodeScalars
        #if os(Windows)
            if let last = scalars.lastIndex(where: { $0 == "/" || $0 == "\\" }) {
                return String(scalars[...last])
            }
            // `C:out.wat` names `out.wat` in the current directory of drive C.
            return scalars.dropFirst().first == ":" ? String(scalars.prefix(2)) : ""
        #else
            guard let last = scalars.lastIndex(of: "/") else { return "" }
            return String(scalars[...last])
        #endif
    }

    private static func moveFile(_ source: String, replacing destination: String) throws {
        #if os(Windows)
            // `_wrename` fails when `destination` exists.
            let moved = source.withCString(encodedAs: UTF16.self) { wideSource in
                destination.withCString(encodedAs: UTF16.self) { wideDestination in
                    MoveFileExW(wideSource, wideDestination, DWORD(MOVEFILE_REPLACE_EXISTING))
                }
            }
            guard moved else {
                let code = GetLastError()
                throw Error(description: "Failed to replace file: \(destination) (Windows error \(code))")
            }
        #else
            guard rename(source, destination) == 0 else {
                throw Error(description: "Failed to replace file: \(destination) (\(_errnoMessage()))")
            }
        #endif
    }

    private static func removeFile(_ path: String) throws {
        #if os(Windows)
            let result = path.withCString(encodedAs: UTF16.self) { _wremove($0) }
        #else
            let result = remove(path)
        #endif
        guard result == 0 else {
            throw Error(description: "Failed to remove file: \(path) (\(_errnoMessage()))")
        }
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

    fileprivate static var currentErrno: CInt {
        #if os(Windows)
            var errnoValue: CInt = 0
            _get_errno(&errnoValue)
            return errnoValue
        #else
            return errno
        #endif
    }

    fileprivate static func _errnoMessage(_ errnoValue: CInt = currentErrno) -> String {
        guard let message = strerror(errnoValue) else { return "errno \(errnoValue)" }
        return String(cString: message)
    }
}

extension CLIFile.Handle: TextOutputStream {
    /// Writes `string` into the stream's buffer without flushing. ``flush()``
    /// reports a failed write.
    mutating func write(_ string: String) {
        var string = string
        string.withUTF8 { bytes in
            guard let base = bytes.baseAddress, bytes.count > 0 else { return }
            if fwrite(base, 1, bytes.count, stream) < bytes.count, firstWriteErrno == nil {
                firstWriteErrno = CLIFile.currentErrno
            }
        }
    }

    /// Writes out buffered data, throwing if this or an earlier write failed.
    func flush() throws {
        let flushErrno = fflush(stream) == 0 ? nil : CLIFile.currentErrno
        if let errnoValue = firstWriteErrno ?? flushErrno {
            throw CLIFile.Error(description: "I/O error: \(CLIFile._errnoMessage(errnoValue))")
        }
    }
}
