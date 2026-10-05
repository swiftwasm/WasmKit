// Windows implementations of the directory-relative PAL primitives.
//
// Windows has no `openat` family in Win32, but the NT layer underneath has
// one: `NtCreateFile` opens a name relative to a directory HANDLE given as
// the `RootDirectory` of its object attributes, and `NtSetInformationFile`
// renames or links an open file into a directory given the same way. Every
// operation here goes through a directory HANDLE like that, never through a
// path rebuilt from one, so a guest renaming directories or planting
// symlinks concurrently cannot redirect it, just as with `openat` on POSIX.
// A directory is opened with backup semantics, and its HANDLE is wrapped in
// a CRT file descriptor so that `FileDescriptor` stays a CRT descriptor
// everywhere.
//
// The sandbox walker (`PathResolution`) hands these functions a single
// name, never a path, and resolves `..` and symlinks itself. They therefore
// never follow a symlink: every open uses `FILE_OPEN_REPARSE_POINT`, and an
// open that lands on a symlink fails with ELOOP, as `O_NOFOLLOW` does.
//
// Every file is opened with all three share modes, including
// `FILE_SHARE_DELETE`, so that an open file or directory can be renamed or
// unlinked as on POSIX, and deletion and renaming use the POSIX-semantics
// flags so that a name disappears at once even while open.
#if os(Windows)
    import ucrt
    import WinSDK

    enum WindowsFileSystem {
        static let shareAll = DWORD(FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE)
        // FILE_GENERIC_READ and FILE_GENERIC_WRITE are macros too complex to
        // import; these are their definitions from winnt.h.
        static let genericRead = DWORD(STANDARD_RIGHTS_READ) | DWORD(FILE_READ_DATA) | DWORD(FILE_READ_ATTRIBUTES) | DWORD(FILE_READ_EA) | DWORD(SYNCHRONIZE)
        static let genericWrite =
            DWORD(STANDARD_RIGHTS_WRITE) | DWORD(FILE_WRITE_DATA) | DWORD(FILE_WRITE_ATTRIBUTES) | DWORD(FILE_WRITE_EA) | DWORD(FILE_APPEND_DATA)
            | DWORD(SYNCHRONIZE)

        static func handle(_ fd: FileDescriptor) -> HANDLE? {
            HANDLE(bitPattern: _get_osfhandle(fd.rawValue))
        }

        static func lastError() -> any Error {
            _wasiError(fromWin32: GetLastError())
        }

        // MARK: NT entry points

        // ntdll exports these, but no import library comes with the SDK the
        // toolchain uses, so they are looked up at run time.
        private typealias NtCreateFileFunction =
            @convention(c) (
                UnsafeMutablePointer<HANDLE?>?, ACCESS_MASK, UnsafeMutablePointer<OBJECT_ATTRIBUTES>?,
                UnsafeMutablePointer<IO_STATUS_BLOCK>?, UnsafeMutablePointer<LARGE_INTEGER>?,
                ULONG, ULONG, ULONG, ULONG, UnsafeMutableRawPointer?, ULONG
            ) -> NTSTATUS
        private typealias NtSetInformationFileFunction =
            @convention(c) (
                HANDLE?, UnsafeMutablePointer<IO_STATUS_BLOCK>?, UnsafeMutableRawPointer?, ULONG, Int32
            ) -> NTSTATUS
        private typealias RtlNtStatusToDosErrorFunction = @convention(c) (NTSTATUS) -> ULONG

        private struct NTFunctions: @unchecked Sendable {
            let createFile: NtCreateFileFunction
            let setInformationFile: NtSetInformationFileFunction
            let statusToDosError: RtlNtStatusToDosErrorFunction

            init() {
                let ntdll = GetModuleHandleW(Array("ntdll.dll".utf16) + [0])
                func lookup<F>(_ name: String, as type: F.Type) -> F {
                    guard let address = GetProcAddress(ntdll, name) else {
                        fatalError("ntdll.dll does not export \(name)")
                    }
                    return unsafeBitCast(address, to: type)
                }
                createFile = lookup("NtCreateFile", as: NtCreateFileFunction.self)
                setInformationFile = lookup("NtSetInformationFile", as: NtSetInformationFileFunction.self)
                statusToDosError = lookup("RtlNtStatusToDosError", as: RtlNtStatusToDosErrorFunction.self)
            }
        }
        private static let nt = NTFunctions()

        // NT values the SDK headers leave out.
        private static let fileCreated: ULONG_PTR = 2
        private static let fileRenameInformation: Int32 = 10
        private static let fileLinkInformation: Int32 = 11
        private static let fileRenameInformationEx: Int32 = 65
        private static let fileLinkInformationEx: Int32 = 72
        private static let fileLinkReplaceIfExists: DWORD = 0x1
        private static let fileLinkPOSIXSemantics: DWORD = 0x2

        static func error(fromStatus status: NTSTATUS) -> any Error {
            switch UInt32(bitPattern: status) {
            case 0xC000_00BA:  // STATUS_FILE_IS_A_DIRECTORY
                return WASIAbi.Errno.EISDIR
            case 0xC000_0103:  // STATUS_NOT_A_DIRECTORY
                return WASIAbi.Errno.ENOTDIR
            case 0xC000_0056:  // STATUS_DELETE_PENDING: the name is already gone.
                return WASIAbi.Errno.ENOENT
            default:
                return _wasiError(fromWin32: UInt32(nt.statusToDosError(status)))
            }
        }

        /// `NtCreateFile` for `name` relative to the directory `dir`, never
        /// following a reparse point at `name`. `.` names `dir` itself; `..`
        /// is refused, since only the sandbox walker may leave a directory.
        static func openRelative(
            _ dir: HANDLE?, _ name: String,
            access: DWORD, disposition: ULONG, options: ULONG = 0,
            created: UnsafeMutablePointer<Bool>? = nil
        ) throws -> HANDLE {
            var units: [UInt16]
            switch name {
            case "", ".": units = []
            case "..": throw WASIAbi.Errno.EPERM
            default:
                // A backslash would be a separator to Windows and a colon
                // names an alternate data stream; neither is a single name.
                guard !name.utf16.contains(UInt16(UInt8(ascii: "\\"))), !name.utf16.contains(UInt16(UInt8(ascii: ":"))) else {
                    throw WASIAbi.Errno.ENOENT
                }
                units = Array(name.utf16)
            }
            guard units.count * 2 <= Int(UInt16.max) else { throw WASIAbi.Errno.ENAMETOOLONG }

            var handle: HANDLE? = nil
            var ioStatus = IO_STATUS_BLOCK()
            let status = units.withUnsafeMutableBufferPointer { buffer -> NTSTATUS in
                let byteCount = USHORT(buffer.count * 2)
                var objectName = UNICODE_STRING(Length: byteCount, MaximumLength: byteCount, Buffer: buffer.baseAddress)
                return withUnsafeMutablePointer(to: &objectName) { objectName in
                    var attributes = OBJECT_ATTRIBUTES(
                        Length: ULONG(MemoryLayout<OBJECT_ATTRIBUTES>.size), RootDirectory: dir,
                        ObjectName: objectName, Attributes: ULONG(OBJ_CASE_INSENSITIVE),
                        SecurityDescriptor: nil, SecurityQualityOfService: nil)
                    return nt.createFile(
                        &handle, ACCESS_MASK(access) | ACCESS_MASK(SYNCHRONIZE), &attributes, &ioStatus, nil,
                        ULONG(FILE_ATTRIBUTE_NORMAL), ULONG(shareAll), disposition,
                        options | ULONG(FILE_SYNCHRONOUS_IO_NONALERT | FILE_OPEN_FOR_BACKUP_INTENT | FILE_OPEN_REPARSE_POINT),
                        nil, 0)
                }
            }
            guard status >= 0, let handle else { throw error(fromStatus: status) }
            created?.pointee = ioStatus.Information == fileCreated
            return handle
        }

        /// Opens `name` in `dir` for the duration of `body`.
        static func withRelative<R>(
            _ dir: FileDescriptor, _ name: String, access: DWORD, options: ULONG = 0,
            _ body: (HANDLE) throws -> R
        ) throws -> R {
            let handle = try openRelative(Self.handle(dir), name, access: access, disposition: ULONG(FILE_OPEN), options: options)
            defer { CloseHandle(handle) }
            return try body(handle)
        }

        // MARK: Metadata

        static func information(of handle: HANDLE?) throws -> BY_HANDLE_FILE_INFORMATION {
            var info = BY_HANDLE_FILE_INFORMATION()
            guard GetFileInformationByHandle(handle, &info) else { throw lastError() }
            return info
        }

        /// The reparse tag of the entry behind `handle`, or nil when it is
        /// not a reparse point.
        static func reparseTag(of handle: HANDLE?) throws -> UInt32? {
            var info = FILE_ATTRIBUTE_TAG_INFO()
            guard GetFileInformationByHandleEx(handle, FileAttributeTagInfo, &info, DWORD(MemoryLayout.size(ofValue: info))) else {
                throw lastError()
            }
            return info.FileAttributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT) != 0 ? info.ReparseTag : nil
        }

        /// Whether a reparse tag redirects to another name, as symlinks and
        /// junctions do. Other reparse points, such as cloud-file
        /// placeholders, are ordinary files and directories to their users.
        static func isNameSurrogate(_ tag: UInt32?) -> Bool {
            guard let tag else { return false }
            return tag & 0x2000_0000 != 0
        }

        static func isSameFile(_ a: BY_HANDLE_FILE_INFORMATION, _ b: BY_HANDLE_FILE_INFORMATION) -> Bool {
            a.dwVolumeSerialNumber == b.dwVolumeSerialNumber && a.nFileIndexHigh == b.nFileIndexHigh && a.nFileIndexLow == b.nFileIndexLow
        }

        static func isDirectory(_ info: BY_HANDLE_FILE_INFORMATION) -> Bool {
            info.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) != 0
        }

        /// `fstat`.
        static func attributes(of fd: FileDescriptor) throws -> FileDescriptor.Attributes {
            let handle = handle(fd)
            let isSymlink = isNameSurrogate(try? reparseTag(of: handle))
            return FileDescriptor.Attributes(windowsFileInformation: try information(of: handle), isSymlink: isSymlink)
        }

        /// `fstatat` with `AT_SYMLINK_NOFOLLOW`.
        static func attributes(at name: String, in dir: FileDescriptor) throws -> FileDescriptor.Attributes {
            try withRelative(dir, name, access: DWORD(FILE_READ_ATTRIBUTES)) { handle in
                FileDescriptor.Attributes(
                    windowsFileInformation: try information(of: handle),
                    isSymlink: isNameSurrogate(try reparseTag(of: handle)))
            }
        }

        static func setTimes(of handle: HANDLE?, access: FileTime, modification: FileTime) throws {
            var atime = _windowsFILETIME(from: access)
            var mtime = _windowsFILETIME(from: modification)
            guard atime != nil || mtime != nil else { return }
            let ok = withOptionalPointer(to: &atime) { atimePtr in
                withOptionalPointer(to: &mtime) { mtimePtr in
                    SetFileTime(handle, nil, atimePtr, mtimePtr)
                }
            }
            guard ok else { throw lastError() }
        }

        /// `utimensat` with `AT_SYMLINK_NOFOLLOW`.
        static func setTimes(at name: String, in dir: FileDescriptor, access: FileTime, modification: FileTime) throws {
            try withRelative(dir, name, access: DWORD(FILE_WRITE_ATTRIBUTES)) { handle in
                try setTimes(of: handle, access: access, modification: modification)
            }
        }

        // MARK: Opening

        /// Wraps a HANDLE in a CRT descriptor, closing the HANDLE on failure.
        static func wrap(_ handle: HANDLE, crtFlags: CInt) throws -> FileDescriptor {
            let fd = _open_osfhandle(intptr_t(bitPattern: handle), crtFlags)
            guard fd >= 0 else {
                CloseHandle(handle)
                throw _wasiError(fromErrno: _palErrno)
            }
            return FileDescriptor(rawValue: fd)
        }

        /// Opens a host directory, given by the embedder as a host path.
        static func openPreopenDirectory(_ path: String) throws -> FileDescriptor {
            let widePath = Array(path.utf16) + [0]
            let handle = CreateFileW(widePath, genericRead, shareAll, nil, DWORD(OPEN_EXISTING), DWORD(FILE_FLAG_BACKUP_SEMANTICS), nil)
            guard let handle, handle != INVALID_HANDLE_VALUE else { throw lastError() }
            do {
                guard isDirectory(try information(of: handle)) else { throw WASIAbi.Errno.ENOTDIR }
            } catch {
                CloseHandle(handle)
                throw error
            }
            return try wrap(handle, crtFlags: _O_RDONLY)
        }

        /// `openat` with `O_NOFOLLOW`, with POSIX outcomes: a symlink fails
        /// with ELOOP, `.directory` on anything else with ENOTDIR, and
        /// writing, creating or truncating a directory with EISDIR.
        static func open(
            at name: String, in dir: FileDescriptor,
            mode: FileDescriptor.AccessMode, options: FileDescriptor.OpenOptions
        ) throws -> FileDescriptor {
            if options.contains(.directory) && options.contains(.create) {
                // `open("name/", O_CREAT)`: POSIX refuses to create a directory this way.
                throw WASIAbi.Errno.EISDIR
            }
            var access: DWORD
            switch mode {
            case .readOnly: access = genericRead
            case .writeOnly: access = genericWrite
            case .readWrite: access = genericRead | genericWrite
            }
            // POSIX lets any descriptor set timestamps and read metadata.
            access |= DWORD(FILE_READ_ATTRIBUTES | FILE_WRITE_ATTRIBUTES)

            // Never let the open itself overwrite: the entry might be a
            // symlink or a directory, which O_TRUNC must leave alone. A
            // regular file is truncated below, once its type is known.
            let disposition: Int32
            switch (options.contains(.create), options.contains(.exclusiveCreate)) {
            case (true, true): disposition = FILE_CREATE
            case (true, false): disposition = FILE_OPEN_IF
            case (false, _): disposition = FILE_OPEN
            }
            var ntOptions: ULONG = 0
            if options.contains(.directory) { ntOptions |= ULONG(FILE_DIRECTORY_FILE) }
            if options.contains(.fileSync) || options.contains(.dataSync) { ntOptions |= ULONG(FILE_WRITE_THROUGH) }

            var created = false
            var handle: HANDLE
            do {
                handle = try openRelative(Self.handle(dir), name, access: access, disposition: ULONG(disposition), options: ntOptions, created: &created)
            } catch WASIAbi.Errno.EACCES {
                // Without write permission on the file, FILE_WRITE_ATTRIBUTES
                // alone can be what is denied; retry without it.
                access &= ~DWORD(FILE_WRITE_ATTRIBUTES)
                handle = try openRelative(Self.handle(dir), name, access: access, disposition: ULONG(disposition), options: ntOptions, created: &created)
            }

            do {
                let info = try information(of: handle)
                if isNameSurrogate(try reparseTag(of: handle)) {
                    throw WASIAbi.Errno.ELOOP
                }
                if options.contains(.directory) && !isDirectory(info) {
                    throw WASIAbi.Errno.ENOTDIR
                }
                if isDirectory(info) && (mode != .readOnly || options.contains(.create) || options.contains(.truncate)) {
                    throw WASIAbi.Errno.EISDIR
                }
                if options.contains(.truncate) && !created {
                    var endOfFile = FILE_END_OF_FILE_INFO()
                    guard SetFileInformationByHandle(handle, FileEndOfFileInfo, &endOfFile, DWORD(MemoryLayout.size(ofValue: endOfFile))) else {
                        throw lastError()
                    }
                }
            } catch {
                CloseHandle(handle)
                throw error
            }

            let fd = try wrap(handle, crtFlags: mode == .readOnly ? _O_RDONLY : 0)
            openOptions.set(options.intersection(OpenOptionsTable.recorded), for: fd)
            return fd
        }

        /// The status flags POSIX keeps with an open file (`F_GETFL`) but
        /// Windows does not, by CRT descriptor. `write` seeks to the end
        /// first when `.append` is set, as the CRT's own `_O_APPEND` does.
        static let openOptions = OpenOptionsTable()

        final class OpenOptionsTable: @unchecked Sendable {
            static let recorded: FileDescriptor.OpenOptions = [.append, .nonBlocking, .dataSync, .fileSync, .readSync]
            private let lock = UnsafeMutablePointer<SRWLOCK>.allocate(capacity: 1)
            private var options: [CInt: FileDescriptor.OpenOptions] = [:]

            init() {
                InitializeSRWLock(lock)
            }

            func get(_ fd: FileDescriptor) -> FileDescriptor.OpenOptions {
                AcquireSRWLockShared(lock)
                defer { ReleaseSRWLockShared(lock) }
                return options[fd.rawValue] ?? []
            }

            func set(_ value: FileDescriptor.OpenOptions, for fd: FileDescriptor) {
                AcquireSRWLockExclusive(lock)
                defer { ReleaseSRWLockExclusive(lock) }
                options[fd.rawValue] = value.isEmpty ? nil : value
            }
        }

        static func createDirectory(at name: String, in dir: FileDescriptor) throws {
            let handle = try openRelative(
                Self.handle(dir), name, access: DWORD(FILE_LIST_DIRECTORY), disposition: ULONG(FILE_CREATE),
                options: ULONG(FILE_DIRECTORY_FILE))
            CloseHandle(handle)
        }

        // MARK: Symlinks

        private static let reparseTagSymlink: UInt32 = 0xA000_000C
        private static let reparseTagMountPoint: UInt32 = 0xA000_0003
        private static let symlinkFlagRelative: UInt32 = 1

        /// `readlinkat`: the link's target with `/` separators. An absolute
        /// target gets a leading `/` so that the sandbox walker refuses it.
        static func readSymlink(at name: String, in dir: FileDescriptor) throws -> String {
            try withRelative(dir, name, access: DWORD(FILE_READ_ATTRIBUTES)) { handle in
                var buffer = [UInt8](repeating: 0, count: Int(MAXIMUM_REPARSE_DATA_BUFFER_SIZE))
                var returned: DWORD = 0
                let ok = DeviceIoControl(handle, DWORD(FSCTL_GET_REPARSE_POINT), nil, 0, &buffer, DWORD(buffer.count), &returned, nil)
                guard ok else {
                    if GetLastError() == DWORD(ERROR_NOT_A_REPARSE_POINT) { throw WASIAbi.Errno.EINVAL }
                    throw lastError()
                }
                // REPARSE_DATA_BUFFER is only in the driver kit headers, so
                // read it by hand: ReparseTag (u32), ReparseDataLength (u16),
                // Reserved (u16), then SubstituteNameOffset/Length and
                // PrintNameOffset/Length (u16 each); a symlink adds Flags
                // (u32) before the UTF-16 path buffer, a junction does not.
                return try buffer.withUnsafeBytes { bytes -> String in
                    let tag = bytes.loadUnaligned(fromByteOffset: 0, as: UInt32.self)
                    let pathBufferOffset: Int
                    let isRelative: Bool
                    switch tag {
                    case reparseTagSymlink:
                        pathBufferOffset = 20
                        isRelative = bytes.loadUnaligned(fromByteOffset: 16, as: UInt32.self) & symlinkFlagRelative != 0
                    case reparseTagMountPoint:
                        pathBufferOffset = 16
                        isRelative = false
                    default:
                        throw WASIAbi.Errno.EINVAL
                    }
                    let offset = Int(bytes.loadUnaligned(fromByteOffset: 8, as: UInt16.self))
                    let length = Int(bytes.loadUnaligned(fromByteOffset: 10, as: UInt16.self))
                    let start = pathBufferOffset + offset
                    guard start + length <= Int(returned) else { throw WASIAbi.Errno.EINVAL }
                    let units = (0..<length / 2).map {
                        bytes.loadUnaligned(fromByteOffset: start + $0 * 2, as: UInt16.self)
                    }
                    var target = String(decoding: units, as: UTF16.self).replacingCharacter("\\", with: "/")
                    if !isRelative && !target.hasPrefix("/") { target = "/" + target }
                    return target
                }
            }
        }

        /// `symlinkat`. Windows records whether a symlink points to a
        /// directory, which `targetIsDirectory` answers.
        ///
        /// The link is created relative to `dir` like everything else: an
        /// empty entry is created there and turned into a symlink. Setting
        /// a symlink reparse point needs the symlink privilege, which a
        /// non-elevated process lacks even in Developer Mode; there, fall back
        /// to `CreateSymbolicLinkW` on the directory's current path, as
        /// cap-std does for wasmtime. That fallback can be redirected by a
        /// guest renaming a directory on that path at the same moment.
        static func createSymlink(original: String, link: String, in dir: FileDescriptor, targetIsDirectory: () -> Bool) throws {
            // A drive letter, a stream or a backslash-separated path would
            // all mean something else to Windows than to the guest.
            guard !original.utf16.contains(UInt16(UInt8(ascii: ":"))), !original.utf16.contains(UInt16(UInt8(ascii: "\\"))) else {
                throw WASIAbi.Errno.EPERM
            }
            let target = Array(original.replacingCharacter("/", with: "\\").utf16)
            let isDirectory = targetIsDirectory()

            let entry: HANDLE
            do {
                entry = try openRelative(
                    handle(dir), link, access: genericWrite | DWORD(DELETE), disposition: ULONG(FILE_CREATE),
                    options: ULONG(isDirectory ? FILE_DIRECTORY_FILE : FILE_NON_DIRECTORY_FILE))
            } catch WASIAbi.Errno.EISDIR, WASIAbi.Errno.ENOTDIR {
                // Something of the other type is already there.
                throw WASIAbi.Errno.EEXIST
            }
            defer { CloseHandle(entry) }

            // A symlink REPARSE_DATA_BUFFER (see `readSymlink`) holding the
            // target as both substitute name and print name.
            let nameBytes = target.count * 2
            guard 12 + nameBytes * 2 <= Int(UInt16.max) else {
                try? delete(entry)
                throw WASIAbi.Errno.ENAMETOOLONG
            }
            var buffer = [UInt8](repeating: 0, count: 20 + nameBytes * 2)
            buffer.withUnsafeMutableBytes { bytes in
                bytes.storeBytes(of: reparseTagSymlink, toByteOffset: 0, as: UInt32.self)
                bytes.storeBytes(of: UInt16(12 + nameBytes * 2), toByteOffset: 4, as: UInt16.self)
                bytes.storeBytes(of: 0, toByteOffset: 8, as: UInt16.self)
                bytes.storeBytes(of: UInt16(nameBytes), toByteOffset: 10, as: UInt16.self)
                bytes.storeBytes(of: UInt16(nameBytes), toByteOffset: 12, as: UInt16.self)
                bytes.storeBytes(of: UInt16(nameBytes), toByteOffset: 14, as: UInt16.self)
                bytes.storeBytes(of: symlinkFlagRelative, toByteOffset: 16, as: UInt32.self)
                for (index, unit) in (target + target).enumerated() {
                    bytes.storeBytes(of: unit, toByteOffset: 20 + index * 2, as: UInt16.self)
                }
            }
            var returned: DWORD = 0
            if DeviceIoControl(entry, DWORD(FSCTL_SET_REPARSE_POINT), &buffer, DWORD(buffer.count), nil, 0, &returned, nil) {
                return
            }
            let error = GetLastError()
            try? delete(entry)
            guard error == DWORD(ERROR_PRIVILEGE_NOT_HELD) else { throw _wasiError(fromWin32: error) }

            var flags = DWORD(SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)
            if isDirectory { flags |= DWORD(SYMBOLIC_LINK_FLAG_DIRECTORY) }
            let linkPath = try finalPath(of: handle(dir)) + Array("\\\(link)".utf16) + [0]
            guard CreateSymbolicLinkW(linkPath, target + [0], flags) != 0 else { throw lastError() }
        }

        /// The final path of an open directory, in `\\?\` form, without a
        /// NUL terminator. Only the unprivileged symlink fallback uses it.
        private static func finalPath(of handle: HANDLE?) throws -> [UInt16] {
            var buffer = [UInt16](repeating: 0, count: Int(MAX_PATH))
            while true {
                let count = Int(
                    GetFinalPathNameByHandleW(handle, &buffer, DWORD(buffer.count), DWORD(FILE_NAME_NORMALIZED | VOLUME_NAME_DOS)))
                guard count > 0 else { throw lastError() }
                // On success the count excludes the NUL; when the buffer is
                // too small it is the size needed, NUL included.
                if count < buffer.count { return Array(buffer[..<count]) }
                buffer = [UInt16](repeating: 0, count: count)
            }
        }

        // MARK: Removing, renaming and linking

        /// Deletes the entry behind `handle` with POSIX semantics, so the name
        /// goes away at once even if the file is still open elsewhere.
        private static func delete(_ handle: HANDLE) throws {
            var info = FILE_DISPOSITION_INFO_EX()
            info.Flags = DWORD(FILE_DISPOSITION_FLAG_DELETE | FILE_DISPOSITION_FLAG_POSIX_SEMANTICS | FILE_DISPOSITION_FLAG_IGNORE_READONLY_ATTRIBUTE)
            if SetFileInformationByHandle(handle, FileDispositionInfoEx, &info, DWORD(MemoryLayout.size(ofValue: info))) {
                return
            }
            // File systems other than NTFS may not support the extended form.
            let error = GetLastError()
            guard error == DWORD(ERROR_INVALID_PARAMETER) || error == DWORD(ERROR_NOT_SUPPORTED) else {
                throw _wasiError(fromWin32: error)
            }
            // FILE_DISPOSITION_INFO holds a single BOOLEAN, whose field name
            // the `DeleteFile` macro mangles in the imported header.
            var deleteFile: BOOLEAN = 1
            guard SetFileInformationByHandle(handle, FileDispositionInfo, &deleteFile, DWORD(MemoryLayout<BOOLEAN>.size)) else {
                throw lastError()
            }
        }

        /// `unlinkat`, with or without `AT_REMOVEDIR`. A symlink is removed
        /// as a file even when Windows considers it a directory symlink.
        static func remove(at name: String, in dir: FileDescriptor, directory: Bool) throws {
            guard name != "." && name != ".." else {
                throw directory ? WASIAbi.Errno.EINVAL : WASIAbi.Errno.EISDIR
            }
            try withRelative(dir, name, access: DWORD(DELETE) | DWORD(FILE_READ_ATTRIBUTES)) { handle in
                let info = try information(of: handle)
                let isRealDirectory = try isDirectory(info) && !isNameSurrogate(reparseTag(of: handle))
                if directory && !isRealDirectory { throw WASIAbi.Errno.ENOTDIR }
                if !directory && isRealDirectory { throw WASIAbi.Errno.EISDIR }
                try delete(handle)
            }
        }

        /// Gives the entry behind `handle` the name `name` in `dir`, by
        /// `NtSetInformationFile` with a FILE_RENAME_INFORMATION or
        /// FILE_LINK_INFORMATION. The two share FILE_RENAME_INFO's layout.
        private static func setName(
            of handle: HANDLE, in dir: FileDescriptor, to name: String,
            extendedClass: Int32, legacyClass: Int32, replace: Bool
        ) throws {
            let units = Array(name.utf16)
            let nameBytes = units.count * MemoryLayout<UInt16>.size
            let nameOffset = MemoryLayout<FILE_RENAME_INFO>.offset(of: \FILE_RENAME_INFO.FileName)!
            let size = max(MemoryLayout<FILE_RENAME_INFO>.size, nameOffset + nameBytes + MemoryLayout<UInt16>.size)
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<FILE_RENAME_INFO>.alignment)
            defer { buffer.deallocate() }

            func attempt(extended: Bool) -> NTSTATUS {
                buffer.initializeMemory(as: UInt8.self, repeating: 0, count: size)
                let info = buffer.assumingMemoryBound(to: FILE_RENAME_INFO.self)
                if extended {
                    info.pointee.Flags = fileLinkPOSIXSemantics | (replace ? fileLinkReplaceIfExists : 0)
                } else {
                    info.pointee.ReplaceIfExists = replace ? 1 : 0
                }
                info.pointee.RootDirectory = Self.handle(dir)
                info.pointee.FileNameLength = DWORD(nameBytes)
                units.withUnsafeBytes { name in
                    if let base = name.baseAddress { (buffer + nameOffset).copyMemory(from: base, byteCount: nameBytes) }
                }
                var ioStatus = IO_STATUS_BLOCK()
                return nt.setInformationFile(handle, &ioStatus, buffer, ULONG(size), extended ? extendedClass : legacyClass)
            }

            var status = attempt(extended: true)
            // File systems other than NTFS may not support the extended form.
            if UInt32(bitPattern: status) == 0xC000_0003 || UInt32(bitPattern: status) == 0xC000_00BB {
                status = attempt(extended: false)  // STATUS_INVALID_INFO_CLASS, STATUS_NOT_SUPPORTED
            }
            guard status >= 0 else { throw error(fromStatus: status) }
        }

        /// `renameat`. A trailing `/` on either name requires a directory.
        static func rename(at oldName: String, in oldDir: FileDescriptor, to newName: String, in newDir: FileDescriptor) throws {
            let oldRequiresDirectory = oldName.hasSuffix("/")
            let newRequiresDirectory = newName.hasSuffix("/")
            let oldName = String(oldName.reversed().drop(while: { $0 == "/" }).reversed())
            let newName = String(newName.reversed().drop(while: { $0 == "/" }).reversed())
            // Neither the directory itself nor its parent can be renamed
            // through it; in particular a preopen cannot be moved.
            for name in [oldName, newName] where name.isEmpty || name == "." || name == ".." {
                throw WASIAbi.Errno.EBUSY
            }

            try withRelative(oldDir, oldName, access: DWORD(DELETE) | DWORD(FILE_READ_ATTRIBUTES)) { handle in
                let oldInfo = try information(of: handle)
                let oldIsDirectory = try isDirectory(oldInfo) && !isNameSurrogate(reparseTag(of: handle))
                if oldRequiresDirectory && !oldIsDirectory { throw WASIAbi.Errno.ENOTDIR }

                let new: (info: BY_HANDLE_FILE_INFORMATION, isDirectory: Bool)?
                do {
                    new = try withRelative(newDir, newName, access: DWORD(FILE_READ_ATTRIBUTES)) {
                        let info = try information(of: $0)
                        return (info, try isDirectory(info) && !isNameSurrogate(reparseTag(of: $0)))
                    }
                } catch WASIAbi.Errno.ENOENT {
                    new = nil
                }
                if let new {
                    // Two links to one file: POSIX does nothing. The same
                    // name in another case in the same directory is that very
                    // entry, though, and renaming it changes the case.
                    let sameFile = isSameFile(new.info, oldInfo)
                    let isCaseChange =
                        try oldName != newName && oldName.lowercased() == newName.lowercased()
                        && isSameFile(information(of: Self.handle(oldDir)), information(of: Self.handle(newDir)))
                    if sameFile && !isCaseChange {
                        return
                    }
                    if !sameFile {
                        if new.isDirectory && !oldIsDirectory { throw WASIAbi.Errno.EISDIR }
                        if !new.isDirectory && (oldIsDirectory || newRequiresDirectory) { throw WASIAbi.Errno.ENOTDIR }
                    }
                } else if newRequiresDirectory && !oldIsDirectory {
                    throw WASIAbi.Errno.ENOTDIR
                }
                // With POSIX semantics, NTFS also replaces an empty directory.
                try setName(
                    of: handle, in: newDir, to: newName,
                    extendedClass: fileRenameInformationEx, legacyClass: fileRenameInformation, replace: true)
            }
        }

        /// `linkat` without following a symlink at the source.
        static func createHardLink(at oldName: String, in oldDir: FileDescriptor, to newName: String, in newDir: FileDescriptor) throws {
            try withRelative(oldDir, oldName, access: DWORD(FILE_READ_ATTRIBUTES)) { handle in
                let info = try information(of: handle)
                if try isDirectory(info) && !isNameSurrogate(reparseTag(of: handle)) {
                    throw WASIAbi.Errno.EPERM
                }
                try setName(
                    of: handle, in: newDir, to: newName,
                    extendedClass: fileLinkInformationEx, legacyClass: fileLinkInformation, replace: false)
            }
        }

        // MARK: Directory enumeration

        /// Reads a directory through its HANDLE in batches of
        /// `FILE_ID_BOTH_DIR_INFO` records. Like `readdir`, it yields `.` and
        /// `..`, and each record carries the file ID, so no entry needs to be
        /// opened for its inode.
        final class DirectoryEnumerator {
            let fd: FileDescriptor
            private var buffer = [UInt8](repeating: 0, count: 64 * 1024)
            private var offset: Int?
            private var restart = true
            private var finished = false

            init(fd: FileDescriptor) {
                self.fd = fd
            }

            func next() -> Result<FileDescriptor.DirectoryEntry, any Error>? {
                if offset == nil {
                    guard !finished else { return nil }
                    let ok = GetFileInformationByHandleEx(
                        WindowsFileSystem.handle(fd), restart ? FileIdBothDirectoryRestartInfo : FileIdBothDirectoryInfo,
                        &buffer, DWORD(buffer.count))
                    restart = false
                    guard ok else {
                        finished = true
                        let error = GetLastError()
                        return error == DWORD(ERROR_NO_MORE_FILES) ? nil : .failure(_wasiError(fromWin32: error))
                    }
                    offset = 0
                }
                return buffer.withUnsafeBytes { bytes in
                    let entryOffset = offset!
                    let entry = (bytes.baseAddress! + entryOffset).assumingMemoryBound(to: FILE_ID_BOTH_DIR_INFO.self)
                    let nameOffset = MemoryLayout<FILE_ID_BOTH_DIR_INFO>.offset(of: \FILE_ID_BOTH_DIR_INFO.FileName)!
                    let nameLength = Int(entry.pointee.FileNameLength) / 2
                    let units = (0..<nameLength).map {
                        bytes.loadUnaligned(fromByteOffset: entryOffset + nameOffset + $0 * 2, as: UInt16.self)
                    }
                    let attributes = entry.pointee.FileAttributes
                    // For a reparse point, EaSize holds the reparse tag.
                    let tag = attributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT) != 0 ? entry.pointee.EaSize : nil
                    let fileType: FileDescriptor.FileType
                    if WindowsFileSystem.isNameSurrogate(tag) {
                        fileType = .symlink
                    } else if attributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) != 0 {
                        fileType = .directory
                    } else {
                        fileType = .regular
                    }
                    let next = Int(entry.pointee.NextEntryOffset)
                    offset = next == 0 ? nil : entryOffset + next
                    return .success(
                        FileDescriptor.DirectoryEntry(
                            name: String(decoding: units, as: UTF16.self), fileType: fileType,
                            inode: UInt64(bitPattern: entry.pointee.FileId.QuadPart)))
                }
            }

            func close() {
                try? fd.close()
            }
        }

        private static func withOptionalPointer<T, R>(to value: inout T?, _ body: (UnsafePointer<T>?) -> R) -> R {
            if value != nil {
                return withUnsafePointer(to: &value!) { body($0) }
            }
            return body(nil)
        }
    }

    extension String {
        fileprivate func replacingCharacter(_ target: Character, with replacement: Character) -> String {
            String(map { $0 == target ? replacement : $0 })
        }
    }
#endif
