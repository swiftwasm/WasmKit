import SystemPackage

struct DirEntry {
    let preopenPath: String?
    let fd: FileDescriptor
}

extension DirEntry: WASIDir, FdWASIEntry {
    func readlink(atPath path: String) throws -> [UInt8] {
        #if os(Windows) || os(WASI)
            throw WASIAbi.Errno.ENOTSUP
        #else
            return try SandboxPrimitives.readlinkAt(start: fd, path: path)
        #endif
    }

    func openFile(
        symlinkFollow: Bool,
        path: String,
        oflags: WASIAbi.Oflags,
        accessMode: FileAccessMode,
        fdflags: WASIAbi.Fdflags
    ) throws -> FileDescriptor {
        #if os(Windows)
            throw WASIAbi.Errno.ENOSYS
        #else
            var options: FileDescriptor.OpenOptions = []
            if !symlinkFollow {
                options.insert(.noFollow)
            }

            if oflags.contains(.DIRECTORY) {
                options.insert(.directory)
            } else {
                // For regular file
                if oflags.contains(.CREAT) {
                    options.insert(.create)
                }
                if oflags.contains(.EXCL) {
                    options.insert(.exclusiveCreate)
                }
                if oflags.contains(.TRUNC) {
                    options.insert(.truncate)
                }
            }

            // SystemPackage.FilePath implicitly normalizes the trailing "/", however
            // it means the last component is expected to be a directory. Therefore
            // check it here before converting path string to FilePath.
            if path.hasSuffix("/") {
                options.insert(.directory)
            }

            if fdflags.contains(.APPEND) {
                options.insert(.append)
            }

            let mode: FileDescriptor.AccessMode
            switch (accessMode.contains(.read), accessMode.contains(.write)) {
            case (true, true): mode = .readWrite
            case (true, false): mode = .readOnly
            case (false, true): mode = .writeOnly
            case (false, false):
                // If not opened for neither write nor read, set read mode by default
                // because underlying `openat` requires mode but WASI's
                // `path_open` can omit FD_READ.
                // https://man7.org/linux/man-pages/man2/open.2.html
                // > The argument flags must include one of the following access
                // > modes: O_RDONLY, O_WRONLY, or O_RDWR.  These request opening the
                // > file read-only, write-only, or read/write, respectively.
                mode = .readOnly
            }

            let newFd = try SandboxPrimitives.openAt(
                start: self.fd,
                path: FilePath(path), mode: mode, options: options,
                // Use 0o600 open mode as the minimum permission
                permissions: .ownerReadWrite
            )
            return newFd
        #endif
    }

    func setFilestatTimes(
        path: String,
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
    ) throws {
        let fd = try openFile(
            symlinkFollow: symlinkFollow, path: path,
            oflags: [], accessMode: .write, fdflags: []
        )
        let (access, modification) = try WASIAbi.Timestamp.platformTimeSpec(
            atim: atim, mtim: mtim, fstFlags: fstFlags
        )
        try WASIAbi.Errno.translatingPlatformErrno {
            try fd.setTimes(access: access, modification: modification)
        }
    }

    func removeFile(atPath path: String) throws {
        let (dir, basename) = try SandboxPrimitives.openParent(start: fd, path: path)
        try WASIAbi.Errno.translatingPlatformErrno {
            try dir.remove(at: FilePath(basename), options: [])
        }
    }

    func removeDirectory(atPath path: String) throws {
        #if os(Windows)
            throw WASIAbi.Errno.ENOSYS
        #else
            let (dir, basename) = try SandboxPrimitives.openParent(start: fd, path: path)
            try WASIAbi.Errno.translatingPlatformErrno {
                try dir.remove(at: FilePath(basename), options: .removeDirectory)
            }
        #endif
    }

    func symlink(from sourcePath: String, to destPath: String) throws {
        let (destDir, destBasename) = try SandboxPrimitives.openParent(
            start: fd, path: destPath
        )
        try WASIAbi.Errno.translatingPlatformErrno {
            try destDir.createSymlink(original: FilePath(sourcePath), link: FilePath(destBasename))
        }
    }

    func rename(from sourcePath: String, toDir newDir: any WASIDir, to destPath: String) throws {
        #if os(Windows)
            throw WASIAbi.Errno.ENOSYS
        #else
            guard let newDir = newDir as? Self else {
                throw WASIAbi.Errno.EBADF
            }

            // As a special case, rename ignores a trailing slash rather than treating
            // it as equivalent to a trailing slash-dot, so strip any trailing slashes
            // for the purposes of openParent.
            let oldHasTrailingSlash = SandboxPrimitives.pathHasTrailingSlash(sourcePath)
            let newHasTrailingSlash = SandboxPrimitives.pathHasTrailingSlash(destPath)

            let oldPath = SandboxPrimitives.stripDirSuffix(sourcePath)
            let newPath = SandboxPrimitives.stripDirSuffix(destPath)

            let (sourceDir, sourceBasename) = try SandboxPrimitives.openParent(
                start: fd, path: oldPath
            )
            let (destDir, destBasename) = try SandboxPrimitives.openParent(
                start: newDir.fd, path: newPath
            )

            // Re-append a slash if the original path had one
            let finalSourceBasename = oldHasTrailingSlash ? sourceBasename + "/" : sourceBasename
            let finalDestBasename = newHasTrailingSlash ? destBasename + "/" : destBasename

            try WASIAbi.Errno.translatingPlatformErrno {
                try sourceDir.rename(
                    at: FilePath(finalSourceBasename),
                    to: destDir,
                    at: FilePath(finalDestBasename)
                )
            }
        #endif
    }

    func readEntries(
        cookie: WASIAbi.DirCookie
    ) throws -> AnyIterator<Result<ReaddirElement, any Error>> {
        #if os(Windows)
            throw WASIAbi.Errno.ENOSYS
        #else
            // Duplicate fd because readdir takes the ownership of
            // the given fd and closedir also close the underlying fd
            let newFd = try WASIAbi.Errno.translatingPlatformErrno {
                try fd.open(at: ".", .readOnly, options: [])
            }
            let iterator = try WASIAbi.Errno.translatingPlatformErrno {
                try newFd.contentsOfDirectory()
            }
            .lazy.enumerated()
            .map { (entryIndex, entry) in
                return Result(catching: { () -> ReaddirElement in
                    let entry = try entry.get()
                    let name = entry.name
                    let stat = try WASIAbi.Errno.translatingPlatformErrno {
                        try fd.attributes(at: name, options: [])
                    }
                    let dirent = WASIAbi.Dirent(
                        // We can't use telldir and seekdir because the location data
                        // is valid for only the same dirp but and there is no way to
                        // share dirp among fd_readdir calls.
                        dNext: WASIAbi.DirCookie(entryIndex + 1),
                        dIno: stat.inode,
                        dirNameLen: WASIAbi.DirNameLen(name.utf8.count),
                        dType: WASIAbi.FileType(platformFileType: entry.fileType)
                    )
                    return (dirent, name)
                })
            }
            .dropFirst(Int(cookie))
            .makeIterator()
            return AnyIterator(iterator)
        #endif
    }

    func createDirectory(atPath path: String) throws {
        let (dir, basename) = try SandboxPrimitives.openParent(start: fd, path: path)
        try WASIAbi.Errno.translatingPlatformErrno {
            try dir.createDirectory(at: FilePath(basename), permissions: .ownerReadWriteExecute)
        }
    }

    func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat {
        #if os(Windows)
            throw WASIAbi.Errno.ENOSYS
        #else
            var options: FileDescriptor.AtOptions = []
            if !symlinkFollow {
                options.insert(.noFollow)
            }
            let (dir, basename) = try SandboxPrimitives.openParent(start: fd, path: path)
            let attributes = try basename.withCString { cBasename in
                try WASIAbi.Errno.translatingPlatformErrno {
                    try dir.attributes(at: cBasename, options: options)
                }
            }

            return WASIAbi.Filestat(stat: attributes)
        #endif
    }
}
