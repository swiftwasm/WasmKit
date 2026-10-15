import Synchronization
import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// A descriptor the embedder owns (process stdio, or any resource handed to
/// ``WASIBridgeToHost/FileSystemOptions/withStdio(stdin:stdout:stderr:)``) is
/// borrowed: the guest may drop it from its own table, but the resource behind
/// it belongs to the host and outlives the guest.
@Suite struct WASIFdLifetimeTests {

    /// A borrowed stdio stream that records whether it was closed.
    final class BorrowedStream: WASIFile, Sendable {
        let closed = Mutex(false)
        var isBorrowed: Bool { true }

        func attributes() throws -> WASIAbi.Filestat {
            WASIAbi.Filestat(dev: 0, ino: 0, filetype: .CHARACTER_DEVICE, nlink: 0, size: 0, atim: 0, mtim: 0, ctim: 0)
        }
        func fileType() throws -> WASIAbi.FileType { .CHARACTER_DEVICE }
        func status() throws -> WASIAbi.Fdflags { [] }
        func setTimes(atim: WASIAbi.Timestamp, mtim: WASIAbi.Timestamp, fstFlags: WASIAbi.FstFlags) throws {}
        func advise(offset: WASIAbi.FileSize, length: WASIAbi.FileSize, advice: WASIAbi.Advice) throws {}
        func close() throws { closed.withLock { $0 = true } }
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
        func write(vectored buffers: GuestBuffers) throws -> WASIAbi.Size { 0 }
        func pwrite(vectored buffers: GuestBuffers, offset: WASIAbi.FileSize) throws -> WASIAbi.Size { 0 }
        func read(into buffers: GuestBuffers) throws -> WASIAbi.Size { 0 }
        func pread(into buffers: GuestBuffers, offset: WASIAbi.FileSize) throws -> WASIAbi.Size { 0 }
    }

    private func withStdio(
        _ body: (WASIImplementation, BorrowedStream) throws -> Void
    ) throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/dir")
        try fs.addFile(at: "/dir/a.txt", content: "a")
        let stdout = BorrowedStream()
        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs)
                .withStdio(stdin: BorrowedStream(), stdout: stdout, stderr: BorrowedStream())
                .withPreopens([.init(guestPath: "/dir", hostPath: "/dir")])
        )
        try bridge.runAndClose { try body($0.underlying, stdout) }
    }

    @Test func closingABorrowedDescriptorLeavesTheResourceOpen() throws {
        try withStdio { wasi, stdout in
            try wasi.fd_close(fd: 1)
            #expect(stdout.closed.withLock { $0 } == false)
            // The guest's own descriptor is gone all the same.
            #expect(throws: WASIAbi.Errno.EBADF) { _ = try wasi.fd_fdstat_get(fileDescriptor: 1) }
        }
    }

    @Test func renumberingOntoABorrowedDescriptorLeavesTheResourceOpen() throws {
        try withStdio { wasi, stdout in
            let fd = try wasi.path_open(
                dirFd: 3, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
            try wasi.fd_renumber(fd: fd, to: 1)
            #expect(stdout.closed.withLock { $0 } == false)
            #expect(try wasi.fd_fdstat_get(fileDescriptor: 1).fsFileType == .REGULAR_FILE)
        }
    }

    /// Renumbering a descriptor onto itself changes nothing, so the descriptor
    /// stays usable afterwards.
    @Test func renumberingADescriptorOntoItselfKeepsIt() throws {
        try withStdio { wasi, _ in
            let fd = try wasi.path_open(
                dirFd: 3, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
            try wasi.fd_renumber(fd: fd, to: fd)
            #expect(try wasi.fd_filestat_get(fd: fd).filetype == .REGULAR_FILE)
        }
    }

    #if os(macOS) || os(Linux)
        /// The same contract for the host descriptors `withStdio(stdin:stdout:stderr:)`
        /// borrows: after the guest closes them, the host still has them open.
        @Test func closingBorrowedStdioLeavesTheHostDescriptorsOpen() throws {
            let directory = try TestSupport.TemporaryDirectory()
            try directory.createFile(at: "out.txt", contents: "")
            let opened = try directory.openFile(at: "out.txt", .readWrite)
            defer { try? opened.close() }
            let expectedPath = try TestSupport.realPath(directory.url.appendingPathComponent("out.txt").path)

            let fs = try MemoryFileSystem()
            try fs.ensureDirectory(at: "/dir")
            let bridge = try WASIBridgeToHost(
                fileSystem: .memory(fs)
                    .withStdio(stdin: opened.fileDescriptor, stdout: opened.fileDescriptor, stderr: opened.fileDescriptor)
                    .withPreopens([.init(guestPath: "/dir", hostPath: "/dir")])
            )
            try bridge.runAndClose { bridge in
                for fd: WASIAbi.Fd in [0, 1, 2] {
                    try bridge.underlying.fd_close(fd: fd)
                }
            }
            #expect(try TestSupport.openDescriptorPaths().contains(expectedPath))
        }
    #endif
}
