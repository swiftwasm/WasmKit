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
