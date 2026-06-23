import Synchronization
import SystemExtras
import SystemPackage
import WasmTypes

/// A `WASIFile` for regular files.
///
/// Holds the file node by reference, so an fd opened before the file is unlinked
/// keeps working until its last close. Content is synchronized by the node; only
/// the per-fd `position` lives here.
final class MemoryFileEntry: WASIFile {
    let fileNode: MemoryFileNode
    let fileSystem: MemoryFileSystem
    let accessMode: FileAccessMode
    let position: Mutex<Int>

    init(fileNode: MemoryFileNode, fileSystem: MemoryFileSystem, accessMode: FileAccessMode, position: Int = 0) {
        self.fileNode = fileNode
        self.fileSystem = fileSystem
        self.accessMode = accessMode
        self.position = Mutex(position)
    }

    // MARK: - WASIEntry

    func attributes() throws -> WASIAbi.Filestat {
        let timestamps = try fileNode.timestamps
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .REGULAR_FILE,
            nlink: 1, size: WASIAbi.FileSize(try fileNode.size),
            atim: timestamps.atim, mtim: timestamps.mtim, ctim: timestamps.ctim
        )
    }

    func fileType() throws -> WASIAbi.FileType {
        return .REGULAR_FILE
    }

    func status() throws -> WASIAbi.Fdflags {
        return []
    }

    func setTimes(
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        let now = WASIAbi.Timestamp.currentWallClock()
        let newAtim: WASIAbi.Timestamp?
        if fstFlags.contains(.ATIM) {
            newAtim = atim
        } else if fstFlags.contains(.ATIM_NOW) {
            newAtim = now
        } else {
            newAtim = nil
        }

        let newMtim: WASIAbi.Timestamp?
        if fstFlags.contains(.MTIM) {
            newMtim = mtim
        } else if fstFlags.contains(.MTIM_NOW) {
            newMtim = now
        } else {
            newMtim = nil
        }

        // nil means the times were applied in memory; a non-nil handle is a host
        // fd whose times we set below.
        guard let handle = fileNode.setTimesInMemory(atim: newAtim, mtim: newMtim) else {
            return
        }

        let accessTime: FileTime
        if fstFlags.contains(.ATIM) {
            accessTime = FileTime(seconds: Int(atim / 1_000_000_000), nanoseconds: Int(atim % 1_000_000_000))
        } else if fstFlags.contains(.ATIM_NOW) {
            accessTime = .now
        } else {
            accessTime = .omit
        }

        let modTime: FileTime
        if fstFlags.contains(.MTIM) {
            modTime = FileTime(seconds: Int(mtim / 1_000_000_000), nanoseconds: Int(mtim % 1_000_000_000))
        } else if fstFlags.contains(.MTIM_NOW) {
            modTime = .now
        } else {
            modTime = .omit
        }

        try handle.setTimes(access: accessTime, modification: modTime)
    }

    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws {
        // No-op for memory filesystem
    }

    func close() throws {
        // No-op: the node is ARC-owned, so there is nothing to release here.
    }

    // MARK: - WASIFile

    func fdStat() throws -> WASIAbi.FdStat {
        var fsRightsBase: WASIAbi.Rights = []
        if accessMode.contains(.read) {
            fsRightsBase.insert(.FD_READ)
            fsRightsBase.insert(.FD_SEEK)
            fsRightsBase.insert(.FD_TELL)
        }
        if accessMode.contains(.write) {
            fsRightsBase.insert(.FD_WRITE)
        }

        return WASIAbi.FdStat(
            fsFileType: .REGULAR_FILE,
            fsFlags: [],
            fsRightsBase: fsRightsBase,
            fsRightsInheriting: []
        )
    }

    func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws {
        // No-op for memory filesystem
    }

    func setFilestatSize(_ size: WASIAbi.FileSize) throws {
        try fileNode.setFilestatSize(size)
    }

    func sync() throws {
        if let handle = fileNode.handle {
            try handle.sync()
        }
    }

    func datasync() throws {
        if let handle = fileNode.handle {
            try handle.datasync()
        }
    }

    func tell() throws -> WASIAbi.FileSize {
        position.withLock { WASIAbi.FileSize($0) }
    }

    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        try position.withLock { pos -> WASIAbi.FileSize in
            let prep = fileNode.seekPrep()

            if let handle = prep.handle {
                let platformWhence: FileDescriptor.SeekOrigin
                switch whence {
                case .SET: platformWhence = .start
                case .CUR: platformWhence = .current
                case .END: platformWhence = .end
                }
                let result = try handle.seek(offset: offset, from: platformWhence)
                pos = Int(result)
                return WASIAbi.FileSize(result)
            }

            let newPosition: Int
            switch whence {
            case .SET: newPosition = Int(offset)
            case .CUR: newPosition = pos + Int(offset)
            case .END: newPosition = prep.byteCount + Int(offset)
            }
            guard newPosition >= 0 else {
                throw WASIAbi.Errno.EINVAL
            }
            pos = newPosition
            return WASIAbi.FileSize(newPosition)
        }
    }

    func write<M: GuestMemory, Buffer: Sequence>(vectored buffer: Buffer, memory: M) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }
        return try position.withLock { pos in
            let result = try fileNode.write(vectored: buffer, memory: memory, position: pos)
            pos = result.newPosition
            return result.count
        }
    }

    func pwrite<M: GuestMemory, Buffer: Sequence>(vectored buffer: Buffer, memory: M, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileNode.pwrite(vectored: buffer, memory: memory, offset: Int(offset))
    }

    func read<M: GuestMemory, Buffer: Sequence>(into buffer: Buffer, memory: M) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }
        return try position.withLock { pos in
            let result = try fileNode.read(into: buffer, memory: memory, position: pos)
            pos = result.newPosition
            return result.count
        }
    }

    func pread<M: GuestMemory, Buffer: Sequence>(into buffer: Buffer, memory: M, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }
        return try fileNode.pread(into: buffer, memory: memory, offset: Int(offset))
    }
}
