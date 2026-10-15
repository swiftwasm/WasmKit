struct PathResolution {
    private let mode: FileDescriptor.AccessMode
    private let options: FileDescriptor.OpenOptions
    private let permissions: FileDescriptor.FilePermissions

    private let startFd: FileDescriptor
    private var baseFd: FileDescriptor
    private let path: GuestPath
    private var openDirectories: [FileDescriptor]
    /// Reverse-ordered remaining path components
    /// File name appears first, then parent directories.
    ///   e.g. `a/b/c` -> ["c", "b", "a"]
    /// This ordering is just to avoid dropFirst() on Array.
    private var components: [GuestPath.Component]
    private var resolvedSymlinks: Int = 0

    private static var MAX_SYMLINKS: Int {
        // Linux defines MAXSYMLINKS as 40, but on darwin platforms, it's 32.
        // Take a single conservative value here to avoid platform-specific
        // behavior as much as possible.
        // * https://github.com/apple-oss-distributions/xnu/blob/8d741a5de7ff4191bf97d57b9f54c2f6d4a15585/bsd/sys/param.h#L207
        // * https://github.com/torvalds/linux/blob/850925a8133c73c4a2453c360b2c3beb3bab67c9/include/linux/namei.h#L13
        return 32
    }

    init(
        baseDirFd: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions,
        permissions: FileDescriptor.FilePermissions,
        path: GuestPath
    ) {
        self.startFd = baseDirFd
        self.baseFd = baseDirFd
        self.mode = mode
        self.options = options
        self.permissions = permissions
        self.path = path
        self.openDirectories = []
        self.components = path.components.reversed()
    }

    mutating func cleanup(keeping keptFd: FileDescriptor?) {
        var keepRawValues = Set<CInt>()
        keepRawValues.insert(startFd.rawValue)
        if let keptFd {
            keepRawValues.insert(keptFd.rawValue)
        }

        var closedRawValues = Set<CInt>()
        func closeIfNeeded(_ fd: FileDescriptor) {
            let rawValue = fd.rawValue
            guard !keepRawValues.contains(rawValue) else { return }
            guard !closedRawValues.contains(rawValue) else { return }
            closedRawValues.insert(rawValue)
            try? fd.close()
        }

        closeIfNeeded(baseFd)
        for fd in openDirectories {
            closeIfNeeded(fd)
        }
        openDirectories.removeAll(keepingCapacity: false)
    }

    mutating func parentDirectory() throws {
        guard let lastDirectory = openDirectories.popLast() else {
            // no more parent directory means too many `..`
            throw WASIAbi.Errno.EPERM
        }
        try self.baseFd.close()
        self.baseFd = lastDirectory
    }

    mutating func regular(component: String) throws {
        var options: FileDescriptor.OpenOptions = []
        // First, try without following symlinks as a fast path.
        // If it's actually a symlink and options don't have O_NOFOLLOW,
        // we'll try again with interpreting resolved symlink.
        options.insert(.noFollow)
        let mode: FileDescriptor.AccessMode

        if !self.components.isEmpty {
            // When trying to open an intermediate directory,
            // we can assume it's directory.
            options.insert(.directory)
            mode = .readOnly
        } else {
            options.formUnion(self.options)
            mode = self.mode
        }

        do {
            let newFd = try self.baseFd.open(
                at: component,
                mode, options: options, permissions: permissions
            )
            self.openDirectories.append(self.baseFd)
            self.baseFd = newFd
            return
        } catch let openErrno as WASIAbi.Errno {
            if self.options.contains(.noFollow) {
                // If "open" failed with O_NOFOLLOW, no need to retry.
                throw openErrno
            }

            // If "open" failed and it might be a symlink, try again with interpreting resolved symlink.

            // Check if it's a symlink by fstatat(2).
            //
            // NOTE: `errno` has enough information to check if the component is a symlink,
            // but the value is platform-specific (e.g. ELOOP on POSIX standards, but EMLINK
            // on BSD family), so we conservatively check it by fstatat(2).
            let attrs = try self.baseFd.attributes(at: component, options: [.noFollow])
            guard attrs.fileType.isSymlink else {
                // openat(2) failed, fstatat(2) succeeded, and it said it's not a symlink.
                // If it's not a symlink, the error is not due to symlink following
                // but other reasons, so just throw the error.
                // e.g. open with O_DIRECTORY on a regular file.
                throw openErrno
            }

            try self.symlink(component: component)
        }
    }

    mutating func symlink(component: String) throws {
        guard resolvedSymlinks < Self.MAX_SYMLINKS else {
            throw WASIAbi.Errno.ELOOP
        }

        // If it's a symlink, readlink(2) and check it doesn't escape sandbox.
        var buffer = [UInt8](repeating: 0, count: FileDescriptor.maximumPathLength)
        let length = try buffer.withUnsafeMutableBytes { rawBuffer in
            try self.baseFd.readSymlink(at: component, into: rawBuffer)
        }
        // Symlink contents are interpreted with WASI guest path semantics
        // ('/'-separated, UTF-8), which POSIX hosts share.
        let linkPath = GuestPath(String(decoding: buffer[..<length], as: UTF8.self))

        guard !linkPath.isAbsolute else {
            // Ban absolute symlink to avoid sandbox-escaping.
            throw WASIAbi.Errno.EPERM
        }

        // Increment the number of resolved symlinks to prevent infinite
        // link loop.
        resolvedSymlinks += 1

        // Add resolved path to the worklist.
        self.components.append(contentsOf: linkPath.components.reversed())
    }

    mutating func resolve() throws -> FileDescriptor {
        var resultFd: FileDescriptor? = nil
        defer { cleanup(keeping: resultFd) }

        if path.isAbsolute {
            // POSIX openat(2) interprets absolute path ignoring base directory fd
            // but it leads sandbox-escaping, so reject absolute path here.
            throw WASIAbi.Errno.EPERM
        }

        while let component = components.popLast() {
            switch component {
            case .currentDirectory:
                break  // no-op
            case .parentDirectory:
                try parentDirectory()
            case .regular(let name): try regular(component: name)
            }
        }

        // If the path resolved without opening any new fd (e.g. "."),
        // dup to avoid returning an aliased fd to the caller.
        if baseFd.rawValue == startFd.rawValue {
            baseFd = try startFd.open(at: ".", mode, options: options, permissions: permissions)
        }

        resultFd = self.baseFd
        return self.baseFd
    }
}

extension SandboxPrimitives {
    static func openAt(
        start startFd: FileDescriptor,
        path: GuestPath,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions,
        permissions: FileDescriptor.FilePermissions
    ) throws -> FileDescriptor {
        var resolution = PathResolution(
            baseDirFd: startFd, mode: mode, options: options,
            permissions: permissions, path: path
        )
        return try resolution.resolve()
    }
}
