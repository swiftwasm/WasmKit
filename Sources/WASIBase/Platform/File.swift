import Foundation
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

    @inlinable
    func write<Buffer: Sequence>(vectored buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }
        // TODO: Use `writev`
        let handle = FileHandle(fileDescriptor: fd.rawValue)
        var bytesWritten: UInt32 = 0
        for iovec in buffer {
            try iovec.withHostBufferPointer {
                try handle.write(contentsOf: $0)
            }
            bytesWritten += iovec.length
        }
        return bytesWritten
    }

    @inlinable
    func pwrite<Buffer: Sequence>(vectored buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        // TODO: Use `pwritev`
        let handle = FileHandle(fileDescriptor: fd.rawValue)
        let savedOffset = try handle.offset()
        try handle.seek(toOffset: offset)
        let nwritten = try write(vectored: buffer)
        try handle.seek(toOffset: savedOffset)
        return nwritten
    }

    @inlinable
    func read<Buffer: Sequence>(into buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        // TODO: Use `readv`
        let handle = FileHandle(fileDescriptor: fd.rawValue)
        var nread: UInt32 = 0
        for iovec in buffer {
            try iovec.buffer.withHostPointer { rawBufferStart in
                var bufferStart = rawBufferStart.bindMemory(
                    to: UInt8.self, capacity: Int(iovec.length)
                )
                let bufferEnd = bufferStart + Int(iovec.length)
                while bufferStart < bufferEnd {
                    let remaining = bufferEnd - bufferStart
                    guard let bytes = try handle.read(upToCount: remaining) else {
                        break
                    }
                    bytes.copyBytes(to: bufferStart, count: bytes.count)
                    bufferStart += bytes.count
                }
                nread += iovec.length - UInt32(bufferEnd - bufferStart)
            }
        }
        return nread
    }

    @inlinable
    func pread<Buffer: Sequence>(into buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        // TODO: Use `preadv`
        let handle = FileHandle(fileDescriptor: fd.rawValue)
        let savedOffset = try handle.offset()
        try handle.seek(toOffset: offset)
        let nread = try read(into: buffer)
        try handle.seek(toOffset: savedOffset)
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
