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

extension UInt8: GuestPrimitivePointee<Memory> {}
extension UInt16: GuestPrimitivePointee<Memory> {}
extension UInt32: GuestPrimitivePointee<Memory> {}
extension UInt64: GuestPrimitivePointee<Memory> {}

extension UnsafeGuestRawPointer: GuestPointee<Memory> {
    /// Returns the size of this type in bytes in guest memory
    public static var sizeInGuest: UInt32 {
        return UInt32(MemoryLayout<UInt32>.size)
    }

    /// Returns the required alignment of this type, in bytes
    public static var alignInGuest: UInt32 {
        return UInt32(MemoryLayout<UInt32>.alignment)
    }

    /// Reads a value of self type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer<MemorySpace>) -> UnsafeGuestRawPointer<MemorySpace> {
        UnsafeGuestRawPointer(memorySpace: pointer.memorySpace, offset: UInt32.readFromGuest(pointer))
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer<MemorySpace>, value: UnsafeGuestRawPointer<MemorySpace>) {
        UInt32.writeToGuest(at: pointer, value: value.offset)
    }
}

extension UnsafeGuestRawPointer {
    /// Returns a boolean value indicating whether the first pointer references a guest
    /// memory location earlier than the second pointer assuming they point the same guest
    /// memory space.
    public static func < (lhs: UnsafeGuestRawPointer, rhs: UnsafeGuestRawPointer) -> Bool {
        // Assuming they point the same guest memory space
        lhs.offset < rhs.offset
    }

    /// Returns a boolean value indicating whether the first pointer references a guest
    /// memory location later than the second pointer assuming they point the same guest
    /// memory space.
    public static func > (lhs: UnsafeGuestRawPointer, rhs: UnsafeGuestRawPointer) -> Bool {
        // Assuming they point the same guest memory space
        lhs.offset > rhs.offset
    }
}
extension UnsafeGuestRawPointer: GuestPrimitivePointee<Memory> {
    /// Accesses the instance referenced by this pointer.
    public var pointee: Pointee {
        get { Pointee.readFromGuest(self.raw) }
        nonmutating set { Pointee.writeToGuest(at: raw, value: newValue) }
    }
}

extension UnsafeGuestPointer: GuestPointee {
    /// Returns the size of this type in bytes in guest memory
    public static var sizeInGuest: UInt32 {
        UnsafeGuestRawPointer<MemorySpace>.sizeInGuest
    }

    /// Returns the required alignment of this type, in bytes
    public static var alignInGuest: UInt32 {
        UnsafeGuestRawPointer<MemorySpace>.alignInGuest
    }

    /// Reads a value of self type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer<MemorySpace>) -> UnsafeGuestPointer<Pointee, MemorySpace> {
        UnsafeGuestPointer(UnsafeGuestRawPointer.readFromGuest(pointer))
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer<MemorySpace>, value: UnsafeGuestPointer<Pointee, MemorySpace>) {
        UnsafeGuestRawPointer.writeToGuest(at: pointer, value: value.raw)
    }
}

extension UnsafeGuestPointer {
    /// Returns a new pointer offset from this pointer by the specified number of instances.
    public static func + (lhs: UnsafeGuestPointer, rhs: UInt32) -> UnsafeGuestPointer {
        let advanced = lhs.raw.advanced(by: Pointee.sizeInGuest * rhs)
        return UnsafeGuestPointer(advanced)
    }

    /// Returns a new pointer offset from this pointer by the specified number of instances.
    public static func += (lhs: inout Self, rhs: UInt32) {
        lhs = lhs + rhs
    }

    /// Returns a boolean value indicating whether the first pointer references a guest
    /// memory location earlier than the second pointer assuming they point the same guest
    /// memory space.
    public static func < (lhs: UnsafeGuestPointer, rhs: UnsafeGuestPointer) -> Bool {
        lhs.raw < rhs.raw
    }

    /// Returns a boolean value indicating whether the first pointer references a guest
    /// memory location later than the second pointer assuming they point the same guest
    /// memory space.
    public static func > (lhs: UnsafeGuestPointer, rhs: UnsafeGuestPointer) -> Bool {
        lhs.raw > rhs.raw
    }
}

extension UnsafeGuestBufferPointer: Sequence {
    /// An iterator over the elements of the buffer.
    public struct Iterator: IteratorProtocol {
        var position: UInt32
        let buffer: UnsafeGuestBufferPointer

        /// Accesses the next element and advances to the subsequent element, or
        /// returns `nil` if no next element exists.
        public mutating func next() -> Pointee? {
            guard position != buffer.count else { return nil }
            let pointer = buffer.baseAddress + position
            position += 1
            return pointer.pointee
        }
    }

    /// Returns an iterator over the elements of this buffer.
    public func makeIterator() -> Iterator {
        Iterator(position: 0, buffer: self)
    }
}

extension UnsafeGuestBufferPointer: Collection {
    public typealias Index = UInt32

    /// The index of the first element in a nonempty buffer.
    public var startIndex: UInt32 { 0 }

    /// The "past the end" position---that is, the position one greater than the
    /// last valid subscript argument.
    public var endIndex: UInt32 { count }

    /// Accesses the pointee at the specified offset from the base address of the buffer.
    public subscript(position: UInt32) -> Element {
        (self.baseAddress + position).pointee
    }

    /// Returns the position immediately after the given index.
    public func index(after i: UInt32) -> UInt32 {
        return i + 1
    }
}