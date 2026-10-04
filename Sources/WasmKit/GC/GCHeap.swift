import WasmTypes

// # The GC heap
//
// The structs and arrays of a store live in one growable region of memory, its
// GC heap, which is created on the first allocation. A reference to an object
// is the object's byte offset in the region: the region may move when it
// grows, an offset stays valid. Offsets are multiples of 8 and never 0, so in a
// value slot an object reference has its low two bits clear, unlike an i31 or
// a host's external value (see `UntypedValue`).
//
// Every object starts with an 8-byte header: the canonical ID of its type, then
// its kind. An array stores its length after the header and its elements from
// byte 16. A struct stores its fields in declaration order, each at the next
// offset aligned to its size, so a subtype's fields are where its supertype's
// are. A field of reference type takes 8 bytes and holds the reference's
// value-slot bits with the null bit flipped, so that zeroed memory reads as
// null.

/// How a struct field or an array element is stored in an object.
enum FieldStorage: UInt8 {
    case i8, i16, i32, i64, v128, reference

    init(_ storage: StorageType) {
        switch storage {
        case .packed(.i8): self = .i8
        case .packed(.i16): self = .i16
        case .value(.i32), .value(.f32): self = .i32
        case .value(.i64), .value(.f64): self = .i64
        case .value(.v128): self = .v128
        case .value(.ref): self = .reference
        }
    }

    /// The number of bytes the field takes, which is also its alignment.
    var size: Int {
        switch self {
        case .i8: return 1
        case .i16: return 2
        case .i32: return 4
        case .i64, .reference: return 8
        case .v128: return 16
        }
    }

    /// Whether the field's value takes two value slots.
    var isV128: Bool { self == .v128 }

    private static var nullBit: UInt64 { 1 << 63 }

    /// Writes the value of `lo` (and `hi` for a `v128`) to `address`.
    func store(lo: UInt64, hi: UInt64, to address: UnsafeMutableRawPointer) {
        switch self {
        case .i8: address.storeBytes(of: UInt8(truncatingIfNeeded: lo), as: UInt8.self)
        case .i16: address.storeBytes(of: UInt16(truncatingIfNeeded: lo), toByteOffset: 0, as: UInt16.self)
        case .i32: address.storeBytes(of: UInt32(truncatingIfNeeded: lo), as: UInt32.self)
        case .i64: address.storeBytes(of: lo, as: UInt64.self)
        case .reference: address.storeBytes(of: lo ^ Self.nullBit, as: UInt64.self)
        case .v128:
            address.storeBytes(of: lo, as: UInt64.self)
            address.storeBytes(of: hi, toByteOffset: 8, as: UInt64.self)
        }
    }

    /// Reads the value at `address` as value-slot bits, sign-extending a packed
    /// value if `signed`.
    func load(from address: UnsafeRawPointer, signed: Bool = false) -> (lo: UInt64, hi: UInt64) {
        switch self {
        case .i8:
            let value = address.loadUnaligned(as: UInt8.self)
            return (signed ? UInt64(UInt32(bitPattern: Int32(Int8(bitPattern: value)))) : UInt64(value), 0)
        case .i16:
            let value = address.loadUnaligned(as: UInt16.self)
            return (signed ? UInt64(UInt32(bitPattern: Int32(Int16(bitPattern: value)))) : UInt64(value), 0)
        case .i32: return (UInt64(address.loadUnaligned(as: UInt32.self)), 0)
        case .i64: return (address.loadUnaligned(as: UInt64.self), 0)
        case .reference: return (address.loadUnaligned(as: UInt64.self) ^ Self.nullBit, 0)
        case .v128:
            return (address.loadUnaligned(as: UInt64.self), address.loadUnaligned(fromByteOffset: 8, as: UInt64.self))
        }
    }
}

/// Where the fields of a struct type are in its objects.
struct StructLayout {
    struct Field {
        let offset: Int
        let storage: FieldStorage
        /// Whether the field may hold a reference to an object, which the
        /// collector follows. A function reference never does.
        let isTraced: Bool
    }
    let fields: [Field]
    /// The size of an object, header included.
    let size: Int

    /// - Parameter isTraced: Whether a field of the given storage may hold a
    ///   reference to an object.
    init(_ type: StructType, isTraced: (StorageType) -> Bool) {
        self.init(fields: type.fields.map(\.storage), startingAt: GCHeap.headerSize, isTraced: isTraced)
    }

    /// Lays out fields of the given storage from `offset`.
    init(fields storages: [StorageType], startingAt offset: Int, isTraced: (StorageType) -> Bool) {
        var offset = offset
        var fields: [Field] = []
        for storageType in storages {
            let storage = FieldStorage(storageType)
            offset = (offset + storage.size - 1) & ~(storage.size - 1)
            fields.append(Field(offset: offset, storage: storage, isTraced: storage == .reference && isTraced(storageType)))
            offset += storage.size
        }
        self.fields = fields
        self.size = offset
    }
}

/// The kind of a heap object, stored in its header.
enum HeapObjectKind: UInt32 {
    case structObject = 1
    case arrayObject = 2
    /// An exception that a `catch_ref` or `catch_all_ref` clause caught. Its
    /// header has the canonical ID of its tag's function type; the tag's
    /// identity follows, then the payload laid out like struct fields.
    case exceptionObject = 3
}

/// The memory the GC objects of one store live in.
final class GCHeap {
    static let headerSize = 8
    static let arrayLengthOffset = 8
    static let arrayElementsOffset = 16
    static let initialCapacity = 1 << 16

    /// The start of the region, `nil` until the first allocation.
    var base: UnsafeMutableRawPointer?
    var capacity = 0
    /// The offset of the next allocation. The first 8 bytes are never used, so
    /// that no object is at offset 0.
    var top = 8
    /// The offset of the first object. Objects follow each other without gaps
    /// up to `top`.
    var objectsStart: UInt32 = 8
    /// The largest size the region may grow to.
    let maxSize: Int

    /// The stack maps of the store's functions.
    let stackMapTable = GCStackMapTable()
    /// The Wasm frames that called a host function and have not been returned
    /// to yet, with the address the call returns to. The host function may call
    /// back into Wasm, which runs on a stack of its own.
    var suspendedFrames: [(sp: Sp, pc: Pc)] = []
    /// Visits the object references held outside Wasm frames and the heap:
    /// globals, tables and element segments. Set by the store's allocator.
    var visitStoreRoots: ((_ visit: (inout UInt32) -> Void) -> Void)?
    /// Whether every allocation that may collect does, so that a missed root
    /// shows up in testing.
    var isStressMode = false
    /// Which of two offsets the live objects start at after the next stress
    /// collection.
    var stressGapFlag = false

    /// The objects the host holds references to, by root index, with the
    /// generation of the handle that refers to each.
    var hostRoots: [(object: UInt32, generation: UInt32)] = []
    var nextRootGeneration: UInt32 = 1

    /// The registry of the engine, which knows the layout of each object's type.
    let typeRegistry: TypeRegistry

    init(maxSize: Int, typeRegistry: TypeRegistry) {
        self.maxSize = min(maxSize, Int(UInt32.max))
        self.typeRegistry = typeRegistry
    }

    deinit {
        base?.deallocate()
    }

    /// The address of the byte at `offset` in the region.
    @inline(__always)
    func address(_ offset: UInt32) -> UnsafeMutableRawPointer {
        base.unsafelyUnwrapped + Int(offset)
    }

    /// Allocates `size` zeroed bytes, collecting or growing the region if
    /// needed, and returns their offset.
    ///
    /// - Parameter safepoint: The Wasm frame that allocates, where a collection
    ///   may happen, or `nil` if none may.
    func allocate(size: Int, resourceLimiter: any ResourceLimiter, safepoint: GCSafepoint? = nil) throws -> UInt32 {
        try allocate(size: size, resourceLimiter: resourceLimiter, mayCollect: safepoint != nil, safepoint: safepoint)
    }

    /// Allocates for the host, which may collect: the roots are then the frames
    /// suspended in host calls, the store's entities and the host's handles.
    func allocateForHost(size: Int, resourceLimiter: any ResourceLimiter) throws -> UInt32 {
        try allocate(size: size, resourceLimiter: resourceLimiter, mayCollect: true, safepoint: nil)
    }

    private func allocate(
        size: Int, resourceLimiter: any ResourceLimiter, mayCollect: Bool, safepoint: GCSafepoint?
    ) throws -> UInt32 {
        let size = (size + 7) & ~7
        if mayCollect, base != nil, isStressMode || size > capacity - top {
            collect(at: safepoint)
            // Keep at least half the heap free after a collection, so that the
            // next one is as far away as the live data is large.
            let needsRoom = size > capacity - top
            if !isStressMode && (needsRoom || top * 2 > capacity) {
                do {
                    try grow(toFit: size, resourceLimiter: resourceLimiter)
                } catch {
                    if needsRoom { throw error }
                }
            }
        }
        if size > capacity - top {
            try grow(toFit: size, resourceLimiter: resourceLimiter)
        }
        let offset = top
        top += size
        return UInt32(offset)
    }

    private func grow(toFit size: Int, resourceLimiter: any ResourceLimiter) throws {
        let (needed, overflow) = top.addingReportingOverflow(size)
        guard !overflow, needed <= maxSize else {
            throw Trap(.outOfGCHeapMemory)
        }
        let newCapacity = min(max(needed, capacity * 2, Self.initialCapacity), maxSize)
        guard try resourceLimiter.limitGCHeapGrowth(to: newCapacity) else {
            throw Trap(.outOfGCHeapMemory)
        }
        let newBase = UnsafeMutableRawPointer.allocate(byteCount: newCapacity, alignment: 16)
        newBase.initializeMemory(as: UInt8.self, repeating: 0, count: newCapacity)
        if let base {
            newBase.copyMemory(from: base, byteCount: top)
            base.deallocate()
        }
        base = newBase
        capacity = newCapacity
    }

    /// Allocates a struct of the given canonical type with zeroed fields.
    func allocateStruct(
        type: UInt32, layout: StructLayout, resourceLimiter: any ResourceLimiter, safepoint: GCSafepoint? = nil
    ) throws -> UInt32 {
        let object = try allocate(size: layout.size, resourceLimiter: resourceLimiter, safepoint: safepoint)
        writeHeader(object, type: type, kind: .structObject)
        return object
    }

    /// Allocates an array of the given canonical type with `count` zeroed elements.
    func allocateArray(
        type: UInt32, element: FieldStorage, count: UInt32, resourceLimiter: any ResourceLimiter, safepoint: GCSafepoint? = nil
    ) throws -> UInt32 {
        let (bytes, overflow) = Int(count).multipliedReportingOverflow(by: element.size)
        guard !overflow, bytes <= maxSize else {
            throw Trap(.outOfGCHeapMemory)
        }
        let object = try allocate(size: Self.arrayElementsOffset + bytes, resourceLimiter: resourceLimiter, safepoint: safepoint)
        writeHeader(object, type: type, kind: .arrayObject)
        address(object).storeBytes(of: count, toByteOffset: Self.arrayLengthOffset, as: UInt32.self)
        return object
    }

    func writeHeader(_ object: UInt32, type: UInt32, kind: HeapObjectKind) {
        let header = address(object)
        header.storeBytes(of: type, as: UInt32.self)
        header.storeBytes(of: kind.rawValue, toByteOffset: 4, as: UInt32.self)
    }

    static let exceptionTagOffset = 8
    static let exceptionPayloadOffset = 16

    static func exceptionLayout(parameters: [ValueType]) -> StructLayout {
        StructLayout(fields: parameters.map { .value($0) }, startingAt: exceptionPayloadOffset) { storage in
            guard case .value(let type) = storage else { return false }
            return type.mayReferToObject
        }
    }

    /// Allocates an object holding `exception`, whose tag has the function type `tagType`.
    func allocateException(
        _ exception: WasmKitException, tagType: InternedFuncType, resourceLimiter: any ResourceLimiter
    ) throws -> UInt32 {
        let layout = Self.exceptionLayout(parameters: typeRegistry.resolve(tagType).parameters)
        let object = try allocate(size: layout.size, resourceLimiter: resourceLimiter)
        writeHeader(object, type: tagType.id, kind: .exceptionObject)
        let base = address(object)
        base.storeBytes(of: exception.tagIdentity, toByteOffset: Self.exceptionTagOffset, as: Int.self)
        for (field, value) in zip(layout.fields, exception.payload) {
            let (lo, hi) = value.slotBits
            field.storage.store(lo: lo, hi: hi, to: base + field.offset)
        }
        return object
    }

    /// The exception an exception object holds.
    func exception(_ object: UInt32) -> WasmKitException {
        let parameters = typeRegistry.functionType(typeID(of: object)).parameters
        let base = address(object)
        let payload = zip(Self.exceptionLayout(parameters: parameters).fields, parameters).map { field, type -> Value in
            let (lo, hi) = field.storage.load(from: base + field.offset)
            if type == .v128 {
                return .v128(V128Storage(lo: lo, hi: hi).value)
            }
            return UntypedValue(storage: lo).cast(to: type)
        }
        return WasmKitException(
            tagIdentity: base.loadUnaligned(fromByteOffset: Self.exceptionTagOffset, as: Int.self), payload: payload)
    }

    /// The canonical type ID of an object.
    func typeID(of object: UInt32) -> UInt32 {
        address(object).load(as: UInt32.self)
    }

    func kind(of object: UInt32) -> HeapObjectKind {
        HeapObjectKind(rawValue: address(object).load(fromByteOffset: 4, as: UInt32.self)).unsafelyUnwrapped
    }

    func arrayLength(_ array: UInt32) -> UInt32 {
        address(array).load(fromByteOffset: Self.arrayLengthOffset, as: UInt32.self)
    }

    /// The address of element `index` of an array whose elements are `element`.
    func arrayElement(_ array: UInt32, at index: UInt32, element: FieldStorage) -> UnsafeMutableRawPointer {
        address(array) + Self.arrayElementsOffset + Int(index) * element.size
    }
}

extension Store {
    /// The kind of an internal reference: `i31`, `struct` or `array`, or `nil`
    /// for an internalized host value.
    package func kind(of reference: AnyRef) -> AbstractHeapType? {
        if reference.i31 != nil { return .i31 }
        if reference.internalizedValue != nil { return nil }
        guard case .ref(.any(let object?)) = try? allocator.gcHeap.importing(.ref(.any(reference))) else { return nil }
        switch allocator.gcHeap.kind(of: UInt32(truncatingIfNeeded: object.storage)) {
        case .structObject: return .structRef
        case .arrayObject: return .arrayRef
        case .exceptionObject: return .exnRef
        }
    }
}

extension GCHeap {
    /// Calls `visit` with every object reference outside the heap: in the Wasm
    /// frames from `safepoint` on, in the frames that called out to the host,
    /// and in the store's globals, tables and element segments. `visit` may
    /// change the reference.
    func forEachRoot(from safepoint: GCSafepoint?, _ visit: (inout UInt32) -> Void) {
        forEachFrameRootSlot(from: safepoint) { slot in
            guard Self.isObjectReference(slot.pointee) else { return }
            var object = UInt32(truncatingIfNeeded: slot.pointee)
            visit(&object)
            slot.pointee = UInt64(object)
        }
        visitStoreRoots?(visit)
        for index in hostRoots.indices {
            visit(&hostRoots[index].object)
        }
    }

    /// Whether `offset` is the start of an object.
    func isObject(_ offset: UInt32) -> Bool {
        guard offset >= objectsStart, Int(offset) < top, offset & 7 == 0, base != nil else { return false }
        return HeapObjectKind(rawValue: address(offset).load(fromByteOffset: 4, as: UInt32.self)) != nil
    }
}
