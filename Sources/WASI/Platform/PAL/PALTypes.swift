// Platform abstraction layer for the WASI host implementation.
//
// # Design rule
//
// Every PAL declaration exists exactly once, unconditionally, for every
// platform, using platform-neutral canonical representations (enums, Unix
// epoch times, neutral option bits). `#if` platform conditionals are allowed
// only:
//
// - inside implementation *bodies*, where the trailing `#else` arm reports
//   `PlatformError.notSupported` (or is a documented no-op), and
// - around *private storage* or file-internal helpers that never appear in a
//   signature (e.g. `PALWindows.swift`).
//
// This keeps the declared surface identical everywhere: code building
// against the PAL compiles on any platform, including ones WasmKit has never
// heard of, and no per-platform mirror of the API can drift.

/// A raw platform error: the originating error namespace and its code.
/// Each origin is translated into a WASI errno exactly once, in
/// `PALErrnoMapping.swift` — never through another platform's vocabulary.
enum PlatformError: Error, Equatable, CustomStringConvertible {
    /// A POSIX/CRT errno value.
    case errno(CInt)
    /// A Win32 error code from `GetLastError()`.
    case windows(UInt32)
    /// The operation is not supported on this platform.
    case notSupported

    /// The current value of the C `errno` global.
    static var currentErrno: PlatformError { .errno(_palErrno) }

    var description: String {
        switch self {
        case .errno(let value): return _palStrerror(value)
        case .windows(let code): return "Win32 error \(code)"
        case .notSupported: return "operation not supported on this platform"
        }
    }
}

/// A point in time, in Unix epoch seconds/nanoseconds, or one of the
/// `futimens`-style sentinels. Platform time representations (`timespec`,
/// `FILETIME`) are converted at the syscall boundary only.
struct FileTime: Equatable {
    enum Representation: Equatable {
        case absolute(seconds: Int64, nanoseconds: Int64)
        case now
        case omit
    }

    let representation: Representation

    init(seconds: Int, nanoseconds: Int) {
        self.representation = .absolute(seconds: Int64(seconds), nanoseconds: Int64(nanoseconds))
    }

    private init(_ representation: Representation) {
        self.representation = representation
    }

    static var now: FileTime { FileTime(.now) }
    static var omit: FileTime { FileTime(.omit) }

    /// Seconds since the Unix epoch; 0 for the `now`/`omit` sentinels.
    var seconds: Int64 {
        guard case .absolute(let seconds, _) = representation else { return 0 }
        return seconds
    }

    /// Sub-second nanoseconds; 0 for the `now`/`omit` sentinels.
    var nanoseconds: Int64 {
        guard case .absolute(_, let nanoseconds) = representation else { return 0 }
        return nanoseconds
    }
}

extension FileDescriptor {
    /// A classification of a file, independent of any platform's `st_mode`
    /// or file-attribute encoding.
    enum FileType: Equatable {
        case directory
        case regular
        case symlink
        case characterDevice
        case blockDevice
        case socket
        case unknown

        var isDirectory: Bool { self == .directory }
        var isFile: Bool { self == .regular }
        var isSymlink: Bool { self == .symlink }
        var isCharacterDevice: Bool { self == .characterDevice }
        var isBlockDevice: Bool { self == .blockDevice }
        var isSocket: Bool { self == .socket }
    }

    /// File metadata in canonical form, materialized from the platform's
    /// `stat`/file-information structure at query time.
    struct Attributes {
        let device: UInt64
        let inode: UInt64
        let fileType: FileType
        let linkCount: UInt64
        let size: Int64
        let accessTime: FileTime
        let modificationTime: FileTime
        let creationTime: FileTime
    }

    enum AccessMode: Sendable {
        case readOnly, writeOnly, readWrite
    }

    /// Open flags with platform-neutral bit values, translated to the
    /// platform's flag encoding inside `open`. Bits with no equivalent on
    /// the current platform are ignored on open and never reported by
    /// `status()`.
    struct OpenOptions: OptionSet, Sendable {
        var rawValue: UInt32
        init(rawValue: UInt32) { self.rawValue = rawValue }

        static let append = OpenOptions(rawValue: 1 << 0)
        static let nonBlocking = OpenOptions(rawValue: 1 << 1)
        static let noFollow = OpenOptions(rawValue: 1 << 2)
        static let directory = OpenOptions(rawValue: 1 << 3)
        static let create = OpenOptions(rawValue: 1 << 4)
        static let exclusiveCreate = OpenOptions(rawValue: 1 << 5)
        static let truncate = OpenOptions(rawValue: 1 << 6)
        static let dataSync = OpenOptions(rawValue: 1 << 7)
        static let fileSync = OpenOptions(rawValue: 1 << 8)
        static let readSync = OpenOptions(rawValue: 1 << 9)
    }

    /// Permission bits for newly created files, in POSIX octal form (which
    /// is already platform-neutral; non-POSIX platforms apply their nearest
    /// equivalent).
    struct FilePermissions: OptionSet, Sendable {
        var rawValue: CInt
        init(rawValue: CInt) { self.rawValue = rawValue }

        static var ownerReadWrite: FilePermissions { FilePermissions(rawValue: 0o600) }
        static var ownerReadWriteExecute: FilePermissions { FilePermissions(rawValue: 0o700) }
    }

    enum SeekOrigin: Sendable {
        case start, current, end
    }

    struct AtOptions: OptionSet {
        var rawValue: UInt32
        init(rawValue: UInt32) { self.rawValue = rawValue }

        static let noFollow = AtOptions(rawValue: 1 << 0)
    }

    struct RemoveOptions: OptionSet {
        var rawValue: UInt32
        init(rawValue: UInt32) { self.rawValue = rawValue }

        static let removeDirectory = RemoveOptions(rawValue: 1 << 0)
    }

    /// A directory entry in canonical form, materialized from the platform's
    /// `dirent` (or equivalent) during iteration.
    struct DirectoryEntry {
        let name: String
        let fileType: FileType
    }
}
