public struct ComponentTypeIndex: RawRepresentable, Equatable {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32
}

public struct ComponentFuncIndex: RawRepresentable, Equatable {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32
}

public struct ModuleInstanceIndex: RawRepresentable, Equatable {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32
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

public enum ComponentType: Equatable {
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
}

public struct ComponentRecordField: Equatable {
    let name: String
    let type: ComponentTypeIndex
}

public struct ComponentCaseField: Equatable {
    let name: String
    let type: ComponentTypeIndex?
}
