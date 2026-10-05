import WasmTypes

struct DirEntry {
    let preopenPath: String?
    let fd: FileDescriptor
}

extension DirEntry: WASIDir, FdWASIEntry {
    func readlink(atPath path: String) throws -> [UInt8] {
        // Capability checking is owned by `SandboxPrimitives.readlinkAt`.
        try SandboxPrimitives.readlinkAt(start: fd, path: path)
    }

    func openFile(
        symlinkFollow: Bool,
        path: String,
        oflags: WASIAbi.Oflags,
        accessMode: FileAccessMode,
        fdflags: WASIAbi.Fdflags
    ) throws -> FileDescriptor {
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

        // A trailing "/" is dropped by guest path parsing, but it means the
        // last component is expected to be a directory, so check it here
        // before parsing the path string.
        if path.hasSuffix("/") {
            options.insert(.directory)
        }

        options.formUnion(fdflags.platformOpenOptions)

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
            path: GuestPath(path), mode: mode, options: options,
            // Use 0o600 open mode as the minimum permission
            permissions: .ownerReadWrite
        )
        return newFd
    }

    func setFilestatTimes(
        path: String,
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
    ) throws {
        let (access, modification) = try WASIAbi.Timestamp.platformTimeSpec(
            atim: atim, mtim: mtim, fstFlags: fstFlags
        )
        // Following happens in the sandbox, and `utimensat` never follows a
        // symlink in the last component itself.
        let result =
            symlinkFollow
            ? try SandboxPrimitives.openParentFollowingSymlinks(start: fd, path: path)
            : try SandboxPrimitives.openParent(start: fd, path: path)
        try result.withFields { dir, basename in
            try dir.setTimes(at: basename, options: .noFollow, access: access, modification: modification)
        }
    }

    func removeFile(atPath path: String) throws {
        let result = try SandboxPrimitives.openParent(start: fd, path: path)
        try result.withFields { dir, basename in
            try dir.remove(at: basename, options: [])
        }
    }

    func removeDirectory(atPath path: String) throws {
        let path = SandboxPrimitives.stripDirSuffix(path)
        let result = try SandboxPrimitives.openParent(start: fd, path: path)
        try result.withFields { dir, basename in
            try dir.remove(at: basename, options: .removeDirectory)
        }
    }

    func symlink(from sourcePath: String, to destPath: String) throws {
        let result = try SandboxPrimitives.openParent(
            start: fd, path: destPath
        )
        try result.withFields { destDir, destBasename in
            try destDir.createSymlink(original: sourcePath, link: destBasename) {
                // Look the target up inside the sandbox, relative to the
                // directory the link goes in.
                guard let (parent, _) = splitParent(path: destPath) else { return false }
                let targetPath = parent.isEmpty ? sourcePath : parent.string + "/" + sourcePath
                guard
                    let target = try? SandboxPrimitives.openAt(
                        start: fd, path: GuestPath(targetPath), mode: .readOnly, options: .directory, permissions: [])
                else { return false }
                try? target.close()
                return true
            }
        }
    }

    func link(from sourcePath: String, toDir newDir: any WASIDir, to destPath: String) throws {
        guard let newDir = newDir as? Self else {
            throw WASIAbi.Errno.EBADF
        }
        let sourceResult = try SandboxPrimitives.openParent(start: fd, path: sourcePath)
        let destResult = try SandboxPrimitives.openParent(start: newDir.fd, path: destPath)
        try sourceResult.withFields { sourceDir, sourceBasename in
            try destResult.withFields { destDir, destBasename in
                try sourceDir.createHardLink(at: sourceBasename, to: destDir, at: destBasename)
            }
        }
    }

    func rename(from sourcePath: String, toDir newDir: any WASIDir, to destPath: String) throws {
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

        let sourceResult = try SandboxPrimitives.openParent(
            start: fd, path: oldPath
        )
        let destResult = try SandboxPrimitives.openParent(
            start: newDir.fd, path: newPath
        )
        try sourceResult.withFields { sourceDir, sourceBasename in
            try destResult.withFields { destDir, destBasename in
                // Re-append a slash if the original path had one
                let finalSourceBasename = oldHasTrailingSlash ? sourceBasename + "/" : sourceBasename
                let finalDestBasename = newHasTrailingSlash ? destBasename + "/" : destBasename

                try sourceDir.rename(
                    at: finalSourceBasename,
                    to: destDir,
                    at: finalDestBasename
                )
            }
        }
    }

    struct HostDirectoryIterator: WASIReaddirIterator {
        let stream: FileDescriptor.DirectoryStream
        var entryIndex: Int

        init(
            fd: FileDescriptor,
            cookie: WASIAbi.DirCookie
        ) throws {
            // Duplicate fd because readdir takes the ownership of
            // the given fd and closedir also close the underlying fd
            let newFd = try fd.open(at: ".", .readOnly)
            let stream = try newFd.contentsOfDirectory()

            self.entryIndex = 0
            self.stream = stream

            // The cookie is a `u64` the guest chooses; one past the last entry
            // simply skips everything.
            let skippedCount = Int(clamping: cookie)
            while entryIndex < skippedCount {
                guard let entry = stream.next() else { break }
                _ = try entry.get()
                entryIndex += 1
            }
        }

        mutating func next() -> Result<ReaddirElement, any Error>? {
            guard let entry = stream.next() else {
                return nil
            }
            defer { entryIndex += 1 }
            return Result(catching: { () -> ReaddirElement in
                let entry = try entry.get()
                let name = entry.name
                let dirent = WASIAbi.Dirent(
                    // We can't use telldir and seekdir because the location data
                    // is valid for only the same dirp but and there is no way to
                    // share dirp among fd_readdir calls.
                    dNext: WASIAbi.DirCookie(entryIndex + 1),
                    // The inode readdir reports, as wasmtime does, rather
                    // than one `fstatat` per entry.
                    dIno: entry.inode,
                    dirNameLen: WASIAbi.DirNameLen(name.utf8.count),
                    dType: WASIAbi.FileType(platformFileType: entry.fileType)
                )
                return (dirent, name)
            })
        }

        mutating func close() {
            stream.close()
        }
    }
    func readEntries(
        cookie: WASIAbi.DirCookie
    ) throws -> WASIReaddirEntries {
        return WASIReaddirEntries(try HostDirectoryIterator(fd: fd, cookie: cookie))
    }

    func createDirectory(atPath path: String) throws {
        let result = try SandboxPrimitives.openParent(start: fd, path: path)
        try result.withFields { dir, basename in
            try dir.createDirectory(at: basename, permissions: .ownerReadWriteExecute)
        }
    }

    func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat {
        // Following happens in the sandbox, never in the host's `fstatat`,
        // which would follow a symlink pointing out of the sandbox.
        let result =
            symlinkFollow
            ? try SandboxPrimitives.openParentFollowingSymlinks(start: fd, path: path)
            : try SandboxPrimitives.openParent(start: fd, path: path)
        return try result.withFields { dir, basename in
            let attributes = try dir.attributes(at: basename, options: .noFollow)

            return WASIAbi.Filestat(stat: attributes)
        }
    }
}
