import Testing
import WasmKit
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// A guest can pass any pointer to a `wasi_snapshot_preview1` call. One that
/// does not lie inside its memory is answered with `EFAULT`, and the host keeps
/// running.
@Suite struct WASIGuestMemoryBoundsTests {

    /// Addresses in a guest memory of one page.
    enum Address {
        /// The first address past the end of memory.
        static let end: UInt32 = 0x1_0000
        /// `"a.txt"`, a file in the preopened directory.
        static let path: UInt32 = 0x100
        /// `"link"`, which names nothing in the in-memory directory and a
        /// symbolic link to `a.txt` in a host directory.
        static let link: UInt32 = 0x110
        /// One iovec over `data`.
        static let iovs: UInt32 = 0x200
        /// One iovec whose buffer starts at `end`.
        static let iovsOutside: UInt32 = 0x210
        static let data: UInt32 = 0x300
        /// One clock subscription. Zeroed memory is a realtime clock with no timeout.
        static let subscriptions: UInt32 = 0x400
        static let events: UInt32 = 0x500
        /// Room for any result.
        static let result: UInt32 = 0x600
    }

    /// The preopened directory and the file opened in it.
    enum Descriptor {
        static let directory: UInt32 = 3
        static let file: UInt32 = 4
    }

    private struct Guest {
        let wasi: WASIImplementation
        let memory: Memory
        let functions: [String: WASIHostFunction<Memory>]

        func call(_ name: String, _ arguments: [Value]) throws -> [Value] {
            try #require(functions[name]).implementation(memory, arguments)
        }
    }

    /// Runs `body` against a directory that holds `a.txt` and `files`, preopened
    /// as descriptor 3, with `a.txt` open as descriptor 4.
    ///
    /// - Parameter hostDirectory: A host directory to preopen in place of an
    ///   in-memory one. It must already hold `a.txt`, and `files` is ignored.
    private func withGuest(
        files: [String: [UInt8]] = [:],
        hostDirectory: TestSupport.TemporaryDirectory? = nil,
        _ body: (Guest) throws -> Void
    ) throws {
        let fileSystem: WASIBridgeToHost.FileSystemOptions
        if let hostDirectory {
            fileSystem = .host().withPreopens([.init(guestPath: "/dir", hostPath: hostDirectory.path)])
        } else {
            let memoryFileSystem = try MemoryFileSystem()
            try memoryFileSystem.ensureDirectory(at: "/dir")
            try memoryFileSystem.addFile(at: "/dir/a.txt", content: "hello")
            for (name, content) in files {
                try memoryFileSystem.addFile(at: "/dir/\(name)", content: content)
            }
            fileSystem = .memory(memoryFileSystem).withPreopens([.init(guestPath: "/dir", hostPath: "/dir")])
        }
        let bridge = try WASIBridgeToHost(
            args: ["guest", "--flag"],
            environment: ["KEY": "value"],
            fileSystem: fileSystem
        )
        try bridge.runAndClose { bridge in
            let memory = try Memory(store: Store(engine: Engine()), type: MemoryType(min: 1, max: 1))
            let guest = Guest(
                wasi: bridge.underlying,
                memory: memory,
                functions: bridge.hostFunctions(capabilities: WASICapability<Memory>.all, stubUnlinked: false)
            )
            memory.write(Array("a.txt".utf8), at: Address.path)
            memory.write(Array("link".utf8), at: Address.link)
            memory.write(iovec: (Address.data, 5), at: Address.iovs)
            memory.write(iovec: (Address.end, 5), at: Address.iovsOutside)
            let file = try guest.wasi.path_open(
                dirFd: Descriptor.directory, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ, .FD_WRITE, .FD_SEEK, .FD_TELL], fsRightsInheriting: [], fdflags: [])
            try #require(file == Descriptor.file)
            try body(guest)
        }
    }

    /// One pointer argument of one call, set to an address outside memory.
    struct PointerCase: Sendable, CustomTestStringConvertible {
        let function: String
        let argument: String
        let arguments: [Value]

        var testDescription: String { "\(function) \(argument)" }

        init(_ function: String, _ argument: String, _ arguments: [Value]) {
            self.function = function
            self.argument = argument
            self.arguments = arguments
        }
    }

    static let pointerCases: [PointerCase] = {
        let end = Value.i32(Address.end)
        let dir = Value.i32(Descriptor.directory)
        let file = Value.i32(Descriptor.file)
        let path = Value.i32(Address.path)
        let link = Value.i32(Address.link)
        let iovs = Value.i32(Address.iovs)
        let result = Value.i32(Address.result)
        return [
            PointerCase("args_get", "argv", [end, result]),
            PointerCase("args_get", "argv_buf", [result, end]),
            PointerCase("args_sizes_get", "argc", [end, result]),
            PointerCase("args_sizes_get", "argv_buf_size", [result, end]),
            PointerCase("environ_get", "environ", [end, result]),
            PointerCase("environ_get", "environ_buf", [result, end]),
            PointerCase("environ_sizes_get", "environc", [end, result]),
            PointerCase("environ_sizes_get", "environ_buf_size", [result, end]),
            PointerCase("clock_res_get", "resolution", [.i32(0), end]),
            PointerCase("clock_time_get", "time", [.i32(0), .i64(0), end]),
            // The end of the range does not fit in 32 bits.
            PointerCase("clock_time_get", "time near 4 GiB", [.i32(0), .i64(0), .i32(0xFFFF_FFFC)]),
            PointerCase("random_get", "buf", [end, .i32(4)]),
            PointerCase("fd_write", "iovs", [file, end, .i32(1), result]),
            PointerCase("fd_write", "iovec buffer", [file, .i32(Address.iovsOutside), .i32(1), result]),
            PointerCase("fd_write", "nwritten", [file, iovs, .i32(1), end]),
            PointerCase("fd_read", "iovs", [file, end, .i32(1), result]),
            PointerCase("fd_read", "iovec buffer", [file, .i32(Address.iovsOutside), .i32(1), result]),
            PointerCase("fd_read", "nread", [file, iovs, .i32(1), end]),
            PointerCase("fd_pread", "iovs", [file, end, .i32(1), .i64(0), result]),
            PointerCase("fd_pread", "iovec buffer", [file, .i32(Address.iovsOutside), .i32(1), .i64(0), result]),
            PointerCase("fd_pread", "nread", [file, iovs, .i32(1), .i64(0), end]),
            PointerCase("fd_pwrite", "iovs", [file, end, .i32(1), .i64(0), result]),
            PointerCase("fd_pwrite", "iovec buffer", [file, .i32(Address.iovsOutside), .i32(1), .i64(0), result]),
            PointerCase("fd_pwrite", "nwritten", [file, iovs, .i32(1), .i64(0), end]),
            PointerCase("fd_fdstat_get", "stat", [file, end]),
            PointerCase("fd_seek", "newoffset", [file, .i64(1), .i32(0), end]),
            PointerCase("fd_tell", "offset", [file, end]),
            PointerCase("fd_filestat_get", "filestat", [file, end]),
            PointerCase("fd_prestat_get", "prestat", [dir, end]),
            PointerCase("fd_prestat_dir_name", "path", [dir, end, .i32(4)]),
            PointerCase("fd_readdir", "buf", [dir, end, .i32(128), .i64(0), result]),
            PointerCase("fd_readdir", "bufused", [dir, result, .i32(128), .i64(0), end]),
            PointerCase("path_create_directory", "path", [dir, end, .i32(3)]),
            PointerCase("path_filestat_get", "path", [dir, .i32(0), end, .i32(5), result]),
            PointerCase("path_filestat_get", "filestat", [dir, .i32(0), path, .i32(5), end]),
            PointerCase("path_filestat_set_times", "path", [dir, .i32(0), end, .i32(5), .i64(0), .i64(0), .i32(0)]),
            PointerCase("path_link", "old_path", [dir, .i32(0), end, .i32(5), dir, link, .i32(4)]),
            PointerCase("path_link", "new_path", [dir, .i32(0), path, .i32(5), dir, end, .i32(4)]),
            PointerCase("path_open", "path", [dir, .i32(0), end, .i32(5), .i32(0), .i64(0), .i64(0), .i32(0), result]),
            PointerCase("path_open", "fd", [dir, .i32(0), path, .i32(5), .i32(0), .i64(0), .i64(0), .i32(0), end]),
            PointerCase("path_readlink", "path", [dir, end, .i32(4), result, .i32(16), result]),
            PointerCase("path_readlink", "bufused", [dir, link, .i32(4), result, .i32(16), end]),
            PointerCase("path_remove_directory", "path", [dir, end, .i32(3)]),
            PointerCase("path_rename", "old_path", [dir, end, .i32(5), dir, link, .i32(4)]),
            PointerCase("path_rename", "new_path", [dir, path, .i32(5), dir, end, .i32(4)]),
            PointerCase("path_symlink", "old_path", [end, .i32(5), dir, link, .i32(4)]),
            PointerCase("path_symlink", "new_path", [path, .i32(5), dir, end, .i32(4)]),
            PointerCase("path_unlink_file", "path", [dir, end, .i32(5)]),
            PointerCase("poll_oneoff", "in", [end, .i32(Address.events), .i32(1), result]),
            PointerCase("poll_oneoff", "out", [.i32(Address.subscriptions), end, .i32(1), result]),
            PointerCase("poll_oneoff", "nevents", [.i32(Address.subscriptions), .i32(Address.events), .i32(1), end]),
        ]
    }()

    @Test(arguments: WASIGuestMemoryBoundsTests.pointerCases)
    func aPointerOutsideMemoryIsAnsweredWithEFAULT(_ pointerCase: PointerCase) throws {
        try withGuest { guest in
            let result = try guest.call(pointerCase.function, pointerCase.arguments)
            #expect(result == [.i32(UInt32(WASIAbi.Errno.EFAULT.rawValue))])
        }
    }

    /// The in-memory file system has no symbolic links, so this one call runs
    /// against a host directory.
    @Test(.disabled(if: TestSupport.hostPreopensUnavailable, "host preopens are not available on this platform"))
    func aLinkBufferOutsideMemoryIsAnsweredWithEFAULT() throws {
        let directory = try TestSupport.TemporaryDirectory()
        try directory.createFile(at: "a.txt", contents: "hello")
        try directory.createSymlink(at: "link", to: "a.txt")
        try withGuest(hostDirectory: directory) { guest in
            let result = try guest.call(
                "path_readlink",
                [.i32(Descriptor.directory), .i32(Address.link), .i32(4), .i32(Address.end), .i32(16), .i32(Address.result)])
            #expect(result == [.i32(UInt32(WASIAbi.Errno.EFAULT.rawValue))])
        }
    }

    @Test func aRangeMayEndAtTheEndOfMemory() throws {
        try withGuest { guest in
            let fits = try guest.call("random_get", [.i32(Address.end - 4), .i32(4)])
            #expect(fits == [.i32(0)])
            let overruns = try guest.call("random_get", [.i32(Address.end - 3), .i32(4)])
            #expect(overruns == [.i32(UInt32(WASIAbi.Errno.EFAULT.rawValue))])
        }
    }

    /// The result pointers are checked before the call runs, so a rejected call
    /// opens no descriptor and moves no position.
    @Test func aRejectedResultPointerLeavesNoEffect() throws {
        try withGuest { guest in
            let efault = [Value.i32(UInt32(WASIAbi.Errno.EFAULT.rawValue))]
            let end = Value.i32(Address.end)
            let opened = try guest.call(
                "path_open",
                [.i32(Descriptor.directory), .i32(0), .i32(Address.path), .i32(5), .i32(0), .i64(0), .i64(0), .i32(0), end])
            #expect(opened == efault)
            #expect(throws: WASIAbi.Errno.EBADF) {
                _ = try guest.wasi.fd_fdstat_get(fileDescriptor: Descriptor.file + 1)
            }

            let file = Value.i32(Descriptor.file)
            #expect(try guest.call("fd_seek", [file, .i64(2), .i32(0), end]) == efault)
            #expect(try guest.call("fd_read", [file, .i32(Address.iovs), .i32(1), end]) == efault)
            #expect(try guest.wasi.fd_tell(fd: Descriptor.file) == 0)
        }
    }

    /// A read into the first buffer can overwrite the second iovec, so each one
    /// is checked when it is used.
    @Test func anIOVecOverwrittenByAnEarlierReadIsCheckedWhenItIsUsed() throws {
        // The bytes of an iovec whose buffer starts at the end of memory.
        let iovecOutside = Memory.iovecBytes(buffer: Address.end, length: 4)
        try withGuest(files: ["iov.bin": iovecOutside]) { guest in
            let first: UInt32 = 0x700
            let second = first + 8
            guest.memory.write(iovec: (second, 8), at: first)
            guest.memory.write(iovec: (Address.data, 4), at: second)
            let fd = try guest.wasi.path_open(
                dirFd: Descriptor.directory, dirFlags: [], path: "iov.bin", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
            let result = try guest.call("fd_read", [.i32(fd), .i32(first), .i32(2), .i32(Address.result)])
            #expect(result == [.i32(UInt32(WASIAbi.Errno.EFAULT.rawValue))])
            #expect(guest.memory.read(count: 8, at: second) == iovecOutside)
        }
    }

    /// `fd_readdir` fills the buffer even when the last entry does not fit, and
    /// writes nothing past its end.
    @Test(arguments: [UInt32(0x900), Address.end - 3])
    func aDirectoryEntryCutShortByTheBufferWritesOnlyWhatFits(buffer: UInt32) throws {
        try withGuest { guest in
            let available = min(16, Address.end - buffer)
            guest.memory.write(Array(repeating: 0xAA, count: Int(available)), at: buffer)
            let result = try guest.call(
                "fd_readdir", [.i32(Descriptor.directory), .i32(buffer), .i32(3), .i64(0), .i32(Address.result)])
            #expect(result == [.i32(0)])
            #expect(guest.memory.read(count: 4, at: Address.result) == [3, 0, 0, 0])
            #expect(guest.memory.read(count: Int(available) - 3, at: buffer + 3).allSatisfy { $0 == 0xAA })
        }
    }
}

extension Memory {
    fileprivate static func iovecBytes(buffer: UInt32, length: UInt32) -> [UInt8] {
        withUnsafeBytes(of: buffer.littleEndian, Array.init) + withUnsafeBytes(of: length.littleEndian, Array.init)
    }

    fileprivate func write(_ bytes: [UInt8], at offset: UInt32) {
        withUnsafeMutableBufferPointer(offset: UInt(offset), count: bytes.count) { $0.copyBytes(from: bytes) }
    }

    fileprivate func write(iovec: (buffer: UInt32, length: UInt32), at offset: UInt32) {
        write(Self.iovecBytes(buffer: iovec.buffer, length: iovec.length), at: offset)
    }

    fileprivate func read(count: Int, at offset: UInt32) -> [UInt8] {
        withUnsafeMutableBufferPointer(offset: UInt(offset), count: count) { Array($0) }
    }
}
