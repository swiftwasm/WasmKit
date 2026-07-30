// Directory-relative (`*at`) operations and directory enumeration for the
// WASI platform layer. These are unavailable on Windows, where the caller
// paths that need them already fail with `ENOSYS`/`ENOTSUP`.
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
    import WinSDK
#elseif os(WASI)
    import CWASIPlatform
    import WASILibc
#else
    #error("Unsupported Platform")
#endif

#if !os(Windows)

    extension FileDescriptor {
        struct AtOptions: OptionSet {
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            static var noFollow: AtOptions { AtOptions(rawValue: AT_SYMLINK_NOFOLLOW) }
        }

        struct RemoveOptions: OptionSet {
            var rawValue: CInt
            init(rawValue: CInt) { self.rawValue = rawValue }

            static var removeDirectory: RemoveOptions { RemoveOptions(rawValue: AT_REMOVEDIR) }
        }

        /// Opens a path relative to this directory descriptor; the C
        /// equivalent is `openat`.
        func open(
            at path: String, _ mode: AccessMode,
            options: OpenOptions = OpenOptions(rawValue: 0),
            permissions: FilePermissions = FilePermissions(rawValue: 0)
        ) throws -> FileDescriptor {
            let fd = try valueOrErrno {
                path.withCString { openat(rawValue, $0, mode.rawValue | options.rawValue, mode_t(permissions.rawValue)) }
            }
            return FileDescriptor(rawValue: fd)
        }

        /// Queries metadata of a path relative to this directory descriptor;
        /// the C equivalent is `fstatat`.
        func attributes(at path: String, options: AtOptions = AtOptions(rawValue: 0)) throws -> Attributes {
            var statBuffer = stat()
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { fstatat(rawValue, $0, &statBuffer, options.rawValue) }
            }
            return Attributes(rawValue: statBuffer)
        }

        /// Removes a file or directory entry relative to this directory
        /// descriptor; the C equivalent is `unlinkat`.
        func remove(at path: String, options: RemoveOptions = RemoveOptions(rawValue: 0)) throws {
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { unlinkat(rawValue, $0, options.rawValue) }
            }
        }

        /// Creates a directory relative to this directory descriptor; the C
        /// equivalent is `mkdirat`.
        func createDirectory(at path: String, permissions: FilePermissions) throws {
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { mkdirat(rawValue, $0, mode_t(permissions.rawValue)) }
            }
        }

        /// Creates a symlink at `link` (relative to this directory descriptor)
        /// pointing to `original`; the C equivalent is `symlinkat`.
        func createSymlink(original: String, link: String) throws {
            try valueOrErrno(retryOnInterrupt: false) {
                original.withCString { originalCStr in
                    link.withCString { linkCStr in
                        symlinkat(originalCStr, rawValue, linkCStr)
                    }
                }
            }
        }

        /// Renames `path` (relative to this descriptor) to `newPath` relative
        /// to `newDir`; the C equivalent is `renameat`.
        func rename(at path: String, to newDir: FileDescriptor, at newPath: String) throws {
            try valueOrErrno(retryOnInterrupt: false) {
                path.withCString { oldCStr in
                    newPath.withCString { newCStr in
                        renameat(rawValue, oldCStr, newDir.rawValue, newCStr)
                    }
                }
            }
        }

        /// Reads the target of a symlink relative to this directory
        /// descriptor into `buffer`; the C equivalent is `readlinkat`.
        /// Returns the number of bytes written (no NUL terminator is added).
        func readSymlink(at path: String, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            guard let base = buffer.baseAddress else { throw PlatformErrno(rawValue: EINVAL) }
            return try valueOrErrno(retryOnInterrupt: false) {
                path.withCString {
                    readlinkat(rawValue, $0, base.assumingMemoryBound(to: CChar.self), buffer.count)
                }
            }
        }
    }

    // MARK: - Directory enumeration

    extension FileDescriptor {
        struct DirectoryEntry {
            let rawValue: UnsafeMutablePointer<dirent>

            var name: String {
                #if os(WASI)
                    // ClangImporter can't handle `char d_name[]`, but it's
                    // right after `unsigned char d_type`.
                    withUnsafePointer(to: &rawValue.pointee.d_type) { dType in
                        (dType + 1).withMemoryRebound(to: UInt8.self, capacity: 1) {
                            String(cString: $0)
                        }
                    }
                #else
                    withUnsafePointer(to: &rawValue.pointee.d_name) { dName in
                        dName.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: dName)) {
                            String(cString: $0)
                        }
                    }
                #endif
            }

            var fileType: FileType {
                #if os(WASI)
                    // wasi-libc's d_type values are WASI `filetype` values, which
                    // `WASIAbi.FileType(platformFileType:)` does not consume; map
                    // the common ones onto stat-style types.
                    switch UInt8(rawValue.pointee.d_type) {
                    case UInt8(DT_DIR): return FileType(rawValue: S_IFDIR)
                    case UInt8(DT_REG): return FileType(rawValue: S_IFREG)
                    case UInt8(DT_LNK): return FileType(rawValue: S_IFLNK)
                    case UInt8(DT_BLK): return FileType(rawValue: S_IFBLK)
                    case UInt8(DT_CHR): return FileType(rawValue: S_IFCHR)
                    default: return FileType(rawValue: S_IFMT)
                    }
                #else
                    switch CInt(rawValue.pointee.d_type) {
                    case CInt(DT_DIR): return FileType(rawValue: S_IFDIR)
                    case CInt(DT_REG): return FileType(rawValue: S_IFREG)
                    case CInt(DT_LNK): return FileType(rawValue: S_IFLNK)
                    case CInt(DT_BLK): return FileType(rawValue: S_IFBLK)
                    case CInt(DT_CHR): return FileType(rawValue: S_IFCHR)
                    case CInt(DT_SOCK): return FileType(rawValue: S_IFSOCK)
                    default: return FileType(rawValue: S_IFMT)
                    }
                #endif
            }
        }

        struct DirectoryStream: IteratorProtocol, Sequence {
            #if canImport(Darwin)
                typealias DirP = UnsafeMutablePointer<DIR>
            #else
                typealias DirP = OpaquePointer
            #endif
            let rawValue: DirP

            /// Closes the stream and the file descriptor it took ownership of.
            func close() {
                _ = closedir(rawValue)
            }

            func next() -> Result<DirectoryEntry, PlatformErrno>? {
                // readdir returns NULL both at end-of-stream and on error;
                // reset errno first to tell the two apart.
                setErrno(0)
                if let entry = readdir(rawValue) {
                    return .success(DirectoryEntry(rawValue: entry))
                }
                let current = PlatformErrno.current
                if current.rawValue == 0 { return nil }
                return .failure(current)
            }
        }

        /// Opens a directory stream over this descriptor; the C equivalent is
        /// `fdopendir`. The stream takes ownership of the descriptor, and
        /// closing the stream closes it.
        func contentsOfDirectory() throws -> DirectoryStream {
            guard let dirp = fdopendir(rawValue) else {
                throw PlatformErrno.current
            }
            return DirectoryStream(rawValue: dirp)
        }
    }

    private func setErrno(_ value: CInt) {
        errno = value
    }

#endif
