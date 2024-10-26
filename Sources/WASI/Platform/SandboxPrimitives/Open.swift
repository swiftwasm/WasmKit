import SystemExtras
import SystemPackage

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import CSystem
    import Glibc
#elseif canImport(Musl)
    import CSystem
    import Musl
#elseif os(Windows)
    import CSystem
    import ucrt
#else
    #error("Unsupported Platform")
#endif

struct PathResolution {
    private let mode: FileDescriptor.AccessMode
    private let options: FileDescriptor.OpenOptions
    private let permissions: FilePermissions

    private var baseFd: FileDescriptor
    private let path: FilePath
    private var openDirectories: [FileDescriptor]
    /// Reverse-ordered remaining path components
    /// File name appears first, then parent directories.
    ///   e.g. `a/b/c` -> ["c", "b", "a"]
    /// This ordering is just to avoid dropFirst() on Array.
    private var components: FilePath.ComponentView
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
        permissions: FilePermissions,
        path: FilePath
    ) {
        self.baseFd = baseDirFd
        self.mode = mode
        self.options = options
        self.permissions = permissions
        self.path = path
        self.openDirectories = []
        self.components = FilePath.ComponentView(path.components.reversed())
    }

    mutating func parentDirectory() throws {
        guard let lastDirectory = openDirectories.popLast() else {
            // no more parent directory means too many `..`
            throw WASIAbi.Errno.EPERM
        }
        try self.baseFd.close()
        self.baseFd = lastDirectory
    }

    mutating func regular(component: FilePath.Component) throws {
        var options: FileDescriptor.OpenOptions = []
        #if !os(Windows)
            // First, try without following symlinks as a fast path.
            // If it's actually a symlink and options don't have O_NOFOLLOW,
            // we'll try again with interpreting resolved symlink.
            options.insert(.noFollow)
        #endif
        let mode: FileDescriptor.AccessMode

        if !self.components.isEmpty {
            #if !os(Windows)
                // When trying to open an intermediate directory,
                // we can assume it's directory.
                options.insert(.directory)
            #endif
            mode = .readOnly
        } else {
            options.formUnion(self.options)
            mode = self.mode
        }

        try WASIAbi.Errno.translatingPlatformErrno {
            do {
                let newFd = try self.baseFd.open(
                    at: FilePath(root: nil, components: component),
                    mode, options: options, permissions: permissions
                )
                self.openDirectories.append(self.baseFd)
                self.baseFd = newFd
                return
            } catch let openErrno as Errno {
                #if os(Windows)
                    // Windows doesn't have O_NOFOLLOW, so we can't retry with following symlink.
                    throw openErrno
                #else
                    if self.options.contains(.noFollow) {
                        // If "open" failed with O_NOFOLLOW, no need to retry.
                        throw openErrno
                    }

                    // If "open" failed and it might be a symlink, try again with following symlink.

                    // Check if it's a symlink by fstatat(2).
                    //
                    // NOTE: `errno` has enough information to check if the component is a symlink,
                    // but the value is platform-specific (e.g. ELOOP on POSIX standards, but EMLINK
                    // on BSD family), so we conservatively check it by fstatat(2).
                    let attrs = try self.baseFd.attributes(
                        at: FilePath(root: nil, components: component), options: [.noFollow]
                    )
                    guard attrs.fileType.isSymlink else {
                        // openat(2) failed, fstatat(2) succeeded, and it said it's not a symlink.
                        // If it's not a symlink, the error is not due to symlink following
                        // but other reasons, so just throw the error.
                        // e.g. open with O_DIRECTORY on a regular file.
                        throw openErrno
                    }

                    try self.symlink(component: component)
                #endif
            }
        }
    }

    #if !os(Windows)
        mutating func symlink(component: FilePath.Component) throws {
            /// Thin wrapper around readlinkat(2)
            func _readlinkat(_ fd: CInt, _ path: UnsafePointer<CChar>) throws -> FilePath {
                var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
                let length = try buffer.withUnsafeMutableBufferPointer { buffer in
                    try buffer.withMemoryRebound(to: Int8.self) { buffer in
                        guard let bufferBase = buffer.baseAddress else {
                            throw WASIAbi.Errno.EINVAL
                        }
                        return readlinkat(fd, path, bufferBase, buffer.count)
                    }
                }
                guard length >= 0 else {
                    throw try WASIAbi.Errno(platformErrno: errno)
                }
                return FilePath(String(cString: buffer))
            }

            guard resolvedSymlinks < Self.MAX_SYMLINKS else {
                throw WASIAbi.Errno.ELOOP
            }

            // If it's a symlink, readlink(2) and check it doesn't escape sandbox.
            let linkPath = try component.withPlatformString {
                return try _readlinkat(self.baseFd.rawValue, $0)
            }

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
    #endif

    mutating func resolve() throws -> FileDescriptor {
        if path.isAbsolute {
            // POSIX openat(2) interprets absolute path ignoring base directory fd
            // but it leads sandbox-escaping, so reject absolute path here.
            throw WASIAbi.Errno.EPERM
        }

        while let component = components.popLast() {
            switch component.kind {
            case .currentDirectory:
                break  // no-op
            case .parentDirectory:
                try parentDirectory()
            case .regular: try regular(component: component)
            }
        }
        return self.baseFd
    }
}

extension SandboxPrimitives {
    static func openAt(
        start startFd: FileDescriptor,
        path: FilePath,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions,
        permissions: FilePermissions
    ) throws -> FileDescriptor {
        var resolution = PathResolution(
            baseDirFd: startFd, mode: mode, options: options,
            permissions: permissions, path: path
        )
        return try resolution.resolve()
    }
}
