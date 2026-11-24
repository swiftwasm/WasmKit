public struct ComponentTypeIndex: Hashable, Sendable {
    public init(rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    public let rawValue: UInt32
}

/// Index into the resource types array within a component.
package struct ResourceTypeIndex: Hashable, Sendable {
    package init(rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    package let rawValue: UInt32
}

package struct ComponentIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

package struct ComponentInstanceIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

package struct ComponentFuncIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

package struct CoreInstanceIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

package struct CoreModuleIndex: Hashable {
    package init(_ int: Int) {
        self.rawValue = UInt32(int)
    }

    package let rawValue: UInt32
}

package enum CoreDefSort: String {
    case `func`
    case table
    case memory
    case global
    case tag
    case type
    case module
    case instance
}

package enum ComponentDefSort {
    case core(CoreDefSort)
    case `func`
    case value
    case type
    case component
    case instance
}

/// Primitive value types that can be encoded inline in valtypes.
/// Corresponds to `primvaltype` in the Component Model binary spec.
package enum ComponentPrimValType: Hashable {
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
package enum ComponentValType: Hashable {
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

package enum ComponentDefValType: Hashable {
    /// A value type: a type index or an inline primitive.
    case inlined(ComponentValType)

    /// A list type with its element type as a valtype (primitive or indexed)
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
    case resource(destructor: ComponentFuncIndex?)

    /// An owned handle to a resource type
    case own(ResourceTypeIndex)
    /// A borrowed handle to a resource type
    case borrow(ResourceTypeIndex)

    /// Construct an inline-primitive value type.
    package static func primitive(_ type: ComponentPrimValType) -> Self { .inlined(.primitive(type)) }

    /// Construct a type-index value type.
    package static func indexed(_ index: ComponentTypeIndex) -> Self { .inlined(.index(index)) }

    /// `true` if this is an inline-primitive value type.
    package var isPrimitive: Bool {
        guard case .inlined(.primitive(_)) = self else {
            return false
        }

        return true
    }
}

package struct ComponentFuncType: Hashable {
    package init(params: [ComponentFuncType.Param], result: ComponentDefValType?) {
        self.init(params: params, result: result, isAsync: false)
    }

    package init(params: [ComponentFuncType.Param], result: ComponentDefValType?, isAsync: Bool) {
        self.params = params
        self.result = result
        self.isAsync = isAsync
    }

    package struct Param: Hashable {
        package init(name: String, type: ComponentDefValType) {
            self.name = name
            self.type = type
        }

        package let name: String
        package let type: ComponentDefValType
    }
    package let params: [Param]
    package let result: ComponentDefValType?

    /// Whether this is an `async` function type (binary opcode `0x43`), as opposed to a
    /// synchronous function type (`0x40`). Async and sync function types with identical
    /// params/results are distinct binary types and must not be deduplicated together.
    package let isAsync: Bool
}

package struct ComponentRecordField: Hashable {
    package let name: String
    package let type: ComponentValType

    package init(name: String, type: ComponentValType) {
        self.name = name
        self.type = type
    }
}

package struct ComponentCaseField: Hashable {
    package let name: String
    package let type: ComponentValType?

    package init(name: String, type: ComponentValType?) {
        self.name = name
        self.type = type
    }
}

/// String encoding options for the canonical ABI.
package enum ComponentStringEncoding {
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
    case resultOk(ComponentValue?)
    case resultErr(ComponentValue?)
}
