import Synchronization
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
/// let fs = try MemoryFileSystem()
/// try fs.ensureDirectory(at: "/")
/// try fs.addFile(at: "/hello.txt", content: "Hello, world!")
///
/// // Or add a file handle
/// let fd = try FileDescriptor.open("/path/to/file", .readOnly)
/// try fs.addFile(at: "/mounted.txt", handle: fd)
/// ```
public final class MemoryFileSystem: FileSystemImplementation, Sendable {
    private static let rootPath = "/"

    private let root: Mutex<MemoryDirectoryNode>

    /// Creates a new in-memory file system.
    public init() throws {
        self.root = Mutex(MemoryDirectoryNode())
    }

    // MARK: - Tree Lock

    /// Acquires the tree-wide lock for use by MemoryDirEntry / MemoryFileEntry.
    /// All node mutations must be performed under this lock.
    func withTreeLock<R>(_ body: () throws -> R) rethrows -> R {
        try root.withLock { _ in try body() }
    }

    // MARK: - Static Unlocked Helpers (must be called under root lock)
    //
    // These are static to avoid capturing `self` inside Mutex.withLock closures,
    // which would connect the `inout sending` lock parameter to the task-isolated
    // `self` region and violate region isolation constraints.

    /// Traverses the tree from `root` to `path`. Must be called under root lock.
    private static func lookupNode(from root: MemoryDirectoryNode, at path: String) -> MemFSNode? {
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

    /// Resolves a relative path from a directory node. Must be called under root lock.
    private static func resolveNode(root: MemoryDirectoryNode, from directory: MemoryDirectoryNode, at directoryPath: String, path relativePath: String) -> MemFSNode? {
        if relativePath.isEmpty {
            return directory
        }

        if relativePath.hasPrefix("/") {
            return lookupNode(from: root, at: relativePath)
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
        return lookupNode(from: root, at: resolvedPath)
    }

    /// Ensures all directory components exist. Must be called under root lock.
    private static func ensureDirectoryNode(from root: MemoryDirectoryNode, at path: String) throws -> MemoryDirectoryNode {
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

    /// Must be called under root lock.
    @discardableResult
    private static func createFileNode(in directory: MemoryDirectoryNode, at relativePath: String, oflags: WASIAbi.Oflags) throws -> MemoryFileNode {
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

    private static func validateRelativePath(_ path: String) throws {
        guard !path.isEmpty && !path.hasPrefix("/") else {
            throw WASIAbi.Errno.EINVAL
        }
    }

    private static func traverseToParent(from directory: MemoryDirectoryNode, components: [String]) throws -> MemoryDirectoryNode {
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

    // MARK: - Public API

    /// Adds a file to the file system with the given byte content.
    ///
    /// - Parameters:
    ///   - path: The path where the file should be created
    ///   - content: The file content as a sequence of bytes
    public func addFile(at path: String, content: some Sequence<UInt8>) throws {
        let normalized = Self.normalizePath(path)
        let (parentPath, fileName) = try Self.splitPath(normalized)
        let bytes = Array(content)

        try root.withLock { root in
            let parent = try Self.ensureDirectoryNode(from: root, at: parentPath)
            parent.setChild(name: fileName, node: MemoryFileNode(content: .bytes(bytes)))
        }
    }

    /// Adds a file to the file system with the given string content.
    ///
    /// - Parameters:
    ///   - path: The path where the file should be created
    ///   - content: The file content as string (converted to UTF-8)
    public func addFile(at path: String, content: String) throws {
        try addFile(at: path, content: content.utf8)
    }

    /// Adds a file to the file system backed by a file descriptor.
    ///
    /// - Parameters:
    ///   - path: The path where the file should be created
    ///   - handle: The file descriptor handle
    public func addFile(at path: String, handle: FileDescriptor) throws {
        let normalized = Self.normalizePath(path)
        let (parentPath, fileName) = try Self.splitPath(normalized)

        try root.withLock { root in
            let parent = try Self.ensureDirectoryNode(from: root, at: parentPath)
            parent.setChild(name: fileName, node: MemoryFileNode(handle: handle))
        }
    }

    /// Gets the content of a file at the specified path.
    ///
    /// - Parameter path: The path of the file to retrieve
    /// - Returns: The file content
    public func getFile(at path: String) throws -> FileContent {
        try root.withLock { root in
            guard let node = Self.lookupNode(from: root, at: path) else {
                throw WASIAbi.Errno.ENOENT
            }
            guard let fileNode = node as? MemoryFileNode else {
                throw WASIAbi.Errno.EISDIR
            }
            return fileNode.content
        }
    }

    /// Removes a file from the file system.
    ///
    /// - Parameter path: The path of the file to remove
    public func removeFile(at path: String) throws {
        let normalized = Self.normalizePath(path)
        let (parentPath, fileName) = try Self.splitPath(normalized)

        try root.withLock { root in
            guard let parent = Self.lookupNode(from: root, at: parentPath) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOENT
            }
            guard parent.removeChild(name: fileName) else {
                throw WASIAbi.Errno.ENOENT
            }
        }
    }

    // MARK: - FileSystemImplementation (WASI API)

    func preopenDirectory(guestPath: String, hostPath: String) throws -> any WASIDir {
        let node = try ensureDirectory(at: guestPath)

        return MemoryDirEntry(
            preopenPath: guestPath,
            dirNode: node,
            path: guestPath,
            fileSystem: self
        )
    }

    func openAt(
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

        // Extract Sendable values before the lock closure to avoid capturing
        // non-Sendable MemoryDirEntry in the lock's region.
        let dirPath = memoryDir.path
        let fullPath = dirPath.hasSuffix("/") ? dirPath + path : dirPath + "/" + path

        return try root.withLock { root in
            // Re-resolve the directory from root using the path
            guard let dirNode = Self.lookupNode(from: root, at: dirPath) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.EBADF
            }

            var node = Self.resolveNode(root: root, from: dirNode, at: dirPath, path: path)

            if node != nil {
                if oflags.contains(.EXCL) && oflags.contains(.CREAT) {
                    throw WASIAbi.Errno.EEXIST
                }
            } else {
                if oflags.contains(.CREAT) {
                    node = try Self.createFileNode(in: dirNode, at: path, oflags: oflags)
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
                return .directory(
                    MemoryDirEntry(
                        preopenPath: nil,
                        dirNode: dirNode,
                        path: fullPath,
                        fileSystem: self
                    ))
            }

            if resolvedNode.type == .file {
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

                return .file(MemoryFileEntry(fileNode: fileNode, fileSystem: self, accessMode: accessMode, position: 0))
            }

            if resolvedNode.type == .characterDevice {
                guard let deviceNode = resolvedNode as? MemoryCharacterDeviceNode else {
                    throw WASIAbi.Errno.EBADF
                }

                var accessMode: FileAccessMode = []
                if fsRightsBase.contains(.FD_READ) {
                    accessMode.insert(.read)
                }
                if fsRightsBase.contains(.FD_WRITE) {
                    accessMode.insert(.write)
                }

                return .file(MemoryCharacterDeviceEntry(deviceNode: deviceNode, accessMode: accessMode))
            }

            throw WASIAbi.Errno.ENOTSUP
        }
    }

    // MARK: - File Operations

    func lookup(at path: String) -> MemFSNode? {
        root.withLock { root in
            Self.lookupNode(from: root, at: path)
        }
    }

    func resolve(at directoryPath: String, path relativePath: String) -> MemFSNode? {
        root.withLock { root in
            guard let directory = Self.lookupNode(from: root, at: directoryPath) as? MemoryDirectoryNode else {
                return nil
            }
            return Self.resolveNode(root: root, from: directory, at: directoryPath, path: relativePath)
        }
    }

    @discardableResult
    package func ensureDirectory(at path: String) throws -> MemoryDirectoryNode {
        try root.withLock { root in
            try Self.ensureDirectoryNode(from: root, at: path)
        }
    }

    /// Remove a node relative to the directory at `directoryPath`.
    /// Accepts paths (Sendable) rather than node references to satisfy
    /// Mutex.withLock's `inout sending` constraint.
    func removeNode(at directoryPath: String, relativePath: String, mustBeDirectory: Bool) throws {
        try root.withLock { root in
            guard let directory = Self.lookupNode(from: root, at: directoryPath) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOENT
            }

            try Self.validateRelativePath(relativePath)

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
    }

    /// Rename a node from `sourcePath` (relative to `sourceDirectoryPath`) to
    /// `destPath` (relative to `destDirectoryPath`).
    func rename(from sourcePath: String, at sourceDirectoryPath: String, to destPath: String, at destDirectoryPath: String) throws {
        try root.withLock { root in
            guard let sourceDir = Self.lookupNode(from: root, at: sourceDirectoryPath) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOENT
            }
            guard let destDir = Self.lookupNode(from: root, at: destDirectoryPath) as? MemoryDirectoryNode else {
                throw WASIAbi.Errno.ENOENT
            }

            guard let sourceNode = Self.resolveNode(root: root, from: sourceDir, at: sourceDirectoryPath, path: sourcePath) else {
                throw WASIAbi.Errno.ENOENT
            }

            let destComponents = destPath.split(separator: "/").map(String.init)
            guard let destFileName = destComponents.last else {
                throw WASIAbi.Errno.EINVAL
            }

            let destParentDir = try Self.traverseToParent(from: destDir, components: Array(destComponents.dropLast()))

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
    }

    // MARK: - Private Helpers

    private static func normalizePath(_ path: String) -> String {
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

    private static func splitPath(_ path: String) throws -> (parent: String, name: String) {
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
