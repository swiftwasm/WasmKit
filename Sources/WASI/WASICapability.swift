import WasmTypes

/// Wraps an implementation so thrown ``WASIAbi/Errno`` values surface as the
/// errno return value the ABI expects.
func wasiFunction<M: GuestMemory & SendableMetatype>(
    type: FunctionType,
    implementation: @Sendable @escaping (M, [Value]) throws -> [Value]
) -> WASIHostFunction<M> {
    return WASIHostFunction(type: type) { caller, arguments in
        do {
            return try implementation(caller, arguments)
        } catch {
            guard let errno = WASIAbi.Errno.reportable(for: error) else { throw error }
            return [.i32(.init(errno.rawValue))]
        }
    }
}

@Sendable func withMemoryBuffer<M: GuestMemory, T>(
    caller: M,
    body: (M) throws -> T
) throws -> T {
    return try body(caller)
}

@Sendable func readString<M: GuestMemory>(pointer: UInt32, length: UInt32, buffer: M) throws -> String {
    let pointer = UnsafeGuestBufferPointer<UInt8>(
        baseAddress: UnsafeGuestPointer(offset: pointer),
        count: length
    )
    return try pointer.withHostPointer(in: buffer) { hostBuffer in
        guard !hostBuffer.contains(0x00) else {
            // If byte sequence contains null byte in the middle, it's illegal string
            // TODO: This restriction should be only applied to strings that can be interpreted as platform-string, which is expected to be null-terminated
            throw WASIAbi.Errno.EILSEQ
        }
        return String(decoding: hostBuffer, as: UTF8.self)
    }
}

extension WASIImplementation {
    /// Command-line arguments and environment variables.
    func environmentFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["args_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                self.args_get(
                    argv: .init(offset: arguments[0].i32),
                    argvBuffer: .init(offset: arguments[1].i32),
                    memory: buffer
                )
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["args_sizes_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let (argc, bufferSize) = self.args_sizes_get()
                let argcPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[0].i32)
                argcPointer.write(argc, to: buffer)
                let bufferSizePointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[1].i32)
                bufferSizePointer.write(bufferSize, to: buffer)
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["environ_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                self.environ_get(
                    environ: .init(offset: arguments[0].i32),
                    environBuffer: .init(offset: arguments[1].i32),
                    memory: buffer
                )
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["environ_sizes_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let (environSize, bufferSize) = self.environ_sizes_get()
                let environSizePointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[0].i32)
                environSizePointer.write(environSize, to: buffer)
                let bufferSizePointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[1].i32)
                bufferSizePointer.write(bufferSize, to: buffer)
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        return preview1
    }

    /// Wall-clock and monotonic clock queries.
    func clocksFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["clock_res_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            let id = WASIAbi.ClockId(rawValue: arguments[0].i32)
            let res = try self.clock_res_get(id: id)
            try withMemoryBuffer(caller: caller) { buffer in
                let resPointer = UnsafeGuestPointer<WASIAbi.Timestamp>(
                    offset: arguments[1].i32
                )
                resPointer.write(res, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["clock_time_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            let id = WASIAbi.ClockId(rawValue: arguments[0].i32)
            let time = try self.clock_time_get(id: id, precision: WASIAbi.Timestamp(arguments[1].i64))
            try withMemoryBuffer(caller: caller) { buffer in
                let resPointer = UnsafeGuestPointer<WASIAbi.Timestamp>(
                    offset: arguments[2].i32
                )
                resPointer.write(time, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        return preview1
    }

    /// The random byte source.
    func randomFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["random_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                self.random_get(
                    buffer: UnsafeGuestPointer<UInt8>(offset: arguments[0].i32),
                    length: arguments[1].i32,
                    memory: buffer
                )
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        return preview1
    }

    /// Process lifetime and scheduling.
    func processFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["proc_exit"] = wasiFunction(type: .init(parameters: [.i32])) { memory, arguments in
            let exitCode = arguments[0].i32
            throw WASIExitCode(code: exitCode)
        }

        preview1["sched_yield"] = wasiFunction(
            type: .init(parameters: [], results: [.i32])
        ) { _, _ in
            try self.sched_yield()
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        return preview1
    }

    /// Stream I/O on already-open descriptors, which is all a guest needs in
    /// order to write to stdout and stderr.
    func stdioFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["fd_write"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nwritten = try self.fd_write(
                    fileDescriptor: arguments[0].i32,
                    ioVectors: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    memory: buffer
                )
                let nwrittenPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[3].i32)
                nwrittenPointer.write(nwritten, to: buffer)
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["fd_read"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nread = try self.fd_read(
                    fd: arguments[0].i32,
                    iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    memory: buffer
                )
                let nreadPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[3].i32)
                nreadPointer.write(nread, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_close"] = wasiFunction(
            type: .init(parameters: [.i32], results: [.i32])
        ) { caller, arguments in
            try self.fd_close(fd: arguments[0].i32)
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_fdstat_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let stat = try self.fd_fdstat_get(fileDescriptor: arguments[0].i32)
                let statPointer = UnsafeGuestPointer<WASIAbi.FdStat>(offset: arguments[1].i32)
                statPointer.write(stat, to: buffer)
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["fd_fdstat_set_flags"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawFdFlags = UInt16(exactly: arguments[1].i32) else {
                throw WASIAbi.Errno.EINVAL
            }
            try self.fd_fdstat_set_flags(
                fd: arguments[0].i32, flags: WASIAbi.Fdflags(rawValue: rawFdFlags)
            )
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_seek"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            guard let whence = WASIAbi.Whence(rawValue: UInt8(arguments[2].i32)) else {
                return [.i32(.init(WASIAbi.Errno.EINVAL.rawValue))]
            }
            let ret = try self.fd_seek(
                fd: arguments[0].i32, offset: WASIAbi.FileDelta(bitPattern: arguments[1].i64), whence: whence
            )
            try withMemoryBuffer(caller: caller) { buffer in
                let retPointer = UnsafeGuestPointer<WASIAbi.FileSize>(offset: arguments[3].i32)
                retPointer.write(ret, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_tell"] = wasiFunction(type: .init(parameters: [.i32, .i32], results: [.i32])) { caller, arguments in
            let ret = try self.fd_tell(fd: arguments[0].i32)
            try withMemoryBuffer(caller: caller) { buffer in
                let retPointer = UnsafeGuestPointer<WASIAbi.FileSize>(offset: arguments[1].i32)
                retPointer.write(ret, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_sync"] = wasiFunction(type: .init(parameters: [.i32], results: [.i32])) { caller, arguments in
            try self.fd_sync(fd: arguments[0].i32)
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_datasync"] = wasiFunction(
            type: .init(parameters: [.i32], results: [.i32])
        ) { caller, arguments in
            try self.fd_datasync(fd: arguments[0].i32)
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_filestat_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let filestat = try self.fd_filestat_get(fd: arguments[0].i32)
                let filestatPointer = UnsafeGuestPointer<WASIAbi.Filestat>(offset: arguments[1].i32)
                filestatPointer.write(filestat, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        return preview1
    }

    /// Path resolution and the rest of the file-descriptor surface.
    func fileSystemFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["fd_advise"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawAdvice = UInt8(exactly: arguments[3].i32),
                let advice = WASIAbi.Advice(rawValue: rawAdvice)
            else {
                throw WASIAbi.Errno.EINVAL
            }
            try self.fd_advise(
                fd: arguments[0].i32, offset: arguments[1].i64,
                length: arguments[2].i64, advice: advice
            )
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_allocate"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64], results: [.i32])
        ) { caller, arguments in
            try self.fd_allocate(
                fd: arguments[0].i32, offset: arguments[1].i64, length: arguments[2].i64
            )
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_fdstat_set_rights"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64], results: [.i32])
        ) { caller, arguments in
            try self.fd_fdstat_set_rights(
                fd: arguments[0].i32,
                fsRightsBase: WASIAbi.Rights(rawValue: arguments[1].i64),
                fsRightsInheriting: WASIAbi.Rights(rawValue: arguments[2].i64)
            )
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_filestat_set_size"] = wasiFunction(
            type: .init(parameters: [.i32, .i64], results: [.i32])
        ) { caller, arguments in
            try self.fd_filestat_set_size(fd: arguments[0].i32, size: arguments[1].i64)
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_filestat_set_times"] = wasiFunction(
            type: .init(parameters: [.i32, .i64, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawFstFlags = UInt16(exactly: arguments[3].i32) else {
                throw WASIAbi.Errno.EINVAL
            }
            try self.fd_filestat_set_times(
                fd: arguments[0].i32,
                atim: arguments[1].i64, mtim: arguments[2].i64,
                fstFlags: WASIAbi.FstFlags(rawValue: rawFstFlags)
            )
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_pread"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nread = try self.fd_pread(
                    fd: arguments[0].i32,
                    iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    offset: arguments[3].i64,
                    memory: buffer
                )
                let nreadPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[4].i32)
                nreadPointer.write(nread, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_pwrite"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nwritten = try self.fd_pwrite(
                    fd: arguments[0].i32,
                    iovs: UnsafeGuestBufferPointer<WASIAbi.IOVec>(
                        baseAddress: .init(offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    offset: arguments[3].i64,
                    memory: buffer
                )
                let nwrittenPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[4].i32)
                nwrittenPointer.write(nwritten, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_prestat_get"] = wasiFunction(type: .init(parameters: [.i32, .i32], results: [.i32])) { caller, arguments in
            let prestat = try self.fd_prestat_get(fd: arguments[0].i32)
            try withMemoryBuffer(caller: caller) { buffer in
                let prestatPointer = UnsafeGuestPointer<WASIAbi.Prestat>(offset: arguments[1].i32)
                prestatPointer.write(prestat, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_prestat_dir_name"] = wasiFunction(type: .init(parameters: [.i32, .i32, .i32], results: [.i32])) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.fd_prestat_dir_name(
                    fd: arguments[0].i32,
                    path: UnsafeGuestPointer(offset: arguments[1].i32),
                    maxPathLength: arguments[2].i32,
                    memory: buffer
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["fd_readdir"] = wasiFunction(type: .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let nwritten = try self.fd_readdir(
                    fd: arguments[0].i32,
                    buffer: UnsafeGuestBufferPointer<UInt8>(
                        baseAddress: UnsafeGuestPointer<UInt8>(offset: arguments[1].i32),
                        count: arguments[2].i32
                    ),
                    cookie: arguments[3].i64,
                    memory: buffer
                )
                let nwrittenPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[4].i32)
                nwrittenPointer.write(nwritten, to: buffer)
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["fd_renumber"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { caller, arguments in
            try self.fd_renumber(fd: arguments[0].i32, to: arguments[1].i32)
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_create_directory"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_create_directory(
                    dirFd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_filestat_get"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let filestat = try self.path_filestat_get(
                    dirFd: arguments[0].i32, flags: .init(rawValue: arguments[1].i32),
                    path: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer)
                )
                let filestatPointer = UnsafeGuestPointer<WASIAbi.Filestat>(offset: arguments[4].i32)
                filestatPointer.write(filestat, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_filestat_set_times"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i64, .i64, .i32], results: [.i32])
        ) { caller, arguments in
            guard let rawFstFlags = UInt16(exactly: arguments[6].i32) else {
                throw WASIAbi.Errno.EINVAL
            }
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_filestat_set_times(
                    dirFd: arguments[0].i32, flags: .init(rawValue: arguments[1].i32),
                    path: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer),
                    atim: arguments[4].i64, mtim: arguments[5].i64,
                    fstFlags: WASIAbi.FstFlags(rawValue: rawFstFlags)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_link"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_link(
                    oldFd: arguments[0].i32, oldFlags: .init(rawValue: arguments[1].i32),
                    oldPath: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer),
                    newFd: arguments[4].i32,
                    newPath: readString(pointer: arguments[5].i32, length: arguments[6].i32, buffer: buffer)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_open"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i64, .i64, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let newFd = try self.path_open(
                    dirFd: arguments[0].i32,
                    dirFlags: .init(rawValue: arguments[1].i32),
                    path: readString(pointer: arguments[2].i32, length: arguments[3].i32, buffer: buffer),
                    oflags: .init(rawValue: arguments[4].i32),
                    fsRightsBase: .init(rawValue: arguments[5].i64),
                    fsRightsInheriting: .init(rawValue: arguments[6].i64),
                    fdflags: .init(rawValue: UInt16(arguments[7].i32))
                )
                let newFdPointer = UnsafeGuestPointer<WASIAbi.Fd>(offset: arguments[8].i32)
                newFdPointer.write(newFd, to: buffer)
                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        preview1["path_readlink"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let ret = try self.path_readlink(
                    fd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer),
                    buffer: UnsafeGuestBufferPointer<UInt8>(
                        baseAddress: .init(offset: arguments[3].i32),
                        count: arguments[4].i32
                    ),
                    memory: buffer
                )
                let retPointer = UnsafeGuestPointer<WASIAbi.Size>(offset: arguments[5].i32)
                retPointer.write(ret, to: buffer)
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_remove_directory"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_remove_directory(
                    dirFd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_rename"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_rename(
                    oldFd: arguments[0].i32,
                    oldPath: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer),
                    newFd: arguments[3].i32,
                    newPath: readString(pointer: arguments[4].i32, length: arguments[5].i32, buffer: buffer)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_symlink"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_symlink(
                    oldPath: readString(pointer: arguments[0].i32, length: arguments[1].i32, buffer: buffer),
                    dirFd: arguments[2].i32,
                    newPath: readString(pointer: arguments[3].i32, length: arguments[4].i32, buffer: buffer)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        preview1["path_unlink_file"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                try self.path_unlink_file(
                    dirFd: arguments[0].i32,
                    path: readString(pointer: arguments[1].i32, length: arguments[2].i32, buffer: buffer)
                )
            }
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        return preview1
    }

    /// `poll_oneoff`.
    func pollFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["poll_oneoff"] = wasiFunction(
            type: .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])
        ) { caller, arguments in
            try withMemoryBuffer(caller: caller) { buffer in
                let subscriptionsBaseAddress = UnsafeGuestPointer<WASIAbi.Subscription>(offset: arguments[0].i32)
                let eventsBaseAddress = UnsafeGuestPointer<WASIAbi.Event>(offset: arguments[1].i32)
                let size = try self.poll_oneoff(
                    subscriptions: .init(baseAddress: subscriptionsBaseAddress, count: arguments[2].i32),
                    events: .init(baseAddress: eventsBaseAddress, count: arguments[2].i32),
                    memory: buffer
                )
                buffer.withUnsafeMutableBufferPointer(offset: .init(arguments[3].i32), count: MemoryLayout<UInt32>.size) { raw in
                    raw.withMemoryRebound(to: UInt32.self) { rebound in rebound[0] = size.littleEndian }
                }

                return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
            }
        }

        return preview1
    }

    /// The implemented part of the socket surface.
    func socketsFunctions<M: GuestMemory & SendableMetatype>() -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]

        preview1["sock_shutdown"] = wasiFunction(
            type: .init(parameters: [.i32, .i32], results: [.i32])
        ) { _, arguments in
            try self.sock_shutdown(fd: arguments[0].i32)
            return [.i32(.init(WASIAbi.Errno.SUCCESS.rawValue))]
        }

        return preview1
    }

}

/// Every `wasi_snapshot_preview1` function and its type.
///
/// Pure data: it references no implementation, so naming a function here
/// does not keep that function's code alive when the linker strips unused
/// sections. Used to stub imports a guest declares but that no linked
/// capability provides.
let preview1Signatures: [(name: String, type: FunctionType)] = [
    ("args_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("args_sizes_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("clock_res_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("clock_time_get", .init(parameters: [.i32, .i64, .i32], results: [.i32])),
    ("environ_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("environ_sizes_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_advise", .init(parameters: [.i32, .i64, .i64, .i32], results: [.i32])),
    ("fd_allocate", .init(parameters: [.i32, .i64, .i64], results: [.i32])),
    ("fd_close", .init(parameters: [.i32], results: [.i32])),
    ("fd_datasync", .init(parameters: [.i32], results: [.i32])),
    ("fd_fdstat_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_fdstat_set_flags", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_fdstat_set_rights", .init(parameters: [.i32, .i64, .i64], results: [.i32])),
    ("fd_filestat_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_filestat_set_size", .init(parameters: [.i32, .i64], results: [.i32])),
    ("fd_filestat_set_times", .init(parameters: [.i32, .i64, .i64, .i32], results: [.i32])),
    ("fd_pread", .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])),
    ("fd_prestat_dir_name", .init(parameters: [.i32, .i32, .i32], results: [.i32])),
    ("fd_prestat_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_pwrite", .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])),
    ("fd_read", .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])),
    ("fd_readdir", .init(parameters: [.i32, .i32, .i32, .i64, .i32], results: [.i32])),
    ("fd_renumber", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_seek", .init(parameters: [.i32, .i64, .i32, .i32], results: [.i32])),
    ("fd_sync", .init(parameters: [.i32], results: [.i32])),
    ("fd_tell", .init(parameters: [.i32, .i32], results: [.i32])),
    ("fd_write", .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])),
    ("path_create_directory", .init(parameters: [.i32, .i32, .i32], results: [.i32])),
    ("path_filestat_get", .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("path_filestat_set_times", .init(parameters: [.i32, .i32, .i32, .i32, .i64, .i64, .i32], results: [.i32])),
    ("path_link", .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("path_open", .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i64, .i64, .i32, .i32], results: [.i32])),
    ("path_readlink", .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("path_remove_directory", .init(parameters: [.i32, .i32, .i32], results: [.i32])),
    ("path_rename", .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("path_symlink", .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("path_unlink_file", .init(parameters: [.i32, .i32, .i32], results: [.i32])),
    ("poll_oneoff", .init(parameters: [.i32, .i32, .i32, .i32], results: [.i32])),
    ("proc_exit", .init(parameters: [.i32])),
    ("proc_raise", .init(parameters: [.i32], results: [.i32])),
    ("random_get", .init(parameters: [.i32, .i32], results: [.i32])),
    ("sched_yield", .init(parameters: [], results: [.i32])),
    ("sock_accept", .init(parameters: [.i32, .i32, .i32], results: [.i32])),
    ("sock_recv", .init(parameters: [.i32, .i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("sock_send", .init(parameters: [.i32, .i32, .i32, .i32, .i32], results: [.i32])),
    ("sock_shutdown", .init(parameters: [.i32, .i32], results: [.i32])),
]

/// A group of `wasi_snapshot_preview1` functions that can be linked on its own.
///
/// Capabilities are values that each carry their own registrar rather than
/// cases of an option set. That distinction matters on embedded targets: a
/// single function that switched over every option would reference every
/// registrar, so the linker would have to keep all of them. Here a call site
/// references only the capabilities it names, and `--gc-sections` can drop the
/// rest -- provided the code was compiled with `-Xfrontend -function-sections`.
public struct WASICapability<M: GuestMemory & SendableMetatype>: Sendable {
    let functions: @Sendable (WASIImplementation) -> [String: WASIHostFunction<M>]

    /// Command-line arguments and environment variables.
    public static var environment: Self { .init { $0.environmentFunctions() } }
    /// Wall-clock and monotonic clock queries.
    public static var clocks: Self { .init { $0.clocksFunctions() } }
    /// The random byte source.
    public static var random: Self { .init { $0.randomFunctions() } }
    /// Process lifetime and scheduling.
    public static var process: Self { .init { $0.processFunctions() } }
    /// Stream I/O on already-open descriptors -- enough to write to stdout.
    public static var stdio: Self { .init { $0.stdioFunctions() } }
    /// Path resolution and the rest of the file-descriptor surface.
    public static var fileSystem: Self { .init { $0.fileSystemFunctions() } }
    /// `poll_oneoff`.
    public static var poll: Self { .init { $0.pollFunctions() } }
    /// The implemented part of the socket surface.
    public static var sockets: Self { .init { $0.socketsFunctions() } }

    /// Every capability.
    ///
    /// Naming this pulls in all of them, which is the right default on a host
    /// but defeats stripping on a constrained target.
    public static var all: [Self] {
        [.environment, .clocks, .random, .process, .stdio, .fileSystem, .poll, .sockets]
    }
}

extension WASIImplementation {
    /// Builds the host function table for `capabilities`.
    ///
    /// - Parameter stubUnlinked: When true, every preview1 function not
    ///   provided by `capabilities` is defined as a shared stub returning
    ///   `ENOSYS`. Guests link against a fixed import list regardless of what
    ///   they call at runtime, so without this a subset would fail to
    ///   instantiate on an import it never uses.
    func functions<M: GuestMemory & SendableMetatype>(
        for capabilities: [WASICapability<M>],
        stubUnlinked: Bool
    ) -> [String: WASIHostFunction<M>] {
        var preview1: [String: WASIHostFunction<M>] = [:]
        for capability in capabilities {
            // Capabilities may overlap; first one wins, they are equivalent.
            preview1.merge(capability.functions(self)) { existing, _ in existing }
        }
        guard stubUnlinked else { return preview1 }
        for (name, type) in preview1Signatures where preview1[name] == nil {
            preview1[name] = WASIHostFunction(type: type) { _, _ in
                [.i32(.init(WASIAbi.Errno.ENOSYS.rawValue))]
            }
        }
        return preview1
    }
}
