/// A write/read-able view representation of WebAssembly Memory instance
public protocol GuestMemory {
    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    func withUnsafeMutableBufferPointer(
        offset: UInt,
        count: Int,
        _ body: (UnsafeMutableRawBufferPointer) -> Void
    )
}

/// A pointer-referenceable type that is intended to be pointee of ``UnsafeGuestPointer``
public protocol GuestPointee {
    associatedtype MemorySpace: GuestMemory

    /// Returns the size of this type in bytes in guest memory
    static var sizeInGuest: UInt32 { get }

    /// Returns the required alignment of this type, in bytes
    static var alignInGuest: UInt32 { get }

    /// Reads a value of self type from the given pointer of guest memory
    static func readFromGuest(_ pointer: UnsafeGuestRawPointer<MemorySpace>) -> Self

    /// Writes the given value at the given pointer of guest memory
    static func writeToGuest(at pointer: UnsafeGuestRawPointer<MemorySpace>, value: Self)
}

/// A pointer-referenceable primitive type that have the same size and alignment in host and guest
public protocol GuestPrimitivePointee<MemorySpace>: GuestPointee where Self.MemorySpace == MemorySpace {}
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
extension GuestPrimitivePointee where Self: RawRepresentable, Self.RawValue: GuestPrimitivePointee<MemorySpace> {
    /// Reads a value of RawValue type and constructs a value of Self type
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer<MemorySpace>) -> Self {
        Self(rawValue: .readFromGuest(pointer))!
    }

    /// Writes the raw value of the given value to the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer<MemorySpace>, value: Self) {
        Self.RawValue.writeToGuest(at: pointer, value: value.rawValue)
    }
}

extension FixedWidthInteger where Self: GuestPrimitivePointee<MemorySpace> {
    /// Reads a value of Self type from the given pointer of guest memory
    public static func readFromGuest(_ pointer: UnsafeGuestRawPointer<MemorySpace>) -> Self {
        pointer.withHostPointer(count: MemoryLayout<Self>.size) { hostPointer -> Self in
            let pointer = hostPointer.assumingMemoryBound(to: Self.self)
            return pointer.baseAddress!.pointee
        }
    }

    /// Writes the given value at the given pointer of guest memory
    public static func writeToGuest(at pointer: UnsafeGuestRawPointer<MemorySpace>, value: Self) {
        pointer.withHostPointer(count: MemoryLayout<Self>.size) { hostPointer in
            let pointer = hostPointer.assumingMemoryBound(to: Self.self)
            pointer.baseAddress!.pointee = value
        }
    }
}

/// A raw pointer representation of guest memory space
/// > Note: This type assumes pointer-size is 32-bit because WASI preview1 assumes the address space is 32-bit
public struct UnsafeGuestRawPointer<MemorySpace: GuestMemory> {
    /// A guest memory space that this pointer points
    public let memorySpace: MemorySpace
    /// An offset from the base address of the guest memory region
    public let offset: UInt32

    /// Creates a new pointer from the given memory space and offset
    public init(memorySpace: MemorySpace, offset: UInt32) {
        self.memorySpace = memorySpace
        self.offset = offset
    }

    /// Executes the given closure with a mutable raw pointer to the host memory region mapped as guest memory.
    public func withHostPointer<R>(count: Int, _ body: (UnsafeMutableRawBufferPointer) -> R) -> R {
        var result: R!

        memorySpace.withUnsafeMutableBufferPointer(offset: UInt(offset), count: count) { buffer in
            result = body(UnsafeMutableRawBufferPointer(start: buffer.baseAddress!, count: count))
        }
        return result
    }

    /// Returns a new pointer offset from this pointer by the specified number of bytes.
    public func advanced(by n: UInt32) -> UnsafeGuestRawPointer<MemorySpace> {
        UnsafeGuestRawPointer(memorySpace: memorySpace, offset: offset + n)
    }

    /// Obtains the next pointer that is properly aligned for the specified `alignment` value.
    public func alignedUp(toMultipleOf alignment: UInt32) -> UnsafeGuestRawPointer<MemorySpace> {
        let mask = alignment &- 1
        let aligned = (offset &+ mask) & ~mask
        return UnsafeGuestRawPointer(memorySpace: memorySpace, offset: aligned)
    }

    /// Returns a typed pointer to the same memory location.
    public func assumingMemoryBound<T>(to: T.Type) -> UnsafeGuestPointer<T, MemorySpace> {
        return UnsafeGuestPointer<T, MemorySpace>(self)
    }
}

/// A pointee-bound pointer representation of guest memory space
public struct UnsafeGuestPointer<Pointee: GuestPointee, MemorySpace: GuestMemory> {
    /// A raw pointer representation of guest memory space
    public let raw: UnsafeGuestRawPointer<MemorySpace>

    /// Creates a new pointer from the given raw pointer
    public init(_ raw: UnsafeGuestRawPointer<MemorySpace>) {
        self.raw = raw
    }

    /// Creates a new pointer from the given memory space and offset
    public init(memorySpace: MemorySpace, offset: UInt32) {
        self.raw = UnsafeGuestRawPointer<MemorySpace>(memorySpace: memorySpace, offset: offset)
    }

    /// Executes the given closure with a mutable pointer to the host memory region mapped as guest memory.
    public func withHostPointer<R, E: Error>(count: Int, _ body: (UnsafeMutableBufferPointer<Pointee>) throws(E) -> R) throws(E) -> R {
        let result = raw.withHostPointer(count: MemoryLayout<Pointee>.stride * count) { raw -> Result<R, E> in
            return Result<R, E>.catchError(failure: E.self) { () throws(E) -> R in
                try body(raw.assumingMemoryBound(to: Pointee.self))
            }
        }
        return try result.get()
    }
}

extension Result {
    static func catchError(
        failure: Failure.Type,
        catching body: () throws(Failure) -> Success
    ) -> Result<Success, Failure> {
        do {
            return  .success(try body())
        } catch {
            return .failure(error)
        }
    }
}

/// A pointee-bound interface to a buffer of elements stored contiguously in guest memory
public struct UnsafeGuestBufferPointer<Pointee: GuestPointee, MemorySpace: GuestMemory> {
    /// A pointer to the first element of the buffer
    public let baseAddress: UnsafeGuestPointer<Pointee, MemorySpace>
    /// The number of elements in the buffer
    public let count: UInt32

    /// Creates a new buffer from the given base address and count
    public init(baseAddress: UnsafeGuestPointer<Pointee, MemorySpace>, count: UInt32) {
        self.baseAddress = baseAddress
        self.count = count
    }

    /// Executes the given closure with a mutable buffer pointer to the host memory region mapped as guest memory.
    public func withHostPointer<R, E: Error>(_ body: (UnsafeMutableBufferPointer<Pointee>) throws(E) -> R) throws(E) -> R {
        try baseAddress.withHostPointer(count: Int(count)) { baseAddress throws(E) -> R in
            try body(baseAddress)
        }
    }
}