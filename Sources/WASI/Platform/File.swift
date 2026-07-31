import WasmTypes

protocol FdWASIEntry: WASIEntry {
    var fd: FileDescriptor { get }
}

extension FdWASIEntry {
    var hostFileDescriptor: CInt? { fd.rawValue }
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
        try fd.sync()
    }

    func datasync() throws {
        try fd.datasync()
    }

    @inlinable
    func write(vectored buffers: GuestBuffers) throws -> WASIAbi.Size {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }
        // TODO: Use `writev`
        var bytesWritten: UInt32 = 0
        for index in 0..<buffers.count {
            bytesWritten += UInt32(
                try buffers.withHostBuffer(at: index) {
                    try fd.write(UnsafeRawBufferPointer($0))
                })
        }
        return bytesWritten
    }

    @inlinable
    func pwrite(vectored buffers: GuestBuffers, offset: WASIAbi.FileSize) throws -> WASIAbi.Size {
        // TODO: Use `pwritev`
        var currentOffset: Int64 = Int64(offset)
        for index in 0..<buffers.count {
            currentOffset += Int64(
                try buffers.withHostBuffer(at: index) {
                    try fd.writeAll(toAbsoluteOffset: currentOffset, $0)
                })
        }
        let nwritten = WASIAbi.FileSize(currentOffset) - offset
        return WASIAbi.Size(nwritten)
    }

    @inlinable
    func read(into buffers: GuestBuffers) throws -> WASIAbi.Size {
        var nread: UInt32 = 0
        for index in 0..<buffers.count {
            nread += UInt32(
                try buffers.withHostBuffer(at: index) {
                    try fd.read(into: $0)
                })
        }
        return nread
    }

    @inlinable
    func pread(into buffers: GuestBuffers, offset: WASIAbi.FileSize) throws -> WASIAbi.Size {
        // TODO: Use `preadv`
        var nread: UInt32 = 0
        for index in 0..<buffers.count {
            nread += UInt32(
                try buffers.withHostBuffer(at: index) {
                    try fd.read(fromAbsoluteOffset: Int64(offset + UInt64(nread)), into: $0)
                })
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
        try fd.setStatus(flags.platformOpenOptions)
    }
}

struct StdioFileEntry: FdWASIFile {
    let fd: FileDescriptor
    let accessMode: FileAccessMode

    let isBorrowed: Bool = true

    func attributes() throws -> WASIAbi.Filestat {
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .CHARACTER_DEVICE,
            nlink: 0, size: 0, atim: 0, mtim: 0, ctim: 0
        )
    }
}
