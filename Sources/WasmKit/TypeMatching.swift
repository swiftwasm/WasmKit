import WasmTypes

// Subtyping between canonical types (see TypeCanonicalization.swift and
// TypeRegistry.swift):
//
// - A numeric or vector type matches only itself.
// - `(ref null? ht1) <: (ref null ht2)` and `(ref ht1) <: (ref ht2)` iff
//   `ht1 <: ht2`; a nullable reference never matches a non-nullable one.
// - Heap types form four hierarchies: `any` (with `eq`, `i31`, `struct`,
//   `array`, the struct and array types, and `none`), `func` (with the
//   function types and `nofunc`), `extern` (with `noextern`) and `exn` (with
//   `noexn`). A concrete type is a subtype of the types it declares as
//   supertypes, directly or not.

extension HeapType {
    /// Subtyping of canonical heap types. Only two different concrete types
    /// need `registry`, to look up their declared supertypes.
    func isSubtype(of other: HeapType, in registry: TypeRegistry) -> Bool {
        if self == other { return true }
        return registry.isSubtype(self, of: other)
    }
}

extension HeapType {
    /// The abstract type at the top of the heap type's hierarchy: `func`,
    /// `extern`, `exn` or `any`.
    var topType: AbstractHeapType {
        switch self {
        case .abstract(.funcRef), .abstract(.noFunc): return .funcRef
        case .abstract(.externRef), .abstract(.noExtern): return .externRef
        case .abstract(.exnRef), .abstract(.noExn): return .exnRef
        case .abstract(.any), .abstract(.eq), .abstract(.i31), .abstract(.structRef), .abstract(.arrayRef),
            .abstract(.noneRef):
            return .any
        case .concrete(let id):
            return id & TypeRegistry.functionTypeBit != 0 ? .funcRef : .any
        }
    }
}

extension ReferenceType {
    /// The null reference of the canonical type.
    package var nullReference: Reference {
        UntypedValue.nullReference.asReference(self)
    }

    func isSubtype(of other: ReferenceType, in registry: TypeRegistry) -> Bool {
        if self == other { return true }
        guard other.isNullable || !isNullable else { return false }
        return heapType.isSubtype(of: other.heapType, in: registry)
    }
}

extension ValueType {
    /// Whether the type has a default value: zero for numbers and vectors, null
    /// for nullable references.
    var isDefaultable: Bool {
        guard case .ref(let referenceType) = self else { return true }
        return referenceType.isNullable
    }

    func isSubtype(of other: ValueType, in registry: TypeRegistry) -> Bool {
        if self == other { return true }
        guard case .ref(let reference) = self, case .ref(let otherReference) = other else { return false }
        return reference.isSubtype(of: otherReference, in: registry)
    }
}

extension Array where Element == ValueType {
    /// Whether each type is a subtype of the type at the same position in `other`.
    func isSubtype(of other: [ValueType], in registry: TypeRegistry) -> Bool {
        guard count == other.count else { return false }
        return zip(self, other).allSatisfy { $0.isSubtype(of: $1, in: registry) }
    }
}

extension StorageType {
    /// The type of the value a field of this storage holds on the stack: a
    /// packed field is read and written as an `i32`.
    var unpacked: ValueType {
        switch self {
        case .value(let type): return type
        case .packed: return .i32
        }
    }

    var isPacked: Bool {
        guard case .packed = self else { return false }
        return true
    }
}
