import SystemPackage

/// Split the given path to the parent and the last component to be passed to openat
/// Note: `SystemPackage.FilePath` strips explicit trailing "/" by normalization at `init`,
/// so this function takes path as a `String`.
internal func splitParent(path: String) -> (FilePath, FilePath.Component)? {
    func pathRequiresDirectory(path: String) -> Bool {
        return path.hasSuffix("/") || path.hasSuffix("/.")
    }

    guard !path.isEmpty else { return nil }

    if pathRequiresDirectory(path: path) {
        // Create a link to the directory itself
        return (FilePath(path), FilePath.Component("."))
    }

    let filePath = FilePath(path)
    var components = filePath.components
    if let c = components.popLast() {
        switch c.kind {
        case .regular, .currentDirectory:
            return (FilePath(root: filePath.root, components), c)
        case .parentDirectory:
            // Create a link to the parent directory itself
            return (filePath, FilePath.Component("."))
        }
    } else {
        fatalError("non-empty path should have at least one component")
    }
}

extension SandboxPrimitives {
    /// Strip trailing slashes from a path, unless this reduces the path to "/" itself.
    /// This is used by rename operations to prevent paths like "foo/" from canonicalizing
    /// to "foo/." since these syscalls treat these differently.
    static func stripDirSuffix(_ path: String) -> String {
        var path = path
        while path.count > 1 && path.hasSuffix("/") {
            path = String(path.dropLast())
        }
        return path
    }

    /// Check if a path has trailing slashes
    static func pathHasTrailingSlash(_ path: String) -> Bool {
        return path.hasSuffix("/")
    }

    static func openParent(start: FileDescriptor, path: String) throws -> (FileDescriptor, String) {
        guard let (dirName, basename) = splitParent(path: path) else {
            throw WASIAbi.Errno.ENOENT
        }

        let dirFd: FileDescriptor
        if !dirName.isEmpty {
            let options: FileDescriptor.OpenOptions
            #if os(Windows)
                options = []
            #else
                options = .directory
            #endif
            dirFd = try openAt(
                start: start, path: dirName,
                mode: .readOnly, options: options,
                permissions: []
            )
        } else {
            dirFd = start
        }
        return (dirFd, basename.string)
    }
}
