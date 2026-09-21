import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// Every argument of a `wasi_snapshot_preview1` call comes from the guest,
/// including values no well-formed guest would send. Each one is answered with
/// an errno.
@Suite struct WASIArgumentValidationTests {

    private func withMemoryBackedWASI(
        _ body: (WASIImplementation, TestSupport.TestGuestMemory) throws -> Void
    ) throws {
        let fs = try MemoryFileSystem()
        try fs.ensureDirectory(at: "/dir")
        try fs.addFile(at: "/dir/a.txt", content: "hello")
        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fs).withPreopens([.init(guestPath: "/dir", hostPath: "/dir")])
        )
        try bridge.runAndClose { try body($0.underlying, TestSupport.TestGuestMemory()) }
    }

    private func withHostBackedWASI(
        _ body: (WASIImplementation, TestSupport.TestGuestMemory, TestSupport.TemporaryDirectory) throws -> Void
    ) throws {
        let directory = try TestSupport.TemporaryDirectory()
        try directory.createFile(at: "a.txt", contents: "hello")
        let bridge = try WASIBridgeToHost(
            fileSystem: .host().withPreopens([.init(guestPath: "/dir", hostPath: directory.path)])
        )
        try bridge.runAndClose { try body($0.underlying, TestSupport.TestGuestMemory(), directory) }
    }

    private func openFile(_ wasi: WASIImplementation, rights: WASIAbi.Rights = [.FD_READ, .FD_WRITE]) throws -> WASIAbi.Fd {
        try wasi.path_open(
            dirFd: 3, dirFlags: [], path: "a.txt", oflags: [],
            fsRightsBase: rights, fsRightsInheriting: [], fdflags: [])
    }

    private func hostFunction(
        _ name: String
    ) throws -> (WASIBridgeToHost, WASIHostFunction<TestSupport.TestGuestMemory>) {
        let bridge = try WASIBridgeToHost(fileSystem: .memory(MemoryFileSystem()))
        let functions = bridge.hostFunctions(
            capabilities: WASICapability<TestSupport.TestGuestMemory>.all, stubUnlinked: false)
        return (bridge, try #require(functions[name]))
    }

    // MARK: - Flag and enumeration arguments

    /// The ABI passes `fdflags` and `whence` in an i32, so a guest can set bits
    /// that do not fit the narrower field the call actually takes.
    @Test func aFlagFieldWiderThanTheABIIsRejected() throws {
        let (bridge, pathOpen) = try hostFunction("path_open")
        try bridge.runAndClose { _ in
            let result = try pathOpen.implementation(
                TestSupport.TestGuestMemory(),
                [.i32(3), .i32(0), .i32(0), .i32(0), .i32(0), .i64(0), .i64(0), .i32(0x1_0000), .i32(0)])
            #expect(result == [.i32(UInt32(WASIAbi.Errno.EINVAL.rawValue))])
        }
    }

    @Test func anOutOfRangeSeekOriginIsRejected() throws {
        let (bridge, fdSeek) = try hostFunction("fd_seek")
        try bridge.runAndClose { _ in
            let result = try fdSeek.implementation(
                TestSupport.TestGuestMemory(), [.i32(0), .i64(0), .i32(0x1_0000), .i32(0)])
            #expect(result == [.i32(UInt32(WASIAbi.Errno.EINVAL.rawValue))])
        }
    }

    /// `poll_oneoff` reads a tagged union out of guest memory.
    @Test func anUnknownSubscriptionKindIsRejected() throws {
        try withMemoryBackedWASI { wasi, memory in
            let subscriptions = UnsafeGuestBufferPointer<WASIAbi.Subscription>(
                baseAddress: .init(offset: 0), count: 1)
            let events = UnsafeGuestBufferPointer<WASIAbi.Event>(baseAddress: .init(offset: 256), count: 1)
            // userdata, then a union tag no `eventtype` uses.
            memory.write([0, 0, 0, 0, 0, 0, 0, 0, 7], at: 0)
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try wasi.poll_oneoff(subscriptions: subscriptions, events: events, memory: memory)
            }
        }
    }

    // MARK: - Offsets, sizes and cookies

    @Test(arguments: [true, false])
    func anOffsetBeyondTheAddressableRangeIsRejected(hostBacked: Bool) throws {
        func check(_ wasi: WASIImplementation, _ memory: TestSupport.TestGuestMemory) throws {
            let fd = try self.openFile(wasi)
            let readVectors = memory.readIOVecs(sizes: [4])
            let writeVectors = memory.writeIOVecs([Array("x".utf8)])
            let offset = WASIAbi.FileSize(Int64.max) + 1
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try wasi.fd_pread(fd: fd, iovs: readVectors, offset: offset, memory: memory)
            }
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try wasi.fd_pwrite(fd: fd, iovs: writeVectors, offset: offset, memory: memory)
            }
        }
        if hostBacked {
            try withHostBackedWASI { wasi, memory, _ in try check(wasi, memory) }
        } else {
            try withMemoryBackedWASI { wasi, memory in try check(wasi, memory) }
        }
    }

    @Test(arguments: [true, false])
    func aFileSizeBeyondTheAddressableRangeIsRejected(hostBacked: Bool) throws {
        func check(_ wasi: WASIImplementation) throws {
            let fd = try self.openFile(wasi)
            #expect(throws: WASIAbi.Errno.EINVAL) {
                try wasi.fd_filestat_set_size(fd: fd, size: WASIAbi.FileSize(Int64.max) + 1)
            }
        }
        if hostBacked {
            try withHostBackedWASI { wasi, _, _ in try check(wasi) }
        } else {
            try withMemoryBackedWASI { wasi, _ in try check(wasi) }
        }
    }

    /// Seeking relative to the current position or the end must not run off
    /// the end of the arithmetic.
    @Test func aSeekThatWouldOverflowIsRejected() throws {
        try withMemoryBackedWASI { wasi, _ in
            let fd = try self.openFile(wasi)
            _ = try wasi.fd_seek(fd: fd, offset: 3, whence: .SET)
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try wasi.fd_seek(fd: fd, offset: .max, whence: .CUR)
            }
            #expect(throws: WASIAbi.Errno.EINVAL) {
                _ = try wasi.fd_seek(fd: fd, offset: .max, whence: .END)
            }
        }
    }

    /// A write lands at the descriptor's position, which the guest can put
    /// anywhere a position is expressible.
    @Test func aWriteThatWouldRunOffTheEndOfThePositionRangeIsRejected() throws {
        try withMemoryBackedWASI { wasi, memory in
            let fd = try self.openFile(wasi)
            let vectors = memory.writeIOVecs([Array("x".utf8)])
            _ = try wasi.fd_seek(fd: fd, offset: .max, whence: .SET)
            #expect(throws: WASIAbi.Errno.EFBIG) {
                _ = try wasi.fd_write(fileDescriptor: fd, ioVectors: vectors, memory: memory)
            }
            #expect(throws: WASIAbi.Errno.EFBIG) {
                _ = try wasi.fd_pwrite(fd: fd, iovs: vectors, offset: WASIAbi.FileSize(Int64.max), memory: memory)
            }
        }
    }

    /// A readdir cookie is a `u64` the guest chooses.
    @Test(arguments: [true, false])
    func aDirectoryCookieBeyondTheEntryCountYieldsNothing(hostBacked: Bool) throws {
        func check(_ wasi: WASIImplementation, _ memory: TestSupport.TestGuestMemory) throws {
            let buffer = UnsafeGuestBufferPointer<UInt8>(baseAddress: .init(offset: 0), count: 4096)
            let used = try wasi.fd_readdir(fd: 3, buffer: buffer, cookie: .max, memory: memory)
            #expect(used == 0)
        }
        if hostBacked {
            try withHostBackedWASI { wasi, memory, _ in try check(wasi, memory) }
        } else {
            try withMemoryBackedWASI { wasi, memory in try check(wasi, memory) }
        }
    }

    // MARK: - Guest buffers

    /// Only the bytes actually produced are written back, so the size the guest
    /// declares for the destination does not have to be addressable.
    @Test func prestatDirNameWritesOnlyThePathItReturns() throws {
        try withMemoryBackedWASI { wasi, memory in
            try wasi.fd_prestat_dir_name(
                fd: 3, path: .init(offset: 0), maxPathLength: .max, memory: memory)
            #expect(memory.read(count: 4) == Array("/dir".utf8))
        }
    }

    @Test func readlinkWritesOnlyTheLinkItReturns() throws {
        try withHostBackedWASI { wasi, memory, directory in
            try directory.createSymlink(at: "link", to: "a.txt")
            let buffer = UnsafeGuestBufferPointer<UInt8>(baseAddress: .init(offset: 0), count: .max)
            let written = try wasi.path_readlink(fd: 3, path: "link", buffer: buffer, memory: memory)
            #expect(written == 5)
            #expect(memory.read(count: 5) == Array("a.txt".utf8))
        }
    }

    // MARK: - Polling

    /// A subscription set with no clock in it waits indefinitely rather than
    /// carrying a timeout that does not fit the platform call.
    @Test func pollingOnADescriptorWithoutAClockSubscriptionWorks() throws {
        let directory = try TestSupport.TemporaryDirectory()
        try directory.createFile(at: "in.txt", contents: "hello")
        let opened = try directory.openFile(at: "in.txt", .readOnly)
        defer { try? opened.close() }
        let bridge = try WASIBridgeToHost(
            fileSystem: .host().withStdio(stdin: opened.fileDescriptor)
        )
        try bridge.runAndClose { bridge in
            let memory = TestSupport.TestGuestMemory()
            let events = UnsafeGuestBufferPointer<WASIAbi.Event>(baseAddress: .init(offset: 256), count: 2)
            let table = bridge.underlying.fdTable.withLock { $0 }
            // A regular file is always ready, so this returns without waiting.
            let readyCount = try poll(
                subscriptions: [.init(userData: 1, union: .fdRead(0))],
                events: events, table, memory: memory)
            #expect(readyCount == 1)
            // And a timeout too large for the platform call does not overflow it.
            let readyWithClock = try poll(
                subscriptions: [
                    .init(userData: 1, union: .fdRead(0)),
                    .init(userData: 2, union: .clock(.init(id: .MONOTONIC, timeout: .max, precision: 0, flags: []))),
                ],
                events: events, table, memory: memory)
            #expect(readyWithClock == 1)
        }
    }
}
