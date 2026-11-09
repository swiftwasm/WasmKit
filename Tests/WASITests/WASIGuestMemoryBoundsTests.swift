import Testing
import WasmKit
import WasmKitWASI
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// A guest can pass any pointer to a `wasi_snapshot_preview1` call. One that
/// the call would dereference outside its memory stops the guest with
/// `WASIMemoryAccessError`, and the host keeps running.
@Suite struct WASIGuestMemoryBoundsTests {

    /// Addresses in a guest memory of one page.
    enum Address {
        /// The first address past the end of memory.
        static let end: UInt32 = 0x1_0000
        /// An address well past the end of memory.
        static let farOutside: UInt32 = 0xFFFF_0000
        /// `"a.txt"`, a file in the preopened directory.
        static let path: UInt32 = 0x100
        /// `"link"`, which names nothing in the in-memory directory and a
        /// symbolic link to `a.txt` in a host directory.
        static let link: UInt32 = 0x110
        /// `"new.txt"`, which names nothing yet.
        static let newPath: UInt32 = 0x120
        /// One iovec over `data`.
        static let iovs: UInt32 = 0x200
        /// One iovec whose buffer starts at `end`.
        static let iovsOutside: UInt32 = 0x210
        /// One iovec whose buffer starts two bytes before `end` and runs past it.
        static let iovsAcrossEnd: UInt32 = 0x220
        /// One empty iovec whose buffer starts at `farOutside`.
        static let iovsEmptyOutside: UInt32 = 0x230
        /// One iovec over `data`, then one whose buffer starts at `end`.
        static let iovsThenOutside: UInt32 = 0x240
        static let data: UInt32 = 0x300
        /// Two clock subscriptions. Zeroed memory is a realtime clock with no timeout.
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

    fileprivate struct Guest<M: GuestMemory & SendableMetatype> {
        let wasi: WASIImplementation
        let memory: M
        let functions: [String: WASIHostFunction<M>]

        func call(_ name: String, _ arguments: [Value]) throws -> [Value] {
            try #require(functions[name]).implementation(memory, arguments)
        }
    }

    /// Runs `body` against a directory that holds `a.txt` and `files`, preopened
    /// as descriptor 3, with `a.txt` open as descriptor 4.
    ///
    /// - Parameters:
    ///   - memory: The guest memory. It must hold the first page of addresses.
    ///   - hostDirectory: A host directory to preopen in place of an in-memory
    ///     one. It must already hold `a.txt`, and `files` is ignored.
    ///   - stdout: A file to use as descriptor 1.
    private func withGuest<M: GuestMemory & SendableMetatype>(
        in memory: M,
        files: [String: [UInt8]] = [:],
        hostDirectory: TestSupport.TemporaryDirectory? = nil,
        stdout: CustomPlatformInjectionTests.SinkFile? = nil,
        _ body: (Guest<M>) throws -> Void
    ) throws {
        var fileSystem: WASIBridgeToHost.FileSystemOptions
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
        if let stdout {
            fileSystem = fileSystem.withStdio(
                stdin: CustomPlatformInjectionTests.FixedContentFile(bytes: []),
                stdout: stdout,
                stderr: CustomPlatformInjectionTests.SinkFile())
        }
        let bridge = try WASIBridgeToHost(
            args: ["guest", "--flag"],
            environment: ["KEY": "value"],
            fileSystem: fileSystem
        )
        try bridge.runAndClose { bridge in
            let guest = Guest(
                wasi: bridge.underlying,
                memory: memory,
                functions: bridge.hostFunctions(capabilities: WASICapability<M>.all, stubUnlinked: false)
            )
            memory.write(Array("a.txt".utf8), at: Address.path)
            memory.write(Array("link".utf8), at: Address.link)
            memory.write(Array("new.txt".utf8), at: Address.newPath)
            memory.write(iovec: (Address.data, 5), at: Address.iovs)
            memory.write(iovec: (Address.end, 5), at: Address.iovsOutside)
            memory.write(iovec: (Address.end - 2, 5), at: Address.iovsAcrossEnd)
            memory.write(iovec: (Address.farOutside, 0), at: Address.iovsEmptyOutside)
            memory.write(iovec: (Address.data, 5), at: Address.iovsThenOutside)
            memory.write(iovec: (Address.end, 5), at: Address.iovsThenOutside + 8)
            let file = try guest.wasi.path_open(
                dirFd: Descriptor.directory, dirFlags: [], path: "a.txt", oflags: [],
                fsRightsBase: [.FD_READ, .FD_WRITE, .FD_SEEK, .FD_TELL], fsRightsInheriting: [], fdflags: [])
            try #require(file == Descriptor.file)
            try body(guest)
        }
    }

    /// Runs `body` against a guest memory of one page.
    private func withGuest(
        files: [String: [UInt8]] = [:],
        hostDirectory: TestSupport.TemporaryDirectory? = nil,
        stdout: CustomPlatformInjectionTests.SinkFile? = nil,
        _ body: (Guest<Memory>) throws -> Void
    ) throws {
        let memory = try Memory(store: Store(engine: Engine()), type: MemoryType(min: 1, max: 1))
        try withGuest(in: memory, files: files, hostDirectory: hostDirectory, stdout: stdout, body)
    }

    /// One pointer argument of one call, set so that its range reaches past
    /// the end of memory.
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
        let subscriptions = Value.i32(Address.subscriptions)
        let events = Value.i32(Address.events)
        let result = Value.i32(Address.result)
        return [
            PointerCase("args_get", "argv", [end, result]),
            PointerCase("args_get", "argv_buf", [result, end]),
            // Two arguments take 8 bytes of pointers and 13 bytes of strings.
            PointerCase("args_get", "argv across the end", [.i32(Address.end - 4), result]),
            PointerCase("args_get", "argv_buf across the end", [result, .i32(Address.end - 3)]),
            PointerCase("args_sizes_get", "argc", [end, result]),
            PointerCase("args_sizes_get", "argv_buf_size", [result, end]),
            PointerCase("environ_get", "environ", [end, result]),
            PointerCase("environ_get", "environ_buf", [result, end]),
            PointerCase("environ_sizes_get", "environc", [end, result]),
            PointerCase("environ_sizes_get", "environ_buf_size", [result, end]),
            PointerCase("clock_res_get", "resolution", [.i32(0), end]),
            PointerCase("clock_time_get", "time", [.i32(0), .i64(0), end]),
            PointerCase("clock_time_get", "time across the end", [.i32(0), .i64(0), .i32(Address.end - 4)]),
            // The end of the range does not fit in 32 bits.
            PointerCase("clock_time_get", "time near 4 GiB", [.i32(0), .i64(0), .i32(0xFFFF_FFFC)]),
            PointerCase("random_get", "buf", [end, .i32(4)]),
            PointerCase("fd_write", "iovs", [file, end, .i32(1), result]),
            PointerCase("fd_write", "second iovec", [file, .i32(Address.end - 8), .i32(2), result]),
            PointerCase("fd_write", "iovec buffer", [file, .i32(Address.iovsOutside), .i32(1), result]),
            PointerCase("fd_write", "iovec buffer across the end", [file, .i32(Address.iovsAcrossEnd), .i32(1), result]),
            PointerCase("fd_write", "second iovec buffer", [file, .i32(Address.iovsThenOutside), .i32(2), result]),
            PointerCase("fd_write", "nwritten", [file, iovs, .i32(1), end]),
            PointerCase("fd_read", "iovs", [file, end, .i32(1), result]),
            PointerCase("fd_read", "iovec buffer", [file, .i32(Address.iovsOutside), .i32(1), result]),
            PointerCase("fd_read", "second iovec buffer", [file, .i32(Address.iovsThenOutside), .i32(2), result]),
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
            PointerCase("fd_tell", "offset across the end", [file, .i32(Address.end - 4)]),
            PointerCase("fd_filestat_get", "filestat", [file, end]),
            PointerCase("fd_filestat_get", "filestat across the end", [file, .i32(Address.end - 32)]),
            PointerCase("fd_prestat_get", "prestat", [dir, end]),
            PointerCase("fd_prestat_dir_name", "path", [dir, end, .i32(4)]),
            PointerCase("fd_readdir", "buf", [dir, end, .i32(128), .i64(0), result]),
            PointerCase("fd_readdir", "bufused", [dir, result, .i32(128), .i64(0), end]),
            PointerCase("path_create_directory", "path", [dir, end, .i32(3)]),
            PointerCase("path_create_directory", "path across the end", [dir, .i32(Address.end - 2), .i32(5)]),
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
            PointerCase("poll_oneoff", "in", [end, events, .i32(1), result]),
            PointerCase("poll_oneoff", "second subscription", [.i32(Address.end - 48), events, .i32(2), result]),
            PointerCase("poll_oneoff", "out", [subscriptions, end, .i32(1), result]),
            PointerCase("poll_oneoff", "second event", [subscriptions, .i32(Address.end - 32), .i32(2), result]),
            PointerCase("poll_oneoff", "nevents", [subscriptions, events, .i32(1), end]),
        ]
    }()

    @Test(arguments: WASIGuestMemoryBoundsTests.pointerCases)
    func aPointerOutsideMemoryStopsTheGuest(_ pointerCase: PointerCase) throws {
        try withGuest { guest in
            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call(pointerCase.function, pointerCase.arguments)
            }
        }
    }

    /// The in-memory file system has no symbolic links, so this one call runs
    /// against a host directory.
    @Test(.disabled(if: TestSupport.hostPreopensUnavailable, "host preopens are not available on this platform"))
    func aLinkBufferOutsideMemoryStopsTheGuest() throws {
        let directory = try TestSupport.TemporaryDirectory()
        try directory.createFile(at: "a.txt", contents: "hello")
        try directory.createSymlink(at: "link", to: "a.txt")
        try withGuest(hostDirectory: directory) { guest in
            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call(
                    "path_readlink",
                    [.i32(Descriptor.directory), .i32(Address.link), .i32(4), .i32(Address.end), .i32(16), .i32(Address.result)])
            }
        }
    }

    @Test func theErrorDescribesTheRange() throws {
        try withGuest { guest in
            do {
                _ = try guest.call("random_get", [.i32(Address.end - 3), .i32(4)])
                Issue.record("random_get returned")
            } catch let error as WASIMemoryAccessError {
                #expect(error.offset == Address.end - 3)
                #expect(error.count == 4)
                #expect(error.memorySize == Int(Address.end))
            }
        }
    }

    @Test func aRangeMayEndAtTheEndOfMemory() throws {
        try withGuest { guest in
            let fits = try guest.call("random_get", [.i32(Address.end - 4), .i32(4)])
            #expect(fits == [.i32(0)])
            let tell = try guest.call("fd_tell", [.i32(Descriptor.file), .i32(Address.end - 8)])
            #expect(tell == [.i32(0)])
        }
    }

    /// The call does not dereference an empty range, so the range may start
    /// anywhere.
    @Test func anEmptyRangeOutsideMemoryIsNotAnError() throws {
        try withGuest { guest in
            let file = Value.i32(Descriptor.file)
            let result = Value.i32(Address.result)
            let farOutside = Value.i32(Address.farOutside)
            #expect(try guest.call("fd_write", [file, farOutside, .i32(0), result]) == [.i32(0)])
            #expect(try guest.call("fd_write", [file, .i32(Address.iovsEmptyOutside), .i32(1), result]) == [.i32(0)])
            #expect(try guest.call("fd_read", [file, .i32(Address.iovsEmptyOutside), .i32(1), result]) == [.i32(0)])
            #expect(try guest.call("random_get", [farOutside, .i32(0)]) == [.i32(0)])
            let readdir = try guest.call("fd_readdir", [.i32(Descriptor.directory), farOutside, .i32(0), .i64(0), result])
            #expect(readdir == [.i32(0)])
            // An empty path is read as an empty string and answered with an errno or success.
            _ = try guest.call("path_filestat_get", [.i32(Descriptor.directory), .i32(0), farOutside, .i32(0), result])
        }
    }

    /// The result pointers are checked before the call runs, so a stopped call
    /// creates no file, opens no descriptor, and moves no position.
    @Test func aStoppedCallLeavesNoEffect() throws {
        try withGuest { guest in
            let end = Value.i32(Address.end)
            let create = Value.i32(UInt32(WASIAbi.Oflags.CREAT.rawValue))
            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call(
                    "path_open",
                    [.i32(Descriptor.directory), .i32(0), .i32(Address.newPath), .i32(7), create, .i64(0), .i64(0), .i32(0), end])
            }
            #expect(throws: WASIAbi.Errno.ENOENT) {
                _ = try guest.wasi.path_filestat_get(dirFd: Descriptor.directory, flags: [], path: "new.txt")
            }
            #expect(throws: WASIAbi.Errno.EBADF) {
                _ = try guest.wasi.fd_fdstat_get(fileDescriptor: Descriptor.file + 1)
            }

            let file = Value.i32(Descriptor.file)
            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call("fd_seek", [file, .i64(2), .i32(0), end])
            }
            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call("fd_read", [file, .i32(Address.iovs), .i32(1), end])
            }
            let position = try guest.wasi.fd_tell(fd: Descriptor.file)
            #expect(position == 0)
        }
    }

    /// Every iovec is checked before any data moves, so a bad second buffer
    /// stops the call before the first one is written or read.
    @Test func aBadIOVecStopsTheCallBeforeAnyTransfer() throws {
        let stdout = CustomPlatformInjectionTests.SinkFile()
        try withGuest(stdout: stdout) { guest in
            guest.memory.write(Array("hello".utf8), at: Address.data)
            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call("fd_write", [.i32(1), .i32(Address.iovsThenOutside), .i32(2), .i32(Address.result)])
            }
            #expect(stdout.captured.withLock { $0 }.isEmpty)

            #expect(throws: WASIMemoryAccessError.self) {
                try guest.call("fd_read", [.i32(Descriptor.file), .i32(Address.iovsThenOutside), .i32(2), .i32(Address.result)])
            }
            let position = try guest.wasi.fd_tell(fd: Descriptor.file)
            #expect(position == 0)
        }
    }

    /// The iovecs are read once, before the transfer, so a read into the first
    /// buffer that overwrites the second iovec does not change where the
    /// second buffer is.
    @Test func anIOVecOverwrittenByAnEarlierReadKeepsItsBuffer() throws {
        // The bytes of an iovec whose buffer starts at the end of memory.
        let iovecOutside = littleEndianBytes(Address.end, 4)
        try withGuest(files: ["iov.bin": iovecOutside + Array("abcd".utf8)]) { guest in
            let first: UInt32 = 0x700
            let second = first + 8
            guest.memory.write(iovec: (second, 8), at: first)
            guest.memory.write(iovec: (Address.data, 4), at: second)
            let fd = try guest.wasi.path_open(
                dirFd: Descriptor.directory, dirFlags: [], path: "iov.bin", oflags: [],
                fsRightsBase: [.FD_READ], fsRightsInheriting: [], fdflags: [])
            let result = try guest.call("fd_read", [.i32(fd), .i32(first), .i32(2), .i32(Address.result)])
            #expect(result == [.i32(0)])
            #expect(guest.memory.read(count: 4, at: Address.result) == [12, 0, 0, 0])
            #expect(guest.memory.read(count: 8, at: second) == iovecOutside)
            #expect(guest.memory.read(count: 4, at: Address.data) == Array("abcd".utf8))
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

    /// A call can read or write a range that ends exactly at 4 GiB, where the
    /// address past the range does not fit in 32 bits.
    @Test(.enabled(if: Int.bitWidth == 64, "a 4 GiB memory needs a 64-bit host"))
    func aRangeMayEndAtFourGiB() throws {
        let top = UInt64(1) << 32
        func near(_ distance: UInt64) -> UInt32 { UInt32(top - distance) }
        try withGuest(in: FourGiBMemory(), files: ["b.txt": Array("b".utf8)]) { guest in
            let file = Value.i32(Descriptor.file)
            let directory = Value.i32(Descriptor.directory)
            let success = [Value.i32(0)]

            #expect(try guest.call("fd_filestat_get", [file, .i32(near(64))]) == success)
            #expect(try guest.call("fd_fdstat_get", [file, .i32(near(24))]) == success)
            #expect(try guest.call("fd_prestat_get", [directory, .i32(near(8))]) == success)
            #expect(try guest.call("fd_tell", [file, .i32(near(8))]) == success)

            // Two arguments take 8 bytes of pointers and 13 bytes of strings.
            let strings = Address.data
            #expect(try guest.call("args_get", [.i32(near(8)), .i32(strings)]) == success)
            #expect(guest.memory.read(count: 8, at: near(8)) == littleEndianBytes(strings, strings + 6))
            #expect(try guest.call("args_get", [.i32(Address.result), .i32(near(13))]) == success)
            #expect(guest.memory.read(count: 8, at: Address.result) == littleEndianBytes(near(13), near(7)))
            #expect(guest.memory.read(count: 13, at: near(13)) == Array("guest\0--flag\0".utf8))

            // A zeroed subscription is a realtime clock with no timeout.
            guest.memory.write(Array(repeating: 0, count: 48), at: near(48))
            let polled = try guest.call("poll_oneoff", [.i32(near(48)), .i32(Address.events), .i32(1), .i32(Address.result)])
            #expect(polled == success)

            // The first entry, `a.txt`, fills the buffer, and `b.txt` follows it.
            let entry = UInt32(WASIAbi.Dirent.sizeInGuest) + 5
            let readdir = try guest.call("fd_readdir", [directory, .i32(near(UInt64(entry))), .i32(entry), .i64(0), .i32(Address.result)])
            #expect(readdir == success)
            #expect(guest.memory.read(count: 4, at: Address.result) == littleEndianBytes(entry))
            #expect(guest.memory.read(count: 5, at: near(5)) == Array("a.txt".utf8))
        }
    }

    /// The embedder receives the error from the call that entered the guest,
    /// and the instance can be called again.
    @Test func theEmbedderReceivesTheError() throws {
        let stdout = CustomPlatformInjectionTests.SinkFile()
        let fileSystem = try WASIBridgeToHost.FileSystemOptions.memory(MemoryFileSystem()).withStdio(
            stdin: CustomPlatformInjectionTests.FixedContentFile(bytes: []),
            stdout: stdout,
            stderr: CustomPlatformInjectionTests.SinkFile())
        let bridge = try WASIBridgeToHost(fileSystem: fileSystem)
        try bridge.runAndClose { bridge in
            let store = Store(engine: Engine())
            var imports = Imports()
            bridge.link(to: &imports, store: store)
            let instance = try parseWasm(bytes: Self.writerModule).instantiate(store: store, imports: imports)
            let write = try #require(instance.exports[function: "write"])

            #expect(throws: WASIMemoryAccessError.self) {
                try write([.i32(Address.end), .i32(1)])
            }
            #expect(try write([.i32(0), .i32(0)]) == [.i32(0)])
            #expect(stdout.captured.withLock { $0 }.isEmpty)
        }
    }

    /// A module with one page of exported memory and `write(iovs, iovs_len)`,
    /// which returns `fd_write(1, iovs, iovs_len, 0)`.
    static let writerModule: [UInt8] = [
        0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
        // Types: (i32 i32 i32 i32) -> i32 and (i32 i32) -> i32.
        0x01, 0x0F, 0x02,
        0x60, 0x04, 0x7F, 0x7F, 0x7F, 0x7F, 0x01, 0x7F,
        0x60, 0x02, 0x7F, 0x7F, 0x01, 0x7F,
        // Import wasi_snapshot_preview1.fd_write with type 0.
        0x02, 0x23, 0x01,
        0x16, 0x77, 0x61, 0x73, 0x69, 0x5F, 0x73, 0x6E, 0x61, 0x70, 0x73, 0x68,
        0x6F, 0x74, 0x5F, 0x70, 0x72, 0x65, 0x76, 0x69, 0x65, 0x77, 0x31,
        0x08, 0x66, 0x64, 0x5F, 0x77, 0x72, 0x69, 0x74, 0x65,
        0x00, 0x00,
        // One function with type 1.
        0x03, 0x02, 0x01, 0x01,
        // One memory of one page.
        0x05, 0x03, 0x01, 0x00, 0x01,
        // Export the memory and function 1.
        0x07, 0x12, 0x02,
        0x06, 0x6D, 0x65, 0x6D, 0x6F, 0x72, 0x79, 0x02, 0x00,
        0x05, 0x77, 0x72, 0x69, 0x74, 0x65, 0x00, 0x01,
        // Body: (call 0 (i32.const 1) (local.get 0) (local.get 1) (i32.const 0)).
        0x0A, 0x0E, 0x01,
        0x0C, 0x00, 0x41, 0x01, 0x20, 0x00, 0x20, 0x01, 0x41, 0x00, 0x10, 0x00, 0x0B,
    ]
}

/// A 4 GiB guest memory that keeps only its first and last pages.
private final class FourGiBMemory: GuestMemory {
    private static let pageSize = 0x1_0000
    private static let lastPage = (1 << 32) - pageSize
    private var first = [UInt8](repeating: 0, count: pageSize)
    private var last = [UInt8](repeating: 0, count: pageSize)

    var byteCount: Int { 1 << 32 }

    func withUnsafeMutableBufferPointer<T>(
        offset: UInt,
        count: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> T
    ) rethrows -> T {
        let offset = Int(offset)
        precondition(offset + count <= byteCount, "Memory access out of bounds")
        if offset + count <= Self.pageSize {
            return try first.withUnsafeMutableBytes { try body(.init(rebasing: $0[offset..<offset + count])) }
        }
        precondition(offset >= Self.lastPage, "Memory access outside the kept pages")
        let start = offset - Self.lastPage
        return try last.withUnsafeMutableBytes { try body(.init(rebasing: $0[start..<start + count])) }
    }
}

private func littleEndianBytes(_ values: UInt32...) -> [UInt8] {
    values.flatMap { withUnsafeBytes(of: $0.littleEndian, Array.init) }
}

extension GuestMemory {
    fileprivate func write(_ bytes: [UInt8], at offset: UInt32) {
        withUnsafeMutableBufferPointer(offset: UInt(offset), count: bytes.count) { $0.copyBytes(from: bytes) }
    }

    fileprivate func write(iovec: (buffer: UInt32, length: UInt32), at offset: UInt32) {
        write(littleEndianBytes(iovec.buffer, iovec.length), at: offset)
    }

    fileprivate func read(count: Int, at offset: UInt32) -> [UInt8] {
        withUnsafeMutableBufferPointer(offset: UInt(offset), count: count) { Array($0) }
    }
}
