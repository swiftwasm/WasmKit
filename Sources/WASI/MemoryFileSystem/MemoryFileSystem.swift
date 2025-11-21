import SystemPackage

/// An in-memory file system implementation for WASI environments.
///
/// This provides a complete file system that exists entirely in memory, useful for
/// sandboxed environments or testing scenarios where host file system access is not desired.
///
/// Supports both in-memory byte arrays and file descriptor handles.
///
/// Example usage:
/// ```swift
/// let fs = try MemoryFileSystem(preopens: ["/": "/"])
/// try fs.addFile(at: "/hello.txt", content: "Hello, world!")
///
/// // Or add a file handle
/// let fd = try FileDescriptor.open("/path/to/file", .readOnly)
/// try fs.addFile(at: "/mounted.txt", handle: fd)
/// ```
public final class MemoryFileSystem: FileSystemProvider, FileSystem {
    private static let rootPath = "/"
    
    private var root: MemoryDirectoryNode
    private let preopenPaths: [String]

    /// Creates a new in-memory file system.
    ///
    /// - Parameter preopens: Dictionary mapping guest paths to host paths.
    ///   Since this is a memory file system, host paths are ignored and only
    ///   guest paths are used to determine pre-opened directories.
    public init(preopens: [String: String]? = nil) throws {
        self.root = MemoryDirectoryNode()

        if let preopens = preopens {
            self.preopenPaths = Array(preopens.keys).sorted()
        } else {
            self.preopenPaths = [Self.rootPath]
        }

        for guestPath in self.preopenPaths {
            try ensureDirectory(at: guestPath)
        }

        let devDir = try ensureDirectory(at: "/dev")
        devDir.setChild(name: "null", node: MemoryCharacterDeviceNode(kind: .null))
    }

    // MARK: - FileSystemProvider (Public API)
    
    /// Adds a file to the file system with the given byte content.
    ///
    /// - Parameters:
    ///   - path: The path where the file should be created
    ///   - content: The file content as byte array
    public func addFile(at path: String, content: [UInt8]) throws {
        let normalized = normalizePath(path)
        let (parentPath, fileName) = try splitPath(normalized)

        let parent = try ensureDirectory(at: parentPath)
        parent.setChild(name: fileName, node: MemoryFileNode(bytes: content))
    }

    /// Adds a file to the file system with the given string content.
    ///
    /// - Parameters:
    ///   - path: The path where the file should be created
    ///   - content: The file content as string (converted to UTF-8)
    public func addFile(at path: String, content: String) throws {
        try addFile(at: path, content: Array(content.utf8))
    }

    /// Adds a file to the file system backed by a file descriptor.
    ///
    /// - Parameters:
    ///   - path: The path where the file should be created
    ///   - handle: The file descriptor handle
    public func addFile(at path: String, handle: FileDescriptor) throws {
        let normalized = normalizePath(path)
        let (parentPath, fileName) = try splitPath(normalized)

        let parent = try ensureDirectory(at: parentPath)
        parent.setChild(name: fileName, node: MemoryFileNode(handle: handle))
    }

    /// Gets the content of a file at the specified path.
    ///
    /// - Parameter path: The path of the file to retrieve
    /// - Returns: The file content
    public func getFile(at path: String) throws -> FileContent {
        guard let node = lookup(at: path) else {
            throw WASIAbi.Errno.ENOENT
        }

        guard let fileNode = node as? MemoryFileNode else {
            throw WASIAbi.Errno.EISDIR
        }

        return fileNode.content
    }

    /// Removes a file from the file system.
    ///
    /// - Parameter path: The path of the file to remove
    public func removeFile(at path: String) throws {
        let normalized = normalizePath(path)
        let (parentPath, fileName) = try splitPath(normalized)

        guard let parent = lookup(at: parentPath) as? MemoryDirectoryNode else {
            throw WASIAbi.Errno.ENOENT
        }

        guard parent.removeChild(name: fileName) else {
            throw WASIAbi.Errno.ENOENT
        }
    }

    // MARK: - FileSystem (Internal WASI API)
    
    internal func getPreopenPaths() -> [String] {
        return preopenPaths
    }
    
    internal func openDirectory(at path: String) throws -> any WASIDir {
        guard let node = lookup(at: path) else {
            throw WASIAbi.Errno.ENOENT
        }
        
        guard let dirNode = node as? MemoryDirectoryNode else {
            throw WASIAbi.Errno.ENOTDIR
        }
        
        return MemoryDirEntry(
            preopenPath: preopenPaths.contains(path) ? path : nil,
            dirNode: dirNode,
            path: path,
            fileSystem: self
        )
    }
    
    internal func openAt(
        dirFd: any WASIDir,
        path: String,
        oflags: WASIAbi.Oflags,
        fsRightsBase: WASIAbi.Rights,
        fsRightsInheriting: WASIAbi.Rights,
        fdflags: WASIAbi.Fdflags,
        symlinkFollow: Bool
    ) throws -> FdEntry {
        guard let memoryDir = dirFd as? MemoryDirEntry else {
            throw WASIAbi.Errno.EBADF
        }
        
        let fullPath = memoryDir.path.hasSuffix("/") ? memoryDir.path + path : memoryDir.path + "/" + path
        
        var node = resolve(from: memoryDir.dirNode, at: memoryDir.path, path: path)
        
        if node != nil {
            if oflags.contains(.EXCL) && oflags.contains(.CREAT) {
                throw WASIAbi.Errno.EEXIST
            }
        } else {
            if oflags.contains(.CREAT) {
                node = try createFile(in: memoryDir.dirNode, at: path, oflags: oflags)
            } else {
                throw WASIAbi.Errno.ENOENT
            }
        }
        
        guard let resolvedNode = node else {
            throw WASIAbi.Errno.ENOENT
        }
        
        if oflags.contains(.DIRECTORY) {
            guard resolvedNode.type == .directory else {
                throw WASIAbi.Errno.ENOTDIR
            }
        }
        
        if resolvedNode.type == .directory {
            guard let dirNode = resolvedNode as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOTDIR
            }
            return .directory(MemoryDirEntry(
                preopenPath: nil,
                dirNode: dirNode,
                path: fullPath,
                fileSystem: self
            ))
        } else if resolvedNode.type == .file {
            guard let fileNode = resolvedNode as? MemoryFileNode else {
                throw WASIAbi.Errno.EBADF
            }
            
            if oflags.contains(.TRUNC) && fsRightsBase.contains(.FD_WRITE) {
                fileNode.content = .bytes([])
            }
            
            var accessMode: FileAccessMode = []
            if fsRightsBase.contains(.FD_READ) {
                accessMode.insert(.read)
            }
            if fsRightsBase.contains(.FD_WRITE) {
                accessMode.insert(.write)
            }
            
            return .file(MemoryFileEntry(fileNode: fileNode, accessMode: accessMode, position: 0))
        } else {
            throw WASIAbi.Errno.ENOTSUP
        }
    }
    
    internal func createStdioFile(fd: FileDescriptor, accessMode: FileAccessMode) -> any WASIFile {
        return MemoryStdioFile(fd: fd, accessMode: accessMode)
    }

    // MARK: - Internal File Operations

    internal func lookup(at path: String) -> MemFSNode? {
        let normalized = normalizePath(path)

        if normalized == Self.rootPath {
            return root
        }

        let components = normalized.split(separator: "/").map(String.init)
        var current: MemFSNode = root

        for component in components {
            guard let dir = current as? MemoryDirectoryNode else {
                return nil
            }
            guard let next = dir.getChild(name: component) else {
                return nil
            }
            current = next
        }

        return current
    }

    internal func resolve(from directory: MemoryDirectoryNode, at directoryPath: String, path relativePath: String) -> MemFSNode? {
        if relativePath.isEmpty {
            return directory
        }

        if relativePath.hasPrefix("/") {
            return lookup(at: relativePath)
        }

        let fullPath: String
        if directoryPath == Self.rootPath {
            fullPath = Self.rootPath + relativePath
        } else {
            fullPath = directoryPath + "/" + relativePath
        }

        let components = fullPath.split(separator: "/").map(String.init)
        var stack: [String] = []

        for component in components {
            if component == "." {
                continue
            } else if component == ".." {
                if !stack.isEmpty {
                    stack.removeLast()
                }
            } else {
                stack.append(component)
            }
        }

        let resolvedPath = stack.isEmpty ? Self.rootPath : Self.rootPath + stack.joined(separator: "/")
        return lookup(at: resolvedPath)
    }

    @discardableResult
    internal func ensureDirectory(at path: String) throws -> MemoryDirectoryNode {
        let normalized = normalizePath(path)

        if normalized == Self.rootPath {
            return root
        }

        let components = normalized.split(separator: "/").map(String.init)
        var current = root

        for component in components {
            if let existing = current.getChild(name: component) {
                guard let dir = existing as? MemoryDirectoryNode else {
                    throw WASIAbi.Errno.ENOTDIR
                }
                current = dir
            } else {
                let newDir = MemoryDirectoryNode()
                current.setChild(name: component, node: newDir)
                current = newDir
            }
        }

        return current
    }

    private func validateRelativePath(_ path: String) throws {
        guard !path.isEmpty && !path.hasPrefix("/") else {
            throw WASIAbi.Errno.EINVAL
        }
    }

    private func traverseToParent(from directory: MemoryDirectoryNode, components: [String]) throws -> MemoryDirectoryNode {
        var current = directory
        for component in components {
            if let existing = current.getChild(name: component) {
                guard let dir = existing as? MemoryDirectoryNode else {
                    throw WASIAbi.Errno.ENOTDIR
                }
                current = dir
            } else {
                let newDir = MemoryDirectoryNode()
                current.setChild(name: component, node: newDir)
                current = newDir
            }
        }
        return current
    }

    @discardableResult
    internal func createFile(in directory: MemoryDirectoryNode, at relativePath: String, oflags: WASIAbi.Oflags) throws -> MemoryFileNode {
        try validateRelativePath(relativePath)

        let components = relativePath.split(separator: "/").map(String.init)
        guard let fileName = components.last else {
            throw WASIAbi.Errno.EINVAL
        }

        let parentDir = try traverseToParent(from: directory, components: Array(components.dropLast()))

        if let existing = parentDir.getChild(name: fileName) {
            guard let fileNode = existing as? MemoryFileNode else {
                throw WASIAbi.Errno.EISDIR
            }
            if oflags.contains(.TRUNC) {
                fileNode.content = .bytes([])
            }
            return fileNode
        } else {
            let fileNode = MemoryFileNode(bytes: [])
            parentDir.setChild(name: fileName, node: fileNode)
            return fileNode
        }
    }

    internal func removeNode(in directory: MemoryDirectoryNode, at relativePath: String, mustBeDirectory: Bool) throws {
        try validateRelativePath(relativePath)

        let components = relativePath.split(separator: "/").map(String.init)
        guard let fileName = components.last else {
            throw WASIAbi.Errno.EINVAL
        }

        var current = directory
        for component in components.dropLast() {
            guard let next = current.getChild(name: component) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOENT
            }
            current = next
        }

        guard let node = current.getChild(name: fileName) else {
            throw WASIAbi.Errno.ENOENT
        }

        if mustBeDirectory {
            guard let dirNode = node as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOTDIR
            }
            if dirNode.childCount() > 0 {
                throw WASIAbi.Errno.ENOTEMPTY
            }
        } else {
            if node.type == .directory {
                throw WASIAbi.Errno.EISDIR
            }
        }

        current.removeChild(name: fileName)
    }

    internal func rename(from sourcePath: String, in sourceDir: MemoryDirectoryNode, to destPath: String, in destDir: MemoryDirectoryNode) throws {
        guard let sourceNode = resolve(from: sourceDir, at: "", path: sourcePath) else {
            throw WASIAbi.Errno.ENOENT
        }

        let destComponents = destPath.split(separator: "/").map(String.init)
        guard let destFileName = destComponents.last else {
            throw WASIAbi.Errno.EINVAL
        }

        let destParentDir = try traverseToParent(from: destDir, components: Array(destComponents.dropLast()))

        let sourceComponents = sourcePath.split(separator: "/").map(String.init)
        guard let sourceFileName = sourceComponents.last else {
            throw WASIAbi.Errno.EINVAL
        }

        var sourceParentDir = sourceDir
        for component in sourceComponents.dropLast() {
            guard let next = sourceParentDir.getChild(name: component) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOENT
            }
            sourceParentDir = next
        }

        sourceParentDir.removeChild(name: sourceFileName)
        destParentDir.setChild(name: destFileName, node: sourceNode)
    }

    private func normalizePath(_ path: String) -> String {
        if path.isEmpty {
            return Self.rootPath
        }

        var cleaned = ""
        var lastWasSlash = false
        for char in path.hasPrefix("/") ? path : "/\(path)" {
            if char == "/" {
                if !lastWasSlash {
                    cleaned.append(char)
                }
                lastWasSlash = true
            } else {
                cleaned.append(char)
                lastWasSlash = false
            }
        }

        if cleaned == Self.rootPath {
            return cleaned
        }

        if cleaned.hasSuffix("/") {
            return String(cleaned.dropLast())
        }

        return cleaned
    }

    private func splitPath(_ path: String) throws -> (parent: String, name: String) {
        let normalized = normalizePath(path)

        guard normalized != Self.rootPath else {
            throw WASIAbi.Errno.EINVAL
        }

        let components = normalized.split(separator: "/").map(String.init)
        guard let fileName = components.last else {
            throw WASIAbi.Errno.EINVAL
        }

        if components.count == 1 {
            return (Self.rootPath, fileName)
        }

        let parentComponents = components.dropLast()
        let parentPath = Self.rootPath + parentComponents.joined(separator: "/")
        return (parentPath, fileName)
    }
}