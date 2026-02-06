public struct ComponentTypeIndex: Hashable {
    package init(rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    package let rawValue: UInt32
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

public enum ComponentValueType: Hashable {
    case bool
    case u8
    case u16
    case u32
    case u64
    case s8
    case s16
    case s32
    case s64
    case float32
    case float64
    case char
    case string
    case errorContext
    case list(ComponentTypeIndex)
    //    case handleOwn(ResourceSyntax)
    //    case handleBorrow(ResourceSyntax)
    case tuple([ComponentTypeIndex])
    case option(ComponentTypeIndex)
    case result(ok: ComponentTypeIndex?, error: ComponentTypeIndex?)
    case future(ComponentTypeIndex?)
    case stream(element: ComponentTypeIndex?, end: ComponentTypeIndex?)

    // Named type declarations

    case record([ComponentRecordField])
    case flags([String])
    case `enum`([String])
    case variant([ComponentCaseField])
    case resource(destructor: ComponentFuncIndex)

    case indexed(ComponentTypeIndex)

    /// Returns true if this is a primitive type that can be inlined in valtypes
    package var isPrimitive: Bool {
        switch self {
        case .bool, .s8, .u8, .s16, .u16, .s32, .u32, .s64, .u64, .float32, .float64, .char, .string, .errorContext:
            return true
        case .list, .tuple, .option, .result, .future, .stream, .record, .flags, .enum, .variant, .resource, .indexed:
            return false
        }
    }
}

public struct ComponentFuncType: Hashable {
    package init(params: [ComponentFuncType.Param], result: ComponentValueType?) {
        self.params = params
        self.result = result
    }

    public struct Param: Hashable {
        package init(name: String, type: ComponentValueType) {
            self.name = name
            self.type = type
        }

        package let name: String
        package let type: ComponentValueType
    }
    package let params: [Param]
    package let result: ComponentValueType?
}

public struct ComponentRecordField: Hashable {
    package let name: String
    package let type: ComponentTypeIndex

    package init(name: String, type: ComponentTypeIndex) {
        self.name = name
        self.type = type
    }
}

public struct ComponentCaseField: Hashable {
    package let name: String
    package let type: ComponentTypeIndex?

    package init(name: String, type: ComponentTypeIndex?) {
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
