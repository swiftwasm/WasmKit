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
#elseif os(WASI)
    import WASILibc
#endif

// Free function so unqualified errno constants resolve to the libc values
// rather than being shadowed by `WASIAbi.Errno`'s own case names.
func _mapPlatformErrno(_ errno: CInt) -> WASIAbi.Errno? {
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
