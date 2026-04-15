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
