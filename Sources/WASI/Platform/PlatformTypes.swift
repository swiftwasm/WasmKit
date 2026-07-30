import WasmTypes

extension WASIAbi.FileType {
    init(platformFileType: FileDescriptor.FileType) {
        if platformFileType.isDirectory {
            self = .DIRECTORY
            return
        }
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
        self.init(
            seconds: UInt64(timespec.seconds),
            nanoseconds: UInt64(timespec.nanoseconds))
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
