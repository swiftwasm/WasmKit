import SystemPackage

/// A WASIFile implementation for regular files in the memory file system.
internal final class MemoryFileEntry: WASIFile {
    let fileNode: MemoryFileNode
    let accessMode: FileAccessMode
    var position: Int

    init(fileNode: MemoryFileNode, accessMode: FileAccessMode, position: Int = 0) {
        self.fileNode = fileNode
        self.accessMode = accessMode
        self.position = position
    }

    // MARK: - WASIEntry

    func attributes() throws -> WASIAbi.Filestat {
        return WASIAbi.Filestat(
            dev: 0, ino: 0, filetype: .REGULAR_FILE,
            nlink: 1, size: WASIAbi.FileSize(fileNode.size),
            atim: 0, mtim: 0, ctim: 0
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
        // No-op for memory filesystem - timestamps not tracked
    }

    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice
    ) throws {
        // No-op for memory filesystem
    }

    func close() throws {
        // No-op for memory filesystem - no resources to release
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
        switch fileNode.content {
        case .bytes(var bytes):
            let newSize = Int(size)
            if newSize < bytes.count {
                bytes = Array(bytes.prefix(newSize))
            } else if newSize > bytes.count {
                bytes.append(contentsOf: Array(repeating: 0, count: newSize - bytes.count))
            }
            fileNode.content = .bytes(bytes)

        case .handle(let handle):
            try handle.truncate(size: Int64(size))
        }
    }

    func sync() throws {
        if case .handle(let handle) = fileNode.content {
            try handle.sync()
        }
    }

    func datasync() throws {
        if case .handle(let handle) = fileNode.content {
            try handle.datasync()
        }
    }

    func tell() throws -> WASIAbi.FileSize {
        return WASIAbi.FileSize(position)
    }

    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        let newPosition: Int

        switch fileNode.content {
        case .bytes(let bytes):
            switch whence {
            case .SET:
                newPosition = Int(offset)
            case .CUR:
                newPosition = position + Int(offset)
            case .END:
                newPosition = bytes.count + Int(offset)
            }

        case .handle(let handle):
            let platformWhence: FileDescriptor.SeekOrigin
            switch whence {
            case .SET:
                platformWhence = .start
            case .CUR:
                platformWhence = .current
            case .END:
                platformWhence = .end
            }
            let result = try handle.seek(offset: offset, from: platformWhence)
            position = Int(result)
            return WASIAbi.FileSize(result)
        }

        guard newPosition >= 0 else {
            throw WASIAbi.Errno.EINVAL
        }

        position = newPosition
        return WASIAbi.FileSize(newPosition)
    }

    func write<Buffer: Sequence>(vectored buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }

        var totalWritten: UInt32 = 0

        switch fileNode.content {
        case .bytes(var bytes):
            var currentPosition = position
            for iovec in buffer {
                iovec.withHostBufferPointer { bufferPtr in
                    let bytesToWrite = bufferPtr.count
                    let requiredSize = currentPosition + bytesToWrite

                    if requiredSize > bytes.count {
                        bytes.append(contentsOf: Array(repeating: 0, count: requiredSize - bytes.count))
                    }

                    bytes.replaceSubrange(currentPosition..<(currentPosition + bytesToWrite), with: bufferPtr)
                    currentPosition += bytesToWrite
                    totalWritten += UInt32(bytesToWrite)
                }
            }
            fileNode.content = .bytes(bytes)
            position = currentPosition

        case .handle(let handle):
            var currentOffset = Int64(position)
            for iovec in buffer {
                let nwritten = try iovec.withHostBufferPointer { bufferPtr in
                    try handle.writeAll(toAbsoluteOffset: currentOffset, bufferPtr)
                }
                currentOffset += Int64(nwritten)
                totalWritten += UInt32(nwritten)
            }
            position = Int(currentOffset)
        }

        return totalWritten
    }

    func pwrite<Buffer: Sequence>(vectored buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.write) else {
            throw WASIAbi.Errno.EBADF
        }

        var totalWritten: UInt32 = 0

        switch fileNode.content {
        case .bytes(var bytes):
            var currentOffset = Int(offset)
            for iovec in buffer {
                iovec.withHostBufferPointer { bufferPtr in
                    let bytesToWrite = bufferPtr.count
                    let requiredSize = currentOffset + bytesToWrite

                    if requiredSize > bytes.count {
                        bytes.append(contentsOf: Array(repeating: 0, count: requiredSize - bytes.count))
                    }

                    bytes.replaceSubrange(currentOffset..<(currentOffset + bytesToWrite), with: bufferPtr)
                    currentOffset += bytesToWrite
                    totalWritten += UInt32(bytesToWrite)
                }
            }
            fileNode.content = .bytes(bytes)

        case .handle(let handle):
            var currentOffset = Int64(offset)
            for iovec in buffer {
                let nwritten = try iovec.withHostBufferPointer { bufferPtr in
                    try handle.writeAll(toAbsoluteOffset: currentOffset, bufferPtr)
                }
                currentOffset += Int64(nwritten)
                totalWritten += UInt32(nwritten)
            }
        }

        return totalWritten
    }

    func read<Buffer: Sequence>(into buffer: Buffer) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }

        var totalRead: UInt32 = 0

        switch fileNode.content {
        case .bytes(let bytes):
            var currentPosition = position
            for iovec in buffer {
                iovec.withHostBufferPointer { bufferPtr in
                    let available = max(0, bytes.count - currentPosition)
                    let toRead = min(bufferPtr.count, available)

                    guard toRead > 0 else { return }

                    bytes.withUnsafeBytes { contentBytes in
                        let sourcePtr = contentBytes.baseAddress!.advanced(by: currentPosition)
                        bufferPtr.baseAddress!.copyMemory(from: sourcePtr, byteCount: toRead)
                    }

                    currentPosition += toRead
                    totalRead += UInt32(toRead)
                }
            }
            position = currentPosition

        case .handle(let handle):
            var currentOffset = Int64(position)
            for iovec in buffer {
                let nread = try iovec.withHostBufferPointer { bufferPtr in
                    try handle.read(fromAbsoluteOffset: currentOffset, into: bufferPtr)
                }
                currentOffset += Int64(nread)
                totalRead += UInt32(nread)
            }
            position = Int(currentOffset)
        }

        return totalRead
    }

    func pread<Buffer: Sequence>(into buffer: Buffer, offset: WASIAbi.FileSize) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
        guard accessMode.contains(.read) else {
            throw WASIAbi.Errno.EBADF
        }

        var totalRead: UInt32 = 0

        switch fileNode.content {
        case .bytes(let bytes):
            var currentOffset = Int(offset)
            for iovec in buffer {
                iovec.withHostBufferPointer { bufferPtr in
                    let available = max(0, bytes.count - currentOffset)
                    let toRead = min(bufferPtr.count, available)

                    guard toRead > 0 else { return }

                    bytes.withUnsafeBytes { contentBytes in
                        let sourcePtr = contentBytes.baseAddress!.advanced(by: currentOffset)
                        bufferPtr.baseAddress!.copyMemory(from: sourcePtr, byteCount: toRead)
                    }

                    currentOffset += toRead
                    totalRead += UInt32(toRead)
                }
            }

        case .handle(let handle):
            var currentOffset = Int64(offset)
            for iovec in buffer {
                let nread = try iovec.withHostBufferPointer { bufferPtr in
                    try handle.read(fromAbsoluteOffset: currentOffset, into: bufferPtr)
                }
                currentOffset += Int64(nread)
                totalRead += UInt32(nread)
            }
        }

        return totalRead
    }
}
