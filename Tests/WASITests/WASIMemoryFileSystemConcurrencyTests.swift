import Testing

import SystemExtras

@testable import WASI

@Suite struct MemoryFileSystemConcurrencyTests {
    @Test func concurrentAddAndRead() async throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/data")

        let iterations = 50

        try await withThrowingTaskGroup(of: Void.self) { group in
            for t in 0..<4 {
                group.addTask {
                    for i in 0..<iterations {
                        let path = "/data/t\(t)_f\(i).txt"
                        let body = Array("content-\(t)-\(i)".utf8)
                        try fs.addFile(at: path, content: body)
                        let content = try fs.getFile(at: path)
                        guard case .bytes(let bytes) = content else {
                            Issue.record("Expected .bytes content at \(path)")
                            return
                        }
                        #expect(bytes == body)
                    }
                }
            }
            try await group.waitForAll()
        }
    }

    @Test func concurrentCreateAndRemove() async throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")

        let iterations = 50

        try await withThrowingTaskGroup(of: Void.self) { group in
            // Writer: create files
            group.addTask {
                for i in 0..<iterations {
                    try fs.addFile(at: "/file\(i).txt", content: Array("data\(i)".utf8))
                }
            }
            // Reader/remover: try to read and remove files
            group.addTask {
                for i in 0..<iterations {
                    let path = "/file\(i).txt"
                    // File may or may not exist yet — both outcomes are fine
                    if fs.lookup(at: path) != nil {
                        do {
                            try fs.removeFile(at: path)
                        } catch {
                            // ENOENT is acceptable — writer hasn't created it yet
                            // or another iteration already removed it
                        }
                    }
                }
            }
            try await group.waitForAll()
        }
        // No crash, no corruption — success
    }

    @Test func concurrentWASIPathOpen() async throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        for i in 0..<20 {
            try fs.addFile(at: "/f\(i).txt", content: Array("data".utf8))
        }

        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([
                .init(guestPath: "/", hostPath: "/")
            ])
        )
        let wasi = bridge.underlying

        let rootFd: WASIAbi.Fd = 3

        do {
            // Each task returns its own open count; summing the returned values
            // avoids sharing mutable state across the `sending` task boundary.
            let openCount = try await withThrowingTaskGroup(of: Int.self) { group in
                for t in 0..<4 {
                    group.addTask {
                        var localCount = 0
                        for i in 0..<20 {
                            let idx = (t * 5 + i) % 20
                            let fd = try wasi.path_open(
                                dirFd: rootFd,
                                dirFlags: [],
                                path: "f\(idx).txt",
                                oflags: [],
                                fsRightsBase: [.FD_READ],
                                fsRightsInheriting: [],
                                fdflags: []
                            )
                            localCount += 1
                            try wasi.fd_close(fd: fd)
                        }
                        return localCount
                    }
                }
                var total = 0
                for try await count in group {
                    total += count
                }
                return total
            }

            #expect(openCount == 80)
            try bridge.close()
        } catch {
            try bridge.close()
            throw error
        }
    }

    // MARK: - Node lifetime (unlink-while-open, shared content, reclaim stress)
    //
    // A node's lifetime is governed by ARC: an open `MemoryFileEntry` holds it by
    // reference, so unlinking only drops the directory edge and the node is freed
    // once the last fd closes. These tests assert that contract via `weak` references.

    /// An fd opened before its file is unlinked keeps working until it is closed,
    /// and the node is reclaimed by ARC on last close.
    @Test func unlinkWhileOpenReclaimsViaARC() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/f.txt", content: Array("WORLD".utf8))

        // Weak reference to the node: it must stay alive while an fd holds it and
        // be reclaimed once unlinked and closed.
        weak let weakNode = fs.lookup(at: "/f.txt") as? MemoryFileNode
        #expect(weakNode != nil)

        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([.init(guestPath: "/", hostPath: "/")])
        )
        try bridge.runAndClose { _ in
            let wasi = bridge.underlying
            let rootFd: WASIAbi.Fd = 3

            let fd = try wasi.path_open(
                dirFd: rootFd, dirFlags: [], path: "f.txt", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
            )

            // Unlink while the fd is open.
            try wasi.path_unlink_file(dirFd: rootFd, path: "f.txt")

            // The directory edge is gone...
            #expect(fs.nodeType(at: "/f.txt") == nil)

            // ...but the open fd still resolves its node: fd_filestat_get succeeds
            // and reports the original content size.
            let stat = try wasi.fd_filestat_get(fd: fd)
            #expect(stat.filetype == .REGULAR_FILE)
            #expect(stat.size == 5)
            #expect(weakNode != nil)  // the open fd keeps the node alive

            // Last close drops the only remaining reference: ARC reclaims the node,
            // and a fresh open is then ENOENT.
            try wasi.fd_close(fd: fd)
            #expect(weakNode == nil)
            #expect(throws: WASIAbi.Errno.ENOENT) {
                _ = try wasi.path_open(
                    dirFd: rootFd, dirFlags: [], path: "f.txt", oflags: [],
                    fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
                )
            }
        }
    }

    /// Two fds to the same path share the underlying node (same size) but have
    /// independent positions.
    @Test func sharedContentAcrossFds() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/s.txt", content: Array("abcdefg".utf8))  // size 7

        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([.init(guestPath: "/", hostPath: "/")])
        )
        try bridge.runAndClose { _ in
            let wasi = bridge.underlying
            let rootFd: WASIAbi.Fd = 3
            let rights: WASIAbi.Rights = [.FD_READ, .FD_SEEK, .FD_TELL]

            let fd1 = try wasi.path_open(dirFd: rootFd, dirFlags: [], path: "s.txt", oflags: [], fsRightsBase: rights, fsRightsInheriting: [], fdflags: [])
            let fd2 = try wasi.path_open(dirFd: rootFd, dirFlags: [], path: "s.txt", oflags: [], fsRightsBase: rights, fsRightsInheriting: [], fdflags: [])

            // Same underlying file → both report size 7.
            #expect(try wasi.fd_filestat_get(fd: fd1).size == 7)
            #expect(try wasi.fd_filestat_get(fd: fd2).size == 7)

            // Independent positions.
            _ = try wasi.fd_seek(fd: fd1, offset: 0, whence: .END)
            #expect(try wasi.fd_tell(fd: fd1) == 7)
            #expect(try wasi.fd_tell(fd: fd2) == 0)

            try wasi.fd_close(fd: fd1)
            try wasi.fd_close(fd: fd2)
        }
    }

    /// Stress the open/unlink/recreate/close transitions concurrently. A
    /// `fd_filestat_get` through a still-open fd must never spuriously fail with
    /// EBADF, and the run must complete without crash or corruption.
    @Test func concurrentOpenUnlinkRecreate() async throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let path = "/race.txt"
        try fs.addFile(at: path, content: Array("seed".utf8))

        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([.init(guestPath: "/", hostPath: "/")])
        )
        let wasi = bridge.underlying
        let rootFd: WASIAbi.Fd = 3

        try await withAsyncThrowing {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for t in 0..<8 {
                    group.addTask {
                        for i in 0..<100 {
                            switch (t + i) % 3 {
                            case 0:
                                // ENOENT (file currently unlinked) is fine; but an
                                // open fd must never see EBADF from fd_filestat_get.
                                if let fd = try? wasi.path_open(
                                    dirFd: rootFd, dirFlags: [], path: "race.txt", oflags: [],
                                    fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: []
                                ) {
                                    _ = try wasi.fd_filestat_get(fd: fd)
                                    try wasi.fd_close(fd: fd)
                                }
                            case 1:
                                try? fs.removeFile(at: path)
                            default:
                                try? fs.addFile(at: path, content: Array("data".utf8))
                            }
                        }
                    }
                }
                try await group.waitForAll()
            }
        } defer: {
            try bridge.close()
        }
    }
}
