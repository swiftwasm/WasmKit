import SystemPackage

/// A WASIDir implementation backed by an in-memory directory node.
internal struct MemoryDirEntry: WASIDir {
    let preopenPath: String?
    let dirNode: MemoryDirectoryNode
    let path: String
    let fileSystem: MemoryFileSystem
    
    func attributes() throws -> WASIAbi.Filestat {
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .DIRECTORY,
            nlink: 1, size: 0,
            atim: 0, mtim: 0, ctim: 0
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
        // No-op for memory filesystem - timestamps not tracked
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
        
        switch node.type {
        case .directory:
            fileType = .DIRECTORY
        case .file:
            fileType = .REGULAR_FILE
            if let fileNode = node as? MemoryFileNode {
                size = WASIAbi.FileSize(fileNode.size)
            }
        case .characterDevice:
            fileType = .CHARACTER_DEVICE
        }
        
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: fileType,
            nlink: 1, size: size,
            atim: 0, mtim: 0, ctim: 0
        )
    }
    
    func setFilestatTimes(
        path: String,
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
    ) throws {
        // No-op for memory filesystem - timestamps not tracked
    }
}