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

    static func openParent(start: FileDescriptor, path: String) throws -> SplitPath {
        guard let (dirName, basename) = splitParent(path: path) else {
            throw WASIAbi.Errno.ENOENT
        }

        let splitPath: SplitPath
        if !dirName.isEmpty {
            splitPath = try .init(
                parentFd: openAt(
                    start: start, path: dirName,
                    mode: .readOnly, options: .directory,
                    permissions: []
                ),
                basename: basename.string,
                isTemporary: true
            )
        } else {
            splitPath = .init(
                parentFd: start,
                basename: basename.string,
                isTemporary: false
            )
        }
        return splitPath
    }

    /// Like `openParent`, but while the last component names a symlink,
    /// replaces it with the symlink's target and resolves again, so that the
    /// result never names a symlink. The host never follows a symlink
    /// itself, which could lead it out of the sandbox.
    static func openParentFollowingSymlinks(start: FileDescriptor, path: String) throws -> SplitPath {
        var path = path
        for _ in 0...PathResolution.MAX_SYMLINKS {
            let result = try openParent(start: start, path: path)
            let target: [UInt8]? = try result.withFields { dir, basename in
                guard try dir.attributes(at: basename, options: .noFollow).fileType.isSymlink else { return nil }
                return try readSymlink(in: dir, name: basename)
            }
            guard let target else { return result }
            let targetPath = String(decoding: target, as: UTF8.self)
            guard !GuestPath(targetPath).isAbsolute else {
                // Ban absolute symlink to avoid sandbox-escaping.
                throw WASIAbi.Errno.EPERM
            }
            // The target is relative to the directory holding the symlink.
            // `start` stays the base, so `..` cannot climb above it.
            guard let (parent, _) = splitParent(path: path) else { throw WASIAbi.Errno.ENOENT }
            path = parent.isEmpty ? targetPath : parent.string + "/" + targetPath
        }
        throw WASIAbi.Errno.ELOOP
    }
}

/// The return value of `SandboxPrimitives.openParent`.
///
/// If `isTemporary` is `true`, the file descriptor will be closed when the instance is destroyed.
struct SplitPath: ~Copyable {
    var parentFd: FileDescriptor
    var basename: String
    var isTemporary: Bool

    borrowing func withFields<R>(_ body: (FileDescriptor, String) throws -> R) rethrows -> R {
        try body(parentFd, basename)
    }

    deinit {
        if isTemporary {
            try? parentFd.close()
        }
    }
}
