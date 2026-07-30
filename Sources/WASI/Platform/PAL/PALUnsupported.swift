// Stub platform layer for platforms without a known libc.
//
// This arm exists so the WASI module *compiles* on unknown platforms (e.g.
// custom embedded targets): every host-filesystem operation fails with
// `ENOTSUP` at runtime, while platform-independent backends — the in-memory
// file system, `FileSystemOptions.custom(_:)` implementations, and injected
// clocks/random generators — remain fully functional.
//
// Keep this API surface in sync with the real implementations in
// `PALCore.swift`, `PALAttributes.swift`, `PALFileAtOperations.swift`, and
// `PALClock.swift`.
#if !(os(Windows) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI))

    /// A raw platform error, carrying an errno value.
    struct PlatformErrno: Error, Equatable, CustomStringConvertible {
        let rawValue: CInt
        init(rawValue: CInt) { self.rawValue = rawValue }

        var description: String { "errno \(rawValue)" }

        static var notSupported: PlatformErrno { PlatformErrno(rawValue: -1) }
    }

    /// A platform file descriptor. Unused on this platform: all operations
    /// fail with `notSupported`.
    struct FileDescriptor: Sendable, Hashable {
        let rawValue: CInt
        init(rawValue: CInt) { self.rawValue = rawValue }

        enum AccessMode: Sendable {
            case readOnly, writeOnly, readWrite
        }

        struct OpenOptions: OptionSet, Sendable {
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            static var append: OpenOptions { OpenOptions(rawValue: 1 << 0) }
            static var nonBlocking: OpenOptions { OpenOptions(rawValue: 1 << 1) }
            static var noFollow: OpenOptions { OpenOptions(rawValue: 1 << 2) }
            static var directory: OpenOptions { OpenOptions(rawValue: 1 << 3) }
            static var create: OpenOptions { OpenOptions(rawValue: 1 << 4) }
            static var exclusiveCreate: OpenOptions { OpenOptions(rawValue: 1 << 5) }
            static var truncate: OpenOptions { OpenOptions(rawValue: 1 << 6) }
            static var dataSync: OpenOptions { OpenOptions(rawValue: 1 << 7) }
            static var fileSync: OpenOptions { OpenOptions(rawValue: 1 << 8) }
        }

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
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            static var noFollow: AtOptions { AtOptions(rawValue: 1 << 0) }
        }

        struct RemoveOptions: OptionSet {
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            static var removeDirectory: RemoveOptions { RemoveOptions(rawValue: 1 << 0) }
        }

        struct FileType: Equatable {
            var isDirectory: Bool { false }
            var isFile: Bool { false }
            var isCharacterDevice: Bool { false }
            var isSymlink: Bool { false }
            var isBlockDevice: Bool { false }
            var isSocket: Bool { false }
        }

        struct Attributes {
            var device: UInt64 { 0 }
            var inode: UInt64 { 0 }
            var fileType: FileType { FileType() }
            var linkCount: UInt32 { 0 }
            var size: Int64 { 0 }
            var accessTime: FileTime { FileTime(seconds: 0, nanoseconds: 0) }
            var modificationTime: FileTime { FileTime(seconds: 0, nanoseconds: 0) }
            var creationTime: FileTime { FileTime(seconds: 0, nanoseconds: 0) }
        }

        static func open(
            _ path: String, _ mode: AccessMode,
            options: OpenOptions = OpenOptions(rawValue: 0),
            permissions: FilePermissions = FilePermissions(rawValue: 0)
        ) throws -> FileDescriptor {
            throw PlatformErrno.notSupported
        }

        static func openPreopenDirectory(_ path: String) throws -> FileDescriptor {
            throw PlatformErrno.notSupported
        }

        static var maximumPathLength: Int { 4096 }

        func close() throws { throw PlatformErrno.notSupported }
        func read(into buffer: UnsafeMutableRawBufferPointer) throws -> Int { throw PlatformErrno.notSupported }
        func write(_ buffer: UnsafeRawBufferPointer) throws -> Int { throw PlatformErrno.notSupported }
        func read(fromAbsoluteOffset offset: Int64, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            throw PlatformErrno.notSupported
        }
        func writeAll(toAbsoluteOffset offset: Int64, _ buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            throw PlatformErrno.notSupported
        }
        func writeAll(toAbsoluteOffset offset: Int64, _ buffer: UnsafeRawBufferPointer) throws -> Int {
            throw PlatformErrno.notSupported
        }
        func seek(offset: Int64, from whence: SeekOrigin) throws -> Int64 { throw PlatformErrno.notSupported }
        func truncate(size: Int64) throws { throw PlatformErrno.notSupported }
        func sync() throws { throw PlatformErrno.notSupported }
        func datasync() throws { throw PlatformErrno.notSupported }
        func status() throws -> OpenOptions { throw PlatformErrno.notSupported }
        func setStatus(_ options: OpenOptions) throws { throw PlatformErrno.notSupported }
        func attributes() throws -> Attributes { throw PlatformErrno.notSupported }
        func setTimes(access: FileTime = .omit, modification: FileTime = .omit) throws {
            throw PlatformErrno.notSupported
        }
        func adviseWillNeedRead(offset: UInt64, length: UInt64) throws {}

        func open(
            at path: String, _ mode: AccessMode,
            options: OpenOptions = OpenOptions(rawValue: 0),
            permissions: FilePermissions = FilePermissions(rawValue: 0)
        ) throws -> FileDescriptor {
            throw PlatformErrno.notSupported
        }
        func attributes(at path: String, options: AtOptions = AtOptions(rawValue: 0)) throws -> Attributes {
            throw PlatformErrno.notSupported
        }
        func remove(at path: String, options: RemoveOptions = RemoveOptions(rawValue: 0)) throws {
            throw PlatformErrno.notSupported
        }
        func createDirectory(at path: String, permissions: FilePermissions) throws {
            throw PlatformErrno.notSupported
        }
        func createSymlink(original: String, link: String) throws { throw PlatformErrno.notSupported }
        func rename(at path: String, to newDir: FileDescriptor, at newPath: String) throws {
            throw PlatformErrno.notSupported
        }
        func readSymlink(at path: String, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            throw PlatformErrno.notSupported
        }

        struct DirectoryEntry {
            var name: String { "" }
            var fileType: FileType { FileType() }
        }

        struct DirectoryStream: IteratorProtocol, Sequence {
            func close() {}
            func next() -> Result<DirectoryEntry, PlatformErrno>? { nil }
        }

        func contentsOfDirectory() throws -> DirectoryStream { throw PlatformErrno.notSupported }
    }

    /// A point in time. On this platform the only consumer is the stub
    /// `setTimes`, which throws before inspecting the value, so `now`/`omit`
    /// need no distinguishing representation.
    struct FileTime {
        var seconds: Int64
        var nanoseconds: Int64

        init(seconds: Int, nanoseconds: Int) {
            self.seconds = Int64(seconds)
            self.nanoseconds = Int64(nanoseconds)
        }

        static var now: FileTime { FileTime(seconds: 0, nanoseconds: 0) }
        static var omit: FileTime { FileTime(seconds: 0, nanoseconds: 0) }
    }

    /// Thread scheduling primitives.
    enum PlatformScheduler {
        static func yieldCurrentThread() throws {
            throw PlatformErrno.notSupported
        }
    }

#endif
