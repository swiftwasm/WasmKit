import WasmTypes

/// The requested access mode for an opened file.
@_spi(WASIPlatform) public struct FileAccessMode: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let read = FileAccessMode(rawValue: 1)
    public static let write = FileAccessMode(rawValue: 1 << 1)
}

/// A resource installed in the WASI file descriptor table.
///
/// This protocol (and its refinements ``WASIFile``/``WASIDir``) is the
/// platform-independent boundary of the WASI host implementation: all
/// requirements are expressed in `WASIAbi` types, so implementations can be
/// backed by anything from host file descriptors to in-memory data or
/// device drivers on embedded systems. Implementations report failures by
/// throwing `WASIAbi.Errno`.
@_spi(WASIPlatform) public protocol WASIEntry: Sendable {
    /// Whether this entry wraps a borrowed file descriptor that should not be
    /// closed when the WASI instance is torn down (e.g. process stdio).
    var isBorrowed: Bool { get }
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

extension WASIEntry {
    @_spi(WASIPlatform) public var isBorrowed: Bool { false }
}

/// A file-like resource (regular file, stdio stream, device, ...) exposed
/// to WASI guests.
@_spi(WASIPlatform) public protocol WASIFile: WASIEntry {
    func fdStat() throws -> WASIAbi.FdStat
    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws
    func setFilestatSize(_ size: WASIAbi.FileSize) throws
    func sync() throws
    func datasync() throws

    func tell() throws -> WASIAbi.FileSize
    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize

    func write<M: GuestMemory, Buffer: Sequence>(
        vectored buffer: Buffer, memory: M
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
    func pwrite<M: GuestMemory, Buffer: Sequence>(
        vectored buffer: Buffer, memory: M, offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
    func read<M: GuestMemory, Buffer: Sequence>(
        into buffer: Buffer, memory: M
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
    func pread<M: GuestMemory, Buffer: Sequence>(
        into buffer: Buffer, memory: M, offset: WASIAbi.FileSize
    ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec
}

/// A directory-like resource exposed to WASI guests.
@_spi(WASIPlatform) public protocol WASIDir: WASIEntry {
    typealias ReaddirElement = (dirent: WASIAbi.Dirent, name: String)
    associatedtype ReadEntriesResult: WASIReaddirIterator where ReadEntriesResult.Element == ReaddirElement

    var preopenPath: String? { get }

    func readlink(atPath path: String) throws -> [UInt8]

    func createDirectory(atPath path: String) throws
    func removeDirectory(atPath path: String) throws
    func removeFile(atPath path: String) throws
    func symlink(from sourcePath: String, to destPath: String) throws
    func rename(from sourcePath: String, toDir newDir: any WASIDir, to destPath: String) throws
    func readEntries(cookie: WASIAbi.DirCookie) throws -> ReadEntriesResult
    func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat
    func setFilestatTimes(
        path: String,
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
    ) throws
}

/// An iterator over directory entries produced by ``WASIDir/readEntries(cookie:)``.
@_spi(WASIPlatform) public protocol WASIReaddirIterator {
    associatedtype Element
    mutating func next() -> Result<Element, any Error>?
    /// Closes the iterator and releases any owned resources.
    ///
    /// Callers must invoke this exactly once after iteration completes.
    mutating func close()
}

/// A file descriptor table entry: either a file or a directory resource.
@_spi(WASIPlatform) public enum FdEntry: Sendable {
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

    func asFile() -> (any WASIFile)? {
        if case .file(let entry) = self {
            return entry
        }
        return nil
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

    /// Whether another descriptor can be installed, i.e. the table is below capacity.
    var hasCapacity: Bool {
        map.count < WASIAbi.Fd.max
    }

    /// Inserts an entry and returns the corresponding file descriptor
    mutating func push(_ entry: FdEntry) throws -> WASIAbi.Fd {
        guard hasCapacity else {
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

    /// Closes all owned file descriptors, skipping borrowed ones (e.g. stdio).
    mutating func closeAll() throws {
        var firstError: (any Error)?
        for (_, entry) in map {
            let wasiEntry = entry.asEntry()
            guard !wasiEntry.isBorrowed else { continue }
            do {
                try wasiEntry.close()
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        map = map.filter { $0.value.asEntry().isBorrowed }
        if let firstError { throw firstError }
    }
}

/// Content of a file that can be retrieved from the file system.
public enum FileContent: Sendable {
    case bytes([UInt8])
    /// A caller-owned platform file descriptor. The file system borrows it:
    /// the caller is responsible for keeping it valid and closing it.
    case handle(CInt)
}

/// Protocol for file system implementations used by WASI.
///
/// The built-in implementations are ``MemoryFileSystem`` and the host file
/// system used by `FileSystemOptions.host()`. Custom implementations can be
/// injected with `FileSystemOptions.custom(_:)` to run WASI guests on
/// platforms without a usable host file system (e.g. embedded targets).
/// All requirements are expressed in `WASIAbi` and standard Swift types;
/// implementations report failures by throwing `WASIAbi.Errno`.
@_spi(WASIPlatform) public protocol FileSystemImplementation: ~Copyable, Sendable {
    /// Preopens a directory and returns a WASIDir implementation.
    func preopenDirectory(guestPath: String, hostPath: String) throws -> any WASIDir

    /// Opens a file or directory from a directory file descriptor.
    func openAt(
        dirFd: any WASIDir,
        path: String,
        oflags: WASIAbi.Oflags,
        fsRightsBase: WASIAbi.Rights,
        fsRightsInheriting: WASIAbi.Rights,
        fdflags: WASIAbi.Fdflags,
        symlinkFollow: Bool
    ) throws -> FdEntry
}
