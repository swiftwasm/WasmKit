import Testing
import WasmTypes

@_spi(WASIPlatform) @testable import WASI

/// The buffers of one vectored call may overlap, so their lengths can add up
/// to more than a `size` can count, even in a small memory.
@Suite struct WASIIOVecLengthTests {
    /// The size of guest memory. 1024 buffers, the most one call accepts, that
    /// each cover all of it add up to 4 GiB, one byte more than a `size` counts.
    static let memorySize: UInt32 = 0x40_0000

    /// Writes 1024 iovecs at address 0. Each covers all of memory, except the
    /// last one, which is `last`.
    private func writeOverlappingIOVecs(
        last: WASIAbi.IOVec, to memory: TestSupport.TestGuestMemory
    ) throws -> UnsafeGuestBufferPointer<WASIAbi.IOVec> {
        let count = UInt32(GuestBuffers.maxCount)
        let iovs = UnsafeGuestBufferPointer<WASIAbi.IOVec>(baseAddress: .init(offset: 0), count: count)
        for index in 0..<count - 1 {
            try iovs.write(at: index, WASIAbi.IOVec(buffer: .init(offset: 0), length: Self.memorySize), to: memory)
        }
        try iovs.write(at: count - 1, last, to: memory)
        return iovs
    }

    /// Runs `body` with an in-memory null device as standard output.
    private func withWASI(_ body: (WASIImplementation) throws -> Void) throws {
        let fileSystem = try MemoryFileSystem()
        let null = MemoryCharacterDeviceEntry(deviceNode: MemoryCharacterDeviceNode(kind: .null), accessMode: .write)
        let bridge = try WASIBridgeToHost(
            fileSystem: .memory(fileSystem).withStdio(stdin: null, stdout: null, stderr: null)
        )
        try bridge.runAndClose { bridge in
            try body(bridge.underlying)
        }
    }

    @Test func aWriteOfSizeMaxBytesIsCounted() throws {
        let memory = TestSupport.TestGuestMemory(size: Int(Self.memorySize))
        let iovs = try writeOverlappingIOVecs(
            last: WASIAbi.IOVec(buffer: .init(offset: 0), length: Self.memorySize - 1), to: memory)
        try withWASI { wasi in
            let written = try wasi.fd_write(fileDescriptor: 1, ioVectors: iovs, memory: memory)
            #expect(written == WASIAbi.Size.max)
        }
    }

    /// The call transfers the buffers before the one that would take the total
    /// past what a `size` counts, and reports a short write.
    @Test func aWriteOfMoreThanSizeMaxBytesIsShort() throws {
        let memory = TestSupport.TestGuestMemory(size: Int(Self.memorySize))
        let iovs = try writeOverlappingIOVecs(
            last: WASIAbi.IOVec(buffer: .init(offset: 0), length: Self.memorySize), to: memory)
        try withWASI { wasi in
            let written = try wasi.fd_write(fileDescriptor: 1, ioVectors: iovs, memory: memory)
            #expect(written == WASIAbi.Size.max - Self.memorySize + 1)
        }
    }

    /// A buffer the call does not transfer is never dereferenced, so it may
    /// lie outside memory.
    @Test func aBufferPastTheShortWriteIsNotUsed() throws {
        let memory = TestSupport.TestGuestMemory(size: Int(Self.memorySize))
        let iovs = try writeOverlappingIOVecs(
            last: WASIAbi.IOVec(buffer: .init(offset: Self.memorySize), length: Self.memorySize), to: memory)
        try withWASI { wasi in
            let written = try wasi.fd_write(fileDescriptor: 1, ioVectors: iovs, memory: memory)
            #expect(written == WASIAbi.Size.max - Self.memorySize + 1)
        }
    }
}
