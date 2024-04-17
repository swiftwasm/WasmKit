import WasmTypes

extension GuestPointee {
    static func readFromGuest(_ pointer: inout UnsafeGuestRawPointer) -> Self {
        pointer = pointer.alignedUp(toMultipleOf: Self.alignInGuest)
        let value = readFromGuest(pointer)
        pointer = pointer.advanced(by: sizeInGuest)
        return value
    }

    static func writeToGuest(at pointer: inout UnsafeGuestRawPointer, value: Self) {
        pointer = pointer.alignedUp(toMultipleOf: Self.alignInGuest)
        writeToGuest(at: pointer, value: value)
        pointer = pointer.advanced(by: sizeInGuest)
    }
}
