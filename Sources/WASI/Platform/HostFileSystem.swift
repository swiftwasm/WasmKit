
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(Windows)
    import ucrt
#elseif os(WASI)
    import WASILibc
#else
    #error("Unsupported Platform")
#endif

import WasmTypes

/// A file system implementation that directly accesses the host operating system's file system.
///
/// This implementation provides access to actual files and directories on the host system.
final class HostFileSystem: FileSystemImplementation, Sendable {

    /// Creates a new host file system.
    init() {
    }

    // MARK: - FileSystemImplementation (WASI API)

    func preopenDirectory(guestPath: String, hostPath: String) throws -> any WASIDir {
        #if os(Windows) || os(WASI)
            let fd: FileDescriptor
            do {
                fd = try FileDescriptor.open(hostPath, .readWrite)
            } catch let error as PlatformErrno {
                throw WASIError(description: "Failed to open preopen path '\(hostPath)': \(error)")
            }
        #else
            let fd = try hostPath.withCString { cHostPath in
                let fd = open(cHostPath, O_DIRECTORY)
                if fd < 0 {
                    let errno = errno
                    throw WASIError(description: "Failed to open preopen path '\(hostPath)': \(String(cString: strerror(errno)))")
                }
                return FileDescriptor(rawValue: fd)
            }
        #endif

        do {
            guard try fd.attributes().fileType.isDirectory else {
                throw WASIAbi.Errno.ENOTDIR
            }
        } catch {
            throw CleanupFailure.preserving(error, cleanup: fd.close)
        }

        return DirEntry(preopenPath: guestPath, fd: fd)
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
        #if os(Windows)
            throw WASIAbi.Errno.ENOTSUP
        #else
            var accessMode: FileAccessMode = []
            if fsRightsBase.contains(.FD_READ) {
                accessMode.insert(.read)
            }
            if fsRightsBase.contains(.FD_WRITE) {
                accessMode.insert(.write)
            }

            let hostFd = try dirFd.openFile(
                symlinkFollow: symlinkFollow,
                path: path,
                oflags: oflags,
                accessMode: accessMode,
                fdflags: fdflags
            )

            let actualFileType = try hostFd.attributes().fileType
            if oflags.contains(.DIRECTORY), actualFileType != .directory {
                throw WASIAbi.Errno.ENOTDIR
            }

            if actualFileType == .directory {
                return .directory(DirEntry(preopenPath: nil, fd: hostFd))
            } else {
                return .file(RegularFileEntry(fd: hostFd, accessMode: accessMode))
            }
        #endif
    }

    func createStdioFile(fd: FileDescriptor, accessMode: FileAccessMode) -> any WASIFile {
        return StdioFileEntry(fd: fd, accessMode: accessMode)
    }
}
