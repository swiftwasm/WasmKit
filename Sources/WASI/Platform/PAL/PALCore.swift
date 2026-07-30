// Platform abstraction layer for the WASI host implementation.
//
// This is a thin, internal wrapper over the platform's file descriptor
// syscalls, trimmed to exactly the surface WASI needs. It intentionally
// mirrors the shape of the swift-system API it replaced so the rest of the
// module reads the same, but it is not a general-purpose file API.
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
    import WinSDK
#elseif os(WASI)
    import CWASIPlatform
    import WASILibc
#endif

#if os(Windows) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)

    #if os(WASI)
        // wasi-libc defines these as macros derived from WASI ABI constants, which
        // ClangImporter can't import; the CWASIPlatform shim re-exposes their values.
        private var O_APPEND: CInt { CInt(WASI_PLATFORM_O_APPEND) }
        private var O_NONBLOCK: CInt { CInt(WASI_PLATFORM_O_NONBLOCK) }
        private var O_NOFOLLOW: CInt { CInt(WASI_PLATFORM_O_NOFOLLOW) }
        private var O_DIRECTORY: CInt { CInt(WASI_PLATFORM_O_DIRECTORY) }
        private var O_CREAT: CInt { CInt(WASI_PLATFORM_O_CREAT) }
        private var O_EXCL: CInt { CInt(WASI_PLATFORM_O_EXCL) }
        private var O_TRUNC: CInt { CInt(WASI_PLATFORM_O_TRUNC) }
        private var PATH_MAX: CInt { CInt(WASI_PLATFORM_PATH_MAX) }
    #endif

    /// A raw platform error, carrying an errno value.
    struct PlatformErrno: Error, Equatable, CustomStringConvertible {
        let rawValue: CInt
        init(rawValue: CInt) { self.rawValue = rawValue }

        /// The current value of the C `errno` global.
        static var current: PlatformErrno {
            #if os(Windows)
                var value: CInt = 0
                _get_errno(&value)
                return PlatformErrno(rawValue: value)
            #else
                return PlatformErrno(rawValue: errno)
            #endif
        }

        var description: String {
            guard let message = strerror(rawValue) else { return "errno \(rawValue)" }
            return String(cString: message)
        }

        static var notSupported: PlatformErrno { PlatformErrno(rawValue: ENOTSUP) }
    }

    /// Runs `body` until it returns a non-negative value, retrying on `EINTR`,
    /// and throws `PlatformErrno` on failure.
    @discardableResult
    func valueOrErrno<I: FixedWidthInteger>(retryOnInterrupt: Bool = true, _ body: () -> I) throws -> I {
        while true {
            let result = body()
            if result >= 0 { return result }
            let error = PlatformErrno.current
            if retryOnInterrupt && error.rawValue == EINTR { continue }
            throw error
        }
    }

    /// A platform file descriptor. On Windows this is a CRT file descriptor.
    struct FileDescriptor: Sendable, Hashable {
        let rawValue: CInt
        init(rawValue: CInt) { self.rawValue = rawValue }

        static var standardInput: FileDescriptor { FileDescriptor(rawValue: 0) }
        static var standardOutput: FileDescriptor { FileDescriptor(rawValue: 1) }
        static var standardError: FileDescriptor { FileDescriptor(rawValue: 2) }

        enum AccessMode: Sendable {
            case readOnly, writeOnly, readWrite

            var rawValue: CInt {
                #if os(Windows)
                    switch self {
                    case .readOnly: return _O_RDONLY
                    case .writeOnly: return _O_WRONLY
                    case .readWrite: return _O_RDWR
                    }
                #else
                    switch self {
                    case .readOnly: return O_RDONLY
                    case .writeOnly: return O_WRONLY
                    case .readWrite: return O_RDWR
                    }
                #endif
            }
        }

        struct OpenOptions: OptionSet, Sendable {
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            #if os(Windows)
                static var append: OpenOptions { OpenOptions(rawValue: _O_APPEND) }
            #else
                static var append: OpenOptions { OpenOptions(rawValue: O_APPEND) }
                static var nonBlocking: OpenOptions { OpenOptions(rawValue: O_NONBLOCK) }
                static var noFollow: OpenOptions { OpenOptions(rawValue: O_NOFOLLOW) }
                static var directory: OpenOptions { OpenOptions(rawValue: O_DIRECTORY) }
                static var create: OpenOptions { OpenOptions(rawValue: O_CREAT) }
                static var exclusiveCreate: OpenOptions { OpenOptions(rawValue: O_EXCL) }
                static var truncate: OpenOptions { OpenOptions(rawValue: O_TRUNC) }
                #if canImport(Android)
                    static var dataSync: OpenOptions { OpenOptions(rawValue: O_DSYNC) }
                    // Bionic defines `O_SYNC` as a complex macro (`__O_SYNC | O_DSYNC`)
                    // that ClangImporter can't import; use the value directly.
                    static var fileSync: OpenOptions { OpenOptions(rawValue: 0o4010000) }
                #elseif !os(WASI)
                    static var dataSync: OpenOptions { OpenOptions(rawValue: O_DSYNC) }
                    static var fileSync: OpenOptions { OpenOptions(rawValue: O_SYNC) }
                #endif
                #if os(Linux)
                    static var readSync: OpenOptions { OpenOptions(rawValue: O_RSYNC) }
                #endif
            #endif
        }

        struct FilePermissions: OptionSet, Sendable {
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            static var ownerReadWrite: FilePermissions { FilePermissions(rawValue: 0o600) }
            static var ownerReadWriteExecute: FilePermissions { FilePermissions(rawValue: 0o700) }
        }

        enum SeekOrigin: Sendable {
            case start, current, end

            var rawValue: CInt {
                switch self {
                case .start: return SEEK_SET
                case .current: return SEEK_CUR
                case .end: return SEEK_END
                }
            }
        }

        /// Opens the file at an absolute or current-directory-relative host path.
        static func open(
            _ path: String, _ mode: AccessMode,
            options: OpenOptions = OpenOptions(rawValue: 0),
            permissions: FilePermissions = FilePermissions(rawValue: 0)
        ) throws -> FileDescriptor {
            #if os(Windows)
                var fd: CInt = -1
                let err = path.withCString(encodedAs: UTF16.self) { widePath in
                    _wsopen_s(&fd, widePath, mode.rawValue | options.rawValue | _O_BINARY, _SH_DENYNO, _S_IREAD | _S_IWRITE)
                }
                guard err == 0 else { throw PlatformErrno(rawValue: err) }
                return FileDescriptor(rawValue: fd)
            #else
                let fd = try valueOrErrno {
                    path.withCString { open_syscall($0, mode.rawValue | options.rawValue, mode_t(permissions.rawValue)) }
                }
                return FileDescriptor(rawValue: fd)
            #endif
        }

        /// Opens a host directory for use as a WASI preopen.
        static func openPreopenDirectory(_ path: String) throws -> FileDescriptor {
            #if os(Windows) || os(WASI)
                return try open(path, .readWrite)
            #else
                let fd = try valueOrErrno {
                    path.withCString { open_syscall($0, O_DIRECTORY, 0) }
                }
                return FileDescriptor(rawValue: fd)
            #endif
        }

        /// The platform's maximum path length, used to size symlink buffers.
        static var maximumPathLength: Int {
            #if os(Windows)
                return 4096
            #else
                return Int(PATH_MAX)
            #endif
        }

        func close() throws {
            #if os(Windows)
                try valueOrErrno(retryOnInterrupt: false) { _close(rawValue) }
            #else
                try valueOrErrno(retryOnInterrupt: false) { close_syscall(rawValue) }
            #endif
        }

        func read(into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
            #if os(Windows)
                return try Int(valueOrErrno { _read(rawValue, base, UInt32(min(buffer.count, Int(Int32.max)))) })
            #else
                return try valueOrErrno { read_syscall(rawValue, base, buffer.count) }
            #endif
        }

        func write(_ buffer: UnsafeRawBufferPointer) throws -> Int {
            guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
            #if os(Windows)
                return try Int(valueOrErrno { _write(rawValue, base, UInt32(min(buffer.count, Int(Int32.max)))) })
            #else
                return try valueOrErrno { write_syscall(rawValue, base, buffer.count) }
            #endif
        }

        /// Reads at the given absolute offset without changing the current offset
        /// (except on Windows, where the CRT offers no `pread` and the offset moves).
        func read(fromAbsoluteOffset offset: Int64, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            #if os(Windows)
                _ = try seek(offset: offset, from: .start)
                return try read(into: buffer)
            #else
                guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
                return try valueOrErrno { pread(rawValue, base, buffer.count, off_t(offset)) }
            #endif
        }

        /// Writes all of `buffer` at the given absolute offset.
        func writeAll(toAbsoluteOffset offset: Int64, _ buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            try writeAll(toAbsoluteOffset: offset, UnsafeRawBufferPointer(buffer))
        }

        /// Writes all of `buffer` at the given absolute offset.
        func writeAll(toAbsoluteOffset offset: Int64, _ buffer: UnsafeRawBufferPointer) throws -> Int {
            #if os(Windows)
                _ = try seek(offset: offset, from: .start)
                var written = 0
                while written < buffer.count {
                    written += try write(UnsafeRawBufferPointer(rebasing: buffer[written...]))
                }
                return written
            #else
                guard let base = buffer.baseAddress else { return 0 }
                var written = 0
                while written < buffer.count {
                    written += try valueOrErrno {
                        pwrite(rawValue, base + written, buffer.count - written, off_t(offset) + off_t(written))
                    }
                }
                return written
            #endif
        }

        func seek(offset: Int64, from whence: SeekOrigin) throws -> Int64 {
            #if os(Windows)
                return try valueOrErrno(retryOnInterrupt: false) { _lseeki64(rawValue, offset, whence.rawValue) }
            #else
                return try Int64(valueOrErrno(retryOnInterrupt: false) { lseek(rawValue, off_t(offset), whence.rawValue) })
            #endif
        }

        func truncate(size: Int64) throws {
            #if os(Windows)
                var info = FILE_END_OF_FILE_INFO()
                info.EndOfFile.QuadPart = size
                let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
                guard SetFileInformationByHandle(handle, FileEndOfFileInfo, &info, DWORD(MemoryLayout.size(ofValue: info))) else {
                    throw PlatformErrno(windowsError: GetLastError())
                }
            #else
                try valueOrErrno { ftruncate(rawValue, off_t(size)) }
            #endif
        }

        func sync() throws {
            #if os(Windows)
                let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
                guard FlushFileBuffers(handle) else {
                    throw PlatformErrno(windowsError: GetLastError())
                }
            #elseif canImport(Darwin)
                try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_FULLFSYNC) }
            #else
                try valueOrErrno(retryOnInterrupt: false) { fsync(rawValue) }
            #endif
        }

        func datasync() throws {
            #if os(Windows)
                try sync()
            #elseif canImport(Darwin)
                try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_FULLFSYNC) }
            #elseif os(Linux) || os(Android) || os(FreeBSD) || os(OpenBSD)
                try valueOrErrno(retryOnInterrupt: false) { fdatasync(rawValue) }
            #else
                try valueOrErrno(retryOnInterrupt: false) { fsync(rawValue) }
            #endif
        }

        /// The file status flags, from `fcntl(F_GETFL)`.
        func status() throws -> OpenOptions {
            #if os(Windows)
                return OpenOptions(rawValue: 0)
            #elseif os(WASI)
                throw PlatformErrno.notSupported
            #else
                return OpenOptions(rawValue: try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_GETFL) })
            #endif
        }

        func setStatus(_ options: OpenOptions) throws {
            #if os(Windows)
                // FIXME: Re-open the file with new options?
            #elseif os(WASI)
                throw PlatformErrno.notSupported
            #else
                try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_SETFL, options.rawValue) }
            #endif
        }

        #if canImport(Darwin)
            /// Announces an intent to read the given region, via `F_RDADVISE`.
            func adviseRead(offset: Int64, length: Int32) throws {
                var advisory = radvisory(ra_offset: off_t(offset), ra_count: length)
                try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_RDADVISE, &advisory) }
            }
        #elseif os(Linux) || os(Android)
            /// Announces an expected access pattern via `posix_fadvise(POSIX_FADV_WILLNEED)`.
            func adviseWillNeed(offset: Int, length: Int) throws {
                let result = posix_fadvise(rawValue, off_t(offset), off_t(length), CInt(POSIX_FADV_WILLNEED))
                // posix_fadvise returns the error number directly instead of setting errno.
                guard result == 0 else { throw PlatformErrno(rawValue: result) }
            }
        #endif
    }

    #if !os(Windows)
        // Unshadowed libc entry points: inside `FileDescriptor` methods, unqualified
        // `read`/`write`/`close` would resolve to the methods themselves.
        func open_syscall(_ path: UnsafePointer<CChar>, _ oflag: CInt, _ mode: mode_t) -> CInt {
            open(path, oflag, mode)
        }
        private func read_syscall(_ fd: CInt, _ buffer: UnsafeMutableRawPointer, _ count: Int) -> Int {
            read(fd, buffer, count)
        }
        private func write_syscall(_ fd: CInt, _ buffer: UnsafeRawPointer, _ count: Int) -> Int {
            write(fd, buffer, count)
        }
        private func close_syscall(_ fd: CInt) -> CInt {
            close(fd)
        }
    #endif

#endif  // known platforms
