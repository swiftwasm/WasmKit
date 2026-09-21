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
/// let fd = FileHandle(forReadingAtPath: "/path/to/file")!.fileDescriptor
/// try fs.addFile(at: "/mounted.txt", handle: fd)
/// ```
public final class MemoryFileSystem: Sendable {
    private static let rootPath = "/"

    /// The directory tree. Synchronization lives in the nodes, so the file system
    /// needs no lock of its own.
    private let root: MemoryDirectoryNode

    /// Creates a new in-memory file system.
    public init() throws {
        self.root = MemoryDirectoryNode()
    }

    // MARK: - Tree Helpers
    //
    // Each structural step is atomic on the node it touches, but a multi-node
    // operation (e.g. rename across directories) is a sequence of such steps, not
    // one critical section: a concurrent observer can briefly see an intermediate
    // tree, though the moved node is held by reference and never lost.

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

    /// Resolves a guest-supplied path against the directory a descriptor refers
    /// to, without leaving that directory.
    ///
    /// The guest chooses the path, and the directory it holds a descriptor for
    /// is the boundary it is allowed to work within. So the walk starts at that
    /// directory rather than at the filesystem root, an absolute path is
    /// refused, and `..` pops the directories this walk has itself descended
    /// through -- never above the one it started from.
    static func resolve(
        from directory: MemoryDirectoryNode, path relativePath: String
    ) throws -> MemFSNode? {
        if relativePath.isEmpty {
            return directory
        }
        guard !relativePath.hasPrefix("/") else {
            throw WASIAbi.Errno.EPERM
        }

        var current: MemFSNode = directory
        // The directories descended through since `directory`, so `..` can only
        // unwind what this walk did.
        var descended: [MemoryDirectoryNode] = []

        for component in relativePath.split(separator: "/").map(String.init) {
            switch component {
            case "", ".":
                continue
            case "..":
                guard current is MemoryDirectoryNode else {
                    throw WASIAbi.Errno.ENOTDIR
                }
                guard let parent = descended.popLast() else {
                    // Would leave the directory the descriptor refers to.
                    throw WASIAbi.Errno.EPERM
                }
                current = parent
            default:
                guard let dir = current as? MemoryDirectoryNode else {
                    throw WASIAbi.Errno.ENOTDIR
                }
                guard let next = dir.getChild(name: component) else {
                    return nil
                }
                descended.append(dir)
                current = next
            }
        }

        return current
    }

    /// Resolves the parent directory and final component of a guest path, under
    /// the same confinement as ``resolve(from:path:)``.
    static func resolveParent(
        from directory: MemoryDirectoryNode, path relativePath: String
    ) throws -> (parent: MemoryDirectoryNode, name: String) {
        try validateRelativePath(relativePath)
        var components = relativePath.split(separator: "/").map(String.init).filter { $0 != "." && !$0.isEmpty }
        guard let name = components.popLast(), name != ".." else {
            throw WASIAbi.Errno.EINVAL
        }
        guard let parent = try resolve(from: directory, path: components.joined(separator: "/")) as? MemoryDirectoryNode
        else {
            throw WASIAbi.Errno.ENOENT
        }
        return (parent, name)
    }

    @discardableResult
    private static func ensureDirectoryNode(from root: MemoryDirectoryNode, at path: String) throws -> MemoryDirectoryNode {
        let normalized = normalizePath(path)
        if normalized == Self.rootPath {
            return root
        }

        let components = normalized.split(separator: "/").map(String.init)
        var current = root
        for component in components {
            if component == "." { continue }
            // A literal ".." entry would be unreachable by resolution and would
            // give a traversal something to walk onto.
            guard component != ".." else {
                throw WASIAbi.Errno.EINVAL
            }
            current = try current.getOrCreateChildDirectory(name: component)
        }
        return current
    }

    /// Creates the file `relativePath` names within `directory`. The parent
    /// directories on the way there must already exist: creating them would
    /// both deviate from `openat` and put entries in the tree that the guest
    /// path never named.
    @discardableResult
    private static func createFileNode(in directory: MemoryDirectoryNode, at relativePath: String, oflags: WASIAbi.Oflags) throws -> MemoryFileNode {
        let (parentDir, fileName) = try resolveParent(from: directory, path: relativePath)
        let fileNode = try parentDir.getOrCreateChildFile(name: fileName)
        if oflags.contains(.TRUNC) {
            fileNode.truncateToEmpty()
        }
        return fileNode
    }

    private static func validateRelativePath(_ path: String) throws {
        guard !path.isEmpty && !path.hasPrefix("/") else {
            throw WASIAbi.Errno.EINVAL
        }
    }

    // MARK: - Public API

    /// Adds a file to the file system with the given byte content.
    public func addFile(at path: String, content: some Sequence<UInt8>) throws {
        let normalized = Self.normalizePath(path)
        let (parentPath, fileName) = try Self.splitPath(normalized)
        let parent = try Self.ensureDirectoryNode(from: root, at: parentPath)
        parent.setChild(name: fileName, node: MemoryFileNode(content: .bytes(Array(content))))
    }

    /// Adds a file to the file system with the given string content.
    public func addFile(at path: String, content: String) throws {
        try addFile(at: path, content: content.utf8)
    }

    /// Adds a file to the file system backed by a caller-owned platform file
    /// descriptor. The file system borrows the descriptor: the caller must
    /// keep it open while the file system is in use and close it afterwards.
    public func addFile(at path: String, handle: CInt) throws {
        let normalized = Self.normalizePath(path)
        let (parentPath, fileName) = try Self.splitPath(normalized)
        let parent = try Self.ensureDirectoryNode(from: root, at: parentPath)
        parent.setChild(name: fileName, node: MemoryFileNode(handle: FileDescriptor(rawValue: handle)))
    }

    /// Gets the content of a file at the specified path.
    public func getFile(at path: String) throws -> FileContent {
        guard let node = Self.lookupNode(from: root, at: path) else {
            throw WASIAbi.Errno.ENOENT
        }
        guard let fileNode = node as? MemoryFileNode else {
            throw WASIAbi.Errno.EISDIR
        }
        return fileNode.content
    }

    /// Removes a file. A currently-open fd to the removed file keeps working until
    /// its last close: the open `MemoryFileEntry` holds the node by reference, so
    /// unlinking only drops the directory edge.
    public func removeFile(at path: String) throws {
        let normalized = Self.normalizePath(path)
        let (parentPath, fileName) = try Self.splitPath(normalized)
        guard let parent = Self.lookupNode(from: root, at: parentPath) as? MemoryDirectoryNode else {
            throw WASIAbi.Errno.ENOENT
        }
        guard parent.removeChild(name: fileName) else {
            throw WASIAbi.Errno.ENOENT
        }
    }

    // MARK: - File Operations

    func lookup(at path: String) -> MemFSNode? {
        Self.lookupNode(from: root, at: path)
    }

    /// The type of the node reached by resolving `relativePath` from `directoryPath`.
    func resolveType(at directoryPath: String, path relativePath: String) -> MemFSNodeType? {
        guard Self.lookupNode(from: root, at: directoryPath) is MemoryDirectoryNode else {
            return nil
        }
        // Note: this resolves across the whole filesystem by design. It is an
        // embedder-side helper -- no guest entry point reaches it, and those go
        // through `resolve(from:path:)`, which stays inside the directory.
        if relativePath.hasPrefix("/") {
            return Self.lookupNode(from: root, at: relativePath)?.type
        }
        let components = Self.joinGuestPath(directoryPath, relativePath).split(separator: "/").map(String.init)
        var stack: [String] = []
        for component in components {
            switch component {
            case ".": continue
            case "..": if !stack.isEmpty { stack.removeLast() }
            default: stack.append(component)
            }
        }
        let resolvedPath = stack.isEmpty ? Self.rootPath : Self.rootPath + stack.joined(separator: "/")
        return Self.lookupNode(from: root, at: resolvedPath)?.type
    }

    /// The type of the node at `path`, or nil if nothing is there.
    func nodeType(at path: String) -> MemFSNodeType? {
        Self.lookupNode(from: root, at: path)?.type
    }

    @discardableResult
    package func ensureDirectory(at path: String) throws -> MemoryDirectoryNode {
        try Self.ensureDirectoryNode(from: root, at: path)
    }

    /// Remove a node named by a guest path relative to `directory`.
    func removeNode(in directory: MemoryDirectoryNode, relativePath: String, mustBeDirectory: Bool) throws {
        let (current, fileName) = try Self.resolveParent(from: directory, path: relativePath)

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

    /// Rename a node from `sourcePath` (relative to `sourceDirectory`) to
    /// `destPath` (relative to `destDirectory`).
    func rename(from sourcePath: String, in sourceDirectory: MemoryDirectoryNode, to destPath: String, in destDirectory: MemoryDirectoryNode) throws {
        let (sourceParentDir, sourceFileName) = try Self.resolveParent(from: sourceDirectory, path: sourcePath)
        let (destParentDir, destFileName) = try Self.resolveParent(from: destDirectory, path: destPath)

        guard let sourceNode = sourceParentDir.getChild(name: sourceFileName) else {
            throw WASIAbi.Errno.ENOENT
        }

        sourceParentDir.removeChild(name: sourceFileName)
        destParentDir.setChild(name: destFileName, node: sourceNode)
    }

    // MARK: - Private Helpers

    /// Joins a base guest path and a relative component with a single "/".
    /// `relative` must be non-empty and must not start with "/" — callers guarantee this;
    /// an empty `relative` would leave a trailing slash and an absolute one a doubled "//".
    package static func joinGuestPath(_ base: String, _ relative: String) -> String {
        base.hasSuffix("/") ? base + relative : base + "/" + relative
    }

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

@_spi(WASIPlatform) extension MemoryFileSystem: FileSystemImplementation {
    // MARK: - FileSystemImplementation (WASI API)

    public func preopenDirectory(guestPath: String, hostPath: String) throws -> any WASIDir {
        let node = try ensureDirectory(at: guestPath)
        return MemoryDirEntry(preopenPath: guestPath, dirNode: node, fileSystem: self)
    }

    public func openAt(
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

        // The descriptor's own directory node, not a fresh lookup by its path:
        // the path is a name the tree may no longer agree with, while the node
        // is what the descriptor refers to.
        let dirNode = memoryDir.dirNode

        var node = try Self.resolve(from: dirNode, path: path)

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
                MemoryDirEntry(preopenPath: nil, dirNode: dirNode, fileSystem: self))
        }

        if resolvedNode.type == .file {
            guard let fileNode = resolvedNode as? MemoryFileNode else {
                throw WASIAbi.Errno.EBADF
            }

            if oflags.contains(.TRUNC) && fsRightsBase.contains(.FD_WRITE) {
                fileNode.truncateToEmpty()
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
