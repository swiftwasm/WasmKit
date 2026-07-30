// Windows error mapping, adapted from swift-system's vendored
// WindowsSyscallAdapter (Apache License 2.0). Maps Win32 error codes from
// `GetLastError()` onto CRT errno values so the rest of the platform layer
// deals in errno alone.
#if os(Windows)
    import WinSDK
    import ucrt

    extension PlatformErrno {
        init(windowsError: DWORD) {
            self.init(rawValue: _mapWindowsErrorToErrno(windowsError))
        }
    }

    private func _mapWindowsErrorToErrno(_ errorCode: DWORD) -> CInt {
        switch Int32(errorCode) {
        case ERROR_SUCCESS:
            return 0
        case ERROR_INVALID_FUNCTION,
            ERROR_INVALID_ACCESS,
            ERROR_INVALID_DATA,
            ERROR_INVALID_PARAMETER,
            ERROR_NEGATIVE_SEEK:
            return EINVAL
        case ERROR_FILE_NOT_FOUND,
            ERROR_PATH_NOT_FOUND,
            ERROR_INVALID_DRIVE,
            ERROR_NO_MORE_FILES,
            ERROR_BAD_NETPATH,
            ERROR_BAD_NET_NAME,
            ERROR_BAD_PATHNAME,
            ERROR_FILENAME_EXCED_RANGE:
            return ENOENT
        case ERROR_TOO_MANY_OPEN_FILES:
            return EMFILE
        case ERROR_ACCESS_DENIED,
            ERROR_CURRENT_DIRECTORY,
            ERROR_LOCK_VIOLATION,
            ERROR_NETWORK_ACCESS_DENIED,
            ERROR_CANNOT_MAKE,
            ERROR_FAIL_I24,
            ERROR_DRIVE_LOCKED,
            ERROR_SEEK_ON_DEVICE,
            ERROR_NOT_LOCKED,
            ERROR_LOCK_FAILED,
            ERROR_WRITE_PROTECT...ERROR_SHARING_BUFFER_EXCEEDED:
            return EACCES
        case ERROR_INVALID_HANDLE,
            ERROR_INVALID_TARGET_HANDLE,
            ERROR_DIRECT_ACCESS_HANDLE:
            return EBADF
        case ERROR_ARENA_TRASHED,
            ERROR_NOT_ENOUGH_MEMORY,
            ERROR_INVALID_BLOCK,
            ERROR_NOT_ENOUGH_QUOTA:
            return ENOMEM
        case ERROR_BAD_ENVIRONMENT:
            return E2BIG
        case ERROR_BAD_FORMAT,
            ERROR_INVALID_STARTING_CODESEG...ERROR_INFLOOP_IN_RELOC_CHAIN:
            return ENOEXEC
        case ERROR_NOT_SAME_DEVICE:
            return EXDEV
        case ERROR_FILE_EXISTS,
            ERROR_ALREADY_EXISTS:
            return EEXIST
        case ERROR_NO_PROC_SLOTS,
            ERROR_MAX_THRDS_REACHED,
            ERROR_NESTING_NOT_ALLOWED:
            return EAGAIN
        case ERROR_BROKEN_PIPE:
            return EPIPE
        case ERROR_DISK_FULL:
            return ENOSPC
        case ERROR_DIR_NOT_EMPTY:
            return ENOTEMPTY
        case ERROR_WAIT_NO_CHILDREN,
            ERROR_CHILD_NOT_COMPLETE:
            return ECHILD
        case ERROR_NO_UNICODE_TRANSLATION:
            return EILSEQ
        default:
            return EINVAL
        }
    }
#endif

#if os(Windows)
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
