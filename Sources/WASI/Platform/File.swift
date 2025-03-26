import SystemPackage

protocol FdWASIEntry: WASIEntry {
    var fd: FileDescriptor { get }
}

protocol FdWASIFile: WASIFile, FdWASIEntry {
    var accessMode: FileAccessMode { get }
}

extension FdWASIFile {
    func fdStat() throws -> WASIAbi.FdStat {
        var fsRightsBase: WASIAbi.Rights = []
        if accessMode.contains(.read) {
            fsRightsBase.insert(.FD_READ)
        }
        if accessMode.contains(.write) {
            fsRightsBase.insert(.FD_WRITE)
        }
        return try WASIAbi.FdStat(
            fsFileType: self.fileType(),
            fsFlags: self.status(),
            fsRightsBase: fsRightsBase, fsRightsInheriting: []
        )
    }

    func sync() throws {
        try WASIAbi.Errno.translatingPlatformErrno {
            try fd.sync()
        }
    }

    func datasync() throws {
        try WASIAbi.Errno.translatingPlatformErrno {
            try fd.datasync()
        }
    }

    @inlinable
    func write<Buffer: Sequence>(vectored buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }
        // TODO: Use `writev`
        var bytesWritten: UInt32 = 0
        for iovec in buffer {
            bytesWritten += try iovec.withHostBufferPointer {
                UInt32(try fd.write(UnsafeRawBufferPointer($0)))
            }
        }
        return bytesWritten
    }

    @inlinable
    func pwrite<Buffer: Sequence>(vectored buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        // TODO: Use `pwritev`
        var currentOffset: Int64 = Int64(offset)
        for iovec in buffer {
            currentOffset += try iovec.withHostBufferPointer {
                Int64(try fd.writeAll(toAbsoluteOffset: currentOffset, $0))
            }
        }
        let nwritten = WASIAbi.FileSize(currentOffset) - offset
        return WASIAbi.Size(nwritten)
    }

    @inlinable
    func read<Buffer: Sequence>(into buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        var nread: UInt32 = 0
        for iovec in buffer {
            nread += try iovec.withHostBufferPointer {
                try UInt32(fd.read(into: $0))
            }
        }
        return nread
    }

    @inlinable
    func pread<Buffer: Sequence>(into buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        // TODO: Use `preadv`
        var nread: UInt32 = 0
        for iovec in buffer {
            nread += try iovec.withHostBufferPointer {
                try UInt32(fd.read(fromAbsoluteOffset: Int64(offset + UInt64(nread)), into: $0))
            }
        }
        return nread
    }
}

struct RegularFileEntry: FdWASIFile {
    let fd: FileDescriptor
    let accessMode: FileAccessMode
}

extension FdWASIFile {
    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws {
        try WASIAbi.Errno.translatingPlatformErrno {
            try fd.setStatus(flags.platformOpenOptions)
        }
    }
}

struct StdioFileEntry: FdWASIFile {
    let fd: FileDescriptor
    let accessMode: FileAccessMode

    func attributes() throws -> WASIAbi.Filestat {
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .CHARACTER_DEVICE,
            nlink: 0, size: 0, atim: 0, mtim: 0, ctim: 0
        )
    }
}
