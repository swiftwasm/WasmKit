import SystemPackage

extension FdWASIEntry {
    /// Returns the metadata for the fd entry
    func attributes() throws -> WASIAbi.Filestat {
        try WASIAbi.Errno.translatingPlatformErrno {
            try WASIAbi.Filestat(stat: self.fd.attributes())
        }
    }

    /// Announces the expected access pattern to the system for optimization
    func advise(
        offset: WASIAbi.FileSize, length: WASIAbi.FileSize,
        advice: WASIAbi.Advice
    ) throws {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            guard let offset = Int64(exactly: offset),
                let length = Int32(exactly: length)
            else {
                // no-op if offset or length is invalid
                return
            }
            try WASIAbi.Errno.translatingPlatformErrno {
                try self.fd.adviseRead(offset: offset, length: length)
            }
        #elseif os(Linux)
            guard let offset = Int(exactly: offset),
                let length = Int(exactly: length)
            else {
                // no-op if offset or length is invalid
                return
            }
            try WASIAbi.Errno.translatingPlatformErrno {
                try self.fd.advise(offset: offset, length: length, advice: .willNeed)
            }
        #endif
    }

    /// Closes the file descriptor
    func close() throws {
        try WASIAbi.Errno.translatingPlatformErrno { try fd.close() }
    }

    /// Truncates or extends the file
    func setFilestatSize(_ size: WASIAbi.FileSize) throws {
        try WASIAbi.Errno.translatingPlatformErrno {
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
        let newOffset = try WASIAbi.Errno.translatingPlatformErrno {
            try fd.seek(offset: offset, from: platformWhence)
        }
        return WASIAbi.FileSize(newOffset)
    }

    /// Returns the current reading/writing offset
    func tell() throws -> WASIAbi.FileSize {
        WASIAbi.FileSize(
            try WASIAbi.Errno.translatingPlatformErrno {
                try fd.seek(offset: 0, from: .current)
            })
    }

    /// Returns the file type of the file
    func fileType() throws -> WASIAbi.FileType {
        try WASIAbi.FileType(platformFileType: self.fd.attributes().fileType)
    }

    /// Returns the current file descriptor status
    func status() throws -> WASIAbi.Fdflags {
        return try WASIAbi.Errno.translatingPlatformErrno {
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
        try WASIAbi.Errno.translatingPlatformErrno {
            try self.fd.setTimes(access: access, modification: modification)
        }
    }
}
