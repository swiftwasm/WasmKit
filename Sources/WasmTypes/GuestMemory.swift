/// A write/read-able view representation of WebAssembly Memory instance
public protocol GuestMemory {
    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    func withUnsafeMutableBufferPointer<T>(
        offset: UInt,
        count: Int,
        _ body: (UnsafeMutableRawBufferPointer) throws -> T
    ) rethrows -> T
}

/// A pointer-referenceable type that is intended to be pointee of ``UnsafeGuestPointer``
public protocol GuestPointee {
    /// Returns the size of this type in bytes in guest memory
    static var sizeInGuest: UInt32 { get }

    /// Returns the required alignment of this type, in bytes
    static var alignInGuest: UInt32 { get }

    /// Reads a value of self type from the given pointer of guest memory
    static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> Self

    /// Writes the given value at the given pointer of guest memory
    static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: Self)
}

/// A pointer-referenceable primitive type that have the same size and alignment in host and guest
public protocol GuestPrimitivePointee: GuestPointee {}
extension GuestPrimitivePointee {
    /// Returns the same size of this type in bytes in the host
    public static var sizeInGuest: UInt32 {
        UInt32(MemoryLayout<Self>.size)
    }

    /// Returns the same required alignment of this type in the host
    public static var alignInGuest: UInt32 {
        UInt32(MemoryLayout<Self>.alignment)
    }
}

/// Auto implementation of ``GuestPointee`` for ``RawRepresentable`` types
extension GuestPointee where Self: RawRepresentable, Self.RawValue: GuestPointee {
    public static var sizeInGuest: UInt32 {
        RawValue.sizeInGuest
    }

    public static var alignInGuest: UInt32 {
        RawValue.alignInGuest
    }

    /// Reads a value of RawValue type and constructs a value of Self type
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> Self {
        Self(rawValue: .readFromGuest(pointer, in: memory))!
    }

    /// Writes the raw value of the given value to the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: Self) {
        Self.RawValue.writeToGuest(at: pointer, in: memory, value: value.rawValue)
    }
}

extension UInt8: GuestPrimitivePointee {
    /// Reads a value of `UInt8` type from the given pointer of guest memory
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> UInt8 {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt8>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt8.self)
            return pointer.baseAddress!.pointee
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: UInt8) {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt8>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt8.self)
            pointer.baseAddress!.pointee = value
        }
    }
}

extension UInt16: GuestPrimitivePointee {
    /// Reads a value of `UInt16` type from the given pointer of guest memory
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> UInt16 {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt16>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt16.self)
            let value = pointer.baseAddress!.pointee
            #if _endian(little)
                return value
            #else
                return value.byteSwapped
            #endif
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: UInt16) {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt16>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt16.self)
            let writingValue: UInt16
            #if _endian(little)
                writingValue = value
            #else
                value = value.byteSwapped
            #endif
            pointer.baseAddress!.pointee = writingValue
        }
    }
}

extension UInt32: GuestPrimitivePointee {
    /// Reads a value of `UInt32` type from the given pointer of guest memory
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> UInt32 {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt32>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt32.self)
            let value = pointer.baseAddress!.pointee
            #if _endian(little)
                return value
            #else
                return value.byteSwapped
            #endif
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: UInt32) {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt32>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt32.self)
            let writingValue: UInt32
            #if _endian(little)
                writingValue = value
            #else
                value = value.byteSwapped
            #endif
            pointer.baseAddress!.pointee = writingValue
        }
    }
}

extension UInt64: GuestPrimitivePointee {
    /// Reads a value of `UInt64` type from the given pointer of guest memory
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> UInt64 {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt64>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt64.self)
            let value = pointer.baseAddress!.pointee
            #if _endian(little)
                return value
            #else
                return value.byteSwapped
            #endif
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: UInt64) {
        pointer.withHostPointer(in: memory, count: MemoryLayout<UInt64>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt64.self)
            let writingValue: UInt64
            #if _endian(little)
                writingValue = value
            #else
                value = value.byteSwapped
            #endif
            pointer.baseAddress!.pointee = writingValue
        }
    }
}

/// A raw pointer representation of guest memory space
/// > Note: This type assumes pointer-size is 32-bit because WASI preview1 assumes the address space is 32-bit
public struct UnsafeGuestRawPointer {
    /// An offset from the base address of the guest memory region
    public let offset: UInt32

    /// Creates a new pointer from the given offset
    public init(offset: UInt32) {
        self.offset = offset
    }

    /// Executes the given closure with a mutable raw pointer to the host memory region mapped as guest memory.
    public func withHostPointer<M: GuestMemory, R>(in memory: M, count: Int, _ body: (UnsafeMutableRawBufferPointer) throws -> R) rethrows -> R {
        try memory.withUnsafeMutableBufferPointer(offset: UInt(offset), count: count) { buffer in
            try body(UnsafeMutableRawBufferPointer(start: buffer.baseAddress!, count: count))
        }
    }

    /// Returns a new pointer offset from this pointer by the specified number of bytes.
    public func advanced(by n: UInt32) -> UnsafeGuestRawPointer {
        UnsafeGuestRawPointer(offset: offset + n)
    }

    /// Obtains the next pointer that is properly aligned for the specified `alignment` value.
    public func alignedUp(toMultipleOf alignment: UInt32) -> UnsafeGuestRawPointer {
        let mask = alignment &- 1
        let aligned = (offset &+ mask) & ~mask
        return UnsafeGuestRawPointer(offset: aligned)
    }

    /// Returns a typed pointer to the same memory location.
    public func assumingMemoryBound<T>(to: T.Type) -> UnsafeGuestPointer<T> {
        return UnsafeGuestPointer(self)
    }
}

extension UnsafeGuestRawPointer: GuestPointee {
    /// Returns the size of this type in bytes in guest memory
    public static var sizeInGuest: UInt32 {
        return UInt32(MemoryLayout<UInt32>.size)
    }

    /// Returns the required alignment of this type, in bytes
    public static var alignInGuest: UInt32 {
        return UInt32(MemoryLayout<UInt32>.alignment)
    }

    /// Reads a value of self type from the given pointer of guest memory
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> UnsafeGuestRawPointer {
        UnsafeGuestRawPointer(offset: UInt32.readFromGuest(pointer, in: memory))
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: UnsafeGuestRawPointer) {
        UInt32.writeToGuest(at: pointer, in: memory, value: value.offset)
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

/// A pointee-bound pointer representation of guest memory space
public struct UnsafeGuestPointer<Pointee: GuestPointee> {
    /// A raw pointer representation of guest memory space
    public let raw: UnsafeGuestRawPointer

    /// Creates a new pointer from the given raw pointer
    public init(_ raw: UnsafeGuestRawPointer) {
        self.raw = raw
    }

    /// Creates a new pointer from the given offset
    public init(offset: UInt32) {
        self.raw = UnsafeGuestRawPointer(offset: offset)
    }

    /// Executes the given closure with a mutable pointer to the host memory region mapped as guest memory.
    public func withHostPointer<M: GuestMemory, R>(in memory: M, count: Int, _ body: (UnsafeMutableBufferPointer<Pointee>) throws -> R) rethrows -> R {
        try raw.withHostPointer(in: memory, count: MemoryLayout<Pointee>.stride * count) { raw in
            try body(raw.assumingMemoryBound(to: Pointee.self))
        }
    }

    /// Reads the instance referenced by this pointer from the given memory.
    public func read<M: GuestMemory>(from memory: M) -> Pointee {
        Pointee.readFromGuest(self.raw, in: memory)
    }

    /// Writes the given value at this pointer in the given memory.
    public func write<M: GuestMemory>(_ value: Pointee, to memory: M) {
        Pointee.writeToGuest(at: raw, in: memory, value: value)
    }
}

extension UnsafeGuestPointer: GuestPointee {
    /// Returns the size of this type in bytes in guest memory
    public static var sizeInGuest: UInt32 {
        UnsafeGuestRawPointer.sizeInGuest
    }

    /// Returns the required alignment of this type, in bytes
    public static var alignInGuest: UInt32 {
        UnsafeGuestRawPointer.alignInGuest
    }

    /// Reads a value of self type from the given pointer of guest memory
    public static func readFromGuest<M: GuestMemory>(_ pointer: UnsafeGuestRawPointer, in memory: M) -> UnsafeGuestPointer<Pointee> {
        UnsafeGuestPointer(UnsafeGuestRawPointer.readFromGuest(pointer, in: memory))
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest<M: GuestMemory>(at pointer: UnsafeGuestRawPointer, in memory: M, value: UnsafeGuestPointer<Pointee>) {
        UnsafeGuestRawPointer.writeToGuest(at: pointer, in: memory, value: value.raw)
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

/// A pointee-bound interface to a buffer of elements stored contiguously in guest memory
public struct UnsafeGuestBufferPointer<Pointee: GuestPointee> {
    /// A pointer to the first element of the buffer
    public let baseAddress: UnsafeGuestPointer<Pointee>
    /// The number of elements in the buffer
    public let count: UInt32

    /// Creates a new buffer from the given base address and count
    public init(baseAddress: UnsafeGuestPointer<Pointee>, count: UInt32) {
        self.baseAddress = baseAddress
        self.count = count
    }

    /// A Boolean value indicating whether the buffer is empty.
    public var isEmpty: Bool { count == 0 }

    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    public func withHostPointer<M: GuestMemory, R>(in memory: M, _ body: (UnsafeMutableBufferPointer<Pointee>) throws -> R) rethrows -> R {
        try baseAddress.withHostPointer(in: memory, count: Int(count)) { baseAddress in
            try body(baseAddress)
        }
    }

    /// Reads the element at the given index from the given memory.
    public func read<M: GuestMemory>(at index: UInt32, in memory: M) -> Pointee {
        (baseAddress + index).read(from: memory)
    }

    /// Writes the given value at the given index in the given memory.
    public func write<M: GuestMemory>(at index: UInt32, _ value: Pointee, to memory: M) {
        Pointee.writeToGuest(at: baseAddress.raw.advanced(by: index * Pointee.sizeInGuest), in: memory, value: value)
    }
}
