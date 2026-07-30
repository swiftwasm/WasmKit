extension FdWASIEntry {
    /// Returns the metadata for the fd entry
    func attributes() throws -> WASIAbi.Filestat {
        try WASIAbi.Errno.translatingPlatformError {
            try WASIAbi.Filestat(stat: self.fd.attributes())
        }
    }

    /// Announces the expected access pattern to the system for optimization
    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize,
        advice: WASIAbi.Advice
    ) throws {
        try WASIAbi.Errno.translatingPlatformError {
            try self.fd.adviseWillNeedRead(offset: offset, length: length)
        }
    }

    /// Closes the file descriptor
    func close() throws {
        try WASIAbi.Errno.translatingPlatformError { try fd.close() }
    }

    /// Truncates or extends the file
    func setFilestatSize(_ size: WASIAbi.FileSize) throws {
        try WASIAbi.Errno.translatingPlatformError {
            try fd.truncate(size: Int64(size))
        }
    }

    /// Seek to the offset
    func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
        let platformWhence: FileDescriptor.SeekOrigin
        switch whence {
        case .SET:
            platformWhence = .start
        case .CUR:
            platformWhence = .current
        case .END:
            platformWhence = .end
        }
        let newOffset = try WASIAbi.Errno.translatingPlatformError {
            try fd.seek(offset: offset, from: platformWhence)
        }
        return WASIAbi.FileSize(newOffset)
    }

    /// Returns the current reading/writing offset
    func tell() throws -> WASIAbi.FileSize {
        WASIAbi.FileSize(
            try WASIAbi.Errno.translatingPlatformError {
                try fd.seek(offset: 0, from: .current)
            })
    }

    /// Returns the file type of the file
    func fileType() throws -> WASIAbi.FileType {
        try WASIAbi.FileType(platformFileType: self.fd.attributes().fileType)
    }

    /// Returns the current file descriptor status
    func status() throws -> WASIAbi.Fdflags {
        return try WASIAbi.Errno.translatingPlatformError {
            WASIAbi.Fdflags(platformOpenOptions: try self.fd.status())
        }
    }

    /// Sets timestamps that belongs to the file
    func setTimes(
        atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
        fstFlags: WASIAbi.FstFlags
    ) throws {
        let (access, modification) = try WASIAbi.Timestamp.platformTimeSpec(
            atim: atim, mtim: mtim, fstFlags: fstFlags
        )
        try WASIAbi.Errno.translatingPlatformError {
            try self.fd.setTimes(access: access, modification: modification)
        }
    }
}
