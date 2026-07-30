// File metadata and timestamp types for the WASI platform layer.
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

#if os(Windows)
    /// A point in time for `setTimes`, expressed as a Windows `FILETIME`.
    enum FileTime {
        case omit
        case now
        case absolute(FILETIME)

        var unixNanoseconds: Int64 {
            guard case .absolute(let rawValue) = self else { return 0 }
            let ntIntervals = (Int64(rawValue.dwHighDateTime) << 32) | Int64(rawValue.dwLowDateTime)
            // FILETIME is 100ns intervals since 1601-01-01.
            return (ntIntervals - Self.unixEpochIntervals) * 100
        }

        private static var unixEpochIntervals: Int64 {
            11_644_473_600 * 10_000_000
        }

        init(seconds: Int, nanoseconds: Int) {
            let intervals = (Int64(seconds) * 1_000_000_000 + Int64(nanoseconds)) / 100 + Self.unixEpochIntervals
            self = .absolute(
                FILETIME(
                    dwLowDateTime: DWORD(UInt64(bitPattern: intervals) & 0xFFFF_FFFF),
                    dwHighDateTime: DWORD(UInt64(bitPattern: intervals) >> 32)
                ))
        }
    }
#else
    /// A point in time, wrapping a C `timespec`. `.now`/`.omit` use the
    /// `UTIME_NOW`/`UTIME_OMIT` sentinels understood by `futimens`.
    struct FileTime {
        var rawValue: timespec

        init(rawValue: timespec) { self.rawValue = rawValue }

        init(seconds: Int, nanoseconds: Int) {
            self.init(rawValue: timespec(tv_sec: time_t(seconds), tv_nsec: nanoseconds))
        }

        var seconds: Int64 { Int64(rawValue.tv_sec) }
        var nanoseconds: Int64 { Int64(rawValue.tv_nsec) }

        static var now: FileTime {
            FileTime(rawValue: timespec(tv_sec: 0, tv_nsec: Int(UTIME_NOW)))
        }
        static var omit: FileTime {
            FileTime(rawValue: timespec(tv_sec: 0, tv_nsec: Int(UTIME_OMIT)))
        }
    }
#endif

extension FileDescriptor {
    /// A type of file, derived from `st_mode & S_IFMT` (or Windows file
    /// attributes).
    struct FileType: Equatable {
        #if os(Windows)
            let rawValue: DWORD
            init(rawValue: DWORD) { self.rawValue = rawValue }

            var isDirectory: Bool { rawValue == DWORD(FILE_ATTRIBUTE_DIRECTORY) }
        #else
            let rawValue: mode_t
            init(rawValue: mode_t) { self.rawValue = rawValue }

            static var directory: FileType { FileType(rawValue: S_IFDIR) }

            var isDirectory: Bool { rawValue == S_IFDIR }
            var isFile: Bool { rawValue == S_IFREG }
            var isCharacterDevice: Bool { rawValue == S_IFCHR }
            var isSymlink: Bool { rawValue == S_IFLNK }
            var isBlockDevice: Bool { rawValue == S_IFBLK }
            var isSocket: Bool { rawValue == S_IFSOCK }
        #endif
    }

    /// File metadata; the C equivalent is `struct stat`.
    struct Attributes {
        #if os(Windows)
            let rawValue: BY_HANDLE_FILE_INFORMATION

            var device: UInt64 { UInt64(rawValue.dwVolumeSerialNumber) }
            var inode: UInt64 { UInt64(rawValue.nFileIndexHigh) << 32 | UInt64(rawValue.nFileIndexLow) }
            var fileType: FileType { FileType(rawValue: rawValue.dwFileAttributes) }
            var linkCount: UInt32 { rawValue.nNumberOfLinks }
            var size: Int64 { Int64(rawValue.nFileSizeHigh) << 32 | Int64(rawValue.nFileSizeLow) }
            var accessTime: FileTime { FileTime(rawValue: rawValue.ftLastAccessTime) }
            var modificationTime: FileTime { FileTime(rawValue: rawValue.ftLastWriteTime) }
            var creationTime: FileTime { FileTime(rawValue: rawValue.ftCreationTime) }
        #else
            let rawValue: stat

            var device: UInt64 {
                // Preserve the bit pattern: dev_t may be signed or unsigned
                // depending on the platform.
                let dev = rawValue.st_dev
                var result: UInt64 = 0
                withUnsafeBytes(of: dev) { bytes in
                    let copyCount = min(bytes.count, MemoryLayout<UInt64>.size)
                    withUnsafeMutableBytes(of: &result) { resultBytes in
                        resultBytes.prefix(copyCount).copyBytes(from: bytes.prefix(copyCount))
                    }
                }
                return result
            }
            var inode: UInt64 { UInt64(rawValue.st_ino) }
            var fileType: FileType { FileType(rawValue: rawValue.st_mode & S_IFMT) }
            var linkCount: UInt32 { UInt32(rawValue.st_nlink) }
            var size: Int64 { Int64(rawValue.st_size) }
            var accessTime: FileTime {
                #if canImport(Darwin)
                    FileTime(rawValue: rawValue.st_atimespec)
                #else
                    FileTime(rawValue: rawValue.st_atim)
                #endif
            }
            var modificationTime: FileTime {
                #if canImport(Darwin)
                    FileTime(rawValue: rawValue.st_mtimespec)
                #else
                    FileTime(rawValue: rawValue.st_mtim)
                #endif
            }
            var creationTime: FileTime {
                #if canImport(Darwin)
                    FileTime(rawValue: rawValue.st_ctimespec)
                #else
                    FileTime(rawValue: rawValue.st_ctim)
                #endif
            }
        #endif
    }

    /// Queries file metadata; the C equivalent is `fstat`.
    func attributes() throws -> Attributes {
        #if os(Windows)
            var info = BY_HANDLE_FILE_INFORMATION()
            let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
            guard GetFileInformationByHandle(handle, &info) else {
                throw PlatformErrno(windowsError: GetLastError())
            }
            return Attributes(rawValue: info)
        #else
            var statBuffer = stat()
            try valueOrErrno(retryOnInterrupt: false) { fstat(rawValue, &statBuffer) }
            return Attributes(rawValue: statBuffer)
        #endif
    }

    /// Sets the access/modification timestamps; the C equivalent is `futimens`.
    func setTimes(access: FileTime = .omit, modification: FileTime = .omit) throws {
        #if os(Windows)
            let handle = HANDLE(bitPattern: _get_osfhandle(rawValue))
            var nowCache: FILETIME?
            func resolve(_ time: FileTime) -> FILETIME? {
                switch time {
                case .omit:
                    return nil
                case .absolute(let value):
                    return value
                case .now:
                    if let now = nowCache { return now }
                    var now = FILETIME()
                    GetSystemTimeAsFileTime(&now)
                    nowCache = now
                    return now
                }
            }
            var atime = resolve(access)
            var mtime = resolve(modification)
            guard atime != nil || mtime != nil else { return }
            let ok = withUnsafeOptionalPointer(to: &atime) { atimePtr in
                withUnsafeOptionalPointer(to: &mtime) { mtimePtr in
                    SetFileTime(handle, nil, atimePtr, mtimePtr)
                }
            }
            guard ok else { throw PlatformErrno(windowsError: GetLastError()) }
        #else
            let times = ContiguousArray([access.rawValue, modification.rawValue])
            _ = try times.withUnsafeBufferPointer { timesPtr in
                try valueOrErrno(retryOnInterrupt: false) { futimens(rawValue, timesPtr.baseAddress!) }
            }
        #endif
    }
}

#if os(Windows)
    private func withUnsafeOptionalPointer<T, R>(to value: inout T?, _ body: (UnsafePointer<T>?) -> R) -> R {
        if value != nil {
            return withUnsafePointer(to: &value!) { body($0) }
        }
        return body(nil)
    }
#endif

#endif  // known platforms
