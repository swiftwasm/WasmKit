import SystemPackage

struct FileAccessMode: OptionSet {
    let rawValue: UInt32
    static let read = FileAccessMode(rawValue: 1)
    static let write = FileAccessMode(rawValue: 1 << 1)
}

protocol WASIEntry {
    func attributes() throws -> WASIAbi.Filestat
    func fileType() throws -> WASIAbi.FileType
    func status() throws -> WASIAbi.Fdflags
    func setTimes(
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws
    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws
    func close() throws
}

protocol WASIFile: WASIEntry {
    func fdStat() throws -> WASIAbi.FdStat
    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws
    func setFilestatSize(_ size: WASIAbi.FileSize) throws
    func sync() throws

    func tell() throws -> WASIAbi.FileSize
    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize

    func write<Buffer: Sequence>(
        vectored buffer: Buffer
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
    func pwrite<Buffer: Sequence>(
        vectored buffer: Buffer, offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
    func read<Buffer: Sequence>(
        into buffer: Buffer
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
    func pread<Buffer: Sequence>(
        into buffer: Buffer, offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
}

protocol WASIDir: WASIEntry {
    typealias ReaddirElement = (dirent: WASIAbi.Dirent, name: String)

    var preopenPath: String? { get }

    func openFile(
        symlinkFollow: Bool,
        path: String,
        oflags: WASIAbi.Oflags,
        accessMode: FileAccessMode,
        fdflags: WASIAbi.Fdflags
    ) throws -> FileDescriptor

    func createDirectory(atPath path: String) throws
    func removeDirectory(atPath path: String) throws
    func removeFile(atPath path: String) throws
    func symlink(from sourcePath: String, to destPath: String) throws
    func readEntries(cookie: WASIAbi.DirCookie) throws -> AnyIterator<Result<ReaddirElement, any Error>>
    func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat
    func setFilestatTimes(
        path: String,
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
    ) throws
}

enum FdEntry {
    case file(any WASIFile)
    case directory(any WASIDir)

    func asEntry() -> any WASIEntry {
        switch self {
        case .file(let entry):
            return entry
        case .directory(let directory):
            return directory
        }
    }
}

/// A table that maps file descriptor to actual resource in host environment
struct FdTable {
    private var map: [WASIAbi.Fd: FdEntry]
    private var nextFd: WASIAbi.Fd

    init() {
        self.map = [:]
        // 0, 1 and 2 are reserved for stdio
        self.nextFd = 3
    }

    /// Inserts a resource as the given file descriptor
    subscript(_ fd: WASIAbi.Fd) -> FdEntry? {
        get { self.map[fd] }
        set { self.map[fd] = newValue }
    }

    /// Inserts an entry and returns the corresponding file descriptor
    mutating func push(_ entry: FdEntry) throws -> WASIAbi.Fd {
        guard map.count < WASIAbi.Fd.max else {
            throw WASIAbi.Errno.ENFILE
        }
        // Find a free fd
        while true {
            let fd = self.nextFd
            // Wrapping to find fd again from 0 after overflow
            self.nextFd &+= 1
            if self.map[fd] != nil {
                continue
            }
            self.map[fd] = entry
            return fd
        }
    }
}
