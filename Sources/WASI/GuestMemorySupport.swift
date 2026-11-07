import WasmTypes

extension GuestPointee {
    static func readFromGuest<M: GuestMemory>(_ pointer: inout UnsafeGuestRawPointer, in memory: M) -> Self {
        pointer = pointer.alignedUp(toMultipleOf: Self.alignInGuest)
        let value = readFromGuest(pointer, in: memory)
        pointer = pointer.advanced(by: sizeInGuest)
        return value
    }

    static func writeToGuest<M: GuestMemory>(at pointer: inout UnsafeGuestRawPointer, in memory: M, value: Self) {
        pointer = pointer.alignedUp(toMultipleOf: Self.alignInGuest)
        writeToGuest(at: pointer, in: memory, value: value)
        pointer = pointer.advanced(by: sizeInGuest)
    }
}

extension GuestMemory {
    /// Throws `EFAULT` unless the `count` bytes at `pointer` lie inside this memory.
    func checkBounds(_ pointer: UnsafeGuestRawPointer, count: UInt64) throws {
        guard UInt64(pointer.offset) + count <= UInt64(byteCount) else {
            throw WASIAbi.Errno.EFAULT
        }
    }
}

extension UnsafeGuestPointer {
    /// Throws `EFAULT` unless the pointee lies inside `memory`.
    func checkBounds<M: GuestMemory>(in memory: M) throws {
        try memory.checkBounds(raw, count: UInt64(Pointee.sizeInGuest))
    }
}

extension UnsafeGuestBufferPointer {
    /// Throws `EFAULT` unless every element of the buffer lies inside `memory`.
    func checkBounds<M: GuestMemory>(in memory: M) throws {
        try memory.checkBounds(baseAddress.raw, count: UInt64(count) * UInt64(Pointee.sizeInGuest))
    }
}
