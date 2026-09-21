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
