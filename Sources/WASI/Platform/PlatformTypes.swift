import SystemExtras
import SystemPackage

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
                seconds: UInt64(timespec.rawValue.tv_sec),
                nanoseconds: UInt64(timespec.rawValue.tv_nsec))
        #endif
    }

    init(wallClockDuration duration: WallClock.Duration) {
        self.init(seconds: duration.seconds, nanoseconds: UInt64(duration.nanoseconds))
    }
}

extension WASIAbi.Errno {

    static func translatingPlatformErrno<R>(_ body: () throws -> R) throws -> R {
        do {
            return try body()
        } catch let errno as Errno {
            throw try WASIAbi.Errno(platformErrno: errno)
        }
    }

    init(platformErrno: CInt) throws {
        try self.init(platformErrno: SystemPackage.Errno(rawValue: platformErrno))
    }

    init(platformErrno: Errno) throws {
        guard let error = WASIAbi.Errno(_platformErrno: platformErrno) else {
            throw WASIError(description: "Unknown underlying OS error: \(platformErrno)")
        }
        self = error
    }

    private init?(_platformErrno: SystemPackage.Errno) {
        switch _platformErrno {
        case .permissionDenied: self = .EPERM
        case .notPermitted: self = .EPERM
        case .noSuchFileOrDirectory: self = .ENOENT
        case .noSuchProcess: self = .ESRCH
        case .interrupted: self = .EINTR
        case .ioError: self = .EIO
        case .noSuchAddressOrDevice: self = .ENXIO
        case .argListTooLong: self = .E2BIG
        case .execFormatError: self = .ENOEXEC
        case .badFileDescriptor: self = .EBADF
        case .noChildProcess: self = .ECHILD
        case .deadlock: self = .EDEADLK
        case .noMemory: self = .ENOMEM
        case .permissionDenied: self = .EACCES
        case .badAddress: self = .EFAULT
        case .resourceBusy: self = .EBUSY
        case .fileExists: self = .EEXIST
        case .improperLink: self = .EXDEV
        case .operationNotSupportedByDevice: self = .ENODEV
        case .notDirectory: self = .ENOTDIR
        case .isDirectory: self = .EISDIR
        case .invalidArgument: self = .EINVAL
        case .tooManyOpenFilesInSystem: self = .ENFILE
        case .tooManyOpenFiles: self = .EMFILE
        #if !os(Windows)
            case .inappropriateIOCTLForDevice: self = .ENOTTY
            case .textFileBusy: self = .ETXTBSY
        #endif
        case .fileTooLarge: self = .EFBIG
        case .noSpace: self = .ENOSPC
        case .illegalSeek: self = .ESPIPE
        case .readOnlyFileSystem: self = .EROFS
        case .tooManyLinks: self = .EMLINK
        case .brokenPipe: self = .EPIPE
        case .outOfDomain: self = .EDOM
        case .outOfRange: self = .ERANGE
        case .resourceTemporarilyUnavailable: self = .EAGAIN
        case .nowInProgress: self = .EINPROGRESS
        case .alreadyInProcess: self = .EALREADY
        case .notSocket: self = .ENOTSOCK
        case .addressRequired: self = .EDESTADDRREQ
        case .messageTooLong: self = .EMSGSIZE
        case .protocolWrongTypeForSocket: self = .EPROTOTYPE
        case .protocolNotAvailable: self = .ENOPROTOOPT
        case .protocolNotSupported: self = .EPROTONOSUPPORT
        case .notSupported: self = .ENOTSUP
        case .addressFamilyNotSupported: self = .EAFNOSUPPORT
        case .addressInUse: self = .EADDRINUSE
        case .addressNotAvailable: self = .EADDRNOTAVAIL
        case .networkDown: self = .ENETDOWN
        case .networkUnreachable: self = .ENETUNREACH
        case .networkReset: self = .ENETRESET
        case .connectionAbort: self = .ECONNABORTED
        case .connectionReset: self = .ECONNRESET
        case .noBufferSpace: self = .ENOBUFS
        case .socketIsConnected: self = .EISCONN
        case .socketNotConnected: self = .ENOTCONN
        case .timedOut: self = .ETIMEDOUT
        case .connectionRefused: self = .ECONNREFUSED
        case .tooManySymbolicLinkLevels: self = .ELOOP
        case .fileNameTooLong: self = .ENAMETOOLONG
        case .noRouteToHost: self = .EHOSTUNREACH
        case .directoryNotEmpty: self = .ENOTEMPTY
        case .diskQuotaExceeded: self = .EDQUOT
        case .staleNFSFileHandle: self = .ESTALE
        case .noLocks: self = .ENOLCK
        case .noFunction: self = .ENOSYS
        #if !os(Windows)
            case .overflow: self = .EOVERFLOW
        #endif
        case .canceled: self = .ECANCELED
        #if !os(Windows)
            case .identifierRemoved: self = .EIDRM
            case .noMessage: self = .ENOMSG
        #endif
        case .illegalByteSequence: self = .EILSEQ
        #if !os(Windows)
            case .badMessage: self = .EBADMSG
            case .multiHop: self = .EMULTIHOP
            case .noLink: self = .ENOLINK
            case .protocolError: self = .EPROTO
            case .notRecoverable: self = .ENOTRECOVERABLE
            case .previousOwnerDied: self = .EOWNERDEAD
        #endif
        default: return nil
        }
    }
}
