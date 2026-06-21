import Testing

@testable import WASI

@Suite struct WASIFdRenumberTests {
    /// Helper: run `body` with a WASI implementation backed by a MemoryFileSystem
    /// containing two files. The owning bridge is closed once `body` returns.
    private func withWASI(_ body: (WASIImplementation) throws -> Void) throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/a.txt", content: Array("file-a".utf8))
        try fs.addFile(at: "/b.txt", content: Array("file-b".utf8))
        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([
                .init(guestPath: "/", hostPath: "/")
            ])
        )
        try bridge.runAndClose { bridge in
            try body(bridge.underlying)
        }
    }

    @Test func renumber_sourceBecomesInvalid() throws {
        try withWASI { wasi in
            let rootFd: WASIAbi.Fd = 3

            let fdA = try wasi.path_open(
                dirFd: rootFd, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
            )
            let fdB = try wasi.path_open(
                dirFd: rootFd, dirFlags: [], path: "b.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
            )

            // Both fds valid before renumber
            #expect(try wasi.fd_filestat_get(fd: fdA).filetype == .REGULAR_FILE)
            #expect(try wasi.fd_filestat_get(fd: fdB).filetype == .REGULAR_FILE)

            try wasi.fd_renumber(fd: fdA, to: fdB)

            // Source fd is now invalid
            #expect(throws: WASIAbi.Errno.EBADF) {
                _ = try wasi.fd_filestat_get(fd: fdA)
            }

            // Target fd is valid (now points to what was fdA)
            #expect(try wasi.fd_filestat_get(fd: fdB).filetype == .REGULAR_FILE)

            try wasi.fd_close(fd: fdB)
        }
    }

    @Test func renumber_targetEntryIsClosed() throws {
        try withWASI { wasi in
            let rootFd: WASIAbi.Fd = 3

            let fdA = try wasi.path_open(
                dirFd: rootFd, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
            )
            let fdB = try wasi.path_open(
                dirFd: rootFd, dirFlags: [], path: "b.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
            )

            // Renumber fdA -> fdB; the old fdB entry gets closed
            try wasi.fd_renumber(fd: fdA, to: fdB)

            // After renumber, closing fdB again should succeed (it's the moved fdA)
            try wasi.fd_close(fd: fdB)

            // Both fds now invalid
            #expect(throws: WASIAbi.Errno.EBADF) {
                _ = try wasi.fd_filestat_get(fd: fdA)
            }
            #expect(throws: WASIAbi.Errno.EBADF) {
                _ = try wasi.fd_filestat_get(fd: fdB)
            }
        }
    }

    @Test func renumber_invalidSourceReturnsEBADF() throws {
        try withWASI { wasi in
            #expect(throws: WASIAbi.Errno.EBADF) {
                try wasi.fd_renumber(fd: 99, to: 3)
            }

            // fd 3 (root preopen) is unaffected — accessing it should not throw
            _ = try wasi.fd_prestat_get(fd: 3)
        }
    }

    @Test func renumber_invalidTargetReturnsEBADF() throws {
        try withWASI { wasi in
            #expect(throws: WASIAbi.Errno.EBADF) {
                try wasi.fd_renumber(fd: 3, to: 99)
            }

            // fd 3 is unaffected — accessing it should not throw
            _ = try wasi.fd_prestat_get(fd: 3)
        }
    }

    @Test func renumber_selfIsNoop() throws {
        try withWASI { wasi in
            let rootFd: WASIAbi.Fd = 3

            let fd = try wasi.path_open(
                dirFd: rootFd, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
            )

            // Renumber fd to itself — fd_renumber sets source to nil after
            // overwriting target with the same entry, so the slot is cleared
            try wasi.fd_renumber(fd: fd, to: fd)

            // The fd should be gone
            #expect(throws: WASIAbi.Errno.EBADF) {
                _ = try wasi.fd_filestat_get(fd: fd)
            }
        }
    }
}
