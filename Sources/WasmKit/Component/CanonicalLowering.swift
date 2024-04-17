/// A namespace for the canonical lowering operations used by host side.
public enum CanonicalLowering {
    /// Lowers a Swift String value to a pair of a pointer and a length
    /// The pointer points to a guest memory region that contains the encoded string value.
    public static func lowerString(
        _ value: String, context: CanonicalCallContext
    ) throws -> (pointer: UInt32, length: UInt32) {
        guard context.options.stringEncoding == .utf8 else {
            throw CanonicalABIError(description: "Unsupported string encoding: \(context.options.stringEncoding)")
        }
        let bytes = value.utf8
        let newBuffer = try context.realloc(
            old: 0, oldSize: 0, oldAlign: 1, newSize: UInt32(bytes.count)
        )
        newBuffer.withHostPointer(count: bytes.count) { newBuffer in
            newBuffer.copyBytes(from: bytes)
        }
        return (newBuffer.offset, UInt32(bytes.count))
    }

    /// Lowers a Swift Array value to a pair of a pointer and a length.
    ///
    /// - Parameters:
    ///   - value: A Swift Array value to be lowered.
    ///   - elementSize: A byte size of an element of the array value in lowered representation.
    ///   - elementAlignment: A byte alignment of an element of the array value in lowered representation.
    ///   - storeElement: A closure that stores an element to the given pointer.
    ///   - context: A canonical call context.
    /// - Returns: A pair of a pointer and a length.
    public static func lowerList<Element>(
        _ value: [Element], elementSize: UInt32, elementAlignment: UInt32,
        storeElement: (Element, UnsafeGuestRawPointer) throws -> Void,
        context: CanonicalCallContext
    ) throws -> (pointer: UInt32, length: UInt32) {
        let byteLength = UInt32(value.count) * elementSize
        let newBuffer = try context.realloc(
            old: 0, oldSize: 0, oldAlign: elementAlignment, newSize: byteLength
        )
        for (i, element) in value.enumerated() {
            try storeElement(element, newBuffer.advanced(by: elementSize * UInt32(i)))
        }
        return (newBuffer.offset, UInt32(value.count))
    }
}
