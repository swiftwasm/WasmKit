// Maps raw platform errno values onto WASI errno codes. This lives in the
// PAL because the libc errno constants it consumes are platform-domain, even
// though the mapping's output is WASI-domain.
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
    import WASILibc
#endif

// Free function so unqualified errno constants resolve to the libc values
// rather than being shadowed by `WASIAbi.Errno`'s own case names.
/// Translates a C errno value into the error the PAL reports: the WASI
/// errno, or a descriptive `WASIError` for values with no WASI equivalent.
/// Each platform implementation calls this at its own failing syscall site.
func _wasiError(fromErrno value: CInt) -> any Error {
    if let mapped = _mapErrno(value) {
        return mapped
    }
    return WASIError(description: "Unknown underlying OS error: \(_palStrerror(value))")
}

/// Translates a Win32 `GetLastError()` code into the error the PAL reports.
func _wasiError(fromWin32 code: UInt32) -> any Error {
    if let mapped = _mapWindowsError(code) {
        return mapped
    }
    return WASIError(description: "Unknown underlying OS error: Win32 error \(code)")
}

private func _mapErrno(_ errno: CInt) -> WASIAbi.Errno? {
    #if !(os(Windows) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI))
        // Unknown platform: no libc errno constants to map.
        return nil
    #else
        switch errno {
        case 0: return nil
        case EPERM: return .EPERM
        case ENOENT: return .ENOENT
        case ESRCH: return .ESRCH
        case EINTR: return .EINTR
        case EIO: return .EIO
        case ENXIO: return .ENXIO
        case E2BIG: return .E2BIG
        case ENOEXEC: return .ENOEXEC
        case EBADF: return .EBADF
        case ECHILD: return .ECHILD
        case EDEADLK: return .EDEADLK
        case ENOMEM: return .ENOMEM
        case EACCES: return .EACCES
        case EFAULT: return .EFAULT
        case EBUSY: return .EBUSY
        case EEXIST: return .EEXIST
        case EXDEV: return .EXDEV
        case ENODEV: return .ENODEV
        case ENOTDIR: return .ENOTDIR
        case EISDIR: return .EISDIR
        case EINVAL: return .EINVAL
        case ENFILE: return .ENFILE
        case EMFILE: return .EMFILE
        #if !os(Windows)
            case ENOTTY: return .ENOTTY
            case ETXTBSY: return .ETXTBSY
        #endif
        case EFBIG: return .EFBIG
        case ENOSPC: return .ENOSPC
        case ESPIPE: return .ESPIPE
        case EROFS: return .EROFS
        case EMLINK: return .EMLINK
        case EPIPE: return .EPIPE
        case EDOM: return .EDOM
        case ERANGE: return .ERANGE
        case EAGAIN: return .EAGAIN
        case EINPROGRESS: return .EINPROGRESS
        case EALREADY: return .EALREADY
        case ENOTSOCK: return .ENOTSOCK
        case EDESTADDRREQ: return .EDESTADDRREQ
        case EMSGSIZE: return .EMSGSIZE
        case EPROTOTYPE: return .EPROTOTYPE
        case ENOPROTOOPT: return .ENOPROTOOPT
        case EPROTONOSUPPORT: return .EPROTONOSUPPORT
        case ENOTSUP: return .ENOTSUP
        case EAFNOSUPPORT: return .EAFNOSUPPORT
        case EADDRINUSE: return .EADDRINUSE
        case EADDRNOTAVAIL: return .EADDRNOTAVAIL
        case ENETDOWN: return .ENETDOWN
        case ENETUNREACH: return .ENETUNREACH
        case ENETRESET: return .ENETRESET
        case ECONNABORTED: return .ECONNABORTED
        case ECONNRESET: return .ECONNRESET
        case ENOBUFS: return .ENOBUFS
        case EISCONN: return .EISCONN
        case ENOTCONN: return .ENOTCONN
        case ETIMEDOUT: return .ETIMEDOUT
        case ECONNREFUSED: return .ECONNREFUSED
        case ELOOP: return .ELOOP
        case ENAMETOOLONG: return .ENAMETOOLONG
        case EHOSTUNREACH: return .EHOSTUNREACH
        case ENOTEMPTY: return .ENOTEMPTY
        #if !os(Windows)
            case EDQUOT: return .EDQUOT
            case ESTALE: return .ESTALE
        #endif
        case ENOLCK: return .ENOLCK
        case ENOSYS: return .ENOSYS
        #if !os(Windows)
            case EOVERFLOW: return .EOVERFLOW
        #endif
        case ECANCELED: return .ECANCELED
        #if !os(Windows)
            case EIDRM: return .EIDRM
            case ENOMSG: return .ENOMSG
        #endif
        case EILSEQ: return .EILSEQ
        #if !os(Windows)
            case EBADMSG: return .EBADMSG
            case EMULTIHOP: return .EMULTIHOP
            case ENOLINK: return .ENOLINK
            case EPROTO: return .EPROTO
            case ENOTRECOVERABLE: return .ENOTRECOVERABLE
            case EOWNERDEAD: return .EOWNERDEAD
        #endif
        default: return nil
        }
    #endif
}

// Win32 error mapping, adapted from swift-system's vendored
// WindowsSyscallAdapter (Apache License 2.0), retargeted to produce WASI
// errno codes directly instead of detouring through CRT errno.
private func _mapWindowsError(_ code: UInt32) -> WASIAbi.Errno? {
    #if os(Windows)
        switch Int32(code) {
        case ERROR_SUCCESS:
            return nil
        case ERROR_INVALID_FUNCTION,
            ERROR_INVALID_ACCESS,
            ERROR_INVALID_DATA,
            ERROR_INVALID_PARAMETER,
            ERROR_NEGATIVE_SEEK:
            return .EINVAL
        case ERROR_FILE_NOT_FOUND,
            ERROR_PATH_NOT_FOUND,
            ERROR_INVALID_DRIVE,
            ERROR_NO_MORE_FILES,
            ERROR_BAD_NETPATH,
            ERROR_BAD_NET_NAME,
            ERROR_BAD_PATHNAME,
            ERROR_FILENAME_EXCED_RANGE:
            return .ENOENT
        case ERROR_TOO_MANY_OPEN_FILES:
            return .EMFILE
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
            return .EACCES
        case ERROR_INVALID_HANDLE,
            ERROR_INVALID_TARGET_HANDLE,
            ERROR_DIRECT_ACCESS_HANDLE:
            return .EBADF
        case ERROR_ARENA_TRASHED,
            ERROR_NOT_ENOUGH_MEMORY,
            ERROR_INVALID_BLOCK,
            ERROR_NOT_ENOUGH_QUOTA:
            return .ENOMEM
        case ERROR_BAD_ENVIRONMENT:
            return .E2BIG
        case ERROR_BAD_FORMAT,
            ERROR_INVALID_STARTING_CODESEG...ERROR_INFLOOP_IN_RELOC_CHAIN:
            return .ENOEXEC
        case ERROR_NOT_SAME_DEVICE:
            return .EXDEV
        case ERROR_FILE_EXISTS,
            ERROR_ALREADY_EXISTS:
            return .EEXIST
        case ERROR_NO_PROC_SLOTS,
            ERROR_MAX_THRDS_REACHED,
            ERROR_NESTING_NOT_ALLOWED:
            return .EAGAIN
        case ERROR_BROKEN_PIPE:
            return .EPIPE
        case ERROR_DISK_FULL:
            return .ENOSPC
        case ERROR_DIR_NOT_EMPTY:
            return .ENOTEMPTY
        case ERROR_WAIT_NO_CHILDREN,
            ERROR_CHILD_NOT_COMPLETE:
            return .ECHILD
        case ERROR_NO_UNICODE_TRANSLATION:
            return .EILSEQ
        default:
            return .EINVAL
        }
    #else
        // Win32 error codes originate only on Windows.
        return nil
    #endif
}
