import SystemExtras
import SystemPackage

/// A WASIDir implementation backed by an in-memory directory node.
struct MemoryDirEntry: WASIDir {
    struct ReadEntriesResult: WASIReaddirIterator {
        let children: [String]
        let fileSystem: MemoryFileSystem
        let basePath: String
        var nextIndex: Int

        mutating func next() -> Result<ReaddirElement, any Error>? {
            guard nextIndex < children.count else { return nil }
            let index = nextIndex
            let name = children[index]
            nextIndex += 1
            return Result(catching: {
                let childPath = MemoryFileSystem.joinGuestPath(basePath, name)
                guard let childNode = fileSystem.lookup(at: childPath) else {
                    throw WASIAbi.Errno.ENOENT
                }

                let fileType: WASIAbi.FileType
                switch childNode.type {
                case .directory: fileType = .DIRECTORY
                case .file: fileType = .REGULAR_FILE
                case .characterDevice: fileType = .CHARACTER_DEVICE
                }

                let dirent = WASIAbi.Dirent(
                    dNext: WASIAbi.DirCookie(index + 1),
                    dIno: 0,
                    dirNameLen: WASIAbi.DirNameLen(name.utf8.count),
                    dType: fileType
                )

                return (dirent, name)
            })
        }

        mutating func close() {
        }
    }

    let preopenPath: String?
    let dirNode: MemoryDirectoryNode
    let path: String
    let fileSystem: MemoryFileSystem

    func readlink(atPath path: String) throws -> [UInt8] {
        // Symlinks are not supported in the memory filesystem.
        throw WASIAbi.Errno.ENOTSUP
    }

    func attributes() throws -> WASIAbi.Filestat {
        let timestamps = dirNode.timestamps
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .DIRECTORY,
            nlink: 1, size: 0,
            atim: timestamps.atim, mtim: timestamps.mtim, ctim: timestamps.ctim
        )
    }

    func fileType() throws -> WASIAbi.FileType {
        return .DIRECTORY
    }

    func status() throws -> WASIAbi.Fdflags {
        return []
    }

    func setTimes(
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        let now = WASIAbi.Timestamp.currentWallClock()
        let newAtim: WASIAbi.Timestamp?
        if fstFlags.contains(.ATIM) {
            newAtim = atim
        } else if fstFlags.contains(.ATIM_NOW) {
            newAtim = now
        } else {
            newAtim = nil
        }

        let newMtim: WASIAbi.Timestamp?
        if fstFlags.contains(.MTIM) {
            newMtim = mtim
        } else if fstFlags.contains(.MTIM_NOW) {
            newMtim = now
        } else {
            newMtim = nil
        }

        dirNode.setTimes(atim: newAtim, mtim: newMtim)
    }

    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws {
        // No-op for memory filesystem
    }

    func close() throws {
        // No-op for memory filesystem - no resources to release
    }

    func openFile(
        symlinkFollow: Bool,
        path: String,
        oflags: WASIAbi.Oflags,
        accessMode: FileAccessMode,
        fdflags: WASIAbi.Fdflags
    ) throws -> FileDescriptor {
        // Memory filesystem doesn't return real file descriptors for this method.
        // File opening is handled through the WASI bridge's path_open implementation.
        throw WASIAbi.Errno.ENOTSUP
    }

    func createDirectory(atPath path: String) throws {
        try fileSystem.ensureDirectory(at: MemoryFileSystem.joinGuestPath(self.path, path))
    }

    func removeDirectory(atPath path: String) throws {
        try fileSystem.removeNode(at: self.path, relativePath: path, mustBeDirectory: true)
    }

    func removeFile(atPath path: String) throws {
        try fileSystem.removeNode(at: self.path, relativePath: path, mustBeDirectory: false)
    }

    func symlink(from sourcePath: String, to destPath: String) throws {
        // Symlinks not supported in memory filesystem
        throw WASIAbi.Errno.ENOTSUP
    }

    func rename(from sourcePath: String, toDir newDir: any WASIDir, to destPath: String) throws {
        guard let newMemoryDir = newDir as? MemoryDirEntry else {
            throw WASIAbi.Errno.EXDEV
        }

        try fileSystem.rename(
            from: sourcePath, at: self.path,
            to: destPath, at: newMemoryDir.path
        )
    }

    func readEntries(cookie: WASIAbi.DirCookie) throws -> ReadEntriesResult {
        ReadEntriesResult(
            children: dirNode.listChildren(),
            fileSystem: fileSystem,
            basePath: path,
            nextIndex: Int(cookie)
        )
    }

    func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat {
        guard let node = fileSystem.lookup(at: MemoryFileSystem.joinGuestPath(self.path, path)) else {
            throw WASIAbi.Errno.ENOENT
        }

        let fileType: WASIAbi.FileType
        var size: WASIAbi.FileSize = 0
        var atim: WASIAbi.Timestamp = 0
        var mtim: WASIAbi.Timestamp = 0
        var ctim: WASIAbi.Timestamp = 0

        switch node.type {
        case .directory:
            fileType = .DIRECTORY
            if let dirNode = node as? MemoryDirectoryNode {
                let timestamps = dirNode.timestamps
                atim = timestamps.atim
                mtim = timestamps.mtim
                ctim = timestamps.ctim
            }
        case .file:
            fileType = .REGULAR_FILE
            if let fileNode = node as? MemoryFileNode {
                size = WASIAbi.FileSize(try fileNode.size)
                let timestamps = try fileNode.timestamps
                atim = timestamps.atim
                mtim = timestamps.mtim
                ctim = timestamps.ctim
            }
        case .characterDevice:
            fileType = .CHARACTER_DEVICE
        }

        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: fileType,
            nlink: 1, size: size,
            atim: atim, mtim: mtim, ctim: ctim
        )
    }

    func setFilestatTimes(
        path: String,
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
    ) throws {
        guard let node = fileSystem.lookup(at: MemoryFileSystem.joinGuestPath(self.path, path)) else {
            throw WASIAbi.Errno.ENOENT
        }

        let now = WASIAbi.Timestamp.currentWallClock()
        let newAtim: WASIAbi.Timestamp?
        if fstFlags.contains(.ATIM) {
            newAtim = atim
        } else if fstFlags.contains(.ATIM_NOW) {
            newAtim = now
        } else {
            newAtim = nil
        }

        let newMtim: WASIAbi.Timestamp?
        if fstFlags.contains(.MTIM) {
            newMtim = mtim
        } else if fstFlags.contains(.MTIM_NOW) {
            newMtim = now
        } else {
            newMtim = nil
        }

        if let dirNode = node as? MemoryDirectoryNode {
            dirNode.setTimes(atim: newAtim, mtim: newMtim)
            return
        }

        guard let fileNode = node as? MemoryFileNode else {
            return
        }

        // nil means the times were applied in memory; a non-nil handle is a host
        // fd whose times we set below.
        guard let handle = fileNode.setTimesInMemory(atim: newAtim, mtim: newMtim) else {
            return
        }

        let accessTime: FileTime
        if fstFlags.contains(.ATIM) {
            accessTime = FileTime(seconds: Int(atim / 1_000_000_000), nanoseconds: Int(atim % 1_000_000_000))
        } else if fstFlags.contains(.ATIM_NOW) {
            accessTime = .now
        } else {
            accessTime = .omit
        }

        let modTime: FileTime
        if fstFlags.contains(.MTIM) {
            modTime = FileTime(seconds: Int(mtim / 1_000_000_000), nanoseconds: Int(mtim % 1_000_000_000))
        } else if fstFlags.contains(.MTIM_NOW) {
            modTime = .now
        } else {
            modTime = .omit
        }

        try handle.setTimes(access: accessTime, modification: modTime)
    }
}
