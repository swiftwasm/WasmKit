import SystemExtras
import SystemPackage

struct PathResolution {
    private let mode: FileDescriptor.AccessMode
    private let options: FileDescriptor.OpenOptions
    private let permissions: FilePermissions

    private var baseFd: FileDescriptor
    private let path: FilePath
    private var openDirectories: [FileDescriptor]
    /// Reverse-ordered remaining path components
    private var components: FilePath.ComponentView

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
        self.baseFd = lastDirectory
    }

    mutating func regular(component: FilePath.Component) throws {
        let options: FileDescriptor.OpenOptions
        let mode: FileDescriptor.AccessMode
        if !self.components.isEmpty {
            var intermediateOptions: FileDescriptor.OpenOptions = []

            #if !os(Windows)
                // When trying to open an intermediate directory,
                // we can assume it's directory.
                intermediateOptions.insert(.directory)
                // FIXME: Resolve symlink in safe way
                intermediateOptions.insert(.noFollow)
            #endif
            options = intermediateOptions
            mode = .readOnly
        } else {
            options = self.options
            mode = self.mode
        }

        try WASIAbi.Errno.translatingPlatformErrno {
            let newFd = try self.baseFd.open(
                at: FilePath(root: nil, components: component),
                mode, options: options, permissions: permissions
            )
            self.openDirectories.append(self.baseFd)
            self.baseFd = newFd
        }
    }

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
