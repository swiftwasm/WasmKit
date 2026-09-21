import Foundation
import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// What a descriptor was opened for bounds what can be done through it, and a
/// host resource an embedder lent the file system is not the guest's to change.
@Suite struct WASIAccessModeTests {

    #if !os(WASI) && !os(Windows)
        /// `path_open` may omit `FD_READ`, in which case the descriptor is not
        /// a descriptor to read from -- even though the host file underneath it
        /// was opened readable, since `openat` needs an access mode.
        @Test func readingThroughADescriptorOpenedWithoutReadRightsIsRefused() throws {
            let directory = try TestSupport.TemporaryDirectory()
            try directory.createFile(at: "a.txt", contents: "secret")
            let bridge = try WASIBridgeToHost(
                fileSystem: .host().withPreopens([.init(guestPath: "/dir", hostPath: directory.path)])
            )
            try bridge.runAndClose { bridge in
                let wasi = bridge.underlying
                let fd = try wasi.path_open(
                    dirFd: 3, dirFlags: [], path: "a.txt", oflags: [],
                    fsRightsBase: [], fsRightsInheriting: [], fdflags: [])
                let memory = TestSupport.TestGuestMemory()
                let vectors = memory.readIOVecs(sizes: [6])
                #expect(throws: WASIAbi.Errno.EBADF) {
                    _ = try wasi.fd_read(fd: fd, iovs: vectors, memory: memory)
                }
                #expect(throws: WASIAbi.Errno.EBADF) {
                    _ = try wasi.fd_pread(fd: fd, iovs: vectors, offset: 0, memory: memory)
                }
                try wasi.fd_close(fd: fd)
            }
        }

        /// A `.handle`-backed file in a ``MemoryFileSystem`` is a descriptor the
        /// embedder lent it. Its timestamps are the host file's, so the guest
        /// sets them on the node instead of writing through.
        @Test func settingTimesOnAHandleBackedFileLeavesTheHostFileAlone() throws {
            let directory = try TestSupport.TemporaryDirectory()
            try directory.createFile(at: "target.txt", contents: "content")
            let opened = try directory.openFile(at: "target.txt", .readWrite)
            defer { try? opened.close() }

            let path = directory.url.appendingPathComponent("target.txt").path
            func hostModificationDate() throws -> Date {
                try #require(FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date)
            }
            let before = try hostModificationDate()

            let fs = try MemoryFileSystem()
            try fs.addFile(at: "/dir/handle.txt", handle: opened.fileDescriptor)
            let bridge = try WASIBridgeToHost(
                fileSystem: .memory(fs).withPreopens([.init(guestPath: "/dir", hostPath: "/dir")])
            )
            try bridge.runAndClose { bridge in
                let wasi = bridge.underlying
                let fd = try wasi.path_open(
                    dirFd: 3, dirFlags: [], path: "handle.txt", oflags: [],
                    fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
                // A timestamp far from now, so a write-through would show.
                let stamp: WASIAbi.Timestamp = 1_000_000_000
                try wasi.fd_filestat_set_times(fd: fd, atim: stamp, mtim: stamp, fstFlags: [.ATIM, .MTIM])
                #expect(try wasi.fd_filestat_get(fd: fd).mtim == stamp)
                try wasi.fd_close(fd: fd)
            }
            #expect(try hostModificationDate() == before)
        }
    #endif
}
