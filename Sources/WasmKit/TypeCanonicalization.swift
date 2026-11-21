import WasmParser
import WasmTypes

// # Canonical types
//
// A concrete heap type in a module, `(ref $t)`, names a type by its index in
// that module's type section. Types are compared structurally, also across
// modules, by their recursion groups (see TypeRegistry.swift).
//
// Inside the engine, a concrete heap type therefore carries the canonical type
// ID the registry gives the type instead of a module-relative index, so two
// types are equivalent exactly when their canonical IDs are equal.
//
// Canonical types reuse `HeapType.concrete(typeIndex:)`, so the same Swift
// value means a module index in parsed `Module` data and a canonical ID in
// everything the translator and the runtime see: function entities, globals,
// tables, element segments and `Function.type`. A type without concrete heap
// types is its own canonical form. Types given by the host must be canonical
// already: creating a host function, tag, global or table checks that every
// concrete heap type in its type is a registered type.

extension WasmKitError.Message {
    static func unknownType(_ index: UInt32) -> Self {
        Self("unknown type \(index)")
    }
}

/// Maps the type indices of one module to canonical type IDs.
@_spi(Fuzzing)
public struct TypeCanonicalizer {
    /// The canonical ID of each type in the module's type section. The ID of a
    /// struct or array type is stored as an `InternedFuncType` too, but names no function type.
    let typeIDs: [InternedFuncType]

    /// Canonicalizes a module's type section.
    ///
    /// Throws "unknown type" if a type refers to a type defined in a later
    /// recursion group, and an error if a declared supertype is invalid.
    init(typeSection: TypeSection, registry: TypeRegistry) throws(WasmKitError) {
        var typeIDs: [InternedFuncType] = []
        typeIDs.reserveCapacity(typeSection.count)
        for group in typeSection.recursiveGroups {
            let ids = try registry.register(group, firstIndex: UInt32(typeIDs.count)) { (index) throws(WasmKitError) in
                typeIDs[Int(index)].id
            }
            typeIDs.append(contentsOf: ids.map { InternedFuncType(id: $0) })
        }
        self.typeIDs = typeIDs
    }

    /// Canonicalizes the type section of `module`, registering its types in `engine`.
    ///
    /// - Throws: `WasmKitError` if a type refers to a type defined in a later
    ///   recursion group, if a declared supertype is invalid, or if the engine
    ///   already holds `EngineConfiguration.maxTypeCount` types.
    @_spi(Fuzzing)
    public init(module: Module, engine: Engine) throws(WasmKitError) {
        try self.init(typeSection: module.types, registry: engine.typeRegistry)
    }

    init(typeIDs: [InternedFuncType]) {
        self.typeIDs = typeIDs
    }

    func canonicalID(of index: TypeIndex) throws(WasmKitError) -> InternedFuncType {
        guard Int(index) < typeIDs.count else {
            throw WasmKitError(message: .unknownType(index))
        }
        return typeIDs[Int(index)]
    }

    func canonicalize(_ heapType: HeapType) throws(WasmKitError) -> HeapType {
        switch heapType {
        case .abstract: return heapType
        case .concrete(let index): return .concrete(typeIndex: try canonicalID(of: index).id)
        }
    }

    func canonicalize(_ type: ReferenceType) throws(WasmKitError) -> ReferenceType {
        guard case .concrete = type.heapType else { return type }
        return ReferenceType(isNullable: type.isNullable, heapType: try canonicalize(type.heapType))
    }

    func canonicalize(_ type: ValueType) throws(WasmKitError) -> ValueType {
        guard case .ref(let referenceType) = type else { return type }
        return .ref(try canonicalize(referenceType))
    }

    func canonicalize(_ types: [ValueType]) throws(WasmKitError) -> [ValueType] {
        // Most types refer to no other type; keep them without copying.
        guard types.contains(where: \.hasConcreteHeapType) else { return types }
        var result: [ValueType] = []
        result.reserveCapacity(types.count)
        for type in types {
            result.append(try canonicalize(type))
        }
        return result
    }

    @_spi(Fuzzing)
    public func canonicalize(_ type: FunctionType) throws(WasmKitError) -> FunctionType {
        guard type.parameters.contains(where: \.hasConcreteHeapType) || type.results.contains(where: \.hasConcreteHeapType) else {
            return type
        }
        return FunctionType(parameters: try canonicalize(type.parameters), results: try canonicalize(type.results))
    }

    @_spi(Fuzzing)
    public func canonicalize(_ type: GlobalType) throws(WasmKitError) -> GlobalType {
        GlobalType(mutability: type.mutability, valueType: try canonicalize(type.valueType))
    }

    @_spi(Fuzzing)
    public func canonicalize(_ type: TableType) throws(WasmKitError) -> TableType {
        TableType(elementType: try canonicalize(type.elementType), limits: type.limits)
    }
}

extension ValueType {
    /// Whether the type refers to a type in a type section.
    fileprivate var hasConcreteHeapType: Bool {
        guard case .ref(let referenceType) = self, case .concrete = referenceType.heapType else { return false }
        return true
    }
}
