/// A write/read-able view representation of WebAssembly Memory instance
public struct GuestMemory {
    private let store: Store
    private let address: MemoryAddress

    /// Creates a new memory instance from the given store and address
    public init(store: Store, address: MemoryAddress) {
        self.store = store
        self.address = address
    }

    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    func withUnsafeMutableBufferPointer<T>(_ body: (UnsafeMutableRawBufferPointer) throws -> T) rethrows -> T {
        try store.withMemory(at: address) { memory in
            try memory.data.withUnsafeMutableBufferPointer { buffer in
                try body(UnsafeMutableRawBufferPointer(buffer))
            }
        }
    }
}

/// A pointer-referenceable type that is intended to be pointee of ``UnsafeGuestPointer``
public protocol GuestPointee {
    /// Returns the size of this type in bytes in guest memory
    static var sizeInGuest: UInt32 { get }

    /// Returns the required alignment of this type, in bytes
    static var alignInGuest: UInt32 { get }

    /// Reads a value of self type from the given pointer of guest memory
    static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> Self

    /// Writes the given value at the given pointer of guest memory
    static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: Self)
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
extension GuestPrimitivePointee where Self: RawRepresentable, Self.RawValue: GuestPointee {
    /// Reads a value of RawValue type and constructs a value of Self type
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> Self {
        Self(rawValue: .readFromGuest(pointer))!
    }

    /// Writes the raw value of the given value to the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: Self) {
        Self.RawValue.writeToGuest(at: pointer, value: value.rawValue)
    }
}

extension UInt8: GuestPrimitivePointee {
    /// Reads a value of `UInt8` type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> UInt8 {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt8.self)
            return pointer.pointee
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: UInt8) {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt8.self)
            pointer.pointee = value
        }
    }
}

extension UInt16: GuestPrimitivePointee {
    /// Reads a value of `UInt16` type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> UInt16 {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt16.self)
            let value = pointer.pointee
            #if _endian(little)
                return value
            #else
                return value.byteSwapped
            #endif
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: UInt16) {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt16.self)
            let writingValue: UInt16
            #if _endian(little)
                writingValue = value
            #else
                value = value.byteSwapped
            #endif
            pointer.pointee = writingValue
        }
    }
}

extension UInt32: GuestPrimitivePointee {
    /// Reads a value of `UInt32` type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> UInt32 {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt32.self)
            let value = pointer.pointee
            #if _endian(little)
                return value
            #else
                return value.byteSwapped
            #endif
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: UInt32) {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt32.self)
            let writingValue: UInt32
            #if _endian(little)
                writingValue = value
            #else
                value = value.byteSwapped
            #endif
            pointer.pointee = writingValue
        }
    }
}

extension UInt64: GuestPrimitivePointee {
    /// Reads a value of `UInt64` type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> UInt64 {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt64.self)
            let value = pointer.pointee
            #if _endian(little)
                return value
            #else
                return value.byteSwapped
            #endif
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: UInt64) {
        pointer.withHostPointer { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: UInt64.self)
            let writingValue: UInt64
            #if _endian(little)
                writingValue = value
            #else
                value = value.byteSwapped
            #endif
            pointer.pointee = writingValue
        }
    }
}

/// A raw pointer representation of guest memory space
/// > Note: This type assumes pointer-size is 32-bit because WASI preview1 assumes the address space is 32-bit
public struct UnsafeGuestRawPointer {
    /// A guest memory space that this pointer points
    public let memorySpace: GuestMemory
    /// An offset from the base address of the guest memory region
    public let offset: UInt32

    /// Creates a new pointer from the given memory space and offset
    public init(memorySpace: GuestMemory, offset: UInt32) {
        self.memorySpace = memorySpace
        self.offset = offset
    }

    /// Executes the given closure with a mutable raw pointer to the host memory region mapped as guest memory.
    public func withHostPointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R {
        try memorySpace.withUnsafeMutableBufferPointer { buffer in
            try body(buffer.baseAddress!.advanced(by: Int(offset)))
        }
    }

    /// Returns a new pointer offset from this pointer by the specified number of bytes.
    public func advanced(by n: UInt32) -> UnsafeGuestRawPointer {
        UnsafeGuestRawPointer(memorySpace: memorySpace, offset: offset + n)
    }

    /// Obtains the next pointer that is properly aligned for the specified `alignment` value.
    public func alignedUp(toMultipleOf alignment: UInt32) -> UnsafeGuestRawPointer {
        let mask = alignment &- 1
        let aligned = (offset &+ mask) & ~mask
        return UnsafeGuestRawPointer(memorySpace: memorySpace, offset: aligned)
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
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> UnsafeGuestRawPointer {
        UnsafeGuestRawPointer(memorySpace: pointer.memorySpace, offset: UInt32.readFromGuest(pointer))
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: UnsafeGuestRawPointer) {
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

/// A pointee-bound pointer representation of guest memory space
public struct UnsafeGuestPointer<Pointee: GuestPointee> {
    /// A raw pointer representation of guest memory space
    public let raw: UnsafeGuestRawPointer

    /// Creates a new pointer from the given raw pointer
    public init(_ raw: UnsafeGuestRawPointer) {
        self.raw = raw
    }

    /// Creates a new pointer from the given memory space and offset
    public init(memorySpace: GuestMemory, offset: UInt32) {
        self.raw = UnsafeGuestRawPointer(memorySpace: memorySpace, offset: offset)
    }

    /// Executes the given closure with a mutable pointer to the host memory region mapped as guest memory.
    public func withHostPointer<R>(_ body: (UnsafeMutablePointer<Pointee>) throws -> R) rethrows -> R {
        try raw.withHostPointer { raw in
            try body(raw.assumingMemoryBound(to: Pointee.self))
        }
    }

    /// Accesses the instance referenced by this pointer.
    public var pointee: Pointee {
        get { Pointee.readFromGuest(self.raw) }
        nonmutating set { Pointee.writeToGuest(at: raw, value: newValue) }
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
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer) -> UnsafeGuestPointer<Pointee> {
        UnsafeGuestPointer(UnsafeGuestRawPointer.readFromGuest(pointer))
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer, value: UnsafeGuestPointer<Pointee>) {
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

    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    public func withHostPointer<R>(_ body: (UnsafeMutableBufferPointer<Pointee>) throws -> R) rethrows -> R {
        try baseAddress.withHostPointer { baseAddress in
            try body(UnsafeMutableBufferPointer(start: baseAddress, count: Int(count)))
        }
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
