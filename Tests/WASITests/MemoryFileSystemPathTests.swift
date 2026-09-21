import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// A descriptor refers to a directory, and a guest path is resolved within it.
@Suite struct MemoryFileSystemPathTests {

    /// ```
    /// /outside.txt   -- not reachable from the descriptor below
    /// /a/            -- the directory fd 3 refers to
    /// /b/private.txt -- a sibling, likewise not reachable
    /// ```
    private func withSandbox(_ body: (WASIImplementation, MemoryFileSystem) throws -> Void) throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/a")
        try fs.ensureDirectory(at: "/b")
        try fs.addFile(at: "/outside.txt", content: "outside")
        try fs.addFile(at: "/b/private.txt", content: "sibling")
        try fs.addFile(at: "/a/inside.txt", content: "inside")
        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([.init(guestPath: "/a", hostPath: "/a")])
        )
        try bridge.runAndClose { try body($0.underlying, fs) }
    }

    private func open(_ wasi: WASIImplementation, _ path: String) throws -> WASIAbi.Fd {
        try wasi.path_open(
            dirFd: 3, dirFlags: [], path: path, oflags: [],
            fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
    }

    @Test func aPathInsideTheDirectoryResolves() throws {
        try withSandbox { wasi, _ in
            _ = try self.open(wasi, "inside.txt")
            _ = try self.open(wasi, "./inside.txt")
            // `..` is fine as long as it only unwinds what the path descended.
            try _ = wasi.path_create_directory(dirFd: 3, path: "sub")
            _ = try self.open(wasi, "sub/../inside.txt")
        }
    }

    @Test(arguments: ["..", "../", "../outside.txt", "../../outside.txt", "sub/../../outside.txt", "../b/private.txt"])
    func aPathLeavingTheDirectoryIsRefused(path: String) throws {
        try withSandbox { wasi, _ in
            try? wasi.path_create_directory(dirFd: 3, path: "sub")
            #expect(throws: (any Error).self) { _ = try self.open(wasi, path) }
        }
    }

    @Test(arguments: ["/outside.txt", "/b/private.txt", "/a/inside.txt"])
    func anAbsolutePathIsRefused(path: String) throws {
        try withSandbox { wasi, _ in
            #expect(throws: (any Error).self) { _ = try self.open(wasi, path) }
        }
    }

    /// `path_open` is not the only entry point that takes a guest path.
    @Test func theOtherPathEntryPointsAreConfinedToo() throws {
        try withSandbox { wasi, fs in
            #expect(throws: (any Error).self) {
                _ = try wasi.path_filestat_get(dirFd: 3, flags: [], path: "../outside.txt")
            }
            #expect(throws: (any Error).self) {
                try wasi.path_create_directory(dirFd: 3, path: "../made-outside")
            }
            #expect(throws: (any Error).self) {
                try wasi.path_filestat_set_times(
                    dirFd: 3, flags: [], path: "../outside.txt", atim: 1, mtim: 1, fstFlags: [.ATIM, .MTIM])
            }
            #expect(throws: (any Error).self) {
                try wasi.path_unlink_file(dirFd: 3, path: "../outside.txt")
            }
            #expect(fs.lookup(at: "/made-outside") == nil)
            #expect(fs.lookup(at: "/outside.txt") != nil)
        }
    }

    /// A directory entry literally named ".." would be unreachable by
    /// resolution and would give a traversal something to walk onto. A "."
    /// component is just redundant, and a preopen may legitimately use it.
    @Test func aDotDotDirectoryCannotBeCreated() throws {
        let fs = try MemoryFileSystem()
        #expect(throws: (any Error).self) { _ = try fs.ensureDirectory(at: "/a/..") }
        #expect(throws: (any Error).self) { _ = try fs.ensureDirectory(at: "/..") }
        // "." collapses rather than creating an entry.
        _ = try fs.ensureDirectory(at: "/a/./b")
        #expect(fs.lookup(at: "/a/b") != nil)
    }
}

/// Removing, renaming and listing take a guest path too, and each is confined
/// to the directory its descriptor refers to in the same way ``path_open`` is.
@Suite struct MemoryFileSystemDirectoryOperationTests {

    /// ```
    /// /outside.txt   -- not reachable from the descriptors below
    /// /a/inside.txt  -- fd 3 refers to /a
    /// /b/private.txt -- fd 4 refers to /b
    /// ```
    private func withSandbox(_ body: (WASIImplementation, MemoryFileSystem) throws -> Void) throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/a")
        try fs.ensureDirectory(at: "/b")
        try fs.addFile(at: "/outside.txt", content: "outside")
        try fs.addFile(at: "/a/inside.txt", content: "inside")
        try fs.addFile(at: "/b/private.txt", content: "sibling")
        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([
                .init(guestPath: "/a", hostPath: "/a"),
                .init(guestPath: "/b", hostPath: "/b"),
            ])
        )
        try bridge.runAndClose { try body($0.underlying, fs) }
    }

    private func entryNames(_ wasi: WASIImplementation, _ fd: WASIAbi.Fd) throws -> [String] {
        var entries = try wasi.fdTable.withLock { table -> WASIReaddirEntries in
            guard case .directory(let directory) = table[fd] else { throw WASIAbi.Errno.EBADF }
            return try directory.readEntries(cookie: 0)
        }
        defer { entries.close() }
        var names: [String] = []
        while let element = entries.next() {
            names.append(try element.get().name)
        }
        return names
    }

    @Test(arguments: ["../outside.txt", "..", ".", "/outside.txt"])
    func unlinkingAPathOutsideTheDirectoryIsRefused(path: String) throws {
        try withSandbox { wasi, fs in
            #expect(throws: (any Error).self) { try wasi.path_unlink_file(dirFd: 3, path: path) }
            #expect(throws: (any Error).self) { try wasi.path_remove_directory(dirFd: 3, path: path) }
            #expect(fs.lookup(at: "/outside.txt") != nil)
            #expect(fs.lookup(at: "/a") != nil)
        }
    }

    @Test func aRenameDestinationOutsideTheDirectoryIsRefused() throws {
        try withSandbox { wasi, fs in
            #expect(throws: (any Error).self) {
                try wasi.path_rename(oldFd: 3, oldPath: "inside.txt", newFd: 3, newPath: "../moved.txt")
            }
            #expect(fs.lookup(at: "/moved.txt") == nil)
            #expect(fs.lookup(at: "/a/inside.txt") != nil)
        }
    }

    /// A directory cannot be renamed onto "." or "..", which name the walk
    /// itself rather than an entry: doing so would put a directory under a name
    /// that later traversals interpret as a step, not a child.
    @Test(arguments: [".", ".."])
    func renamingToOrFromADotComponentIsRefused(name: String) throws {
        try withSandbox { wasi, fs in
            try wasi.path_create_directory(dirFd: 3, path: "sub")
            let subFd = try wasi.path_open(
                dirFd: 3, dirFlags: [], path: "sub", oflags: [.DIRECTORY],
                fsRightsBase: [], fsRightsInheriting: [], fdflags: [])

            #expect(throws: (any Error).self) {
                try wasi.path_rename(oldFd: 3, oldPath: name, newFd: subFd, newPath: "grafted")
            }
            #expect(throws: (any Error).self) {
                try wasi.path_rename(oldFd: 3, oldPath: "inside.txt", newFd: subFd, newPath: name)
            }
            #expect(fs.nodeType(at: "/a/sub/\(name)") == nil)
            #expect(fs.nodeType(at: "/a/sub/grafted") == nil)

            // And nothing a rename left behind lets a later removal walk upward.
            #expect(throws: (any Error).self) {
                try wasi.path_unlink_file(dirFd: subFd, path: "../inside.txt")
            }
            #expect(throws: (any Error).self) {
                try wasi.path_unlink_file(dirFd: 3, path: "../b/private.txt")
            }
            #expect(fs.lookup(at: "/a/inside.txt") != nil)
            #expect(fs.lookup(at: "/b/private.txt") != nil)
        }
    }

    /// The descriptor refers to a directory, not to the path it was opened
    /// under, so an entry created and then renamed elsewhere stays reachable
    /// through it -- and a new directory taking the old name does not.
    @Test func aDirectoryDescriptorFollowsTheDirectoryAndNotItsName() throws {
        try withSandbox { wasi, fs in
            try wasi.path_create_directory(dirFd: 3, path: "sub")
            try wasi.path_create_directory(dirFd: 3, path: "sub/child")
            let subFd = try wasi.path_open(
                dirFd: 3, dirFlags: [], path: "sub", oflags: [.DIRECTORY],
                fsRightsBase: [], fsRightsInheriting: [], fdflags: [])

            try wasi.path_rename(oldFd: 3, oldPath: "sub", newFd: 3, newPath: "moved")
            // A different directory now answers to the old name.
            try wasi.path_create_directory(dirFd: 3, path: "sub")
            try wasi.path_create_directory(dirFd: 3, path: "sub/other")

            _ = try wasi.path_open(
                dirFd: subFd, dirFlags: [], path: "child", oflags: [.DIRECTORY],
                fsRightsBase: [], fsRightsInheriting: [], fdflags: [])
            #expect(throws: (any Error).self) {
                _ = try wasi.path_open(
                    dirFd: subFd, dirFlags: [], path: "other", oflags: [.DIRECTORY],
                    fsRightsBase: [], fsRightsInheriting: [], fdflags: [])
            }
            #expect(try self.entryNames(wasi, subFd) == ["child"])

            try wasi.path_create_directory(dirFd: subFd, path: "made")
            #expect(fs.nodeType(at: "/a/moved/made") == .directory)
            #expect(fs.nodeType(at: "/a/sub/made") == nil)
        }
    }

    /// A descriptor opened as "." lists the directory it refers to.
    @Test func entriesOfADirectoryOpenedAsDotAreListed() throws {
        try withSandbox { wasi, _ in
            let dotFd = try wasi.path_open(
                dirFd: 3, dirFlags: [], path: ".", oflags: [.DIRECTORY],
                fsRightsBase: [], fsRightsInheriting: [], fdflags: [])
            #expect(try self.entryNames(wasi, dotFd) == ["inside.txt"])
        }
    }

    /// `path_open` creates the file it names, not the directories leading to it.
    @Test func creatingAFileDoesNotCreateItsParentDirectories() throws {
        try withSandbox { wasi, fs in
            #expect(throws: (any Error).self) {
                _ = try wasi.path_open(
                    dirFd: 3, dirFlags: [], path: "missing/new.txt", oflags: [.CREAT],
                    fsRightsBase: [.FD_WRITE], fsRightsInheriting: [], fdflags: [])
            }
            #expect(fs.lookup(at: "/a/missing") == nil)

            // Nor does a path whose parent component does not resolve.
            #expect(throws: (any Error).self) {
                _ = try wasi.path_open(
                    dirFd: 3, dirFlags: [], path: "missing/../new.txt", oflags: [.CREAT],
                    fsRightsBase: [.FD_WRITE], fsRightsInheriting: [], fdflags: [])
            }
            #expect(fs.lookup(at: "/a/missing") == nil)
            #expect(fs.lookup(at: "/a/new.txt") == nil)
        }
    }

    /// Only a directory has components below it.
    @Test(arguments: ["inside.txt/..", "inside.txt/x"])
    func walkingThroughANonDirectoryIsRefused(path: String) throws {
        try withSandbox { wasi, _ in
            #expect(throws: WASIAbi.Errno.ENOTDIR) {
                _ = try wasi.path_open(
                    dirFd: 3, dirFlags: [], path: path, oflags: [],
                    fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
            }
        }
    }
}
