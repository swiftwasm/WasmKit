import SystemExtras
import SystemPackage

/// A WASIDir implementation backed by an in-memory directory node.
struct MemoryDirEntry: WASIDir {
    let preopenPath: String?
    let dirNode: MemoryDirectoryNode
    let path: String
    let fileSystem: MemoryFileSystem

    func attributes() throws -> WASIAbi.Filestat {
        let timestamps = dirNode.timestamps
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .DIRECTORY,
            nlink: 1, size: 0,
            atim: timestamps.atim,
            mtim: timestamps.mtim,
            ctim: timestamps.ctim
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
        // Memory filesystem doesn't return real file descriptors for this method
        // File opening is handled through the WASI bridge's path_open implementation
        throw WASIAbi.Errno.ENOTSUP
    }

    func createDirectory(atPath path: String) throws {
        let fullPath = self.path.hasSuffix("/") ? self.path + path : self.path + "/" + path
        try fileSystem.ensureDirectory(at: fullPath)
    }

    func removeDirectory(atPath path: String) throws {
        try fileSystem.removeNode(in: dirNode, at: path, mustBeDirectory: true)
    }

    func removeFile(atPath path: String) throws {
        try fileSystem.removeNode(in: dirNode, at: path, mustBeDirectory: false)
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
            from: sourcePath, in: dirNode,
            to: destPath, in: newMemoryDir.dirNode
        )
    }

    func readEntries(cookie: WASIAbi.DirCookie) throws -> AnyIterator<Result<ReaddirElement, any Error>> {
        let children = dirNode.listChildren()

        let iterator = children.enumerated()
            .dropFirst(Int(cookie))
            .map { (index, name) -> Result<ReaddirElement, any Error> in
                return Result(catching: {
                    let childPath = self.path.hasSuffix("/") ? self.path + name : self.path + "/" + name
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
            .makeIterator()

        return AnyIterator(iterator)
    }

    func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat {
        let fullPath = self.path.hasSuffix("/") ? self.path + path : self.path + "/" + path
        guard let node = fileSystem.lookup(at: fullPath) else {
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
                size = WASIAbi.FileSize(fileNode.size)
                let timestamps = fileNode.timestamps
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
        let fullPath = self.path.hasSuffix("/") ? self.path + path : self.path + "/" + path
        guard let node = fileSystem.lookup(at: fullPath) else {
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

        switch fileNode.content {
        case .bytes:
            fileNode.setTimes(atim: newAtim, mtim: newMtim)

        case .handle(let handle):
            let accessTime: FileTime
            if fstFlags.contains(.ATIM) {
                accessTime = FileTime(
                    seconds: Int(atim / 1_000_000_000),
                    nanoseconds: Int(atim % 1_000_000_000)
                )
            } else if fstFlags.contains(.ATIM_NOW) {
                accessTime = .now
            } else {
                accessTime = .omit
            }

            let modTime: FileTime
            if fstFlags.contains(.MTIM) {
                modTime = FileTime(
                    seconds: Int(mtim / 1_000_000_000),
                    nanoseconds: Int(mtim % 1_000_000_000)
                )
            } else if fstFlags.contains(.MTIM_NOW) {
                modTime = .now
            } else {
                modTime = .omit
            }

            try handle.setTimes(access: accessTime, modification: modTime)
        }
    }
}
