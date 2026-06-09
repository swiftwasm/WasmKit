import Testing

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
}
