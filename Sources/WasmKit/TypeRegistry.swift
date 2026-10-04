import WasmParser
import WasmTypes

// # The type registry
//
// Under the GC proposal, a type a module defines is identified by its
// recursion group: two defined types are the same type if they sit at the
// same position in recursion groups that are structurally identical, where a
// reference to a member of the same group compares by its position in the
// group and a reference to any other type compares by that type's own
// identity. Finality and declared supertypes are part of the structure.
//
// Each engine has a registry, which gives each distinct defined type a
// canonical ID, a `UInt32` shared by every module and store of the engine.
// Inside the engine a concrete heap type carries this ID instead of a
// module-relative index, so two concrete types are equal exactly when their IDs
// are, and a function type's ID is what `InternedFuncType` holds. Registrations
// are never removed.
//
// An ID also tells the kind of its type: bit 27 is set for a function type and
// bit 28 for an array type, and neither for a struct type. So the hierarchy of
// a concrete type, and whether it is a subtype of an abstract type, need no
// lookup; the entry is at the ID with those bits cleared.
//
// Each type also records its "display": the IDs of its declared supertypes
// from the root of its hierarchy down to the type itself. `A <: B` for
// concrete types then means that A's display has B at B's depth, which takes
// constant time.

/// The canonical form of every type definition registered in an engine.
final class TypeRegistry: @unchecked Sendable {
    /// Set in the ID of a function type.
    static let functionTypeBit: UInt32 = 1 << 27
    /// Set in the ID of an array type.
    static let arrayTypeBit: UInt32 = 1 << 28

    /// The kind bits of the ID of a type with the given body.
    static func kindBits(_ body: CompositeType) -> UInt32 {
        switch body {
        case .function: return functionTypeBit
        case .structType: return 0
        case .arrayType: return arrayTypeBit
        }
    }

    /// The position of a type's entry, without the kind bits of its ID.
    private static func index(_ id: UInt32) -> Int {
        Int(id & (functionTypeBit - 1))
    }

    /// A registered type definition.
    struct Entry {
        /// The definition, with every concrete heap type in it a canonical ID.
        let subType: SubType
        /// The IDs of the type's supertypes from the root, ending with the type itself.
        let display: [UInt32]
        /// Where the fields of an object of a struct type are.
        let structLayout: StructLayout?
        /// Whether the elements of an array type may hold references to objects.
        let isArrayElementTraced: Bool

        init(subType: SubType, display: [UInt32]) {
            self.subType = subType
            self.display = display
            func isTraced(_ storage: StorageType) -> Bool {
                guard case .value(.ref(let referenceType)) = storage else { return false }
                switch referenceType.heapType {
                case .abstract(let abstract): return abstract != .funcRef && abstract != .noFunc
                case .concrete(let id): return id & TypeRegistry.functionTypeBit == 0
                }
            }
            switch subType.body {
            case .structType(let structType):
                self.structLayout = StructLayout(structType, isTraced: isTraced)
                self.isArrayElementTraced = false
            case .arrayType(let arrayType):
                self.structLayout = nil
                self.isArrayElementTraced = isTraced(arrayType.element.storage)
            case .function:
                self.structLayout = nil
                self.isArrayElementTraced = false
            }
        }

        var depth: Int { display.count - 1 }

        /// How the elements of an array type are stored.
        var arrayElement: FieldStorage? {
            guard case .arrayType(let arrayType) = subType.body else { return nil }
            return FieldStorage(arrayType.element.storage)
        }
    }

    /// Marks a reference to a member of the recursion group being registered,
    /// by its position in the group. Canonical IDs never have this bit set.
    private static let groupRelativeBit: UInt32 = 1 << 31

    private static let pageSize = 1 << 12
    private static let pageCount = 1 << 15

    private struct State {
        /// The first ID of each registered group, keyed by the group with its
        /// own members referenced by position.
        var groups: [[SubType]: UInt32] = [:]
        var count: UInt32 = 0
    }

    // `var` because the single-threaded PlatformMutex fallback mutates in
    // place; the mutex itself guarantees exclusivity.
    nonisolated(unsafe) private var state = PlatformMutex(State())

    /// Entries in fixed-size pages that never move, so that a reader holding
    /// an ID can look it up without taking the lock: an ID is only handed out
    /// after its entry is written, under the lock.
    private let pages: UnsafeMutablePointer<UnsafeMutablePointer<Entry>?>

    init() {
        pages = .allocate(capacity: Self.pageCount)
        pages.initialize(repeating: nil, count: Self.pageCount)
    }

    /// The entry of a registered type.
    func entry(_ id: UInt32) -> Entry {
        let index = Self.index(id)
        let page = pages[index / Self.pageSize].unsafelyUnwrapped
        return page[index % Self.pageSize]
    }

    func subType(_ id: UInt32) -> SubType { entry(id).subType }

    /// The function type with the given ID.
    func functionType(_ id: UInt32) -> FunctionType {
        guard case .function(let type) = entry(id).subType.body else {
            preconditionFailure("Type \(id) is not a function type")
        }
        return type
    }

    /// Registers a recursion group and returns the canonical IDs of its members.
    ///
    /// - Parameters:
    ///   - group: The group, with module-relative type indices.
    ///   - firstIndex: The module-relative index of the group's first member.
    ///   - resolve: The canonical ID of a type defined before the group.
    /// - Throws: An error if the group is invalid, for example if a type refers
    ///   to a later group or declares an unsound supertype.
    func register(
        _ group: RecursiveGroup, firstIndex: UInt32, resolve: (UInt32) throws(WasmKitError) -> UInt32
    ) throws(WasmKitError) -> [UInt32] {
        let size = UInt32(group.types.count)
        let key = try group.types.map { (type) throws(WasmKitError) in
            try type.mappingTypeIndices { (index) throws(WasmKitError) -> UInt32 in
                if index >= firstIndex, index - firstIndex < size {
                    return Self.groupRelativeBit | (index - firstIndex)
                }
                guard index < firstIndex else {
                    throw WasmKitError(message: .unknownType(index))
                }
                return try resolve(index)
            }
        }
        // Supertypes must be defined before the type that declares them.
        for (position, type) in key.enumerated() {
            for supertype in type.supertypes where supertype & Self.groupRelativeBit != 0 {
                guard supertype & ~Self.groupRelativeBit < UInt32(position) else {
                    throw WasmKitError(message: .unknownType(firstIndex + UInt32(position)))
                }
            }
        }
        return try register(key: key)
    }

    /// Registers a function type that is the only member of its group, final
    /// and without supertypes, as every function type the host gives is.
    func intern(_ type: FunctionType) -> InternedFuncType {
        let key = [SubType(isFinal: true, supertypes: [], body: .function(type))]
        // Such a group is always valid.
        let id = try! register(key: key)[0]
        return InternedFuncType(id: id)
    }

    func resolve(_ type: InternedFuncType) -> FunctionType {
        functionType(type.id)
    }

    private func register(key: [SubType]) throws(WasmKitError) -> [UInt32] {
        try state.withLock { (state) throws(WasmKitError) -> [UInt32] in
            let ids = { (base: UInt32) in key.indices.map { base + UInt32($0) | Self.kindBits(key[$0].body) } }
            if let base = state.groups[key] {
                return ids(base)
            }
            let base = state.count
            guard Int(base) + key.count <= Self.pageSize * Self.pageCount else {
                throw WasmKitError("too many types")
            }
            let entries = try Self.makeEntries(key: key, base: base, lookup: self.entry)
            for (offset, entry) in entries.enumerated() {
                let id = Int(base) + offset
                if pages[id / Self.pageSize] == nil {
                    pages[id / Self.pageSize] = .allocate(capacity: Self.pageSize)
                }
                (pages[id / Self.pageSize].unsafelyUnwrapped + id % Self.pageSize).initialize(to: entry)
            }
            state.count += UInt32(key.count)
            state.groups[key] = base
            return ids(base)
        }
    }

    /// Builds and validates the entries of a group that gets IDs from `base`.
    private static func makeEntries(
        key: [SubType], base: UInt32, lookup: @escaping (UInt32) -> Entry
    ) throws(WasmKitError) -> [Entry] {
        func id(ofMember position: UInt32) -> UInt32 {
            base + position | kindBits(key[Int(position)].body)
        }
        let types = key.map { type in
            type.mappingTypeIndices { index in
                index & groupRelativeBit != 0 ? id(ofMember: index & ~groupRelativeBit) : index
            }
        }
        var entries: [Entry] = []
        func entry(_ id: UInt32) -> Entry {
            Self.index(id) >= Int(base) ? entries[Self.index(id) - Int(base)] : lookup(id)
        }
        // Displays first: a field of a member may refer to a later member whose
        // subtyping the checks below need.
        for (offset, type) in types.enumerated() {
            guard type.supertypes.count <= 1 else {
                throw WasmKitError("multiple supertypes are not supported")
            }
            let display = (type.supertypes.first.map { entry($0).display } ?? []) + [id(ofMember: UInt32(offset))]
            entries.append(Entry(subType: type, display: display))
        }
        let context = SubtypingContext(entry: entry)
        for type in types {
            guard let supertypeID = type.supertypes.first else { continue }
            let supertype = entry(supertypeID).subType
            guard !supertype.isFinal else {
                throw WasmKitError("type mismatch: cannot declare a subtype of final type \(supertypeID)")
            }
            guard context.isSubtype(type.body, of: supertype.body) else {
                throw WasmKitError("type mismatch: invalid declared supertype \(supertypeID)")
            }
        }
        return entries
    }

    func isSubtype(_ type: HeapType, of other: HeapType) -> Bool {
        SubtypingContext(entry: entry).isSubtype(type, of: other)
    }
}

/// Subtyping between canonical types, with the entries of concrete types
/// looked up by `entry`.
struct SubtypingContext {
    let entry: (UInt32) -> TypeRegistry.Entry

    /// The abstract type a concrete type is directly below.
    static func abstractKind(of id: UInt32) -> AbstractHeapType {
        if id & TypeRegistry.functionTypeBit != 0 { return .funcRef }
        if id & TypeRegistry.arrayTypeBit != 0 { return .arrayRef }
        return .structRef
    }

    func isSubtype(_ type: HeapType, of other: HeapType) -> Bool {
        if type == other { return true }
        switch (type, other) {
        case (.concrete(let id), .concrete(let otherID)):
            let display = entry(id).display
            let otherDepth = entry(otherID).depth
            return otherDepth < display.count && display[otherDepth] == otherID
        case (.concrete(let id), .abstract(let abstract)):
            return Self.isSubtype(Self.abstractKind(of: id), of: abstract)
        case (.abstract(let abstract), .concrete(let id)):
            switch Self.abstractKind(of: id) {
            case .funcRef: return abstract == .noFunc
            default: return abstract == .noneRef
            }
        case (.abstract(let abstract), .abstract(let otherAbstract)):
            return Self.isSubtype(abstract, of: otherAbstract)
        }
    }

    /// Subtyping between abstract heap types.
    static func isSubtype(_ type: AbstractHeapType, of other: AbstractHeapType) -> Bool {
        if type == other { return true }
        switch (type, other) {
        case (.i31, .eq), (.structRef, .eq), (.arrayRef, .eq),
            (.i31, .any), (.structRef, .any), (.arrayRef, .any), (.eq, .any),
            (.noneRef, .any), (.noneRef, .eq), (.noneRef, .i31), (.noneRef, .structRef), (.noneRef, .arrayRef),
            (.noFunc, .funcRef), (.noExtern, .externRef), (.noExn, .exnRef):
            return true
        default:
            return false
        }
    }

    func isSubtype(_ type: ReferenceType, of other: ReferenceType) -> Bool {
        if type == other { return true }
        guard other.isNullable || !type.isNullable else { return false }
        return isSubtype(type.heapType, of: other.heapType)
    }

    func isSubtype(_ type: ValueType, of other: ValueType) -> Bool {
        if type == other { return true }
        guard case .ref(let reference) = type, case .ref(let otherReference) = other else { return false }
        return isSubtype(reference, of: otherReference)
    }

    func isSubtype(_ type: StorageType, of other: StorageType) -> Bool {
        switch (type, other) {
        case (.packed(let packed), .packed(let otherPacked)): return packed == otherPacked
        case (.value(let value), .value(let otherValue)): return isSubtype(value, of: otherValue)
        default: return false
        }
    }

    /// A mutable field must have the same type as the field it overrides; an
    /// immutable one may be narrower.
    func isSubtype(_ field: FieldType, of other: FieldType) -> Bool {
        guard field.isMutable == other.isMutable else { return false }
        if field.isMutable {
            return field.storage == other.storage
        }
        return isSubtype(field.storage, of: other.storage)
    }

    func isSubtype(_ type: CompositeType, of other: CompositeType) -> Bool {
        switch (type, other) {
        case (.function(let function), .function(let otherFunction)):
            guard function.parameters.count == otherFunction.parameters.count,
                function.results.count == otherFunction.results.count
            else { return false }
            return zip(otherFunction.parameters, function.parameters).allSatisfy { isSubtype($0, of: $1) }
                && zip(function.results, otherFunction.results).allSatisfy { isSubtype($0, of: $1) }
        case (.structType(let structType), .structType(let otherStruct)):
            guard structType.fields.count >= otherStruct.fields.count else { return false }
            return zip(structType.fields, otherStruct.fields).allSatisfy { isSubtype($0, of: $1) }
        case (.arrayType(let arrayType), .arrayType(let otherArray)):
            return isSubtype(arrayType.element, of: otherArray.element)
        default:
            return false
        }
    }
}

extension HeapType {
    /// Applies `transform` to the index of a concrete heap type.
    fileprivate func mappingTypeIndex<E: Error>(_ transform: (UInt32) throws(E) -> UInt32) throws(E) -> HeapType {
        guard case .concrete(let index) = self else { return self }
        return .concrete(typeIndex: try transform(index))
    }
}

extension ValueType {
    fileprivate func mappingTypeIndices<E: Error>(_ transform: (UInt32) throws(E) -> UInt32) throws(E) -> ValueType {
        guard case .ref(let reference) = self, case .concrete = reference.heapType else { return self }
        return .ref(ReferenceType(isNullable: reference.isNullable, heapType: try reference.heapType.mappingTypeIndex(transform)))
    }
}

extension FieldType {
    fileprivate func mappingTypeIndices<E: Error>(_ transform: (UInt32) throws(E) -> UInt32) throws(E) -> FieldType {
        guard case .value(let value) = storage else { return self }
        return FieldType(storage: .value(try value.mappingTypeIndices(transform)), isMutable: isMutable)
    }
}

extension SubType {
    /// Applies `transform` to every type index in the definition: its
    /// supertypes and the concrete heap types in its body.
    fileprivate func mappingTypeIndices<E: Error>(_ transform: (UInt32) throws(E) -> UInt32) throws(E) -> SubType {
        let body: CompositeType
        switch self.body {
        case .function(let function):
            var parameters: [ValueType] = []
            for parameter in function.parameters { parameters.append(try parameter.mappingTypeIndices(transform)) }
            var results: [ValueType] = []
            for result in function.results { results.append(try result.mappingTypeIndices(transform)) }
            body = .function(FunctionType(parameters: parameters, results: results))
        case .structType(let structType):
            var fields: [FieldType] = []
            for field in structType.fields { fields.append(try field.mappingTypeIndices(transform)) }
            body = .structType(StructType(fields: fields))
        case .arrayType(let arrayType):
            body = .arrayType(ArrayType(element: try arrayType.element.mappingTypeIndices(transform)))
        }
        var supertypes: [UInt32] = []
        for supertype in self.supertypes { supertypes.append(try transform(supertype)) }
        return SubType(isFinal: isFinal, supertypes: supertypes, body: body)
    }
}
