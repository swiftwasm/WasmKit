import WasmTypes

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

extension WASIAbi.FileType {
    init(platformFileType: FileDescriptor.FileType) {
        if platformFileType.isDirectory {
            self = .DIRECTORY
            return
        }
        #if !os(Windows)
            if platformFileType.isSymlink {
                self = .SYMBOLIC_LINK
                return
            }
            if platformFileType.isFile {
                self = .REGULAR_FILE
                return
            }
            if platformFileType.isCharacterDevice {
                self = .CHARACTER_DEVICE
                return
            }
            if platformFileType.isBlockDevice {
                self = .BLOCK_DEVICE
                return
            }
            if platformFileType.isSocket {
                self = .SOCKET_STREAM
                return
            }
        #endif
        self = .UNKNOWN
    }
}

extension WASIAbi.Fdflags {
    init(platformOpenOptions: FileDescriptor.OpenOptions) {
        var fdFlags: WASIAbi.Fdflags = []
        #if !os(Windows)
            if platformOpenOptions.contains(.append) {
                fdFlags.insert(.APPEND)
            }
            if platformOpenOptions.contains(.nonBlocking) {
                fdFlags.insert(.NONBLOCK)
            }
            #if !os(WASI)
                if platformOpenOptions.contains(.dataSync) {
                    fdFlags.insert(.DSYNC)
                }
                if platformOpenOptions.contains(.fileSync) {
                    fdFlags.insert(.SYNC)
                }
            #endif
            #if os(Linux)
                if platformOpenOptions.contains(.readSync) {
                    fdFlags.insert(.RSYNC)
                }
            #endif
        #endif
        self = fdFlags
    }

    var platformOpenOptions: FileDescriptor.OpenOptions {
        var flags: FileDescriptor.OpenOptions = []
        if self.contains(.APPEND) {
            flags.insert(.append)
        }
        #if !os(Windows)
            if self.contains(.NONBLOCK) {
                flags.insert(.nonBlocking)
            }
            #if !os(WASI)
                if self.contains(.DSYNC) {
                    flags.insert(.dataSync)
                }
                if self.contains(.SYNC) {
                    flags.insert(.fileSync)
                }
            #endif
            #if os(Linux)
                if self.contains(.RSYNC) {
                    flags.insert(.readSync)
                }
            #endif
        #endif
        return flags
    }
}

extension WASIAbi.Timestamp {
    static func platformTimeSpec(
        atim: WASIAbi.Timestamp,
        mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws -> (access: FileTime, modification: FileTime) {
        return try (
            atim.platformTimeSpec(
                set: fstFlags.contains(.ATIM), now: fstFlags.contains(.ATIM_NOW)
            ),
            mtim.platformTimeSpec(
                set: fstFlags.contains(.MTIM), now: fstFlags.contains(.MTIM_NOW)
            )
        )
    }

    func platformTimeSpec(set: Bool, now: Bool) throws -> FileTime {
        switch (set, now) {
        case (true, true):
            throw WASIAbi.Errno.EINVAL
        case (true, false):
            return FileTime(
                seconds: Int(self / 1_000_000_000),
                nanoseconds: Int(self % 1_000_000_000)
            )
        case (false, true): return .now
        case (false, false): return .omit
        }
    }
}

extension WASIAbi.Filestat {
    init(stat: FileDescriptor.Attributes) {
        self = WASIAbi.Filestat(
            dev: WASIAbi.Device(stat.device),
            ino: WASIAbi.Inode(stat.inode),
            filetype: WASIAbi.FileType(platformFileType: stat.fileType),
            nlink: WASIAbi.LinkCount(stat.linkCount),
            size: WASIAbi.FileSize(stat.size),
            atim: WASIAbi.Timestamp(platformTimeSpec: stat.accessTime),
            mtim: WASIAbi.Timestamp(platformTimeSpec: stat.modificationTime),
            ctim: WASIAbi.Timestamp(platformTimeSpec: stat.creationTime)
        )
    }
}

extension WASIAbi.Timestamp {

    fileprivate init(seconds: UInt64, nanoseconds: UInt64) {
        self = nanoseconds + seconds * 1_000_000_000
    }

    init(platformTimeSpec timespec: FileTime) {
        #if os(Windows)
            self = UInt64(timespec.unixNanoseconds)
        #else
            self.init(
                seconds: UInt64(timespec.seconds),
                nanoseconds: UInt64(timespec.nanoseconds))
        #endif
    }

    init(wallClockDuration duration: WallClock.Duration) {
        self.init(seconds: duration.seconds, nanoseconds: UInt64(duration.nanoseconds))
    }
}

extension WASIAbi.Errno {

    /// Looks through a cleanup failure so a failing close still reports the operation's own errno
    /// instead of trapping the guest.
    static func reportable(for error: any Error) -> WASIAbi.Errno? {
        switch error {
        case let errno as WASIAbi.Errno: return errno
        case let failure as CleanupFailure: return reportable(for: failure.underlying)
        default: return nil
        }
    }

    static func translatingPlatformErrno<R>(_ body: () throws -> R) throws -> R {
        do {
            return try body()
        } catch let errno as PlatformErrno {
            throw try WASIAbi.Errno(platformErrno: errno)
        }
    }

    init(platformErrno: CInt) throws {
        try self.init(platformErrno: PlatformErrno(rawValue: platformErrno))
    }

    init(platformErrno: PlatformErrno) throws {
        guard let error = WASIAbi.Errno(_platformErrno: platformErrno.rawValue) else {
            throw WASIError(description: "Unknown underlying OS error: \(platformErrno)")
        }
        self = error
    }

    private init?(_platformErrno errno: CInt) {
        guard let mapped = _mapPlatformErrno(errno) else { return nil }
        self = mapped
    }
}

// Free function so unqualified errno constants resolve to the libc values
// rather than being shadowed by `WASIAbi.Errno`'s own case names.
private func _mapPlatformErrno(_ errno: CInt) -> WASIAbi.Errno? {
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
