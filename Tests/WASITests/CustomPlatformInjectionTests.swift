import Synchronization
import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// Exercises the platform-injection seams end to end: a WASI instance built
/// from a custom `FileSystemImplementation`, custom `WASIFile` stdio, and
/// injected clocks/random generator, without touching any host platform API.
/// This is the contract that lets WASI run on platforms WasmKit doesn't know
/// about (e.g. custom embedded systems).
@Suite
struct CustomPlatformInjectionTests {

    /// A read-only file backed by an in-memory byte buffer.
    final class FixedContentFile: WASIFile, Sendable {
        let bytes: [UInt8]
        init(bytes: [UInt8]) { self.bytes = bytes }

        func attributes() throws -> WASIAbi.Filestat {
            WASIAbi.Filestat(
                dev: 0, ino: 1, filetype: .REGULAR_FILE, nlink: 1,
                size: WASIAbi.FileSize(bytes.count), atim: 0, mtim: 0, ctim: 0)
        }
        func fileType() throws -> WASIAbi.FileType { .REGULAR_FILE }
        func status() throws -> WASIAbi.Fdflags { [] }
        func setTimes(atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, fstFlags: WASIAbi.FstFlags) throws {
            throw WASIAbi.Errno.EROFS
        }
        func advise(offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice) throws {}
        func close() throws {}
        func fdStat() throws -> WASIAbi.FdStat {
            WASIAbi.FdStat(fsFileType: .REGULAR_FILE, fsFlags: [], fsRightsBase: .FD_READ, fsRightsInheriting: [])
        }
        func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws { throw WASIAbi.Errno.ENOTSUP }
        func setFilestatSize(_ size: WASIAbi.FileSize) throws { throw WASIAbi.Errno.EROFS }
        func sync() throws {}
        func datasync() throws {}
        func tell() throws -> WASIAbi.FileSize { 0 }
        func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
            throw WASIAbi.Errno.ESPIPE
        }
        func write<M: GuestMemory, Buffer: Sequence>(
            vectored buffer: Buffer, memory: M
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            throw WASIAbi.Errno.EROFS
        }
        func pwrite<M: GuestMemory, Buffer: Sequence>(
            vectored buffer: Buffer, memory: M, offset: WASIAbi.FileSize
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            throw WASIAbi.Errno.EROFS
        }
        func read<M: GuestMemory, Buffer: Sequence>(
            into buffer: Buffer, memory: M
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            try pread(into: buffer, memory: memory, offset: 0)
        }
        func pread<M: GuestMemory, Buffer: Sequence>(
            into buffer: Buffer, memory: M, offset: WASIAbi.FileSize
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            var cursor = Int(offset)
            var total: WASIAbi.Size = 0
            for iovec in buffer {
                let count: Int = iovec.withHostBufferPointer(in: memory) { destination in
                    let available = max(0, bytes.count - cursor)
                    let toRead = min(destination.count, available)
                    guard toRead > 0 else { return 0 }
                    bytes.withUnsafeBytes { source in
                        destination.baseAddress!.copyMemory(
                            from: source.baseAddress!.advanced(by: cursor), byteCount: toRead)
                    }
                    return toRead
                }
                cursor += count
                total += WASIAbi.Size(count)
            }
            return total
        }
    }

    /// A write-only sink that records everything written to it (a stand-in
    /// for e.g. a UART on an embedded system).
    final class SinkFile: WASIFile, Sendable {
        let captured = Mutex<[UInt8]>([])

        func attributes() throws -> WASIAbi.Filestat {
            WASIAbi.Filestat(dev: 0, ino: 0, filetype: .CHARACTER_DEVICE, nlink: 0, size: 0, atim: 0, mtim: 0, ctim: 0)
        }
        func fileType() throws -> WASIAbi.FileType { .CHARACTER_DEVICE }
        func status() throws -> WASIAbi.Fdflags { [] }
        func setTimes(atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, fstFlags: WASIAbi.FstFlags) throws {
            throw WASIAbi.Errno.ENOTSUP
        }
        func advise(offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice) throws {}
        func close() throws {}
        func fdStat() throws -> WASIAbi.FdStat {
            WASIAbi.FdStat(fsFileType: .CHARACTER_DEVICE, fsFlags: [], fsRightsBase: .FD_WRITE, fsRightsInheriting: [])
        }
        func setFdStatFlags(_ flags: WASIAbi.Fdflags) throws {}
        func setFilestatSize(_ size: WASIAbi.FileSize) throws { throw WASIAbi.Errno.ENOTSUP }
        func sync() throws {}
        func datasync() throws {}
        func tell() throws -> WASIAbi.FileSize { 0 }
        func seek(offset: WASIAbi.FileDelta, whence: WASIAbi.Whence) throws -> WASIAbi.FileSize {
            throw WASIAbi.Errno.ESPIPE
        }
        func write<M: GuestMemory, Buffer: Sequence>(
            vectored buffer: Buffer, memory: M
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            var total: WASIAbi.Size = 0
            for iovec in buffer {
                iovec.withHostBufferPointer(in: memory) { source in
                    captured.withLock { $0.append(contentsOf: source.bindMemory(to: UInt8.self)) }
                    total += WASIAbi.Size(source.count)
                }
            }
            return total
        }
        func pwrite<M: GuestMemory, Buffer: Sequence>(
            vectored buffer: Buffer, memory: M, offset: WASIAbi.FileSize
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            throw WASIAbi.Errno.ESPIPE
        }
        func read<M: GuestMemory, Buffer: Sequence>(
            into buffer: Buffer, memory: M
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            throw WASIAbi.Errno.EBADF
        }
        func pread<M: GuestMemory, Buffer: Sequence>(
            into buffer: Buffer, memory: M, offset: WASIAbi.FileSize
        ) throws -> WASIAbi.Size where Buffer.Element == WASIAbi.IOVec {
            throw WASIAbi.Errno.EBADF
        }
    }

    /// A single-directory file system exposing a fixed set of named files.
    final class SingleDirectoryFS: FileSystemImplementation, Sendable {
        let files: [String: [UInt8]]
        init(files: [String: [UInt8]]) { self.files = files }

        struct Directory: WASIDir {
            let preopenPath: String?
            let files: [String: [UInt8]]

            func attributes() throws -> WASIAbi.Filestat {
                WASIAbi.Filestat(dev: 0, ino: 0, filetype: .DIRECTORY, nlink: 1, size: 0, atim: 0, mtim: 0, ctim: 0)
            }
            func fileType() throws -> WASIAbi.FileType { .DIRECTORY }
            func status() throws -> WASIAbi.Fdflags { [] }
            func setTimes(atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, fstFlags: WASIAbi.FstFlags) throws {
                throw WASIAbi.Errno.EROFS
            }
            func advise(offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice) throws {}
            func close() throws {}

            func readlink(atPath path: String) throws -> [UInt8] { throw WASIAbi.Errno.EINVAL }
            func createDirectory(atPath path: String) throws { throw WASIAbi.Errno.EROFS }
            func removeDirectory(atPath path: String) throws { throw WASIAbi.Errno.EROFS }
            func removeFile(atPath path: String) throws { throw WASIAbi.Errno.EROFS }
            func symlink(from sourcePath: String, to destPath: String) throws { throw WASIAbi.Errno.EROFS }
            func rename(from sourcePath: String, toDir newDir: any WASIDir, to destPath: String) throws {
                throw WASIAbi.Errno.EROFS
            }

            struct ReadEntriesResult: WASIReaddirIterator {
                var entries: [(WASIAbi.Dirent, String)]
                var index = 0
                mutating func next() -> Result<(dirent: WASIAbi.Dirent, name: String), any Error>? {
                    guard index < entries.count else { return nil }
                    defer { index += 1 }
                    return .success(entries[index])
                }
                mutating func close() {}
            }

            func readEntries(cookie: WASIAbi.DirCookie) throws -> ReadEntriesResult {
                let entries = files.keys.sorted().enumerated().map { index, name in
                    (
                        WASIAbi.Dirent(
                            dNext: WASIAbi.DirCookie(index + 1), dIno: 0,
                            dirNameLen: WASIAbi.DirNameLen(name.utf8.count), dType: .REGULAR_FILE),
                        name
                    )
                }
                return ReadEntriesResult(entries: Array(entries.dropFirst(Int(cookie))))
            }

            func attributes(path: String, symlinkFollow: Bool) throws -> WASIAbi.Filestat {
                guard let bytes = files[path] else { throw WASIAbi.Errno.ENOENT }
                return WASIAbi.Filestat(
                    dev: 0, ino: 1, filetype: .REGULAR_FILE, nlink: 1,
                    size: WASIAbi.FileSize(bytes.count), atim: 0, mtim: 0, ctim: 0)
            }
            func setFilestatTimes(
                path: String, atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp,
                fstFlags: WASIAbi.FstFlags, symlinkFollow: Bool
            ) throws {
                throw WASIAbi.Errno.EROFS
            }
        }

        func preopenDirectory(guestPath: String, hostPath: String) throws -> any WASIDir {
            Directory(preopenPath: guestPath, files: files)
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
            guard !oflags.contains(.DIRECTORY) else { throw WASIAbi.Errno.ENOTDIR }
            guard let bytes = files[path] else { throw WASIAbi.Errno.ENOENT }
            return .file(FixedContentFile(bytes: bytes))
        }
    }

    struct FixedWallClock: WallClock {
        func now() throws -> WallClock.Duration { (seconds: 1_234, nanoseconds: 567) }
        func resolution() throws -> WallClock.Duration { (seconds: 0, nanoseconds: 1) }
    }

    struct FixedMonotonicClock: MonotonicClock {
        func now() throws -> MonotonicClock.Instant { 42_000 }
        func resolution() throws -> MonotonicClock.Duration { 1 }
    }

    struct CountingRandom: RandomBufferGenerator {
        func fill(buffer: UnsafeMutableBufferPointer<UInt8>) {
            for i in buffer.indices { buffer[i] = UInt8(truncatingIfNeeded: i &+ 1) }
        }
    }

    private func makeBridge(stdout: SinkFile) throws -> WASIBridgeToHost {
        let files = ["hello.txt": Array("Hello, injected world!".utf8)]
        return try WASIBridgeToHost(
            args: ["main"],
            environment: [:],
            fileSystem: .custom({ SingleDirectoryFS(files: files) })
                .withStdio(stdin: FixedContentFile(bytes: []), stdout: stdout, stderr: SinkFile())
                .withPreopens([.init(guestPath: "/", hostPath: "/")]),
            wallClock: FixedWallClock(),
            monotonicClock: FixedMonotonicClock(),
            randomGenerator: CountingRandom()
        )
    }

    @Test
    func customFileSystemAndStdio() throws {
        let stdout = SinkFile()
        let bridge = try makeBridge(stdout: stdout)
        let wasi = bridge.underlying
        let rootFd: WASIAbi.Fd = 3

        let memory = TestSupport.TestGuestMemory()

        // Open and read a file served by the custom file system.
        let fd = try wasi.path_open(
            dirFd: rootFd, dirFlags: [], path: "hello.txt", oflags: [],
            fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
        )
        let expected = "Hello, injected world!"
        let readVecs = memory.readIOVecs(sizes: [expected.utf8.count])
        let nread = try wasi.fd_read(fd: fd, iovs: readVecs, memory: memory)
        #expect(nread == WASIAbi.Size(expected.utf8.count))
        let content = memory.loadIOVecs(readVecs)[0]
        #expect(String(decoding: content, as: UTF8.self) == expected)
        try wasi.fd_close(fd: fd)

        // Write to the injected stdout sink.
        let writeVecs = memory.writeIOVecs([Array("ping".utf8)])
        let written = try wasi.fd_write(fileDescriptor: 1, ioVectors: writeVecs, memory: memory)
        #expect(written == 4)
        #expect(stdout.captured.withLock { String(decoding: $0, as: UTF8.self) } == "ping")

        try bridge.close()
    }

    @Test
    func injectedClocksAndRandom() throws {
        let bridge = try makeBridge(stdout: SinkFile())
        let wasi = bridge.underlying

        let realtime = try wasi.clock_time_get(id: .REALTIME, precision: 0)
        #expect(realtime == 1_234 * 1_000_000_000 + 567)
        let monotonic = try wasi.clock_time_get(id: .MONOTONIC, precision: 0)
        #expect(monotonic == 42_000)

        let memory = TestSupport.TestGuestMemory()
        wasi.random_get(buffer: UnsafeGuestPointer<UInt8>(offset: 0x100), length: 4, memory: memory)
        let randomBytes = memory.withUnsafeMutableBufferPointer(offset: 0x100, count: 4) { [UInt8]($0) }
        #expect(randomBytes == [1, 2, 3, 4])

        try bridge.close()
    }
}
