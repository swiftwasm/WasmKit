import Testing

@testable import WASI

@Suite
struct WASITests {
    #if !os(Windows)
        @Test
        func pathOpen() throws {
            let t = try TestSupport.TemporaryDirectory()

            try t.createDir(at: "External")
            try t.createDir(at: "External/secret-dir-b")
            try t.createFile(at: "External/secret-a.txt", contents: "Secret A")
            try t.createFile(at: "External/secret-dir-b/secret-c.txt", contents: "Secret C")
            try t.createDir(at: "Sandbox")
            try t.createFile(at: "Sandbox/hello.txt", contents: "Hello")
            try t.createSymlink(at: "Sandbox/link-hello.txt", to: "hello.txt")
            try t.createDir(at: "Sandbox/world.dir")
            try t.createSymlink(at: "Sandbox/link-world.dir", to: "world.dir")
            try t.createSymlink(at: "Sandbox/link-external-secret-a.txt", to: "../External/secret-a.txt")
            try t.createSymlink(at: "Sandbox/link-secret-dir-b", to: "../External/secret-dir-b")
            try t.createSymlink(at: "Sandbox/link-updown-hello.txt", to: "../Sandbox/link-updown-hello.txt")
            try t.createSymlink(at: "Sandbox/link-external-non-existent.txt", to: "../External/non-existent.txt")
            try t.createSymlink(at: "Sandbox/link-root", to: "/")
            try t.createSymlink(at: "Sandbox/link-loop.txt", to: "link-loop.txt")

            let wasi = try WASIBridgeToHost(
                fileSystem: .host().withPreopens(["/Sandbox": t.url.appendingPathComponent("Sandbox").path])
            )
            let mntFd: WASIAbi.Fd = 3

            func assertResolve(_ path: String, followSymlink: Bool, directory: Bool = false) throws {
                let fd = try wasi.underlying.path_open(
                    dirFd: mntFd,
                    dirFlags: followSymlink ? [.SYMLINK_FOLLOW] : [],
                    path: path,
                    oflags: directory ? [.DIRECTORY] : [],
                    fsRightsBase: .DIRECTORY_BASE_RIGHTS,
                    fsRightsInheriting: .DIRECTORY_INHERITING_RIGHTS,
                    fdflags: []
                )
                try wasi.underlying.fd_close(fd: fd)
            }

            func assertNotResolve(
                _ path: String,
                followSymlink: Bool,
                directory: Bool = false,
                sourceLocation: SourceLocation = #_sourceLocation,
                _ checkError: ((WASIAbi.Errno) throws -> Void)?
            ) throws {
                do {
                    _ = try wasi.underlying.path_open(
                        dirFd: mntFd,
                        dirFlags: followSymlink ? [.SYMLINK_FOLLOW] : [],
                        path: path,
                        oflags: directory ? [.DIRECTORY] : [],
                        fsRightsBase: .DIRECTORY_BASE_RIGHTS,
                        fsRightsInheriting: .DIRECTORY_INHERITING_RIGHTS,
                        fdflags: []
                    )
                    #expect((false), "Expected not to be able to open \(path)", sourceLocation: sourceLocation)
                } catch {
                    guard let error = error as? WASIAbi.Errno else {
                        #expect((false), "Expected WASIAbi.Errno error but got \(error)", sourceLocation: sourceLocation)
                        return
                    }
                    try checkError?(error)
                }
            }

            try assertNotResolve("non-existent.txt", followSymlink: false) { error in
                #expect(error == .ENOENT)
            }

            try assertResolve("link-hello.txt", followSymlink: true)
            try assertNotResolve("link-hello.txt", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }
            try assertNotResolve("link-hello.txt", followSymlink: true, directory: true) { error in
                #expect(error == .ENOTDIR)
            }

            try assertNotResolve("link-hello.txt/", followSymlink: true) { error in
                #expect(error == .ENOTDIR)
            }

            try assertResolve("link-world.dir", followSymlink: true)
            try assertNotResolve("link-world.dir", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }

            try assertNotResolve("link-external-secret-a.txt", followSymlink: true) { error in
                #expect(error == .EPERM)
            }
            try assertNotResolve("link-external-secret-a.txt", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }

            try assertNotResolve("link-external-non-existent.txt", followSymlink: true) { error in
                #expect(error == .EPERM)
            }
            try assertNotResolve("link-external-non-existent.txt", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }

            try assertNotResolve("link-updown-hello.txt", followSymlink: true) { error in
                #expect(error == .EPERM)
            }
            try assertNotResolve("link-updown-hello.txt", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }

            try assertNotResolve("link-secret-dir-b/secret-c.txt", followSymlink: true) { error in
                #expect(error == .EPERM)
            }
            try assertNotResolve("link-secret-dir-b/secret-c.txt", followSymlink: false) { error in
                #expect(error == .ENOTDIR)
            }

            try assertNotResolve("link-root", followSymlink: true) { error in
                #expect(error == .EPERM)
            }
            try assertNotResolve("link-root", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }

            try assertNotResolve("link-loop.txt", followSymlink: false) { error in
                #expect(error == .ELOOP)
            }
            try assertNotResolve("link-loop.txt", followSymlink: true) { error in
                #expect(error == .ELOOP)
            }
        }
    #endif

    @Test
    func memoryFileSystem() throws {
        let fs = try MemoryFileSystem()
        _ = try fs.ensureDirectory(at: "/")

        try fs.addFile(at: "/hello.txt", content: Array("Hello, World!".utf8))
        let node = fs.lookup(at: "/hello.txt")
        #expect(node != nil)
        #expect(node?.type == .file)

        guard let fileNode = node as? MemoryFileNode else {
            #expect(Bool(false), "Expected FileNode")
            return
        }

        guard case .bytes(let content) = fileNode.content else {
            #expect(Bool(false), "Expected bytes content")
            return
        }

        #expect(content == Array("Hello, World!".utf8))
        #expect(fileNode.size == 13)

        try fs.ensureDirectory(at: "/dir/subdir")
        #expect(fs.lookup(at: "/dir") != nil)
        #expect(fs.lookup(at: "/dir/subdir") != nil)

        try fs.addFile(at: "/dir/file.txt", content: Array("test".utf8))
        #expect(fs.lookup(at: "/dir/file.txt") != nil)

        try fs.removeFile(at: "/dir/file.txt")
        #expect(fs.lookup(at: "/dir/file.txt") == nil)
    }

    @Test
    func memoryFileSystemBridge() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/test.txt", content: Array("Test Content".utf8))
        try fs.ensureDirectory(at: "/testdir")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying

        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "test.txt",
            oflags: [],
            fsRightsBase: [.FD_READ],
            fsRightsInheriting: [],
            fdflags: []
        )

        let stat = try wasi.fd_filestat_get(fd: fd)
        #expect(stat.filetype == .REGULAR_FILE)
        #expect(stat.size == 12)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemReadWrite() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/readwrite.txt", content: Array("Initial".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "readwrite.txt",
            oflags: [],
            fsRightsBase: [.FD_READ, .FD_WRITE, .FD_SEEK],
            fsRightsInheriting: [],
            fdflags: []
        )

        let newOffset = try wasi.fd_seek(fd: fd, offset: 0, whence: .END)
        #expect(newOffset == 7)

        let tell = try wasi.fd_tell(fd: fd)
        #expect(tell == 7)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemDirectories() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        try wasi.path_create_directory(dirFd: rootFd, path: "newdir")
        #expect(fs.lookup(at: "/newdir") != nil)

        let dirStat = try wasi.path_filestat_get(dirFd: rootFd, flags: [], path: "newdir")
        #expect(dirStat.filetype == .DIRECTORY)

        let dirFd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "newdir",
            oflags: [.DIRECTORY],
            fsRightsBase: .DIRECTORY_BASE_RIGHTS,
            fsRightsInheriting: .DIRECTORY_INHERITING_RIGHTS,
            fdflags: []
        )

        try fs.addFile(at: "/newdir/file1.txt", content: Array("file1".utf8))
        try fs.addFile(at: "/newdir/file2.txt", content: Array("file2".utf8))

        try wasi.fd_close(fd: dirFd)

        try wasi.path_unlink_file(dirFd: rootFd, path: "newdir/file1.txt")
        #expect(fs.lookup(at: "/newdir/file1.txt") == nil)
        #expect(fs.lookup(at: "/newdir/file2.txt") != nil)
    }

    @Test
    func memoryFileSystemCreateAndTruncate() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd1 = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "created.txt",
            oflags: [.CREAT],
            fsRightsBase: [.FD_WRITE],
            fsRightsInheriting: [],
            fdflags: []
        )
        try wasi.fd_close(fd: fd1)

        #expect(fs.lookup(at: "/created.txt") != nil)

        try fs.addFile(at: "/truncate.txt", content: Array("Long content here".utf8))

        let fd2 = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "truncate.txt",
            oflags: [.TRUNC],
            fsRightsBase: [.FD_WRITE],
            fsRightsInheriting: [],
            fdflags: []
        )

        let stat = try wasi.fd_filestat_get(fd: fd2)
        #expect(stat.size == 0)

        try wasi.fd_close(fd: fd2)
    }

    @Test
    func memoryFileSystemExclusive() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/existing.txt", content: [])

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        do {
            _ = try wasi.path_open(
                dirFd: rootFd,
                dirFlags: [],
                path: "existing.txt",
                oflags: [.CREAT, .EXCL],
                fsRightsBase: [.FD_WRITE],
                fsRightsInheriting: [],
                fdflags: []
            )
            #expect(Bool(false), "Should have thrown EEXIST")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EEXIST)
        }
    }

    @Test
    func memoryFileSystemMultiplePreopens() throws {
        let fs = try MemoryFileSystem()
        let preopens = [
            "/": "/",
            "/tmp": "/tmp",
            "/data": "/data",
        ]
        for (_, hostPath) in preopens {
            try fs.ensureDirectory(at: hostPath)
        }
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(preopens))
        #expect(fs.lookup(at: "/tmp") != nil)
        #expect(fs.lookup(at: "/data") != nil)
        _ = wasi
    }

    @Test
    func memoryFileSystemPrestatOperations() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/sandbox")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/sandbox": "/sandbox"])).underlying

        let prestat = try wasi.fd_prestat_get(fd: 3)
        guard case .dir(let pathLen) = prestat else {
            #expect(Bool(false), "Expected directory prestat")
            return
        }
        #expect(pathLen == 8)
    }

    @Test
    func memoryFileSystemPathNormalization() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")

        try fs.addFile(at: "/test.txt", content: [1, 2, 3])

        #expect(fs.lookup(at: "/test.txt") != nil)
        #expect(fs.lookup(at: "//test.txt") != nil)
        #expect(fs.lookup(at: "/./test.txt") == nil)

        try fs.ensureDirectory(at: "/a/b/c")
        #expect(fs.lookup(at: "/a/b/c") != nil)
        #expect(fs.lookup(at: "/a/b") != nil)
        #expect(fs.lookup(at: "/a") != nil)
    }

    @Test
    func memoryFileSystemResolution() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.ensureDirectory(at: "/dir")
        try fs.addFile(at: "/dir/file.txt", content: [])
        guard let dirNode = fs.lookup(at: "/dir") as? MemoryDirectoryNode else {
            #expect(Bool(false), "Expected DirectoryNode")
            return
        }
        let resolved = fs.resolve(from: dirNode, at: "/dir", path: "file.txt")
        #expect(resolved != nil)
        #expect(resolved?.type == .file)

        let dotResolved = fs.resolve(from: dirNode, at: "/dir", path: ".")
        #expect(dotResolved != nil)

        let parentResolved = fs.resolve(from: dirNode, at: "/dir", path: "..")
        #expect(parentResolved != nil)
        #expect(parentResolved?.type == .directory)
    }

    @Test
    func memoryFileSystemWithFileDescriptor() throws {
        #if canImport(System) && !os(WASI)
            let tempDir = try TestSupport.TemporaryDirectory()
            try tempDir.createFile(at: "source.txt", contents: "File descriptor content")

            let fd = try tempDir.openFile(at: "source.txt", .readOnly)
            defer {
                try? fd.close()
            }

            let fs = try MemoryFileSystem()
            try fs.ensureDirectory(at: "/")
            try fs.addFile(at: "/mounted.txt", handle: fd)

            let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
            let rootFd: WASIAbi.Fd = 3

            let openedFd = try wasi.path_open(
                dirFd: rootFd,
                dirFlags: [],
                path: "mounted.txt",
                oflags: [],
                fsRightsBase: [.FD_READ],
                fsRightsInheriting: [],
                fdflags: []
            )

            let stat = try wasi.fd_filestat_get(fd: openedFd)
            #expect(stat.filetype == .REGULAR_FILE)
            #expect(stat.size == 23)

            try wasi.fd_close(fd: openedFd)
        #endif
    }

    @Test
    func unifiedBridgeWithHostFileSystem() throws {
        #if !os(Windows)
            let tempDir = try TestSupport.TemporaryDirectory()
            try tempDir.createFile(at: "host.txt", contents: "Host content")

            // Using default host filesystem
            let wasi = try WASIBridgeToHost(
                fileSystem: .host().withPreopens(["/sandbox": tempDir.url.path])
            ).underlying

            let sandboxFd: WASIAbi.Fd = 3
            let fd = try wasi.path_open(
                dirFd: sandboxFd,
                dirFlags: [],
                path: "host.txt",
                oflags: [],
                fsRightsBase: [.FD_READ],
                fsRightsInheriting: [],
                fdflags: []
            )

            let stat = try wasi.fd_filestat_get(fd: fd)
            #expect(stat.filetype == .REGULAR_FILE)
            #expect(stat.size == 12)

            try wasi.fd_close(fd: fd)
        #endif
    }

    @Test
    func unifiedBridgeWithMemoryFileSystem() throws {
        let memFS = try MemoryFileSystem()
        try memFS.ensureDirectory(at: "/")
        try memFS.addFile(at: "/memory.txt", content: "Memory content")

        // Using memory filesystem through unified bridge
        let wasi = try WASIBridgeToHost(fileSystem: .memory(memFS).withPreopens(["/": "/"])).underlying

        let rootFd: WASIAbi.Fd = 3
        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "memory.txt",
            oflags: [],
            fsRightsBase: [.FD_READ],
            fsRightsInheriting: [],
            fdflags: []
        )

        let stat = try wasi.fd_filestat_get(fd: fd)
        #expect(stat.filetype == .REGULAR_FILE)
        #expect(stat.size == 14)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemSeekPositions() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/positions.txt", content: Array("0123456789".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "positions.txt",
            oflags: [],
            fsRightsBase: [.FD_READ, .FD_SEEK, .FD_TELL],
            fsRightsInheriting: [],
            fdflags: []
        )

        let startPos = try wasi.fd_tell(fd: fd)
        #expect(startPos == 0)

        let endPos = try wasi.fd_seek(fd: fd, offset: 0, whence: .END)
        #expect(endPos == 10)

        let currentPos = try wasi.fd_tell(fd: fd)
        #expect(currentPos == 10)

        let midPos = try wasi.fd_seek(fd: fd, offset: -5, whence: .CUR)
        #expect(midPos == 5)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemAccessModeValidation() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/file.txt", content: Array("test".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let readOnlyFd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "file.txt",
            oflags: [],
            fsRightsBase: [.FD_READ],
            fsRightsInheriting: [],
            fdflags: []
        )

        let stat = try wasi.fd_fdstat_get(fileDescriptor: readOnlyFd)
        #expect(stat.fsRightsBase.contains(.FD_READ))
        #expect(!stat.fsRightsBase.contains(.FD_WRITE))

        try wasi.fd_close(fd: readOnlyFd)

        let writeOnlyFd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "file.txt",
            oflags: [],
            fsRightsBase: [.FD_WRITE],
            fsRightsInheriting: [],
            fdflags: []
        )

        let writeStat = try wasi.fd_fdstat_get(fileDescriptor: writeOnlyFd)
        #expect(!writeStat.fsRightsBase.contains(.FD_READ))
        #expect(writeStat.fsRightsBase.contains(.FD_WRITE))

        try wasi.fd_close(fd: writeOnlyFd)
    }

    @Test
    func memoryFileSystemWithFileDescriptorReadWrite() throws {
        #if canImport(System) && !os(WASI) && !os(Windows)
            let tempDir = try TestSupport.TemporaryDirectory()
            try tempDir.createFile(at: "rw.txt", contents: "Initial")

            let fd = try tempDir.openFile(at: "rw.txt", .readWrite)
            defer {
                try? fd.close()
            }

            let fs = try MemoryFileSystem()
            try fs.ensureDirectory(at: "/")
            try fs.addFile(at: "/handle.txt", handle: fd)

            let content = try fs.getFile(at: "/handle.txt")
            guard case .handle(let retrievedFd) = content else {
                #expect(Bool(false), "Expected handle content")
                return
            }

            #expect(retrievedFd.rawValue == fd.rawValue)
        #endif
    }

    @Test
    func memoryFileSystemGetFileContent() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/data.bin", content: [1, 2, 3, 4, 5])

        let content = try fs.getFile(at: "/data.bin")
        guard case .bytes(let bytes) = content else {
            #expect(Bool(false), "Expected bytes content")
            return
        }
        #expect(bytes == [1, 2, 3, 4, 5])

        do {
            _ = try fs.getFile(at: "/nonexistent.txt")
            #expect(Bool(false), "Should throw ENOENT")
        } catch let error as WASIAbi.Errno {
            #expect(error == .ENOENT)
        }

        try fs.ensureDirectory(at: "/somedir")
        do {
            _ = try fs.getFile(at: "/somedir")
            #expect(Bool(false), "Should throw EISDIR")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EISDIR)
        }
    }

    @Test
    func memoryFileSystemTruncateViaSetSize() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/truncate.txt", content: Array("Long content here".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "truncate.txt",
            oflags: [],
            fsRightsBase: [.FD_READ, .FD_WRITE, .FD_FILESTAT_SET_SIZE],
            fsRightsInheriting: [],
            fdflags: []
        )

        try wasi.fd_filestat_set_size(fd: fd, size: 4)

        let stat = try wasi.fd_filestat_get(fd: fd)
        #expect(stat.size == 4)

        let content = try fs.getFile(at: "/truncate.txt")
        guard case .bytes(let bytes) = content else {
            #expect(Bool(false), "Expected bytes content")
            return
        }
        #expect(bytes == Array("Long".utf8))

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemExpandViaSetSize() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/expand.txt", content: Array("Hi".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "expand.txt",
            oflags: [],
            fsRightsBase: [.FD_WRITE, .FD_FILESTAT_SET_SIZE],
            fsRightsInheriting: [],
            fdflags: []
        )

        try wasi.fd_filestat_set_size(fd: fd, size: 10)

        let stat = try wasi.fd_filestat_get(fd: fd)
        #expect(stat.size == 10)

        let content = try fs.getFile(at: "/expand.txt")
        guard case .bytes(let bytes) = content else {
            #expect(Bool(false), "Expected bytes content")
            return
        }
        #expect(bytes.count == 10)
        #expect(bytes[0] == UInt8(ascii: "H"))
        #expect(bytes[1] == UInt8(ascii: "i"))
        #expect(bytes[2] == 0)
        #expect(bytes[9] == 0)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemRename() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/old.txt", content: Array("Content".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        try wasi.path_rename(
            oldFd: rootFd,
            oldPath: "old.txt",
            newFd: rootFd,
            newPath: "new.txt"
        )

        #expect(fs.lookup(at: "/old.txt") == nil)
        #expect(fs.lookup(at: "/new.txt") != nil)

        let content = try fs.getFile(at: "/new.txt")
        guard case .bytes(let bytes) = content else {
            #expect(Bool(false), "Expected bytes content")
            return
        }
        #expect(bytes == Array("Content".utf8))
    }

    @Test
    func memoryFileSystemRenameToSubdirectory() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/file.txt", content: Array("test".utf8))
        try fs.ensureDirectory(at: "/subdir")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        try wasi.path_rename(
            oldFd: rootFd,
            oldPath: "file.txt",
            newFd: rootFd,
            newPath: "subdir/moved.txt"
        )

        #expect(fs.lookup(at: "/file.txt") == nil)
        #expect(fs.lookup(at: "/subdir/moved.txt") != nil)
    }

    @Test
    func memoryFileSystemRemoveEmptyDirectory() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.ensureDirectory(at: "/emptydir")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        try wasi.path_remove_directory(dirFd: rootFd, path: "emptydir")
        #expect(fs.lookup(at: "/emptydir") == nil)
    }

    @Test
    func memoryFileSystemRemoveNonEmptyDirectoryFails() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.ensureDirectory(at: "/nonempty")
        try fs.addFile(at: "/nonempty/file.txt", content: [])

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        do {
            try wasi.path_remove_directory(dirFd: rootFd, path: "nonempty")
            #expect(Bool(false), "Should not remove non-empty directory")
        } catch let error as WASIAbi.Errno {
            #expect(error == .ENOTEMPTY)
        }

        #expect(fs.lookup(at: "/nonempty") != nil)
    }

    @Test
    func memoryFileSystemSyncOperations() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/sync.txt", content: [])

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "sync.txt",
            oflags: [],
            fsRightsBase: [.FD_SYNC, .FD_DATASYNC],
            fsRightsInheriting: [],
            fdflags: []
        )

        try wasi.fd_sync(fd: fd)
        try wasi.fd_datasync(fd: fd)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemWriteThenRead() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/test.txt", content: [])

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "test.txt",
            oflags: [],
            fsRightsBase: [.FD_READ, .FD_WRITE],
            fsRightsInheriting: [],
            fdflags: []
        )

        let memory = TestSupport.TestGuestMemory()
        let writeData = Array("Hello, WASI!".utf8)
        let writeVecs = memory.writeIOVecs([writeData])

        let nwritten = try wasi.fd_write(fileDescriptor: fd, ioVectors: writeVecs)
        #expect(nwritten == UInt32(writeData.count))

        _ = try wasi.fd_seek(fd: fd, offset: 0, whence: .SET)

        let readVecs = memory.readIOVecs(sizes: [writeData.count])
        let nread = try wasi.fd_read(fd: fd, iovs: readVecs)
        #expect(nread == UInt32(writeData.count))

        let readData = memory.loadIOVecs(readVecs)
        #expect(readData[0] == writeData)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemReadOnlyAccess() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/readonly.txt", content: Array("Read only".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "readonly.txt",
            oflags: [],
            fsRightsBase: [.FD_READ],
            fsRightsInheriting: [],
            fdflags: []
        )

        do {
            let memory = TestSupport.TestGuestMemory()
            let writeData = Array("Fail".utf8)
            let iovecs = memory.writeIOVecs([writeData])

            _ = try wasi.fd_write(fileDescriptor: fd, ioVectors: iovecs)
            #expect(Bool(false), "Should not be able to write to read-only file")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EBADF)
        }

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemWriteOnlyAccess() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/writeonly.txt", content: [])

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "writeonly.txt",
            oflags: [],
            fsRightsBase: [.FD_WRITE],
            fsRightsInheriting: [],
            fdflags: []
        )

        let memory = TestSupport.TestGuestMemory()
        let writeData = Array("Write only".utf8)
        let writeVecs = memory.writeIOVecs([writeData])

        let nwritten = try wasi.fd_write(fileDescriptor: fd, ioVectors: writeVecs)
        #expect(nwritten == UInt32(writeData.count))

        do {
            let readVecs = memory.readIOVecs(sizes: [10])
            _ = try wasi.fd_read(fd: fd, iovs: readVecs)
            #expect(Bool(false), "Should not be able to read from write-only file")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EBADF)
        }

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemWithFileDescriptorWrite() throws {
        #if canImport(System) && !os(WASI) && !os(Windows)
            let tempDir = try TestSupport.TemporaryDirectory()
            try tempDir.createFile(at: "target.txt", contents: "")

            let fd = try tempDir.openFile(at: "target.txt", .writeOnly)
            defer {
                try? fd.close()
            }

            let fs = try MemoryFileSystem()
            try fs.ensureDirectory(at: "/")
            try fs.addFile(at: "/handle.txt", handle: fd)

            let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
            let rootFd: WASIAbi.Fd = 3

            let openedFd = try wasi.path_open(
                dirFd: rootFd,
                dirFlags: [],
                path: "handle.txt",
                oflags: [],
                fsRightsBase: [.FD_WRITE],
                fsRightsInheriting: [],
                fdflags: []
            )

            let memory = TestSupport.TestGuestMemory()
            let writeData = Array("Via handle".utf8)
            let iovecs = memory.writeIOVecs([writeData])

            let nwritten = try wasi.fd_write(fileDescriptor: openedFd, ioVectors: iovecs)
            #expect(nwritten == UInt32(writeData.count))

            try wasi.fd_close(fd: openedFd)

            let content = try String(contentsOf: tempDir.url.appendingPathComponent("target.txt"), encoding: .utf8)
            #expect(content == "Via handle")
        #endif
    }

    @Test
    func memoryFileSystemSeekBeyondEnd() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/small.txt", content: Array("Small".utf8))

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "small.txt",
            oflags: [],
            fsRightsBase: [.FD_READ, .FD_WRITE, .FD_SEEK],
            fsRightsInheriting: [],
            fdflags: []
        )

        let newPos = try wasi.fd_seek(fd: fd, offset: 100, whence: .SET)
        #expect(newPos == 100)

        let memory = TestSupport.TestGuestMemory()
        let writeData = Array("End".utf8)
        let iovecs = memory.writeIOVecs([writeData])

        let nwritten = try wasi.fd_write(fileDescriptor: fd, ioVectors: iovecs)
        #expect(nwritten == UInt32(writeData.count))

        let stat = try wasi.fd_filestat_get(fd: fd)
        #expect(stat.size == 103)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func stdioFileDescriptors() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withStdio().withPreopens(["/": "/"])).underlying

        let stdinStat = try wasi.fd_fdstat_get(fileDescriptor: 0)
        #expect(stdinStat.fsRightsBase.contains(.FD_READ))
        #expect(!stdinStat.fsRightsBase.contains(.FD_WRITE))

        let stdoutStat = try wasi.fd_fdstat_get(fileDescriptor: 1)
        #expect(!stdoutStat.fsRightsBase.contains(.FD_READ))
        #expect(stdoutStat.fsRightsBase.contains(.FD_WRITE))

        let stderrStat = try wasi.fd_fdstat_get(fileDescriptor: 2)
        #expect(!stderrStat.fsRightsBase.contains(.FD_READ))
        #expect(stderrStat.fsRightsBase.contains(.FD_WRITE))
    }

    @Test
    func stdoutWrite() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withStdio().withPreopens(["/": "/"])).underlying

        let memory = TestSupport.TestGuestMemory()
        let writeData = Array("Hello, stdout!".utf8)
        let iovecs = memory.writeIOVecs([writeData])

        let nwritten = try wasi.fd_write(fileDescriptor: 1, ioVectors: iovecs)
        #expect(nwritten == UInt32(writeData.count))
    }

    @Test
    func stderrWrite() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withStdio().withPreopens(["/": "/"])).underlying

        let memory = TestSupport.TestGuestMemory()
        let writeData = Array("Error message".utf8)
        let iovecs = memory.writeIOVecs([writeData])

        let nwritten = try wasi.fd_write(fileDescriptor: 2, ioVectors: iovecs)
        #expect(nwritten == UInt32(writeData.count))
    }

    @Test
    func stdinCannotWrite() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withStdio().withPreopens(["/": "/"])).underlying

        let memory = TestSupport.TestGuestMemory()
        let writeData = Array("Should fail".utf8)
        let iovecs = memory.writeIOVecs([writeData])

        do {
            _ = try wasi.fd_write(fileDescriptor: 0, ioVectors: iovecs)
            #expect(Bool(false), "Should not be able to write to stdin")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EBADF)
        }
    }

    @Test
    func stdoutCannotRead() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying

        let memory = TestSupport.TestGuestMemory()
        let iovecs = memory.readIOVecs(sizes: [10])

        do {
            _ = try wasi.fd_read(fd: 1, iovs: iovecs)
            #expect(Bool(false), "Should not be able to read from stdout")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EBADF)
        }
    }

    @Test
    func stderrCannotRead() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying

        let memory = TestSupport.TestGuestMemory()
        let iovecs = memory.readIOVecs(sizes: [10])

        do {
            _ = try wasi.fd_read(fd: 2, iovs: iovecs)
            #expect(Bool(false), "Should not be able to read from stderr")
        } catch let error as WASIAbi.Errno {
            #expect(error == .EBADF)
        }
    }

    @Test
    func memoryFileSystemFileTimestamps() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/file.txt", content: "test")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let stat1 = try wasi.path_filestat_get(dirFd: rootFd, flags: [], path: "file.txt")
        #expect(stat1.atim > 0)
        #expect(stat1.mtim > 0)
        #expect(stat1.ctim > 0)

        let fd = try wasi.path_open(
            dirFd: rootFd,
            dirFlags: [],
            path: "file.txt",
            oflags: [],
            fsRightsBase: [.FD_READ, .FD_WRITE],
            fsRightsInheriting: [],
            fdflags: []
        )

        let memory = TestSupport.TestGuestMemory()
        let readVecs = memory.readIOVecs(sizes: [4])
        _ = try wasi.fd_read(fd: fd, iovs: readVecs)

        let stat2 = try wasi.fd_filestat_get(fd: fd)
        #expect(stat2.atim >= stat1.atim)

        let writeData = Array("more".utf8)
        let writeVecs = memory.writeIOVecs([writeData])
        _ = try wasi.fd_write(fileDescriptor: fd, ioVectors: writeVecs)

        let stat3 = try wasi.fd_filestat_get(fd: fd)
        #expect(stat3.mtim >= stat2.mtim)

        try wasi.fd_close(fd: fd)
    }

    @Test
    func memoryFileSystemDirectoryTimestamps() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        try wasi.path_create_directory(dirFd: rootFd, path: "testdir")

        let stat1 = try wasi.path_filestat_get(dirFd: rootFd, flags: [], path: "testdir")
        #expect(stat1.atim > 0)
        #expect(stat1.mtim > 0)

        try fs.addFile(at: "/testdir/file.txt", content: [])

        let stat2 = try wasi.path_filestat_get(dirFd: rootFd, flags: [], path: "testdir")
        #expect(stat2.mtim >= stat1.mtim)
    }

    @Test
    func memoryFileSystemSetTimes() throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/")
        try fs.addFile(at: "/file.txt", content: [])

        let wasi = try WASIBridgeToHost(fileSystem: .memory(fs).withPreopens(["/": "/"])).underlying
        let rootFd: WASIAbi.Fd = 3

        let specificTime: WASIAbi.Timestamp = 1_000_000_000_000_000_000

        try wasi.path_filestat_set_times(
            dirFd: rootFd,
            flags: [],
            path: "file.txt",
            atim: specificTime,
            mtim: specificTime,
            fstFlags: [.ATIM, .MTIM]
        )

        let stat = try wasi.path_filestat_get(dirFd: rootFd, flags: [], path: "file.txt")
        #expect(stat.atim == specificTime)
        #expect(stat.mtim == specificTime)
    }

}
