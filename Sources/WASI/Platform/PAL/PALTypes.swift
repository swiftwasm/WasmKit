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
//   `WASIAbi.Errno.ENOTSUP` (or is a documented no-op), and
// - around *private storage* or file-internal helpers that never appear in a
//   signature (e.g. `PALWindows.swift`).
//
// This keeps the declared surface identical everywhere: code building
// against the PAL compiles on any platform, including ones WasmKit has never
// heard of, and no per-platform mirror of the API can drift.
//
// Errors: each platform implementation translates its native error
// vocabulary (errno, Win32 codes) into `WASIAbi.Errno` at its own failing
// call site, via the tables in `PALErrnoMapping.swift` — errors never travel
// through another platform's vocabulary, and callers above the PAL receive
// WASI errors directly.

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

    package enum AccessMode: Sendable {
        case readOnly, writeOnly, readWrite
    }

    /// Open flags with platform-neutral bit values, translated to the
    /// platform's flag encoding inside `open`. Bits with no equivalent on
    /// the current platform are ignored on open and never reported by
    /// `status()`.
    package struct OpenOptions: OptionSet, Sendable {
        package var rawValue: UInt32
        package init(rawValue: UInt32) { self.rawValue = rawValue }

        package static let append = OpenOptions(rawValue: 1 << 0)
        package static let nonBlocking = OpenOptions(rawValue: 1 << 1)
        package static let noFollow = OpenOptions(rawValue: 1 << 2)
        package static let directory = OpenOptions(rawValue: 1 << 3)
        package static let create = OpenOptions(rawValue: 1 << 4)
        package static let exclusiveCreate = OpenOptions(rawValue: 1 << 5)
        package static let truncate = OpenOptions(rawValue: 1 << 6)
        package static let dataSync = OpenOptions(rawValue: 1 << 7)
        package static let fileSync = OpenOptions(rawValue: 1 << 8)
        package static let readSync = OpenOptions(rawValue: 1 << 9)
    }

    /// Permission bits for newly created files, in POSIX octal form (which
    /// is already platform-neutral; non-POSIX platforms apply their nearest
    /// equivalent).
    package struct FilePermissions: OptionSet, Sendable {
        package var rawValue: CInt
        package init(rawValue: CInt) { self.rawValue = rawValue }

        package static var ownerReadWrite: FilePermissions { FilePermissions(rawValue: 0o600) }
        package static var ownerReadWriteExecute: FilePermissions { FilePermissions(rawValue: 0o700) }
    }

    package enum SeekOrigin: Sendable {
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
