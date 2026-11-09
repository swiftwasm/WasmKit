import WasmTypes

// A struct may end exactly at 4 GiB, where the pointer past its last field does
// not fit in 32 bits. Nothing reads through that pointer, so the advance wraps
// instead of stopping the host on an overflow.
extension GuestPointee {
    static func readFromGuest<M: GuestMemory>(_ pointer: inout UnsafeGuestRawPointer, in memory: M) -> Self {
        pointer = pointer.alignedUp(toMultipleOf: Self.alignInGuest)
        let value = readFromGuest(pointer, in: memory)
        pointer = UnsafeGuestRawPointer(offset: pointer.offset &+ sizeInGuest)
        return value
    }

    static func writeToGuest<M: GuestMemory>(at pointer: inout UnsafeGuestRawPointer, in memory: M, value: Self) {
        pointer = pointer.alignedUp(toMultipleOf: Self.alignInGuest)
        writeToGuest(at: pointer, in: memory, value: value)
        pointer = UnsafeGuestRawPointer(offset: pointer.offset &+ sizeInGuest)
    }
}

extension GuestMemory {
    /// Throws ``WASIMemoryAccessError`` unless the `count` bytes at `pointer`
    /// lie inside this memory.
    ///
    /// An empty range is not dereferenced, so it passes wherever it starts.
    func checkBounds(_ pointer: UnsafeGuestRawPointer, count: UInt64) throws {
        let memorySize = byteCount
        guard count == 0 || UInt64(pointer.offset) + count <= UInt64(memorySize) else {
            throw WASIMemoryAccessError(offset: pointer.offset, count: count, memorySize: memorySize)
        }
    }
}

extension UnsafeGuestPointer {
    /// Throws ``WASIMemoryAccessError`` unless the pointee lies inside `memory`.
    func checkBounds<M: GuestMemory>(in memory: M) throws {
        try memory.checkBounds(raw, count: UInt64(Pointee.sizeInGuest))
    }
}

extension UnsafeGuestBufferPointer {
    /// Throws ``WASIMemoryAccessError`` unless every element of the buffer lies
    /// inside `memory`.
    func checkBounds<M: GuestMemory>(in memory: M) throws {
        try memory.checkBounds(baseAddress.raw, count: UInt64(count) * UInt64(Pointee.sizeInGuest))
    }
}
