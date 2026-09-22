import WasmTypes

// Subtyping between canonical types (see TypeCanonicalization.swift), as
// defined by the typed function references proposal:
//
// - A numeric or vector type matches only itself.
// - `(ref null? ht1) <: (ref null ht2)` and `(ref ht1) <: (ref ht2)` iff
//   `ht1 <: ht2`; a nullable reference never matches a non-nullable one.
// - A concrete heap type is a subtype of `func`; two concrete heap types match
//   iff they are the same canonical type.

extension HeapType {
    func isSubtype(of other: HeapType) -> Bool {
        if self == other { return true }
        switch (self, other) {
        case (.concrete, .abstract(.funcRef)): return true
        default: return false
        }
    }
}

extension ReferenceType {
    func isSubtype(of other: ReferenceType) -> Bool {
        if self == other { return true }
        guard other.isNullable || !isNullable else { return false }
        return heapType.isSubtype(of: other.heapType)
    }
}

extension ValueType {
    func isSubtype(of other: ValueType) -> Bool {
        if self == other { return true }
        guard case .ref(let reference) = self, case .ref(let otherReference) = other else { return false }
        return reference.isSubtype(of: otherReference)
    }
}

extension Array where Element == ValueType {
    /// Whether each type is a subtype of the type at the same position in `other`.
    func isSubtype(of other: [ValueType]) -> Bool {
        guard count == other.count else { return false }
        return zip(self, other).allSatisfy { $0.isSubtype(of: $1) }
    }
}
