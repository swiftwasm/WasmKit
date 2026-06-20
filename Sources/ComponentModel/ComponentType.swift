public struct ComponentTypeIndex: Hashable {
    public init(rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    public let rawValue: UInt32
}

public struct ComponentIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

public struct ComponentInstanceIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

public struct ComponentFuncIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

public struct CoreInstanceIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

public struct CoreModuleIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

public enum CoreDefSort: String {
    case `func`
    case table
    case memory
    case global
    case type
    case module
    case instance
}

public enum ComponentDefSort {
    case core(CoreDefSort)
    case `func`
    case value
    case type
    case component
    case instance
}

/// Primitive value types that can be encoded inline in valtypes.
/// Corresponds to `primvaltype` in the Component Model binary spec.
public enum ComponentPrimValType: Hashable {
    case bool
    case s8
    case s16
    case s32
    case s64
    case u8
    case u16
    case u32
    case u64
    case float32
    case float64
    case char
    case string
    case errorContext
}

/// A value type reference: either a type index or an inline primitive.
/// Corresponds to `valtype` in the Component Model binary spec:
/// `valtype ::= i:<typeidx> | pvt:<primvaltype>`
public enum ComponentValType: Hashable {
    case index(ComponentTypeIndex)
    case primitive(ComponentPrimValType)

    /// Resolve this value-type reference to a definition type: inline primitives
    /// become `.inlined(.primitive(...))`; type indices are looked up via `resolveType`.
    package func resolve(
        _ resolveType: (ComponentTypeIndex) throws -> ComponentDefValType
    ) rethrows -> ComponentDefValType {
        switch self {
        case .primitive(let prim): return .inlined(.primitive(prim))
        case .index(let idx): return try resolveType(idx)
        }
    }
}

public enum ComponentDefValType: Hashable {
    /// A value type: a type index or an inline primitive.
    case inlined(ComponentValType)

    case list(ComponentValType)
    case tuple([ComponentValType])
    case option(ComponentValType)
    case result(ok: ComponentValType?, error: ComponentValType?)
    case future(ComponentValType?)
    case stream(element: ComponentValType?, end: ComponentValType?)

    // Named type declarations

    case record([ComponentRecordField])
    case flags([String])
    case `enum`([String])
    case variant([ComponentCaseField])
    case resource(destructor: ComponentFuncIndex)

    /// Construct an inline-primitive value type.
    public static func primitive(_ type: ComponentPrimValType) -> Self { .inlined(.primitive(type)) }

    /// Construct a type-index value type.
    public static func indexed(_ index: ComponentTypeIndex) -> Self { .inlined(.index(index)) }

    /// `true` if this is an inline-primitive value type.
    package var isPrimitive: Bool {
        guard case .inlined(.primitive) = self else { return false }
        return true
    }
}

public struct ComponentFuncType: Hashable {
    public init(params: [ComponentFuncType.Param], result: ComponentDefValType?) {
        self.params = params
        self.result = result
    }

    public struct Param: Hashable {
        public init(name: String, type: ComponentDefValType) {
            self.name = name
            self.type = type
        }

        public let name: String
        public let type: ComponentDefValType
    }
    public let params: [Param]
    public let result: ComponentDefValType?
}

public struct ComponentRecordField: Hashable {
    public let name: String
    public let type: ComponentValType

    public init(name: String, type: ComponentValType) {
        self.name = name
        self.type = type
    }
}

public struct ComponentCaseField: Hashable {
    public let name: String
    public let type: ComponentValType?

    public init(name: String, type: ComponentValType?) {
        self.name = name
        self.type = type
    }
}

/// String encoding options for the canonical ABI.
public enum ComponentStringEncoding {
    case utf8
    case utf16
    case latin1UTF16
}

/// Runtime representation of component values.
/// These are the values that flow through component function boundaries.
public indirect enum ComponentValue {
    // Primitives
    case bool(Bool)
    case s8(Int8)
    case s16(Int16)
    case s32(Int32)
    case s64(Int64)
    case u8(UInt8)
    case u16(UInt16)
    case u32(UInt32)
    case u64(UInt64)
    case float32(Float)
    case float64(Double)
    case char(Unicode.Scalar)
    case string(String)

    // Composite types
    // TODO: store strings in an interner, create a resizable bitset type for `case flags`
    case list([ComponentValue])
    case record([(name: String, value: ComponentValue)])
    case variant(caseName: String, payload: ComponentValue?)
    case tuple([ComponentValue])
    case flags(Set<String>)
    case `enum`(String)
    case option(ComponentValue?)
    case result(ok: ComponentValue?, error: ComponentValue?)

    // Resource handles (future extension)
    // case own(ResourceHandle)
    // case borrow(ResourceHandle)
}
