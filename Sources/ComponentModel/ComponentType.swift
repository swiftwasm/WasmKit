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

public enum ComponentType: Hashable {
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

    indirect case `func`(ComponentFuncType)

    case indexed(ComponentTypeIndex)
}

public struct ComponentFuncType: Hashable {
    struct Param: Hashable {
        let name: String
        let type: ComponentType
    }
    let params: [Param]
    let result: ComponentType
}

public struct ComponentRecordField: Hashable {
    let name: String
    let type: ComponentTypeIndex
}

public struct ComponentCaseField: Hashable {
    let name: String
    let type: ComponentTypeIndex?
}
