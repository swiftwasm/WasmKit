import SystemExtras
import SystemPackage
import WasmTypes

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
    import Glibc
#elseif os(Windows)
    import ucrt
#else
    #error("Unsupported Platform")
#endif

protocol WASI {
    /// Reads command-line argument data.
    /// - Parameters:
    ///   - argv: Pointer to an array of argument strings to be written
    ///   - argvBuffer: Pointer to a buffer of argument strings to be written
    func args_get(
        argv: UnsafeGuestPointer<UnsafeGuestPointer<UInt8>>,
        argvBuffer: UnsafeGuestPointer<UInt8>
    )

    /// Return command-line argument data sizes.
    /// - Returns: Tuple of number of arguments and required buffer size
    func args_sizes_get() -> (WASIAbi.Size, WASIAbi.Size)

    /// Read environment variable data.
    func environ_get(
        environ: UnsafeGuestPointer<UnsafeGuestPointer<UInt8>>,
        environBuffer: UnsafeGuestPointer<UInt8>
    )

    /// Return environment variable data sizes.
    /// - Returns: Tuple of number of environment variables and required buffer size
    func environ_sizes_get() -> (WASIAbi.Size, WASIAbi.Size)

    /// Return the resolution of a clock.
    func clock_res_get(id: WASIAbi.ClockId) throws -> WASIAbi.Timestamp

    /// Return the time value of a clock.
    func clock_time_get(
        id: WASIAbi.ClockId, precision: WASIAbi.Timestamp
    ) throws -> WASIAbi.Timestamp

    /// Provide file advisory information on a file descriptor.
    func fd_advise(
        fd: WASIAbi.Fd, offset: WASIAbi.FileSize,
        length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws

    /// Force the allocation of space in a file.
    func fd_allocate(fd: WASIAbi.Fd, offset: WASIAbi.FileSize, length: WASIAbi.FileSize) throws

    /// Close a file descriptor.
    func fd_close(fd: WASIAbi.Fd) throws

    /// Synchronize the data of a file to disk.
    func fd_datasync(fd: WASIAbi.Fd) throws

    /// Get the attributes of a file descriptor.
    /// - Parameter fileDescriptor: File descriptor to get attribute.
    func fd_fdstat_get(fileDescriptor: UInt32) throws -> WASIAbi.FdStat

    /// Adjust the flags associated with a file descriptor.
    func fd_fdstat_set_flags(fd: WASIAbi.Fd, flags: WASIAbi.Fdflags) throws

    /// Adjust the rights associated with a file descriptor.
    func fd_fdstat_set_rights(
        fd: WASIAbi.Fd,
        fsRightsBase: WASIAbi.Rights,
        fsRightsInheriting: WASIAbi.Rights
    ) throws

    /// Return the attributes of an open file.
    func fd_filestat_get(fd: WASIAbi.Fd) throws -> WASIAbi.Filestat

    ///  Adjust the size of an open file. If this increases the file's size, the extra bytes are filled with zeros.
    func fd_filestat_set_size(fd: WASIAbi.Fd, size: WASIAbi.FileSize) throws

    /// Adjust the timestamps of an open file or directory.
    func fd_filestat_set_times(
        fd: WASIAbi.Fd,
        atim: WASIAbi.Timestamp,
        mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws

    /// Read from a file descriptor, without using and updating the file descriptor's offset.
    func fd_pread(
        fd: WASIAbi.Fd, iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>,
        offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size

    /// Return a description of the given preopened file descriptor.
    func fd_prestat_get(fd: WASIAbi.Fd) throws -> WASIAbi.Prestat

    /// Return a directory name of the given preopened file descriptor
    func fd_prestat_dir_name(fd: WASIAbi.Fd, path: UnsafeGuestPointer<UInt8>, maxPathLength: WASIAbi.Size) throws

    /// Write to a file descriptor, without using and updating the file descriptor's offset.
    func fd_pwrite(
        fd: WASIAbi.Fd, iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>,
        offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size

    /// Read from a file descriptor.
    func fd_read(
        fd: WASIAbi.Fd, iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>
    ) throws -> WASIAbi.Size

    /// Read directory entries from a directory.
    func fd_readdir(
        fd: WASIAbi.Fd,
        buffer: UnsafeGuestBufferPointer<UInt8>,
        cookie: WASIAbi.DirCookie
    ) throws -> WASIAbi.Size

    /// Atomically replace a file descriptor by renumbering another file descriptor.
    func fd_renumber(fd: WASIAbi.Fd, to toFd: WASIAbi.Fd) throws

    /// Move the offset of a file descriptor.
    func fd_seek(fd: WASIAbi.Fd, offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize

    /// Synchronize the data and metadata of a file to disk.
    func fd_sync(fd: WASIAbi.Fd) throws

    /// Return the current offset of a file descriptor.
    func fd_tell(fd: WASIAbi.Fd) throws -> WASIAbi.FileSize

    /// POSIX `writev` equivalent.
    /// - Parameters:
    ///   - fileDescriptor: File descriptor to write to.
    ///   - ioVectors: Buffer pointer to an array of byte buffers to write.
    /// - Returns: Number of bytes written.
    func fd_write(
        fileDescriptor: WASIAbi.Fd,
        ioVectors: UnsafeGuestBufferPointer<WASIAbi.IOVec>
    ) throws -> UInt32

    /// Create a directory.
    func path_create_directory(
        dirFd: WASIAbi.Fd,
        path: String
    ) throws

    /// Return the attributes of a file or directory.
    func path_filestat_get(
        dirFd: WASIAbi.Fd,
        flags: WASIAbi.LookupFlags,
        path: String
    ) throws -> WASIAbi.Filestat

    /// Adjust the timestamps of a file or directory.
    func path_filestat_set_times(
        dirFd: WASIAbi.Fd,
        flags: WASIAbi.LookupFlags,
        path: String,
        atim: WASIAbi.Timestamp,
        mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws

    /// Create a hard link.
    func path_link(
        oldFd: WASIAbi.Fd, oldFlags: WASIAbi.LookupFlags, oldPath: String,
        newFd: WASIAbi.Fd, newPath: String
    ) throws

    /// Open a file or directory.
    func path_open(
        dirFd: WASIAbi.Fd,
        dirFlags: WASIAbi.LookupFlags,
        path: String,
        oflags: WASIAbi.Oflags,
        fsRightsBase: WASIAbi.Rights,
        fsRightsInheriting: WASIAbi.Rights,
        fdflags: WASIAbi.Fdflags
    ) throws -> WASIAbi.Fd

    /// Read the contents of a symbolic link.
    func path_readlink(
        fd: WASIAbi.Fd, path: String,
        buffer: UnsafeGuestBufferPointer<UInt8>
    ) throws -> WASIAbi.Size

    /// Remove a directory.
    func path_remove_directory(dirFd: WASIAbi.Fd, path: String) throws

    /// Rename a file or directory.
    func path_rename(
        oldFd: WASIAbi.Fd, oldPath: String,
        newFd: WASIAbi.Fd, newPath: String
    ) throws

    /// Create a symbolic link.
    func path_symlink(
        oldPath: String, dirFd: WASIAbi.Fd, newPath: String
    ) throws

    /// Unlink a file.
    func path_unlink_file(
        dirFd: WASIAbi.Fd,
        path: String
    ) throws

    /// Concurrently poll for the occurrence of a set of events.
    func poll_oneoff(
        subscriptions: UnsafeGuestRawPointer,
        events: UnsafeGuestRawPointer,
        numberOfSubscriptions: WASIAbi.Size
    ) throws -> WASIAbi.Size

    /// Write high-quality random data into a buffer.
    func random_get(buffer: UnsafeGuestPointer<UInt8>, length: WASIAbi.Size)
}

enum WASIAbi {
    enum Errno: UInt32, Error {
        /// No error occurred. System call completed successfully.
        case SUCCESS = 0
        /// Argument list too long.
        case E2BIG = 1
        /// Permission denied.
        case EACCES = 2
        /// Address in use.
        case EADDRINUSE = 3
        /// Address not available.
        case EADDRNOTAVAIL = 4
        /// Address family not supported.
        case EAFNOSUPPORT = 5
        /// Resource unavailable, or operation would block.
        case EAGAIN = 6
        /// Connection already in progress.
        case EALREADY = 7
        /// Bad file descriptor.
        case EBADF = 8
        /// Bad message.
        case EBADMSG = 9
        /// Device or resource busy.
        case EBUSY = 10
        /// Operation canceled.
        case ECANCELED = 11
        /// No child processes.
        case ECHILD = 12
        /// Connection aborted.
        case ECONNABORTED = 13
        /// Connection refused.
        case ECONNREFUSED = 14
        /// Connection reset.
        case ECONNRESET = 15
        /// Resource deadlock would occur.
        case EDEADLK = 16
        /// Destination address required.
        case EDESTADDRREQ = 17
        /// Mathematics argument out of domain of function.
        case EDOM = 18
        /// Reserved.
        case EDQUOT = 19
        /// File exists.
        case EEXIST = 20
        /// Bad address.
        case EFAULT = 21
        /// File too large.
        case EFBIG = 22
        /// Host is unreachable.
        case EHOSTUNREACH = 23
        /// Identifier removed.
        case EIDRM = 24
        /// Illegal byte sequence.
        case EILSEQ = 25
        /// Operation in progress.
        case EINPROGRESS = 26
        /// Interrupted function.
        case EINTR = 27
        /// Invalid argument.
        case EINVAL = 28
        /// I/O error.
        case EIO = 29
        /// Socket is connected.
        case EISCONN = 30
        /// Is a directory.
        case EISDIR = 31
        /// Too many levels of symbolic links.
        case ELOOP = 32
        /// File descriptor value too large.
        case EMFILE = 33
        /// Too many links.
        case EMLINK = 34
        /// Message too large.
        case EMSGSIZE = 35
        /// Reserved.
        case EMULTIHOP = 36
        /// Filename too long.
        case ENAMETOOLONG = 37
        /// Network is down.
        case ENETDOWN = 38
        /// Connection aborted by network.
        case ENETRESET = 39
        /// Network unreachable.
        case ENETUNREACH = 40
        /// Too many files open in system.
        case ENFILE = 41
        /// No buffer space available.
        case ENOBUFS = 42
        /// No such device.
        case ENODEV = 43
        /// No such file or directory.
        case ENOENT = 44
        /// Executable file format error.
        case ENOEXEC = 45
        /// No locks available.
        case ENOLCK = 46
        /// Reserved.
        case ENOLINK = 47
        /// Not enough space.
        case ENOMEM = 48
        /// No message of the desired type.
        case ENOMSG = 49
        /// Protocol not available.
        case ENOPROTOOPT = 50
        /// No space left on device.
        case ENOSPC = 51
        /// Function not supported.
        case ENOSYS = 52
        /// The socket is not connected.
        case ENOTCONN = 53
        /// Not a directory or a symbolic link to a directory.
        case ENOTDIR = 54
        /// Directory not empty.
        case ENOTEMPTY = 55
        /// State not recoverable.
        case ENOTRECOVERABLE = 56
        /// Not a socket.
        case ENOTSOCK = 57
        /// Not supported, or operation not supported on socket.
        case ENOTSUP = 58
        /// Inappropriate I/O control operation.
        case ENOTTY = 59
        /// No such device or address.
        case ENXIO = 60
        /// Value too large to be stored in data type.
        case EOVERFLOW = 61
        /// Previous owner died.
        case EOWNERDEAD = 62
        /// Operation not permitted.
        case EPERM = 63
        /// Broken pipe.
        case EPIPE = 64
        /// Protocol error.
        case EPROTO = 65
        /// Protocol not supported.
        case EPROTONOSUPPORT = 66
        /// Protocol wrong type for socket.
        case EPROTOTYPE = 67
        /// Result too large.
        case ERANGE = 68
        /// Read-only file system.
        case EROFS = 69
        /// Invalid seek.
        case ESPIPE = 70
        /// No such process.
        case ESRCH = 71
        /// Reserved.
        case ESTALE = 72
        /// Connection timed out.
        case ETIMEDOUT = 73
        /// Text file busy.
        case ETXTBSY = 74
        /// Cross-device link.
        case EXDEV = 75
        /// Extension: Capabilities insufficient.
        case ENOTCAPABLE = 76
    }

    typealias Size = UInt32

    /// Non-negative file size or length of a region within a file.
    typealias FileSize = UInt64

    typealias Fd = UInt32

    struct IOVec: GuestPointee {
        let buffer: UnsafeGuestRawPointer
        let length: WASIAbi.Size

        func withHostBufferPointer<R>(_ body: (UnsafeMutableRawBufferPointer) throws -> R) rethrows -> R {
            try buffer.withHostPointer(count: Int(length)) { hostPointer in
                try body(hostPointer)
            }
        }

        static var sizeInGuest: UInt32 {
            return UnsafeGuestRawPointer.sizeInGuest + WASIAbi.Size.sizeInGuest
        }

        static var alignInGuest: UInt32 {
            max(UnsafeGuestRawPointer.alignInGuest, WASIAbi.Size.alignInGuest)
        }

        static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> IOVec {
            return IOVec(
                buffer: .readFromGuest(pointer),
                length: .readFromGuest(pointer.advanced(by: UnsafeGuestRawPointer.sizeInGuest))
            )
        }

        static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: IOVec) {
            UnsafeGuestRawPointer.writeToGuest(at: pointer, value: value.buffer)
            WASIAbi.Size.writeToGuest(at: pointer.advanced(by: UnsafeGuestRawPointer.sizeInGuest), value: value.length)
        }
    }

    /// Relative offset within a file.
    typealias FileDelta = Int64

    /// The position relative to which to set the offset of the file descriptor.
    enum Whence: UInt8 {
        /// Seek relative to start-of-file.
        case SET = 0
        /// Seek relative to current position.
        case CUR = 1
        /// Seek relative to end-of-file.
        case END = 2
    }

    enum ClockId: UInt32 {
        /// The clock measuring real time. Time value zero corresponds with
        /// 1970-01-01T00:00:00Z.
        case REALTIME = 0
        /// The store-wide monotonic clock, which is defined as a clock measuring
        /// real time, whose value cannot be adjusted and which cannot have negative
        /// clock jumps. The epoch of this clock is undefined. The absolute time
        /// value of this clock therefore has no meaning.
        case MONOTONIC = 1
        /// The CPU-time clock associated with the current process.
        case PROCESS_CPUTIME_ID = 2
        /// The CPU-time clock associated with the current thread.
        case THREAD_CPUTIME_ID = 3
    }

    typealias Timestamp = UInt64

    struct Fdflags: OptionSet, GuestPrimitivePointee {
        var rawValue: UInt16
        /// Append mode: Data written to the file is always appended to the file's end.
        static let APPEND = Fdflags(rawValue: 1 << 0)
        /// Write according to synchronized I/O data integrity completion. Only the data stored in the file is synchronized.
        static let DSYNC = Fdflags(rawValue: 1 << 1)
        /// Non-blocking mode.
        static let NONBLOCK = Fdflags(rawValue: 1 << 2)
        /// Synchronized read I/O operations.
        static let RSYNC = Fdflags(rawValue: 1 << 3)
        /// Write according to synchronized I/O file integrity completion. In
        /// addition to synchronizing the data stored in the file, the implementation
        /// may also synchronously update the file's metadata.
        static let SYNC = Fdflags(rawValue: 1 << 4)
    }

    struct Rights: OptionSet, GuestPrimitivePointee {
        let rawValue: UInt64

        /// The right to invoke `fd_datasync`.
        /// If `path_open` is set, includes the right to invoke
        /// `path_open` with `fdflags::dsync`.
        static let FD_DATASYNC = Rights(rawValue: 1 << 0)
        /// The right to invoke `fd_read` and `sock_recv`.
        /// If `rights::fd_seek` is set, includes the right to invoke `fd_pread`.
        static let FD_READ = Rights(rawValue: 1 << 1)
        /// The right to invoke `fd_seek`. This flag implies `rights::fd_tell`.
        static let FD_SEEK = Rights(rawValue: 1 << 2)
        /// The right to invoke `fd_fdstat_set_flags`.
        static let FD_FDSTAT_SET_FLAGS = Rights(rawValue: 1 << 3)
        /// The right to invoke `fd_sync`.
        /// If `path_open` is set, includes the right to invoke
        /// `path_open` with `fdflags::rsync` and `fdflags::dsync`.
        static let FD_SYNC = Rights(rawValue: 1 << 4)
        /// The right to invoke `fd_seek` in such a way that the file offset
        /// remains unaltered (i.e., `whence::cur` with offset zero), or to
        /// invoke `fd_tell`.
        static let FD_TELL = Rights(rawValue: 1 << 5)
        /// The right to invoke `fd_write` and `sock_send`.
        /// If `rights::fd_seek` is set, includes the right to invoke `fd_pwrite`.
        static let FD_WRITE = Rights(rawValue: 1 << 6)
        /// The right to invoke `fd_advise`.
        static let FD_ADVISE = Rights(rawValue: 1 << 7)
        /// The right to invoke `fd_allocate`.
        static let FD_ALLOCATE = Rights(rawValue: 1 << 8)
        /// The right to invoke `path_create_directory`.
        static let PATH_CREATE_DIRECTORY = Rights(rawValue: 1 << 9)
        /// If `path_open` is set, the right to invoke `path_open` with `oflags::creat`.
        static let PATH_CREATE_FILE = Rights(rawValue: 1 << 10)
        /// The right to invoke `path_link` with the file descriptor as the
        /// source directory.
        static let PATH_LINK_SOURCE = Rights(rawValue: 1 << 11)
        /// The right to invoke `path_link` with the file descriptor as the
        /// target directory.
        static let PATH_LINK_TARGET = Rights(rawValue: 1 << 12)
        /// The right to invoke `path_open`.
        static let PATH_OPEN = Rights(rawValue: 1 << 13)
        /// The right to invoke `fd_readdir`.
        static let FD_READDIR = Rights(rawValue: 1 << 14)
        /// The right to invoke `path_readlink`.
        static let PATH_READLINK = Rights(rawValue: 1 << 15)
        /// The right to invoke `path_rename` with the file descriptor as the source directory.
        static let PATH_RENAME_SOURCE = Rights(rawValue: 1 << 16)
        /// The right to invoke `path_rename` with the file descriptor as the target directory.
        static let PATH_RENAME_TARGET = Rights(rawValue: 1 << 17)
        /// The right to invoke `path_filestat_get`.
        static let PATH_FILESTAT_GET = Rights(rawValue: 1 << 18)
        /// The right to change a file's size (there is no `path_filestat_set_size`).
        /// If `path_open` is set, includes the right to invoke `path_open` with `oflags::trunc`.
        static let PATH_FILESTAT_SET_SIZE = Rights(rawValue: 1 << 19)
        /// The right to invoke `path_filestat_set_times`.
        static let PATH_FILESTAT_SET_TIMES = Rights(rawValue: 1 << 20)
        /// The right to invoke `fd_filestat_get`.
        static let FD_FILESTAT_GET = Rights(rawValue: 1 << 21)
        /// The right to invoke `fd_filestat_set_size`.
        static let FD_FILESTAT_SET_SIZE = Rights(rawValue: 1 << 22)
        /// The right to invoke `fd_filestat_set_times`.
        static let FD_FILESTAT_SET_TIMES = Rights(rawValue: 1 << 23)
        /// The right to invoke `path_symlink`.
        static let PATH_SYMLINK = Rights(rawValue: 1 << 24)
        /// The right to invoke `path_remove_directory`.
        static let PATH_REMOVE_DIRECTORY = Rights(rawValue: 1 << 25)
        /// The right to invoke `path_unlink_file`.
        static let PATH_UNLINK_FILE = Rights(rawValue: 1 << 26)
        /// If `rights::fd_read` is set, includes the right to invoke `poll_oneoff` to subscribe to `eventtype::fd_read`.
        /// If `rights::fd_write` is set, includes the right to invoke `poll_oneoff` to subscribe to `eventtype::fd_write`.
        static let POLL_FD_READWRITE = Rights(rawValue: 1 << 27)
        /// The right to invoke `sock_shutdown`.
        static let SOCK_SHUTDOWN = Rights(rawValue: 1 << 28)
        /// The right to invoke `sock_accept`.
        static let SOCK_ACCEPT = Rights(rawValue: 1 << 29)

        static let DIRECTORY_BASE_RIGHTS: Rights = [
            .PATH_CREATE_DIRECTORY,
            .PATH_CREATE_FILE,
            .PATH_LINK_SOURCE,
            .PATH_LINK_TARGET,
            .PATH_OPEN,
            .FD_READDIR,
            .PATH_READLINK,
            .PATH_RENAME_SOURCE,
            .PATH_RENAME_TARGET,
            .PATH_SYMLINK,
            .PATH_REMOVE_DIRECTORY,
            .PATH_UNLINK_FILE,
            .PATH_FILESTAT_GET,
            .PATH_FILESTAT_SET_TIMES,
            .FD_FILESTAT_GET,
            .FD_FILESTAT_SET_TIMES,
        ]

        static let DIRECTORY_INHERITING_RIGHTS: Rights = DIRECTORY_BASE_RIGHTS.union([
            .FD_DATASYNC,
            .FD_READ,
            .FD_SEEK,
            .FD_FDSTAT_SET_FLAGS,
            .FD_SYNC,
            .FD_TELL,
            .FD_WRITE,
            .FD_ADVISE,
            .FD_ALLOCATE,
            .FD_FILESTAT_GET,
            .FD_FILESTAT_SET_SIZE,
            .FD_FILESTAT_SET_TIMES,
            .POLL_FD_READWRITE,
        ])
    }

    /// A reference to the offset of a directory entry.
    /// The value 0 signifies the start of the directory.
    typealias DirCookie = UInt64
    /// The type for the `dirent::d_namlen` field of `dirent` struct.
    typealias DirNameLen = UInt32

    /// File serial number that is unique within its file system.
    typealias Inode = UInt64

    /// The type of a file descriptor or file.
    enum FileType: UInt8, GuestPrimitivePointee {
        /// The type of the file descriptor or file is unknown or is different from any of the other types specified.
        case UNKNOWN = 0
        /// The file descriptor or file refers to a block device inode.
        case BLOCK_DEVICE = 1
        /// The file descriptor or file refers to a character device inode.
        case CHARACTER_DEVICE = 2
        /// The file descriptor or file refers to a directory inode.
        case DIRECTORY = 3
        /// The file descriptor or file refers to a regular file inode.
        case REGULAR_FILE = 4
        /// The file descriptor or file refers to a datagram socket.
        case SOCKET_DGRAM = 5
        /// The file descriptor or file refers to a byte-stream socket.
        case SOCKET_STREAM = 6
        /// The file refers to a symbolic link inode.
        case SYMBOLIC_LINK = 7
    }

    /// A directory entry.
    struct Dirent {
        /// The offset of the next directory entry stored in this directory.
        let dNext: DirCookie
        /// The serial number of the file referred to by this directory entry.
        let dIno: Inode
        /// The length of the name of the directory entry.
        let dirNameLen: DirNameLen
        /// The type of the file referred to by this directory entry.
        let dType: FileType

        static var sizeInGuest: UInt32 {
            // Hard coded because WIT aligns up at last when calculating struct size, but Swift doesn't
            // https://github.com/WebAssembly/WASI/blob/4712d490fd7662f689af6faa5d718e042f014931/legacy/tools/witx/src/layout.rs#L117C24-L117C24
            24
        }

        static func writeToGuest(unalignedAt pointer: UnsafeGuestRawPointer, end: UnsafeGuestRawPointer, value: Dirent) {
            var pointer = pointer
            guard pointer < end else { return }
            DirCookie.writeToGuest(at: pointer, value: value.dNext)
            pointer = pointer.advanced(by: DirCookie.sizeInGuest)

            guard pointer < end else { return }
            Inode.writeToGuest(at: pointer, value: value.dIno)
            pointer = pointer.advanced(by: Inode.sizeInGuest)

            guard pointer < end else { return }
            DirNameLen.writeToGuest(at: pointer, value: value.dirNameLen)
            pointer = pointer.advanced(by: DirNameLen.sizeInGuest)

            guard pointer < end else { return }
            FileType.writeToGuest(at: pointer, value: value.dType)
            pointer = pointer.advanced(by: FileType.sizeInGuest)
        }
    }

    enum Advice: UInt8 {
        /// The application has no advice to give on its behavior with respect to the specified data.
        case NORMAL = 0
        /// The application expects to access the specified data sequentially from lower offsets to higher offsets.
        case SEQUENTIAL = 1
        /// The application expects to access the specified data in a random order.
        case RANDOM = 2
        /// The application expects to access the specified data in the near future.
        case WILLNEED = 3
        /// The application expects that it will not access the specified data in the near future.
        case DONTNEED = 4
        /// The application expects to access the specified data once and then not reuse it thereafter.
        case NOREUSE = 5
    }

    struct FdStat: GuestPrimitivePointee {
        let fsFileType: FileType
        let fsFlags: Fdflags
        let fsRightsBase: Rights
        let fsRightsInheriting: Rights

        static var sizeInGuest: UInt32 {
            FileType.sizeInGuest + Fdflags.sizeInGuest + Rights.sizeInGuest * 2
        }

        static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> FdStat {
            var pointer = pointer
            return FdStat(
                fsFileType: .readFromGuest(&pointer),
                fsFlags: .readFromGuest(&pointer),
                fsRightsBase: .readFromGuest(&pointer),
                fsRightsInheriting: .readFromGuest(&pointer)
            )
        }

        static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: FdStat) {
            var pointer = pointer
            FileType.writeToGuest(at: &pointer, value: value.fsFileType)
            Fdflags.writeToGuest(at: &pointer, value: value.fsFlags)
            Rights.writeToGuest(at: &pointer, value: value.fsRightsBase)
            Rights.writeToGuest(at: &pointer, value: value.fsRightsInheriting)
        }
    }

    /// Identifier for a device containing a file system. Can be used in combination
    /// with `inode` to uniquely identify a file or directory in the filesystem.
    typealias Device = UInt64

    /// Which file time attributes to adjust.
    struct FstFlags: OptionSet, GuestPrimitivePointee {
        let rawValue: UInt16

        static let ATIM = FstFlags(rawValue: 1 << 0)
        /// Adjust the last data access timestamp to the time of clock `clockid::realtime`.
        static let ATIM_NOW = FstFlags(rawValue: 1 << 1)
        /// Adjust the last data modification timestamp to the value stored in `filestat::mtim`.
        static let MTIM = FstFlags(rawValue: 1 << 2)
        /// Adjust the last data modification timestamp to the time of clock `clockid::realtime`.
        static let MTIM_NOW = FstFlags(rawValue: 1 << 3)
    }

    struct LookupFlags: OptionSet, GuestPrimitivePointee {
        let rawValue: UInt32

        /// As long as the resolved path corresponds to a symbolic link, it is expanded.
        static let SYMLINK_FOLLOW = LookupFlags(rawValue: 1 << 0)
    }

    struct Oflags: OptionSet, GuestPrimitivePointee {
        let rawValue: UInt32

        /// Create file if it does not exist.
        static let CREAT = Oflags(rawValue: 1 << 0)
        /// Fail if not a directory.
        static let DIRECTORY = Oflags(rawValue: 1 << 1)
        /// Fail if file already exists.
        static let EXCL = Oflags(rawValue: 1 << 2)
        /// Truncate file to size 0.
        static let TRUNC = Oflags(rawValue: 1 << 3)
    }

    /// Number of hard links to an inode.
    typealias LinkCount = UInt64

    /// File attributes.
    struct Filestat: GuestPrimitivePointee {
        /// Device ID of device containing the file.
        let dev: Device
        /// File serial number.
        let ino: Inode
        /// File type.
        let filetype: FileType
        /// Number of hard links to the file.
        let nlink: LinkCount
        /// For regular files, the file size in bytes. For symbolic links, the length in bytes of the pathname contained in the symbolic link.
        let size: FileSize
        /// Last data access timestamp.
        let atim: Timestamp
        /// Last data modification timestamp.
        let mtim: Timestamp
        /// Last file status change timestamp.
        let ctim: Timestamp

        static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> WASIAbi.Filestat {
            var pointer = pointer
            return Filestat(
                dev: .readFromGuest(&pointer), ino: .readFromGuest(&pointer),
                filetype: .readFromGuest(&pointer), nlink: .readFromGuest(&pointer),
                size: .readFromGuest(&pointer), atim: .readFromGuest(&pointer),
                mtim: .readFromGuest(&pointer), ctim: .readFromGuest(&pointer)
            )
        }

        static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: WASIAbi.Filestat) {
            var pointer = pointer
            Device.writeToGuest(at: &pointer, value: value.dev)
            Inode.writeToGuest(at: &pointer, value: value.ino)
            FileType.writeToGuest(at: &pointer, value: value.filetype)
            LinkCount.writeToGuest(at: &pointer, value: value.nlink)
            FileSize.writeToGuest(at: &pointer, value: value.size)
            Timestamp.writeToGuest(at: &pointer, value: value.atim)
            Timestamp.writeToGuest(at: &pointer, value: value.mtim)
            Timestamp.writeToGuest(at: &pointer, value: value.ctim)
        }
    }

    typealias PrestatDir = Size

    enum Prestat: GuestPointee {
        case dir(PrestatDir)
        static var sizeInGuest: UInt32 { 8 }
        static var alignInGuest: UInt32 { 4 }

        static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> WASIAbi.Prestat {
            var pointer = pointer
            switch UInt8.readFromGuest(&pointer) {
            case 0:
                return .dir(.readFromGuest(&pointer))
            default: fatalError()
            }
        }

        static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: WASIAbi.Prestat) {
            var pointer = pointer
            switch value {
            case .dir(let dir):
                UInt8.writeToGuest(at: &pointer, value: 0)
                PrestatDir.writeToGuest(at: &pointer, value: dir)
            }
        }
    }
}

public struct WASIError: Error, CustomStringConvertible {
    public let description: String

    public init(description: String) {
        self.description = description
    }
}

public struct WASIExitCode: Error {
    public let code: UInt32
}

public struct WASIHostFunction {
    public let type: FunctionType
    public let implementation: (GuestMemory, [Value]) throws -> [Value]
}

public struct WASIHostModule {
    public let functions: [String: WASIHostFunction]
}

extension WASI {
    var _hostModules: [String: WASIHostModule] {
        let unimplementedFunctionTypes: [String: FunctionType] = [
            "poll_oneoff": .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32]),
            "proc_raise": .init(parameters: [.i32], results: [.i32]),
            "sched_yield": .init(parameters: [], results: [.i32]),
            "sock_accept": .init(parameters: [.i32, .i32, .i32], results: [.i32]),
            "sock_recv": .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32]),
            "sock_send": .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32]),
            "sock_shutdown": .init(parameters: [.i32, .i32], results: [.i32]),

        ]

        var preview1: [String: WASIHostFunction] = unimplementedFunctionTypes.reduce(into: [:]) { functions, entry in
            let (name, type) = entry
            functions[name] = WASIHostFunction(type: type) { _, _ in
                print("\"\(name)\" not implemented yet")
                return [.i32(WASIAbi.Errno.ENOSYS.rawValue)]
            }
        }

        func withMemoryBuffer<T>(
            caller: GuestMemory,
            body: (GuestMemory) throws -> T
        ) throws -> T {
            return try body(caller)
        }

        func readString(pointer: UInt32, length: UInt32, buffer: GuestMemory) throws -> String {
            let pointer = UnsafeGuestBufferPointer<UInt8>(
                baseAddress: UnsafeGuestPointer(memorySpace: buffer, offset: pointer),
                count: length
            )
            return try pointer.withHostPointer { hostBuffer in
                guard let baseAddress = hostBuffer.baseAddress,
                    memchr(baseAddress, 0x00, Int(pointer.count)) == nil
                else {
                    // If byte sequence contains null byte in the middle, it's illegal string
                    // TODO: This restriction should be only applied to strings that can be interpreted as platform-string, which is expected to be null-terminated
                    throw WASIAbi.Errno.EILSEQ
                }
                return String(decoding: hostBuffer, as: UTF8.self)
            }
        }

        func wasiFunction(type: FunctionType, implementation: @escaping (GuestMemory, [Value]) throws -> [Value]) -> WASIHostFunction {
            return WASIHostFunction(type: type) { caller, arguments in
                do {
                    return try implementation(caller, arguments)
                } catch let errno as WASIAbi.Errno {
                    return [.i32(errno.rawValue)]
                }
            }
        }

        preview1["args_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                self.args_get(
                    argv: .init(memorySpace: buffer, offset: arguments[0].i32),
                    argvBuffer: .init(memorySpace: buffer, offset: arguments[1].i32)
                )
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["args_sizes_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let (argc, bufferSize) = self.args_sizes_get()
                let argcPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[0].i32)
                argcPointer.pointee = argc
                let bufferSizePointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[1].i32)
                bufferSizePointer.pointee = bufferSize
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["environ_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                self.environ_get(
                    environ: .init(memorySpace: buffer, offset: arguments[0].i32),
                    environBuffer: .init(memorySpace: buffer, offset: arguments[1].i32)
                )
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["environ_sizes_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let (environSize, bufferSize) = self.environ_sizes_get()
                let environSizePointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[0].i32)
                environSizePointer.pointee = environSize
                let bufferSizePointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[1].i32)
                bufferSizePointer.pointee = bufferSize
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["clock_res_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            guard let id = WASIAbi.ClockId(rawValue: arguments[0].i32) else {
                throw WASIAbi.Errno.EBADF
            }
            let res = try self.clock_res_get(id: id)
            try withMemoryBuffer(caller: caller) { buffer in
                let resPointer = UnsafeGuestPointer<WASIAbi.Timestamp>(
                    memorySpace: buffer, offset: arguments[1].i32
                )
                resPointer.pointee = res
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["clock_time_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let id = WASIAbi.ClockId(rawValue: arguments[0].i32) else {
                throw WASIAbi.Errno.EBADF
            }
            let time = try self.clock_time_get(id: id, precision: WASIAbi.Timestamp(arguments[1].i64))
            try withMemoryBuffer(caller: caller) { buffer in
                let resPointer = UnsafeGuestPointer<WASIAbi.Timestamp>(
                    memorySpace: buffer, offset: arguments[2].i32
                )
                resPointer.pointee = time
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_advise"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawAdvice = UInt8(exactly: arguments[3].i32),
                let advice = WASIAbi.Advice(rawValue: rawAdvice)
            else {
                throw WASIAbi.Errno.EINVAL
            }
            try self.fd_advise(
                fd: arguments[0].i32, offset: arguments[1].i64,
                length: arguments[2].i64, advice: advice
            )
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_allocate"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64], results: [.i32])
        ) { caller, arguments in
            try self.fd_allocate(
                fd: arguments[0].i32, offset: arguments[1].i64, length: arguments[2].i64
            )
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_close"] = wasiFunction(
            type: .init(parameters: [.i32], results: [.i32])
        ) { caller, arguments in
            try self.fd_close(fd: arguments[0].i32)
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_datasync"] = wasiFunction(
            type: .init(parameters: [.i32], results: [.i32])
        ) { caller, arguments in
            try self.fd_datasync(fd: arguments[0].i32)
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_fdstat_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let stat = try self.fd_fdstat_get(fileDescriptor: arguments[0].i32)
                let statPointer = UnsafeGuestPointer<WASIAbi.FdStat>(memorySpace: buffer, offset: arguments[1].i32)
                statPointer.pointee = stat
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["fd_fdstat_set_flags"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawFdFlags = UInt16(exactly: arguments[1].i32) else {
                throw WASIAbi.Errno.EINVAL
            }
            try self.fd_fdstat_set_flags(
                fd: arguments[0].i32, flags: WASIAbi.Fdflags(rawValue: rawFdFlags)
            )
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_fdstat_set_rights"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64], results: [.i32])
        ) { caller, arguments in
            try self.fd_fdstat_set_rights(
                fd: arguments[0].i32,
                fsRightsBase: WASIAbi.Rights(rawValue: arguments[1].i64),
                fsRightsInheriting: WASIAbi.Rights(rawValue: arguments[2].i64)
            )
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_filestat_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let filestat = try self.fd_filestat_get(fd: arguments[0].i32)
                let filestatPointer = UnsafeGuestPointer<WASIAbi.Filestat>(memorySpace: buffer, offset: arguments[1].i32)
                filestatPointer.pointee = filestat
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_filestat_set_size"] = wasiFunction(
            type: .init(parameters: [.i32, .i64], results: [.i32])
        ) { caller, arguments in
            try self.fd_filestat_set_size(fd: arguments[0].i32, size: arguments[1].i64)
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_filestat_set_times"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawFstFlags = UInt16(exactly: arguments[3].i32) else {
                throw WASIAbi.Errno.EINVAL
            }
            try self.fd_filestat_set_times(
                fd: arguments[0].i32,
                atim: arguments[1].i64, mtim: arguments[2].i64,
                fstFlags: WASIAbi.FstFlags(rawValue: rawFstFlags)
            )
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_pread"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nread = try self.fd_pread(
                    fd: arguments[0].i32,
                    iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(memorySpace: buffer, offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    offset: arguments[3].i64
                )
                let nreadPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[4].i32)
                nreadPointer.pointee = nread
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }
        preview1["fd_prestat_get"] = wasiFunction(type: .init(parameters: [.i32, .i32], results: [.i32])) { caller, arguments in
            let prestat = try self.fd_prestat_get(fd: arguments[0].i32)
            try withMemoryBuffer(caller: caller) { buffer in
                let prestatPointer = UnsafeGuestPointer<WASIAbi.Prestat>(memorySpace: buffer, offset: arguments[1].i32)
                prestatPointer.pointee = prestat
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_prestat_dir_name"] = wasiFunction(type: .init(parameters: [.i32, .i32, .i32], results: [.i32])) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.fd_prestat_dir_name(
                    fd: arguments[0].i32,
                    path: UnsafeGuestPointer(memorySpace: buffer, offset: arguments[1].i32),
                    maxPathLength: arguments[2].i32
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_pwrite"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nwritten = try self.fd_pwrite(
                    fd: arguments[0].i32,
                    iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(memorySpace: buffer, offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    offset: arguments[3].i64
                )
                let nwrittenPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[4].i32)
                nwrittenPointer.pointee = nwritten
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_read"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nread = try self.fd_read(
                    fd: arguments[0].i32,
                    iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(memorySpace: buffer, offset: arguments[1].i32),
                        count: arguments[2].i32
                    )
                )
                let nreadPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[3].i32)
                nreadPointer.pointee = nread
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_readdir"] = wasiFunction(type: .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nwritten = try self.fd_readdir(
                    fd: arguments[0].i32,
                    buffer: UnsafeGuestBufferPointer<UInt8>(
                        baseAddress: UnsafeGuestPointer<UInt8>(memorySpace: buffer, offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    cookie: arguments[3].i64
                )
                let nwrittenPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[4].i32)
                nwrittenPointer.pointee = nwritten
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["fd_renumber"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try self.fd_renumber(fd: arguments[0].i32, to: arguments[1].i32)
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_seek"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            guard let whence = WASIAbi.Whence(rawValue: UInt8(arguments[2].i32)) else {
                return [.i32(WASIAbi.Errno.EINVAL.rawValue)]
            }
            let ret = try self.fd_seek(
                fd: arguments[0].i32, offset: WASIAbi.FileDelta(bitPattern: arguments[1].i64), whence: whence
            )
            try withMemoryBuffer(caller: caller) { buffer in
                let retPointer = UnsafeGuestPointer<WASIAbi.FileSize>(memorySpace: buffer, offset: arguments[3].i32)
                retPointer.pointee = ret
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_sync"] = wasiFunction(type: .init(parameters: [.i32], results: [.i32])) { caller, arguments in
            try self.fd_sync(fd: arguments[0].i32)
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_tell"] = wasiFunction(type: .init(parameters: [.i32, .i32], results: [.i32])) { caller, arguments in
            let ret = try self.fd_tell(fd: arguments[0].i32)
            try withMemoryBuffer(caller: caller) { buffer in
                let retPointer = UnsafeGuestPointer<WASIAbi.FileSize>(memorySpace: buffer, offset: arguments[1].i32)
                retPointer.pointee = ret
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["fd_write"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nwritten = try self.fd_write(
                    fileDescriptor: arguments[0].i32,
                    ioVectors: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(memorySpace: buffer, offset: arguments[1].i32),
                        count: arguments[2].i32
                    )
                )
                let nwrittenPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[3].i32)
                nwrittenPointer.pointee = nwritten
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["path_create_directory"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_create_directory(
                    dirFd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }
        preview1["path_filestat_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let filestat = try self.path_filestat_get(
                    dirFd: arguments[0].i32, flags: .init(rawValue: arguments[1].i32),
                    path: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer)
                )
                let filestatPointer = UnsafeGuestPointer<WASIAbi.Filestat>(memorySpace: buffer, offset: arguments[4].i32)
                filestatPointer.pointee = filestat
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_filestat_set_times"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i64, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawFstFlags = UInt16(exactly: arguments[6].i32) else {
                throw WASIAbi.Errno.EINVAL
            }
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_filestat_set_times(
                    dirFd: arguments[0].i32, flags: .init(rawValue: arguments[1].i32),
                    path: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer),
                    atim: arguments[4].i64, mtim: arguments[5].i64,
                    fstFlags: WASIAbi.FstFlags(rawValue: rawFstFlags)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_link"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_link(
                    oldFd: arguments[0].i32, oldFlags: .init(rawValue: arguments[1].i32),
                    oldPath: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer),
                    newFd: arguments[4].i32,
                    newPath: readString(pointer: arguments[5].i32, length: arguments[6].i32, buffer: buffer)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_open"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i64, .i64, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let newFd = try self.path_open(
                    dirFd: arguments[0].i32,
                    dirFlags: .init(rawValue: arguments[1].i32),
                    path: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer),
                    oflags: .init(rawValue: arguments[4].i32),
                    fsRightsBase: .init(rawValue: arguments[5].i64),
                    fsRightsInheriting: .init(rawValue: arguments[6].i64),
                    fdflags: .init(rawValue: UInt16(arguments[7].i32))
                )
                let newFdPointer = UnsafeGuestPointer<WASIAbi.Fd>(memorySpace: buffer, offset: arguments[8].i32)
                newFdPointer.pointee = newFd
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        preview1["path_readlink"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let ret = try self.path_readlink(
                    fd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer),
                    buffer: UnsafeGuestBufferPointer<UInt8>(
                        baseAddress: .init(memorySpace: buffer, offset: arguments[3].i32),
                        count: arguments[4].i32
                    )
                )
                let retPointer = UnsafeGuestPointer<WASIAbi.Size>(memorySpace: buffer, offset: arguments[5].i32)
                retPointer.pointee = ret
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_remove_directory"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_remove_directory(
                    dirFd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_rename"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_rename(
                    oldFd: arguments[0].i32,
                    oldPath: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer),
                    newFd: arguments[3].i32,
                    newPath: readString(pointer: arguments[4].i32, length: arguments[5].i32, buffer: buffer)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_symlink"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_symlink(
                    oldPath: readString(pointer: arguments[0].i32, length: arguments[1].i32, buffer: buffer),
                    dirFd: arguments[2].i32,
                    newPath: readString(pointer: arguments[3].i32, length: arguments[4].i32, buffer: buffer)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["path_unlink_file"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_unlink_file(
                    dirFd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer)
                )
            }
            return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
        }

        preview1["proc_exit"] = wasiFunction(type: .init(parameters: [.i32])) { memory, arguments in
            let exitCode = arguments[0].i32
            throw WASIExitCode(code: exitCode)
        }

        preview1["random_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                self.random_get(
                    buffer: UnsafeGuestPointer<UInt8>(memorySpace: buffer, offset: arguments[0].i32),
                    length: arguments[1].i32
                )
                return [.i32(WASIAbi.Errno.SUCCESS.rawValue)]
            }
        }

        return [
            "wasi_snapshot_preview1": WASIHostModule(functions: preview1)
        ]
    }
}

public class WASIBridgeToHost: WASI {
    private let args: [String]
    private let environment: [String: String]
    private var fdTable: FdTable
    private let wallClock: WallClock
    private let monotonicClock: MonotonicClock
    private var randomGenerator: RandomBufferGenerator

    public init(
        args: [String] = [],
        environment: [String: String] = [:],
        preopens: [String: String] = [:],
        stdin: FileDescriptor = .standardInput,
        stdout: FileDescriptor = .standardOutput,
        stderr: FileDescriptor = .standardError,
        wallClock: WallClock = SystemWallClock(),
        monotonicClock: MonotonicClock = SystemMonotonicClock(),
        randomGenerator: RandomBufferGenerator = SystemRandomNumberGenerator()
    ) throws {
        self.args = args
        self.environment = environment
        var fdTable = FdTable()
        fdTable[0] = .file(StdioFileEntry(fd: stdin, accessMode: .read))
        fdTable[1] = .file(StdioFileEntry(fd: stdout, accessMode: .write))
        fdTable[2] = .file(StdioFileEntry(fd: stderr, accessMode: .write))

        for (guestPath, hostPath) in preopens {
            #if os(Windows)
                let fd = try FileDescriptor.open(FilePath(hostPath), .readWrite)
            #else
                let fd = try hostPath.withCString { cHostPath in
                    let fd = open(cHostPath, O_DIRECTORY)
                    if fd < 0 {
                        let errno = errno
                        throw WASIError(description: "Failed to open preopen path '\(hostPath)': \(String(cString: strerror(errno)))")
                    }
                    return FileDescriptor(rawValue: fd)
                }
            #endif

            if try fd.attributes().fileType.isDirectory {
                _ = try fdTable.push(.directory(DirEntry(preopenPath: guestPath, fd: fd)))
            }
        }
        self.fdTable = fdTable
        self.wallClock = wallClock
        self.monotonicClock = monotonicClock
        self.randomGenerator = randomGenerator
    }

    public var wasiHostModules: [String: WASIHostModule] { _hostModules }

    func args_get(
        argv: UnsafeGuestPointer<UnsafeGuestPointer<UInt8>>,
        argvBuffer: UnsafeGuestPointer<UInt8>
    ) {
        var offsets = argv
        var buffer = argvBuffer
        for arg in args {
            offsets.pointee = buffer
            offsets += 1
            let count = arg.utf8CString.withUnsafeBytes { bytes in
                let count = UInt32(bytes.count)
                buffer.raw.withHostPointer(count: bytes.count) { hostDestBuffer in
                    hostDestBuffer.copyMemory(from: bytes)
                }
                return count
            }
            buffer += count
        }
    }

    func args_sizes_get() -> (WASIAbi.Size, WASIAbi.Size) {
        let bufferSize = args.reduce(0) {
            // `utf8CString` returns null-terminated bytes and WASI also expect it
            $0 + $1.utf8CString.count
        }
        return (WASIAbi.Size(args.count), WASIAbi.Size(bufferSize))
    }

    func environ_get(environ: UnsafeGuestPointer<UnsafeGuestPointer<UInt8>>, environBuffer: UnsafeGuestPointer<UInt8>) {
        var offsets = environ
        var buffer = environBuffer
        for (key, value) in environment {
            offsets.pointee = buffer
            offsets += 1
            let count = "\(key)=\(value)".utf8CString.withUnsafeBytes { bytes in
                let count = UInt32(bytes.count)
                buffer.raw.withHostPointer(count: bytes.count) { hostDestBuffer in
                    hostDestBuffer.copyMemory(from: bytes)
                }
                return count
            }
            buffer += count
        }
    }

    func environ_sizes_get() -> (WASIAbi.Size, WASIAbi.Size) {
        let bufferSize = environment.reduce(0) {
            // `utf8CString` returns null-terminated bytes and WASI also expect it
            $0 + $1.key.utf8CString.count /* = */ + 1 + $1.value.utf8CString.count
        }
        return (WASIAbi.Size(environment.count), WASIAbi.Size(bufferSize))
    }

    func clock_res_get(id: WASIAbi.ClockId) throws -> WASIAbi.Timestamp {
        switch id {
        case .REALTIME:
            return WASIAbi.Timestamp(wallClockDuration: try wallClock.resolution())
        case .MONOTONIC:
            return try monotonicClock.resolution()
        case .PROCESS_CPUTIME_ID, .THREAD_CPUTIME_ID:
            throw WASIAbi.Errno.EBADF
        }
    }

    func clock_time_get(
        id: WASIAbi.ClockId, precision: WASIAbi.Timestamp
    ) throws -> WASIAbi.Timestamp {
        switch id {
        case .REALTIME:
            return WASIAbi.Timestamp(wallClockDuration: try wallClock.now())
        case .MONOTONIC:
            return try monotonicClock.now()
        case .PROCESS_CPUTIME_ID, .THREAD_CPUTIME_ID:
            throw WASIAbi.Errno.EBADF
        }
    }

    func fd_advise(fd: WASIAbi.Fd, offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice) throws {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        try fileEntry.advise(offset: offset, length: length, advice: advice)
    }

    func fd_allocate(fd: WASIAbi.Fd, offset: WASIAbi.FileSize, length: WASIAbi.FileSize) throws {
        guard fdTable[fd] != nil else {
            throw WASIAbi.Errno.EBADF
        }
        // This operation has been removed in preview 2 and is not supported across all linux
        // filesystems, and has no support on macos or windows, so just return ENOTSUP now.
        throw WASIAbi.Errno.ENOTSUP
    }

    func fd_close(fd: WASIAbi.Fd) throws {
        guard let entry = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        fdTable[fd] = nil
        try entry.asEntry().close()
    }

    func fd_datasync(fd: WASIAbi.Fd) throws {
        throw WASIAbi.Errno.ENOTSUP
    }

    func fd_fdstat_get(fileDescriptor: UInt32) throws -> WASIAbi.FdStat {
        let entry = self.fdTable[fileDescriptor]
        switch entry {
        case let .file(entry):
            return try entry.fdStat()
        case .directory:
            return WASIAbi.FdStat(
                fsFileType: .DIRECTORY,
                fsFlags: [],
                fsRightsBase: .DIRECTORY_BASE_RIGHTS,
                fsRightsInheriting: .DIRECTORY_INHERITING_RIGHTS
            )
        case .none:
            throw WASIAbi.Errno.EBADF
        }
    }

    func fd_fdstat_set_flags(fd: WASIAbi.Fd, flags: WASIAbi.Fdflags) throws {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        try fileEntry.setFdStatFlags(flags)
    }

    func fd_fdstat_set_rights(
        fd: WASIAbi.Fd,
        fsRightsBase: WASIAbi.Rights,
        fsRightsInheriting: WASIAbi.Rights
    ) throws {
        throw WASIAbi.Errno.ENOTSUP
    }

    func fd_filestat_get(fd: WASIAbi.Fd) throws -> WASIAbi.Filestat {
        guard let entry = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try entry.asEntry().attributes()
    }

    func fd_filestat_set_size(fd: WASIAbi.Fd, size: WASIAbi.FileSize) throws {
        guard case let .file(entry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try entry.setFilestatSize(size)
    }

    func fd_filestat_set_times(
        fd: WASIAbi.Fd, atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        guard let entry = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        try entry.asEntry().setTimes(atim: atim, mtim: mtim, fstFlags: fstFlags)
    }

    func fd_pread(
        fd: WASIAbi.Fd, iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>,
        offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileEntry.pread(into: iovs, offset: offset)
    }

    func fd_prestat_get(fd: WASIAbi.Fd) throws -> WASIAbi.Prestat {
        guard case let .directory(entry) = fdTable[fd],
            let preopenPath = entry.preopenPath
        else {
            throw WASIAbi.Errno.EBADF
        }
        return .dir(WASIAbi.PrestatDir(preopenPath.utf8.count))
    }

    func fd_prestat_dir_name(fd: WASIAbi.Fd, path: UnsafeGuestPointer<UInt8>, maxPathLength: WASIAbi.Size) throws {
        guard case let .directory(entry) = fdTable[fd],
            var preopenPath = entry.preopenPath
        else {
            throw WASIAbi.Errno.EBADF
        }

        try preopenPath.withUTF8 { bytes in
            guard bytes.count <= maxPathLength else {
                throw WASIAbi.Errno.ENAMETOOLONG
            }
            path.withHostPointer(count: Int(maxPathLength)) { buffer in
                UnsafeMutableRawBufferPointer(buffer).copyBytes(from: bytes)
            }
        }
    }

    func fd_pwrite(
        fd: WASIAbi.Fd, iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>,
        offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileEntry.pwrite(vectored: iovs, offset: offset)
    }

    func fd_read(
        fd: WASIAbi.Fd,
        iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>
    ) throws -> WASIAbi.Size {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileEntry.read(into: iovs)
    }

    func fd_readdir(
        fd: WASIAbi.Fd,
        buffer: UnsafeGuestBufferPointer<UInt8>,
        cookie: WASIAbi.DirCookie
    ) throws -> WASIAbi.Size {
        guard case let .directory(dirEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }

        let entries = try dirEntry.readEntries(cookie: cookie)
        var bufferUsed: WASIAbi.Size = 0
        let totalBufferSize = buffer.count
        while let result = entries.next() {
            var (entry, name) = try result.get()
            do {
                // 1. Copy dirent to the buffer
                // Copy dirent as much as possible even though the buffer doesn't have enough remaining space
                let copyingBytes = min(WASIAbi.Dirent.sizeInGuest, totalBufferSize - bufferUsed)
                let rangeStart = buffer.baseAddress.raw.advanced(by: bufferUsed)
                let rangeEnd = rangeStart.advanced(by: copyingBytes)
                WASIAbi.Dirent.writeToGuest(unalignedAt: rangeStart, end: rangeEnd, value: entry)
                bufferUsed += copyingBytes

                // bail out if the remaining buffer space is not enough
                if copyingBytes < WASIAbi.Dirent.sizeInGuest {
                    return totalBufferSize
                }
            }

            do {
                // 2. Copy name string to the buffer
                // Same truncation rule applied as above
                let copyingBytes = min(entry.dirNameLen, totalBufferSize - bufferUsed)
                let rangeStart = buffer.baseAddress.raw.advanced(by: bufferUsed)
                name.withUTF8 { bytes in
                    rangeStart.withHostPointer(count: Int(copyingBytes)) { hostBuffer in
                        hostBuffer.copyMemory(
                            from: UnsafeRawBufferPointer(start: bytes.baseAddress, count: Int(copyingBytes))
                        )
                    }
                }
                bufferUsed += copyingBytes

                // bail out if the remaining buffer space is not enough
                if copyingBytes < entry.dirNameLen {
                    return totalBufferSize
                }
            }
        }
        return bufferUsed
    }

    func fd_renumber(fd: WASIAbi.Fd, to toFd: WASIAbi.Fd) throws {
        throw WASIAbi.Errno.ENOTSUP
    }

    func fd_seek(fd: WASIAbi.Fd, offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileEntry.seek(offset: offset, whence: whence)
    }

    func fd_sync(fd: WASIAbi.Fd) throws {
        throw WASIAbi.Errno.ENOTSUP
    }

    func fd_tell(fd: WASIAbi.Fd) throws -> WASIAbi.FileSize {
        guard case let .file(fileEntry) = fdTable[fd] else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileEntry.tell()
    }

    func fd_write(
        fileDescriptor: WASIAbi.Fd,
        ioVectors: UnsafeGuestBufferPointer<WASIAbi.IOVec>
    ) throws -> UInt32 {
        guard case let .file(entry) = self.fdTable[fileDescriptor] else {
            throw WASIAbi.Errno.EBADF
        }
        return try entry.write(vectored: ioVectors)
    }

    func path_create_directory(dirFd: WASIAbi.Fd, path: String) throws {
        guard case let .directory(dirEntry) = fdTable[dirFd] else {
            throw WASIAbi.Errno.ENOTDIR
        }
        try dirEntry.createDirectory(atPath: path)
    }

    func path_filestat_get(
        dirFd: WASIAbi.Fd, flags: WASIAbi.LookupFlags, path: String
    ) throws -> WASIAbi.Filestat {
        guard case let .directory(dirEntry) = fdTable[dirFd] else {
            throw WASIAbi.Errno.ENOTDIR
        }
        return try dirEntry.attributes(
            path: path, symlinkFollow: flags.contains(.SYMLINK_FOLLOW)
        )
    }

    func path_filestat_set_times(
        dirFd: WASIAbi.Fd, flags: WASIAbi.LookupFlags,
        path: String, atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        guard case let .directory(dirEntry) = fdTable[dirFd] else {
            throw WASIAbi.Errno.ENOTDIR
        }
        try dirEntry.setFilestatTimes(
            path: path, atim: atim, mtim: mtim,
            fstFlags: fstFlags,
            symlinkFollow: flags.contains(.SYMLINK_FOLLOW)
        )
    }

    func path_link(
        oldFd: WASIAbi.Fd, oldFlags: WASIAbi.LookupFlags, oldPath: String,
        newFd: WASIAbi.Fd, newPath: String
    ) throws {
        throw WASIAbi.Errno.ENOTSUP
    }

    func path_open(
        dirFd: WASIAbi.Fd,
        dirFlags: WASIAbi.LookupFlags,
        path: String,
        oflags: WASIAbi.Oflags,
        fsRightsBase: WASIAbi.Rights,
        fsRightsInheriting: WASIAbi.Rights,
        fdflags: WASIAbi.Fdflags
    ) throws -> WASIAbi.Fd {
        #if os(Windows)
            throw WASIAbi.Errno.ENOTSUP
        #else
            guard case let .directory(dirEntry) = fdTable[dirFd] else {
                throw WASIAbi.Errno.ENOTDIR
            }
            var accessMode: FileAccessMode = []
            if fsRightsBase.contains(.FD_READ) {
                accessMode.insert(.read)
            }
            if fsRightsBase.contains(.FD_WRITE) {
                accessMode.insert(.write)
            }
            let hostFd = try dirEntry.openFile(
                symlinkFollow: dirFlags.contains(.SYMLINK_FOLLOW),
                path: path, oflags: oflags, accessMode: accessMode,
                fdflags: fdflags
            )

            let actualFileType = try hostFd.attributes().fileType
            if oflags.contains(.DIRECTORY), actualFileType != .directory {
                // Check O_DIRECTORY validity just in case when the host system
                // doesn't respects O_DIRECTORY.
                throw WASIAbi.Errno.ENOTDIR
            }

            let newEntry: FdEntry
            if actualFileType == .directory {
                newEntry = .directory(DirEntry(preopenPath: nil, fd: hostFd))
            } else {
                newEntry = .file(RegularFileEntry(fd: hostFd, accessMode: accessMode))
            }
            let guestFd = try fdTable.push(newEntry)
            return guestFd
        #endif
    }

    func path_readlink(fd: WASIAbi.Fd, path: String, buffer: UnsafeGuestBufferPointer<UInt8>) throws -> WASIAbi.Size {
        throw WASIAbi.Errno.ENOTSUP
    }

    func path_remove_directory(dirFd: WASIAbi.Fd, path: String) throws {
        guard case let .directory(dirEntry) = fdTable[dirFd] else {
            throw WASIAbi.Errno.ENOTDIR
        }
        try dirEntry.removeDirectory(atPath: path)
    }

    func path_rename(
        oldFd: WASIAbi.Fd, oldPath: String,
        newFd: WASIAbi.Fd, newPath: String
    ) throws {
        throw WASIAbi.Errno.ENOTSUP
    }

    func path_symlink(oldPath: String, dirFd: WASIAbi.Fd, newPath: String) throws {
        guard case let .directory(dirEntry) = fdTable[dirFd] else {
            throw WASIAbi.Errno.ENOTDIR
        }
        try dirEntry.symlink(from: oldPath, to: newPath)
    }

    func path_unlink_file(dirFd: WASIAbi.Fd, path: String) throws {
        guard case let .directory(dirEntry) = fdTable[dirFd] else {
            throw WASIAbi.Errno.ENOTDIR
        }
        try dirEntry.removeFile(atPath: path)
    }

    func poll_oneoff(
        subscriptions: UnsafeGuestRawPointer,
        events: UnsafeGuestRawPointer,
        numberOfSubscriptions: WASIAbi.Size
    ) throws -> WASIAbi.Size {
        throw WASIAbi.Errno.ENOTSUP
    }

    func random_get(buffer: UnsafeGuestPointer<UInt8>, length: WASIAbi.Size) {
        guard length > 0 else { return }
        buffer.withHostPointer(count: Int(length)) {
            self.randomGenerator.fill(buffer: $0)
        }
    }
}
