// # Host access to GC objects
//
// The host creates structs and arrays of types it registers with an engine,
// reads and writes their fields, and inspects the structs and arrays it gets
// from WebAssembly. A type the host registers is a final type without
// supertypes in a recursion group of its own, so it is the same type as a
// module's `(type (struct ...))` with the same fields, and objects pass between
// the two freely. Its fields cannot refer to concrete types.
//
// Every reference the host holds is a root handle (see Rooting.swift), so the
// objects stay alive and the handles follow them when the collector moves them.

/// A struct type registered with an engine, whose structs the host can create.
public struct GCStructType: Equatable, Sendable {
    let id: UInt32
    /// The struct's fields.
    public let fields: [FieldType]
}

/// An array type registered with an engine, whose arrays the host can create.
public struct GCArrayType: Equatable, Sendable {
    let id: UInt32
    /// The type of the array's elements.
    public let element: FieldType
}

extension Engine {
    private static func checkAbstract(_ field: FieldType) throws {
        if case .value(.ref(let referenceType)) = field.storage, case .concrete = referenceType.heapType {
            throw WasmKitError("a field of a struct or array type the host registers cannot refer to a concrete type")
        }
    }

    private func register(_ body: CompositeType) throws -> UInt32 {
        let group = RecursiveGroup(types: [SubType(isFinal: true, supertypes: [], body: body)])
        return try typeRegistry.register(group, firstIndex: 0) { (index) throws(WasmKitError) in
            throw WasmKitError(message: .unknownType(index))
        }[0]
    }

    /// Registers a struct type, final and without supertypes.
    public func register(structType: StructType) throws -> GCStructType {
        for field in structType.fields {
            try Self.checkAbstract(field)
        }
        return GCStructType(id: try register(.structType(structType)), fields: structType.fields)
    }

    /// Registers an array type, final and without supertypes.
    public func register(arrayType: ArrayType) throws -> GCArrayType {
        try Self.checkAbstract(arrayType.element)
        return GCArrayType(id: try register(.arrayType(arrayType)), element: arrayType.element)
    }
}

extension GCHeap {
    /// The value of a field, as the host holds it.
    fileprivate func read(_ address: UnsafeRawPointer, _ field: FieldType) -> Value {
        let storage = FieldStorage(field.storage)
        let (lo, hi) = storage.load(from: address)
        switch field.storage.unpacked {
        case .v128: return .v128(V128Storage(lo: lo, hi: hi).value)
        case let type: return exporting(UntypedValue(storage: lo).cast(to: type))
        }
    }

    /// Writes a value the host gives to a field, after checking its type.
    fileprivate func write(_ value: Value, to address: UnsafeMutableRawPointer, _ field: FieldType) throws {
        let value = try importing(value)
        try value.checkType(field.storage.unpacked, heap: self)
        let (lo, hi) = value.slotBits
        FieldStorage(field.storage).store(lo: lo, hi: hi, to: address)
    }

    /// The object that a host's handle refers to, if it is of the given kind.
    fileprivate func object(_ reference: AnyRef, kind: HeapObjectKind) -> UInt32? {
        guard case .ref(.any(let resolved?))? = try? importing(.ref(.any(reference))),
            resolved.storage & 0b11 == 0, resolved.storage != 0
        else { return nil }
        let object = UInt32(truncatingIfNeeded: resolved.storage)
        return self.kind(of: object) == kind ? object : nil
    }
}

/// A struct that the host holds.
public struct StructRef {
    /// The reference that the host passes to WebAssembly.
    public let reference: AnyRef
    let store: Store

    private var heap: GCHeap { store.allocator.gcHeap }

    /// Creates a struct of `type` with the given field values.
    public init(store: Store, type: GCStructType, fields: [Value]) throws {
        guard fields.count == type.fields.count else {
            throw WasmKitError("expected \(type.fields.count) field values, got \(fields.count)")
        }
        let heap = store.allocator.gcHeap
        let layout = heap.typeRegistry.entry(type.id).structLayout.unsafelyUnwrapped
        let object = try heap.allocateForHost(size: layout.size, resourceLimiter: store.resourceLimiter)
        heap.writeHeader(object, type: type.id, kind: .structObject)
        // The values are written after allocating, which may move the objects they refer to.
        for (index, value) in fields.enumerated() {
            try heap.write(value, to: heap.address(object) + layout.fields[index].offset, type.fields[index])
        }
        self.init(reference: AnyRef(storage: heap.makeRoot(object)), store: store)
    }

    init(reference: AnyRef, store: Store) {
        self.reference = reference
        self.store = store
    }

    private func object() throws -> UInt32 {
        guard let object = heap.object(reference, kind: .structObject) else {
            throw WasmKitError("attempted to use a garbage-collected object that has been unrooted")
        }
        return object
    }

    private func field(_ index: Int, of object: UInt32) throws -> (type: FieldType, offset: Int) {
        let entry = heap.typeRegistry.entry(heap.typeID(of: object))
        guard case .structType(let type) = entry.subType.body, type.fields.indices.contains(index) else {
            throw WasmKitError("field index \(index) is out of bounds")
        }
        return (type.fields[index], entry.structLayout.unsafelyUnwrapped.fields[index].offset)
    }

    /// The number of fields.
    public var fieldCount: Int {
        get throws {
            let object = try object()
            guard case .structType(let type) = heap.typeRegistry.entry(heap.typeID(of: object)).subType.body else { return 0 }
            return type.fields.count
        }
    }

    /// The value of field `index`. A packed field is zero-extended to an `i32`.
    public func field(_ index: Int) throws -> Value {
        let object = try object()
        let field = try field(index, of: object)
        return heap.read(heap.address(object) + field.offset, field.type)
    }

    /// Writes `value` to field `index`, which must be mutable. A packed field
    /// takes the low bits of an `i32`.
    public func setField(_ index: Int, _ value: Value) throws {
        let object = try object()
        let field = try field(index, of: object)
        guard field.type.isMutable else {
            throw WasmKitError("field \(index) is immutable")
        }
        try heap.write(value, to: heap.address(object) + field.offset, field.type)
    }
}

/// An array that the host holds.
public struct ArrayRef {
    /// The reference that the host passes to WebAssembly.
    public let reference: AnyRef
    let store: Store

    private var heap: GCHeap { store.allocator.gcHeap }

    /// Creates an array of `type` with `count` elements, each `value`.
    public init(store: Store, type: GCArrayType, repeating value: Value, count: Int) throws {
        guard let count = UInt32(exactly: count) else {
            throw Trap(.outOfGCHeapMemory)
        }
        let heap = store.allocator.gcHeap
        let element = FieldStorage(type.element.storage)
        let (bytes, overflow) = Int(count).multipliedReportingOverflow(by: element.size)
        guard !overflow else {
            throw Trap(.outOfGCHeapMemory)
        }
        let array = try heap.allocateForHost(size: GCHeap.arrayElementsOffset + bytes, resourceLimiter: store.resourceLimiter)
        heap.writeHeader(array, type: type.id, kind: .arrayObject)
        heap.address(array).storeBytes(of: count, toByteOffset: GCHeap.arrayLengthOffset, as: UInt32.self)
        for index in 0..<count {
            try heap.write(value, to: heap.arrayElement(array, at: index, element: element), type.element)
        }
        self.init(reference: AnyRef(storage: heap.makeRoot(array)), store: store)
    }

    init(reference: AnyRef, store: Store) {
        self.reference = reference
        self.store = store
    }

    private func array() throws -> (array: UInt32, element: FieldType) {
        guard let array = heap.object(reference, kind: .arrayObject) else {
            throw WasmKitError("attempted to use a garbage-collected object that has been unrooted")
        }
        guard case .arrayType(let type) = heap.typeRegistry.entry(heap.typeID(of: array)).subType.body else {
            preconditionFailure()
        }
        return (array, type.element)
    }

    private func elementAddress(_ index: Int) throws -> (address: UnsafeMutableRawPointer, element: FieldType) {
        let (array, element) = try array()
        guard let index = UInt32(exactly: index), index < heap.arrayLength(array) else {
            throw Trap(.arrayOutOfBounds)
        }
        return (heap.arrayElement(array, at: index, element: FieldStorage(element.storage)), element)
    }

    /// The number of elements.
    public var count: Int {
        get throws { Int(heap.arrayLength(try array().array)) }
    }

    /// The element at `index`. A packed element is zero-extended to an `i32`.
    public func get(_ index: Int) throws -> Value {
        let (address, element) = try elementAddress(index)
        return heap.read(address, element)
    }

    /// Writes `value` to the element at `index`. The elements must be mutable.
    public func set(_ index: Int, _ value: Value) throws {
        let (address, element) = try elementAddress(index)
        guard element.isMutable else {
            throw WasmKitError("the array's elements are immutable")
        }
        try heap.write(value, to: address, element)
    }
}

extension AnyRef {
    /// The struct this reference refers to, or `nil` if it refers to something else.
    public func asStruct(in store: Store) -> StructRef? {
        guard store.allocator.gcHeap.object(self, kind: .structObject) != nil else { return nil }
        return StructRef(reference: self, store: store)
    }

    /// The array this reference refers to, or `nil` if it refers to something else.
    public func asArray(in store: Store) -> ArrayRef? {
        guard store.allocator.gcHeap.object(self, kind: .arrayObject) != nil else { return nil }
        return ArrayRef(reference: self, store: store)
    }
}
