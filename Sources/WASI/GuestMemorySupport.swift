import WasmTypes

/// The bytes of one struct in guest memory, addressed from the start of the
/// struct.
///
/// A struct is read or written through one access of its whole size, and its
/// fields are then laid out inside these bytes. The memory therefore accepts or
/// rejects the struct as a whole, and field offsets stay small, so they cannot
/// wrap around at 4 GiB.
struct GuestStructBytes: GuestMemory {
    let bytes: UnsafeMutableRawBufferPointer

    func withUnsafeMutableBufferPointer<T>(
        offset: UInt,
        count: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> T
    ) throws -> T {
        guard count > 0 else { return try body(UnsafeMutableRawBufferPointer(start: nil, count: 0)) }
        // Field offsets come from the layout of the struct, not from the guest,
        // so a field past the end of the struct is a bug in that layout.
        precondition(
            offset <= UInt(bytes.count) && count <= bytes.count - Int(offset),
            "A field lies outside its struct"
        )
        let start = Int(offset)
        return try body(UnsafeMutableRawBufferPointer(rebasing: bytes[start..<start + count]))
    }
}

extension GuestPointee {
    /// Calls `body` with the bytes of the value of this type at `pointer`, and
    /// a cursor at the first of them.
    static func withFields<M: GuestMemory, R>(
        at pointer: UnsafeGuestRawPointer,
        in memory: M,
        _ body: (inout UnsafeGuestRawPointer, GuestStructBytes) throws -> R
    ) throws -> R {
        try pointer.withHostPointer(in: memory, count: Int(sizeInGuest)) { bytes in
            var cursor = UnsafeGuestRawPointer(offset: 0)
            return try body(&cursor, GuestStructBytes(bytes: bytes))
        }
    }

    /// Reads the field at `cursor`, aligned for this type, and moves `cursor`
    /// past it.
    static func readFromGuest(_ cursor: inout UnsafeGuestRawPointer, in fields: GuestStructBytes) throws -> Self {
        cursor = cursor.alignedUp(toMultipleOf: Self.alignInGuest)
        let value = try readFromGuest(cursor, in: fields)
        cursor = cursor.advanced(by: sizeInGuest)
        return value
    }

    /// Writes the field at `cursor`, aligned for this type, and moves `cursor`
    /// past it.
    static func writeToGuest(at cursor: inout UnsafeGuestRawPointer, in fields: GuestStructBytes, value: Self) throws {
        cursor = cursor.alignedUp(toMultipleOf: Self.alignInGuest)
        try writeToGuest(at: cursor, in: fields, value: value)
        cursor = cursor.advanced(by: sizeInGuest)
    }
}
