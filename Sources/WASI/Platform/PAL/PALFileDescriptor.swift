// File descriptor operations for the WASI platform layer. See PALTypes.swift
// for the PAL design rule: declarations here are unconditional; platform
// switches live only inside bodies, with the `#else` arm reporting
// `WASIAbi.Errno.ENOTSUP`.
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

// MARK: - Internal libc indirections

#if canImport(Glibc) || canImport(Android)
    // Glibc and Bionic define `UTIME_NOW`/`UTIME_OMIT` as complex macros that
    // ClangImporter can't import; the values are identical across platforms.
    private var UTIME_NOW: Int { (1 << 30) - 1 }
    private var UTIME_OMIT: Int { (1 << 30) - 2 }
#endif

#if canImport(Android)
    // Bionic defines `O_SYNC` as a complex macro (`__O_SYNC | O_DSYNC`) that
    // ClangImporter can't import.
    private var O_SYNC: CInt { 0o4010000 }
#endif

var _palErrno: CInt {
    #if os(Windows)
        var value: CInt = 0
        _get_errno(&value)
        return value
    #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
        return errno
    #else
        return -1
    #endif
}

var _palENOTSUP: CInt {
    #if os(Windows) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
        return ENOTSUP
    #else
        return -1
    #endif
}

func _palStrerror(_ error: CInt) -> String {
    #if os(Windows) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
        if let message = strerror(error) {
            return String(cString: message)
        }
    #endif
    return "errno \(error)"
}

/// Runs `body` until it returns a non-negative value, retrying on `EINTR`,
/// and throws the translated WASI error on failure.
@discardableResult
func valueOrErrno<I: FixedWidthInteger>(retryOnInterrupt: Bool = true, _ body: () -> I) throws -> I {
    while true {
        let result = body()
        if result >= 0 { return result }
        let errnoValue = _palErrno
        #if os(Windows) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            if retryOnInterrupt && errnoValue == EINTR { continue }
        #endif
        throw _wasiError(fromErrno: errnoValue)
    }
}

/// A platform file descriptor. On Windows this is a CRT file descriptor.
struct FileDescriptor: Sendable, Hashable {
    let rawValue: CInt
    init(rawValue: CInt) { self.rawValue = rawValue }

    /// The platform's maximum path length, used to size symlink buffers.
    static var maximumPathLength: Int {
        #if os(WASI)
            return Int(WASI_PLATFORM_PATH_MAX)
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
            return Int(PATH_MAX)
        #else
            return 4096
        #endif
    }

    // MARK: Opening

    /// Opens the file at an absolute or current-directory-relative host path.
    static func open(
        _ path: String, _ mode: AccessMode,
        options: OpenOptions = [],
        permissions: FilePermissions = []
    ) throws -> FileDescriptor {
        #if os(Windows)
            var fd: CInt = -1
            var flags = _windowsAccessFlags(mode) | _O_BINARY
            if options.contains(.append) { flags |= _O_APPEND }
            if options.contains(.create) { flags |= _O_CREAT }
            if options.contains(.exclusiveCreate) { flags |= _O_EXCL }
            if options.contains(.truncate) { flags |= _O_TRUNC }
            let err = path.withCString(encodedAs: UTF16.self) { widePath in
                _wsopen_s(&fd, widePath, flags, _SH_DENYNO, _S_IREAD | _S_IWRITE)
            }
            guard err == 0 else { throw _wasiError(fromErrno: err) }
            return FileDescriptor(rawValue: fd)
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            let flags = _posixAccessFlags(mode) | _posixOpenFlags(options)
            let fd = try valueOrErrno {
                path.withCString { _pal_open($0, flags, _palMode(permissions)) }
            }
            return FileDescriptor(rawValue: fd)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Opens a host directory for use as a WASI preopen.
    static func openPreopenDirectory(_ path: String) throws -> FileDescriptor {
        #if os(Windows) || os(WASI)
            return try open(path, .readWrite)
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
            let fd = try valueOrErrno {
                path.withCString { _pal_open($0, O_DIRECTORY, 0) }
            }
            return FileDescriptor(rawValue: fd)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    // MARK: Core IO

    func close() throws {
        #if os(Windows)
            try valueOrErrno(retryOnInterrupt: false) { _close(rawValue) }
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) { _pal_close(rawValue) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func read(into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
        #if os(Windows)
            return try Int(valueOrErrno { _read(rawValue, base, UInt32(min(buffer.count, Int(Int32.max)))) })
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            return try valueOrErrno { _pal_read(rawValue, base, buffer.count) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func write(_ buffer: UnsafeRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
        #if os(Windows)
            return try Int(valueOrErrno { _write(rawValue, base, UInt32(min(buffer.count, Int(Int32.max)))) })
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            return try valueOrErrno { _pal_write(rawValue, base, buffer.count) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Reads at the given absolute offset without changing the current offset
    /// (except on Windows, where the CRT offers no `pread` and the offset moves).
    func read(fromAbsoluteOffset offset: Int64, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        #if os(Windows)
            _ = try seek(offset: offset, from: .start)
            return try read(into: buffer)
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            guard let base = buffer.baseAddress, buffer.count > 0 else { return 0 }
            return try valueOrErrno { pread(rawValue, base, buffer.count, off_t(offset)) }
        #else
            throw WASIAbi.Errno.ENOTSUP
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
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            guard let base = buffer.baseAddress else { return 0 }
            var written = 0
            while written < buffer.count {
                written += try valueOrErrno {
                    pwrite(rawValue, base + written, buffer.count - written, off_t(offset) + off_t(written))
                }
            }
            return written
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func seek(offset: Int64, from whence: SeekOrigin) throws -> Int64 {
        #if os(Windows)
            return try valueOrErrno(retryOnInterrupt: false) { _lseeki64(rawValue, offset, _seekWhence(whence)) }
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            return try Int64(valueOrErrno(retryOnInterrupt: false) { lseek(rawValue, off_t(offset), _seekWhence(whence)) })
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func truncate(size: Int64) throws {
        #if os(Windows)
            var info = FILE_END_OF_FILE_INFO()
            info.EndOfFile.QuadPart = size
            let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
            guard SetFileInformationByHandle(handle, FileEndOfFileInfo, &info, DWORD(MemoryLayout.size(ofValue: info))) else {
                throw _wasiError(fromWin32: GetLastError())
            }
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno { ftruncate(rawValue, off_t(size)) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func sync() throws {
        #if os(Windows)
            let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
            guard FlushFileBuffers(handle) else {
                throw _wasiError(fromWin32: GetLastError())
            }
        #elseif canImport(Darwin)
            try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_FULLFSYNC) }
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) { fsync(rawValue) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func datasync() throws {
        #if os(Windows)
            try sync()
        #elseif canImport(Darwin)
            try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_FULLFSYNC) }
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Android)
            try valueOrErrno(retryOnInterrupt: false) { fdatasync(rawValue) }
        #elseif os(WASI)
            try valueOrErrno(retryOnInterrupt: false) { fsync(rawValue) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    // MARK: Status and metadata

    /// The file status flags, from `fcntl(F_GETFL)` where available. Only
    /// bits representable as `OpenOptions` are reported.
    func status() throws -> OpenOptions {
        #if os(Windows)
            // The CRT offers no F_GETFL equivalent; report no flags.
            return []
        #elseif os(WASI)
            throw WASIAbi.Errno.ENOTSUP
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
            let flags = try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_GETFL) }
            return _neutralOpenOptions(posixFlags: flags)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    func setStatus(_ options: OpenOptions) throws {
        #if os(Windows)
            // The CRT offers no F_SETFL equivalent; accept and ignore.
        #elseif os(WASI)
            throw WASIAbi.Errno.ENOTSUP
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
            try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_SETFL, _posixOpenFlags(options)) }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Queries file metadata; the C equivalent is `fstat`.
    func attributes() throws -> Attributes {
        #if os(Windows)
            var info = BY_HANDLE_FILE_INFORMATION()
            let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
            guard GetFileInformationByHandle(handle, &info) else {
                throw _wasiError(fromWin32: GetLastError())
            }
            return Attributes(windowsFileInformation: info)
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var statBuffer = stat()
            try valueOrErrno(retryOnInterrupt: false) { fstat(rawValue, &statBuffer) }
            return Attributes(stat: statBuffer)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Sets the access/modification timestamps; the C equivalent is `futimens`.
    func setTimes(access: FileTime = .omit, modification: FileTime = .omit) throws {
        #if os(Windows)
            let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
            var atime = _windowsFILETIME(from: access)
            var mtime = _windowsFILETIME(from: modification)
            guard atime != nil || mtime != nil else { return }
            let ok = _withOptionalPointer(to: &atime) { atimePtr in
                _withOptionalPointer(to: &mtime) { mtimePtr in
                    SetFileTime(handle, nil, atimePtr, mtimePtr)
                }
            }
            guard ok else { throw _wasiError(fromWin32: GetLastError()) }
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            let times = ContiguousArray([_posixTimespec(access), _posixTimespec(modification)])
            _ = try times.withUnsafeBufferPointer { timesPtr in
                try valueOrErrno(retryOnInterrupt: false) { futimens(rawValue, timesPtr.baseAddress!) }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Announces an intent to read the given region ahead of time.
    /// Best-effort: platforms without a read-advisory syscall treat this
    /// as a no-op, as do offsets or lengths the platform call can't represent.
    func adviseWillNeedRead(offset: UInt64, length: UInt64) throws {
        #if canImport(Darwin)
            guard let offset = Int64(exactly: offset), let length = Int32(exactly: length) else { return }
            var advisory = radvisory(ra_offset: off_t(offset), ra_count: length)
            try valueOrErrno(retryOnInterrupt: false) { fcntl(rawValue, F_RDADVISE, &advisory) }
        #elseif os(Linux) || os(Android)
            guard let offset = Int(exactly: offset), let length = Int(exactly: length) else { return }
            let result = posix_fadvise(rawValue, off_t(offset), off_t(length), CInt(POSIX_FADV_WILLNEED))
            // posix_fadvise returns the error number directly instead of setting errno.
            guard result == 0 else { throw _wasiError(fromErrno: result) }
        #endif
    }

    // MARK: Directory-relative operations

    /// Opens a path relative to this directory descriptor; the C equivalent
    /// is `openat`.
    func open(
        at path: String, _ mode: AccessMode,
        options: OpenOptions = [],
        permissions: FilePermissions = []
    ) throws -> FileDescriptor {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            let flags = _posixAccessFlags(mode) | _posixOpenFlags(options)
            let fd = try valueOrErrno {
                path.withCString { openat(rawValue, $0, flags, _palMode(permissions)) }
            }
            return FileDescriptor(rawValue: fd)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Queries metadata of a path relative to this directory descriptor;
    /// the C equivalent is `fstatat`.
    func attributes(at path: String, options: AtOptions = []) throws -> Attributes {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var statBuffer = stat()
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { fstatat(rawValue, $0, &statBuffer, options.contains(.noFollow) ? AT_SYMLINK_NOFOLLOW : 0) }
            }
            return Attributes(stat: statBuffer)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Removes a file or directory entry relative to this directory
    /// descriptor; the C equivalent is `unlinkat`.
    func remove(at path: String, options: RemoveOptions = []) throws {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { unlinkat(rawValue, $0, options.contains(.removeDirectory) ? AT_REMOVEDIR : 0) }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Creates a directory relative to this directory descriptor; the C
    /// equivalent is `mkdirat`.
    func createDirectory(at path: String, permissions: FilePermissions) throws {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { mkdirat(rawValue, $0, _palMode(permissions)) }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Creates a symlink at `link` (relative to this directory descriptor)
    /// pointing to `original`; the C equivalent is `symlinkat`.
    func createSymlink(original: String, link: String) throws {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) {
                original.withCString { originalCStr in
                    link.withCString { linkCStr in
                        symlinkat(originalCStr, rawValue, linkCStr)
                    }
                }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Renames `path` (relative to this descriptor) to `newPath` relative
    /// to `newDir`; the C equivalent is `renameat`.
    func rename(at path: String, to newDir: FileDescriptor, at newPath: String) throws {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { oldCStr in
                    newPath.withCString { newCStr in
                        renameat(rawValue, oldCStr, newDir.rawValue, newCStr)
                    }
                }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    /// Reads the target of a symlink relative to this directory descriptor
    /// into `buffer`; the C equivalent is `readlinkat`. Returns the number
    /// of bytes written (no NUL terminator is added).
    func readSymlink(at path: String, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        #if os(WASI)
            // wasi-libc has readlinkat, but symlink reading has never been
            // exercised for WASI hosts; keep it unsupported until it is.
            throw WASIAbi.Errno.ENOTSUP
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
            guard let base = buffer.baseAddress else { throw WASIAbi.Errno.EINVAL }
            return try valueOrErrno(retryOnInterrupt: false) {
                path.withCString {
                    readlinkat(rawValue, $0, base.assumingMemoryBound(to: CChar.self), buffer.count)
                }
            }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }

    // MARK: Directory enumeration

    struct DirectoryStream: IteratorProtocol, Sequence {
        #if canImport(Darwin)
            fileprivate let dirp: UnsafeMutablePointer<DIR>
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            fileprivate let dirp: OpaquePointer
        #endif

        /// Closes the stream and the file descriptor it took ownership of.
        func close() {
            #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
                _ = closedir(dirp)
            #endif
        }

        func next() -> Result<DirectoryEntry, any Error>? {
            #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
                // readdir returns NULL both at end-of-stream and on error;
                // reset errno first to tell the two apart.
                _palSetErrno(0)
                if let entry = readdir(dirp) {
                    return .success(DirectoryEntry(dirent: entry))
                }
                let errnoValue = _palErrno
                if errnoValue == 0 { return nil }
                return .failure(_wasiError(fromErrno: errnoValue))
            #else
                return nil
            #endif
        }
    }

    /// Opens a directory stream over this descriptor; the C equivalent is
    /// `fdopendir`. The stream takes ownership of the descriptor, and
    /// closing the stream closes it.
    func contentsOfDirectory() throws -> DirectoryStream {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            guard let dirp = fdopendir(rawValue) else {
                throw _wasiError(fromErrno: _palErrno)
            }
            return DirectoryStream(dirp: dirp)
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }
}

/// Thread scheduling primitives.
enum PlatformScheduler {
    /// Yields execution of the calling thread; the C equivalent is `sched_yield`.
    static func yieldCurrentThread() throws {
        #if os(Windows)
            // sched_yield is not available on Windows; treat as a no-op.
        #elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            try valueOrErrno(retryOnInterrupt: false) { sched_yield() }
        #else
            throw WASIAbi.Errno.ENOTSUP
        #endif
    }
}

// MARK: - Platform representation conversions

#if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)

    private func _posixAccessFlags(_ mode: FileDescriptor.AccessMode) -> CInt {
        switch mode {
        case .readOnly: return O_RDONLY
        case .writeOnly: return O_WRONLY
        case .readWrite: return O_RDWR
        }
    }

    private func _posixOpenFlags(_ options: FileDescriptor.OpenOptions) -> CInt {
        var flags: CInt = 0
        #if os(WASI)
            if options.contains(.append) { flags |= CInt(WASI_PLATFORM_O_APPEND) }
            if options.contains(.nonBlocking) { flags |= CInt(WASI_PLATFORM_O_NONBLOCK) }
            if options.contains(.noFollow) { flags |= CInt(WASI_PLATFORM_O_NOFOLLOW) }
            if options.contains(.directory) { flags |= CInt(WASI_PLATFORM_O_DIRECTORY) }
            if options.contains(.create) { flags |= CInt(WASI_PLATFORM_O_CREAT) }
            if options.contains(.exclusiveCreate) { flags |= CInt(WASI_PLATFORM_O_EXCL) }
            if options.contains(.truncate) { flags |= CInt(WASI_PLATFORM_O_TRUNC) }
        // The sync-mode bits have no wasi-libc mapping and are ignored.
        #else
            if options.contains(.append) { flags |= O_APPEND }
            if options.contains(.nonBlocking) { flags |= O_NONBLOCK }
            if options.contains(.noFollow) { flags |= O_NOFOLLOW }
            if options.contains(.directory) { flags |= O_DIRECTORY }
            if options.contains(.create) { flags |= O_CREAT }
            if options.contains(.exclusiveCreate) { flags |= O_EXCL }
            if options.contains(.truncate) { flags |= O_TRUNC }
            if options.contains(.dataSync) { flags |= O_DSYNC }
            if options.contains(.fileSync) { flags |= O_SYNC }
            #if os(Linux)
                if options.contains(.readSync) { flags |= O_RSYNC }
            #endif
        #endif
        return flags
    }

    private func _neutralOpenOptions(posixFlags flags: CInt) -> FileDescriptor.OpenOptions {
        var options: FileDescriptor.OpenOptions = []
        #if !os(WASI)
            if flags & O_APPEND != 0 { options.insert(.append) }
            if flags & O_NONBLOCK != 0 { options.insert(.nonBlocking) }
            if flags & O_DSYNC != 0 { options.insert(.dataSync) }
            if flags & O_SYNC != 0 { options.insert(.fileSync) }
            #if os(Linux)
                if flags & O_RSYNC != 0 { options.insert(.readSync) }
            #endif
        #endif
        return options
    }

    private func _palMode(_ permissions: FileDescriptor.FilePermissions) -> mode_t {
        mode_t(permissions.rawValue)
    }

    private func _seekWhence(_ whence: FileDescriptor.SeekOrigin) -> CInt {
        switch whence {
        case .start: return SEEK_SET
        case .current: return SEEK_CUR
        case .end: return SEEK_END
        }
    }

    private func _posixTimespec(_ time: FileTime) -> timespec {
        switch time.representation {
        case .absolute(let seconds, let nanoseconds):
            return timespec(tv_sec: time_t(seconds), tv_nsec: Int(nanoseconds))
        case .now:
            return timespec(tv_sec: 0, tv_nsec: Int(UTIME_NOW))
        case .omit:
            return timespec(tv_sec: 0, tv_nsec: Int(UTIME_OMIT))
        }
    }

    private func _palSetErrno(_ value: CInt) {
        errno = value
    }

    extension FileDescriptor.FileType {
        fileprivate init(mode: mode_t) {
            switch mode & S_IFMT {
            case S_IFDIR: self = .directory
            case S_IFREG: self = .regular
            case S_IFLNK: self = .symlink
            case S_IFCHR: self = .characterDevice
            case S_IFBLK: self = .blockDevice
            case S_IFSOCK: self = .socket
            default: self = .unknown
            }
        }
    }

    extension FileTime {
        fileprivate init(timespec value: timespec) {
            self.init(seconds: Int(value.tv_sec), nanoseconds: Int(value.tv_nsec))
        }
    }

    extension FileDescriptor.Attributes {
        fileprivate init(stat statBuffer: stat) {
            // Preserve the bit pattern: dev_t may be signed or unsigned
            // depending on the platform.
            var device: UInt64 = 0
            withUnsafeBytes(of: statBuffer.st_dev) { bytes in
                let copyCount = min(bytes.count, MemoryLayout<UInt64>.size)
                withUnsafeMutableBytes(of: &device) { deviceBytes in
                    deviceBytes.prefix(copyCount).copyBytes(from: bytes.prefix(copyCount))
                }
            }
            #if canImport(Darwin)
                let accessTime = statBuffer.st_atimespec
                let modificationTime = statBuffer.st_mtimespec
                let creationTime = statBuffer.st_ctimespec
            #else
                let accessTime = statBuffer.st_atim
                let modificationTime = statBuffer.st_mtim
                let creationTime = statBuffer.st_ctim
            #endif
            self.init(
                device: device,
                inode: UInt64(statBuffer.st_ino),
                fileType: FileDescriptor.FileType(mode: statBuffer.st_mode),
                linkCount: UInt64(statBuffer.st_nlink),
                size: Int64(statBuffer.st_size),
                accessTime: FileTime(timespec: accessTime),
                modificationTime: FileTime(timespec: modificationTime),
                creationTime: FileTime(timespec: creationTime)
            )
        }
    }

    extension FileDescriptor.DirectoryEntry {
        fileprivate init(dirent entry: UnsafeMutablePointer<dirent>) {
            #if os(WASI)
                // ClangImporter can't handle `char d_name[]`, but it's
                // right after `unsigned char d_type`.
                let name = withUnsafePointer(to: &entry.pointee.d_type) { dType in
                    (dType + 1).withMemoryRebound(to: UInt8.self, capacity: 1) {
                        String(cString: $0)
                    }
                }
                let fileType: FileDescriptor.FileType
                switch CInt(entry.pointee.d_type) {
                case CInt(WASI_PLATFORM_DT_DIR): fileType = .directory
                case CInt(WASI_PLATFORM_DT_REG): fileType = .regular
                case CInt(WASI_PLATFORM_DT_LNK): fileType = .symlink
                case CInt(WASI_PLATFORM_DT_CHR): fileType = .characterDevice
                case CInt(WASI_PLATFORM_DT_BLK): fileType = .blockDevice
                default: fileType = .unknown
                }
            #else
                let name = withUnsafePointer(to: &entry.pointee.d_name) { dName in
                    dName.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: dName)) {
                        String(cString: $0)
                    }
                }
                let fileType: FileDescriptor.FileType
                switch CInt(entry.pointee.d_type) {
                case CInt(DT_DIR): fileType = .directory
                case CInt(DT_REG): fileType = .regular
                case CInt(DT_LNK): fileType = .symlink
                case CInt(DT_CHR): fileType = .characterDevice
                case CInt(DT_BLK): fileType = .blockDevice
                case CInt(DT_SOCK): fileType = .socket
                default: fileType = .unknown
                }
            #endif
            self.init(name: name, fileType: fileType)
        }
    }

    // Unshadowed libc entry points: inside `FileDescriptor` methods,
    // unqualified `open`/`read`/`write`/`close` would resolve to the methods
    // themselves.
    private func _pal_open(_ path: UnsafePointer<CChar>, _ oflag: CInt, _ mode: mode_t) -> CInt {
        open(path, oflag, mode)
    }
    private func _pal_read(_ fd: CInt, _ buffer: UnsafeMutableRawPointer, _ count: Int) -> Int {
        read(fd, buffer, count)
    }
    private func _pal_write(_ fd: CInt, _ buffer: UnsafeRawPointer, _ count: Int) -> Int {
        write(fd, buffer, count)
    }
    private func _pal_close(_ fd: CInt) -> CInt {
        close(fd)
    }

#endif

#if os(Windows)
    private func _windowsAccessFlags(_ mode: FileDescriptor.AccessMode) -> CInt {
        switch mode {
        case .readOnly: return _O_RDONLY
        case .writeOnly: return _O_WRONLY
        case .readWrite: return _O_RDWR
        }
    }

    private func _seekWhence(_ whence: FileDescriptor.SeekOrigin) -> CInt {
        switch whence {
        case .start: return SEEK_SET
        case .current: return SEEK_CUR
        case .end: return SEEK_END
        }
    }

    private func _withOptionalPointer<T, R>(to value: inout T?, _ body: (UnsafePointer<T>?) -> R) -> R {
        if value != nil {
            return withUnsafePointer(to: &value!) { body($0) }
        }
        return body(nil)
    }
    // FILETIME <-> canonical FileTime conversions. FILETIME is 100ns
    // intervals since 1601-01-01; the offset to the Unix epoch is
    // 11_644_473_600 seconds.
    private let _windowsUnixEpochIntervals: Int64 = 11_644_473_600 * 10_000_000

    extension FileTime {
        init(windowsFILETIME fileTime: FILETIME) {
            let intervals = (Int64(fileTime.dwHighDateTime) << 32) | Int64(fileTime.dwLowDateTime)
            let unixNanoseconds = (intervals - _windowsUnixEpochIntervals) * 100
            self.init(
                seconds: Int(unixNanoseconds / 1_000_000_000),
                nanoseconds: Int(unixNanoseconds % 1_000_000_000)
            )
        }
    }

    /// Converts to a `FILETIME` for `SetFileTime`: nil for `omit`, the
    /// current system time for `now`.
    func _windowsFILETIME(from time: FileTime) -> FILETIME? {
        switch time.representation {
        case .omit:
            return nil
        case .now:
            var now = FILETIME()
            GetSystemTimeAsFileTime(&now)
            return now
        case .absolute(let seconds, let nanoseconds):
            let intervals = (seconds * 1_000_000_000 + nanoseconds) / 100 + _windowsUnixEpochIntervals
            return FILETIME(
                dwLowDateTime: DWORD(UInt64(bitPattern: intervals) & 0xFFFF_FFFF),
                dwHighDateTime: DWORD(UInt64(bitPattern: intervals) >> 32)
            )
        }
    }

    extension FileDescriptor.Attributes {
        init(windowsFileInformation info: BY_HANDLE_FILE_INFORMATION) {
            let fileType: FileDescriptor.FileType
            if info.dwFileAttributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT) != 0 {
                fileType = .symlink
            } else if info.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) != 0 {
                fileType = .directory
            } else {
                fileType = .regular
            }
            self.init(
                device: UInt64(info.dwVolumeSerialNumber),
                inode: UInt64(info.nFileIndexHigh) << 32 | UInt64(info.nFileIndexLow),
                fileType: fileType,
                linkCount: UInt64(info.nNumberOfLinks),
                size: Int64(info.nFileSizeHigh) << 32 | Int64(info.nFileSizeLow),
                accessTime: FileTime(windowsFILETIME: info.ftLastAccessTime),
                modificationTime: FileTime(windowsFILETIME: info.ftLastWriteTime),
                creationTime: FileTime(windowsFILETIME: info.ftCreationTime)
            )
        }
    }

#endif
