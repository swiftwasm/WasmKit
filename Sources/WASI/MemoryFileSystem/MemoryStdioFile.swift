import SystemPackage

struct MemoryStdioFile: WASIFile {
    let fd: FileDescriptor
    let accessMode: FileAccessMode
    
    func attributes() throws -> WASIAbi.Filestat {
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .CHARACTER_DEVICE,
            nlink: 0, size: 0, atim: 0, mtim: 0, ctim: 0
        )
    }
    
    func fileType() throws -> WASIAbi.FileType {
        return .CHARACTER_DEVICE
    }
    
    func status() throws -> WASIAbi.Fdflags {
        return []
    }
    
    func setTimes(
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        // No-op for stdio
    }
    
    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws {
        // No-op for stdio
    }
    
    func close() throws {
        // Don't actually close stdio file descriptors
    }
    
    func fdStat() throws -> WASIAbi.FdStat {
        var fsRightsBase: WASIAbi.Rights = []
        if accessMode.contains(.read) {
            fsRightsBase.insert(.FD_READ)
        }
        if accessMode.contains(.write) {
            fsRightsBase.insert(.FD_WRITE)
        }
        
        return WASIAbi.FdStat(
            fsFileType: .CHARACTER_DEVICE,
            fsFlags: [],
            fsRightsBase: fsRightsBase,
            fsRightsInheriting: []
        )
    }
    
    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws {
        // No-op for stdio
    }
    
    func setFilestatSize(_ size: WASIAbi.FileSize) throws {
        throw WASIAbi.Errno.EINVAL
    }
    
    func sync() throws {
        try fd.sync()
    }
    
    func datasync() throws {
        try fd.datasync()
    }
    
    func tell() throws -> WASIAbi.FileSize {
        return 0
    }
    
    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        throw WASIAbi.Errno.ESPIPE
    }
    
    func write<Buffer: Sequence>(vectored buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }
        
        var bytesWritten: UInt32 = 0
        for iovec in buffer {
            bytesWritten += try iovec.withHostBufferPointer {
                UInt32(try fd.write(UnsafeRawBufferPointer($0)))
            }
        }
        return bytesWritten
    }
    
    func pwrite<Buffer: Sequence>(vectored buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        throw WASIAbi.Errno.ESPIPE
    }
    
    func read<Buffer: Sequence>(into buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }
        
        var nread: UInt32 = 0
        for iovec in buffer {
            nread += try iovec.withHostBufferPointer {
                try UInt32(fd.read(into: $0))
            }
        }
        return nread
    }
    
    func pread<Buffer: Sequence>(into buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        throw WASIAbi.Errno.ESPIPE
    }
}