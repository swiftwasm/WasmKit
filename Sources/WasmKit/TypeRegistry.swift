import Synchronization
import WasmParser
import WasmTypes

extension WasmKitError.Message {
    static func tooManyTypes(limit: Int) -> Self {
        Self("too many types: an engine holds at most \(limit), set by EngineConfiguration.maxTypeCount")
    }
}

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

        var depth: Int { display.count - 1 }
    }

    /// Marks a reference to a member of the recursion group being registered,
    /// by its position in the group. Canonical IDs never have this bit set.
    private static let groupRelativeBit: UInt32 = 1 << 31

    /// The most types a registry can hold, which keeps every ID below the kind bits.
    static let maxCapacity = Int(functionTypeBit)

    #if _pointerBitWidth(_32)
        private static let pageSize = 1 << 8
        // A page table of 256 pointers, small enough for a microcontroller's heap.
        static let defaultCapacity = 1 << 16
    #else
        private static let pageSize = 1 << 12
        static let defaultCapacity = maxCapacity
    #endif

    private struct State {
        /// The first ID of each registered group, keyed by the group with its
        /// own members referenced by position.
        var groups: [[SubType]: UInt32] = [:]
    }

    private let state = PlatformMutex(State())

    /// Entries in fixed-size pages that never move, so that a reader holding
    /// an ID can look it up without taking the lock.
    private let pages: UnsafeMutablePointer<UnsafeMutablePointer<Entry>?>

    private let capacity: Int

    /// The number of registered types. A host-built type or a function of another engine can carry an ID at or
    /// past it.
    private let registeredCount = Atomic<UInt32>(0)

    init(capacity: Int) {
        precondition(
            (1...Self.maxCapacity).contains(capacity),
            "EngineConfiguration.maxTypeCount must be between 1 and \(Self.maxCapacity)"
        )
        self.capacity = capacity
        let pageCount = (capacity + Self.pageSize - 1) / Self.pageSize
        pages = .allocate(capacity: pageCount)
        pages.initialize(repeating: nil, count: pageCount)
    }

    deinit {
        let count = Int(registeredCount.load(ordering: .relaxed))
        for pageIndex in 0..<(count + Self.pageSize - 1) / Self.pageSize {
            let page = pages[pageIndex].unsafelyUnwrapped
            page.deinitialize(count: min(Self.pageSize, count - pageIndex * Self.pageSize))
            page.deallocate()
        }
        pages.deallocate()
    }

    /// The entry of a registered type.
    func entry(_ id: UInt32) -> Entry {
        guard let entry = registeredEntry(id, count: loadRegisteredCount()) else {
            preconditionFailure("Type \(id) is not registered")
        }
        return entry
    }

    private func loadRegisteredCount() -> Int {
        Int(registeredCount.load(ordering: .acquiring))
    }

    /// The entry of `id`, if `id` is the ID of one of the first `count` registered types.
    private func registeredEntry(_ id: UInt32, count: Int) -> Entry? {
        guard Self.index(id) < count else { return nil }
        let entry = uncheckedEntry(id)
        return entry.display.last == id ? entry : nil
    }

    private func uncheckedEntry(_ id: UInt32) -> Entry {
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
                    throw WasmKitError(message: .unknownType(firstIndex + (supertype & ~Self.groupRelativeBit)))
                }
            }
        }
        return try register(key: key, declaredSupertypes: group.types.map(\.supertypes))
    }

    /// Registers a function type that is the only member of its group, final
    /// and without supertypes, as every function type the host gives is.
    ///
    /// - Throws: An error if the type refers to a type that is not registered,
    ///   or if the registry is full.
    func intern(_ type: FunctionType) throws(WasmKitError) -> InternedFuncType {
        let key = [try SubType(isFinal: true, supertypes: [], body: .function(type)).mappingTypeIndices(registeredID)]
        return InternedFuncType(id: try register(key: key, declaredSupertypes: [[]])[0])
    }

    /// Throws "unknown type" if `type` refers to a type that is not registered.
    func checkRegistered(_ type: ValueType) throws(WasmKitError) {
        _ = try type.mappingTypeIndices(registeredID)
    }

    private func registeredID(_ id: UInt32) throws(WasmKitError) -> UInt32 {
        guard registeredEntry(id, count: loadRegisteredCount()) != nil else {
            throw WasmKitError(message: .unknownType(id))
        }
        return id
    }

    func resolve(_ type: InternedFuncType) -> FunctionType {
        functionType(type.id)
    }

    private func register(key: [SubType], declaredSupertypes: [[UInt32]]) throws(WasmKitError) -> [UInt32] {
        try state.withLock { (state) throws(WasmKitError) -> [UInt32] in
            let ids = { (base: UInt32) in key.indices.map { base + UInt32($0) | Self.kindBits(key[$0].body) } }
            if let base = state.groups[key] {
                return ids(base)
            }
            let base = registeredCount.load(ordering: .relaxed)
            guard Int(base) + key.count <= capacity else {
                throw WasmKitError(message: .tooManyTypes(limit: capacity))
            }
            let entries = try Self.makeEntries(
                key: key, declaredSupertypes: declaredSupertypes, base: base, lookup: self.entry)
            for (offset, entry) in entries.enumerated() {
                let id = Int(base) + offset
                if pages[id / Self.pageSize] == nil {
                    pages[id / Self.pageSize] = .allocate(capacity: Self.pageSize)
                }
                (pages[id / Self.pageSize].unsafelyUnwrapped + id % Self.pageSize).initialize(to: entry)
            }
            registeredCount.store(base + UInt32(key.count), ordering: .releasing)
            state.groups[key] = base
            return ids(base)
        }
    }

    /// Builds and validates the entries of a group that gets IDs from `base`.
    /// `declaredSupertypes` holds each member's supertypes as its module numbers
    /// them, for error messages.
    private static func makeEntries(
        key: [SubType], declaredSupertypes: [[UInt32]], base: UInt32, lookup: @escaping (UInt32) -> Entry
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
        for (offset, type) in types.enumerated() {
            guard let supertypeID = type.supertypes.first else { continue }
            let supertype = entry(supertypeID).subType
            let declaredSupertype = declaredSupertypes[offset][0]
            guard !supertype.isFinal else {
                throw WasmKitError("type mismatch: cannot declare a subtype of final type \(declaredSupertype)")
            }
            guard context.isSubtype(type.body, of: supertype.body) else {
                throw WasmKitError("type mismatch: invalid declared supertype \(declaredSupertype)")
            }
        }
        return entries
    }

    func isSubtype(_ type: HeapType, of other: HeapType) -> Bool {
        if case .concrete(let id) = type, case .concrete(let otherID) = other {
            let count = loadRegisteredCount()
            guard registeredEntry(id, count: count) != nil, registeredEntry(otherID, count: count) != nil else {
                return id == otherID
            }
        }
        return SubtypingContext(entry: uncheckedEntry).isSubtype(type, of: other)
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
