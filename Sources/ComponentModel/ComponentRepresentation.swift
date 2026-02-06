import WasmTypes

// MARK: - Core Instance Definitions

/// A core instance definition (from binary section 2).
public enum CoreInstanceDefinition {
    /// Instantiate a core module with arguments
    case instantiate(moduleIndex: UInt32, args: [CoreInstantiateArg])
    /// Inline exports forming an instance
    case exports([CoreInlineExport])
}

/// An argument for core module instantiation.
public struct CoreInstantiateArg {
    public let name: String
    public let instanceIndex: UInt32

    public init(name: String, instanceIndex: UInt32) {
        self.name = name
        self.instanceIndex = instanceIndex
    }
}

/// An inline export in a core instance.
public struct CoreInlineExport {
    public let name: String
    public let sort: CoreDefSort
    public let index: UInt32

    public init(name: String, sort: CoreDefSort, index: UInt32) {
        self.name = name
        self.sort = sort
        self.index = index
    }
}

// MARK: - Core Alias Definitions

/// A core alias definition.
public struct CoreAlias {
    public let sort: CoreDefSort
    public let target: CoreAliasTarget

    public init(sort: CoreDefSort, target: CoreAliasTarget) {
        self.sort = sort
        self.target = target
    }
}

/// Target of a core alias.
public enum CoreAliasTarget {
    case outer(count: UInt32, index: UInt32)
}

// MARK: - Component Instance Definitions

/// A component instance definition (from binary section 5).
public enum ComponentInstanceDefinition {
    /// Instantiate a component with arguments
    case instantiate(componentIndex: UInt32, args: [ComponentInstantiateArg])
    /// Inline exports forming an instance
    case exports([ComponentInlineExport])
}

/// An argument for component instantiation.
public struct ComponentInstantiateArg {
    public let name: String
    public let sort: ComponentDefSort
    public let index: UInt32

    public init(name: String, sort: ComponentDefSort, index: UInt32) {
        self.name = name
        self.sort = sort
        self.index = index
    }
}

/// An inline export in a component instance.
public struct ComponentInlineExport {
    public let name: String
    public let sort: ComponentDefSort
    public let index: UInt32

    public init(name: String, sort: ComponentDefSort, index: UInt32) {
        self.name = name
        self.sort = sort
        self.index = index
    }
}

// MARK: - Alias Definitions

/// An alias definition (from binary section 6).
public struct ComponentAlias {
    public let sort: ComponentDefSort
    public let target: ComponentAliasTarget

    public init(sort: ComponentDefSort, target: ComponentAliasTarget) {
        self.sort = sort
        self.target = target
    }
}

/// Target of a component alias.
public enum ComponentAliasTarget {
    /// Export from a component instance
    case export(instanceIndex: UInt32, name: String)
    /// Export from a core instance
    case coreExport(instanceIndex: UInt32, name: String)
    /// Outer scope reference
    case outer(count: UInt32, index: UInt32)
}

// MARK: - Extern Descriptor Types

/// An import declaration in a type.
public struct ComponentImportDecl {
    public let name: String
    public let externDesc: ComponentExternDesc

    public init(name: String, externDesc: ComponentExternDesc) {
        self.name = name
        self.externDesc = externDesc
    }
}

/// An export declaration in a type.
public struct ComponentExportDecl {
    public let name: String
    public let externDesc: ComponentExternDesc

    public init(name: String, externDesc: ComponentExternDesc) {
        self.name = name
        self.externDesc = externDesc
    }
}

/// An extern descriptor for imports/exports.
public enum ComponentExternDesc {
    case coreModule(typeIndex: UInt32)
    case function(typeIndex: UInt32)
    case value(ComponentValueBound)
    case type(ComponentTypeBound)
    case component(typeIndex: UInt32)
    case instance(typeIndex: UInt32)
}

/// A bound on a value type.
public enum ComponentValueBound {
    case eq(valueIndex: UInt32)
    case type(ComponentValueType)
}

/// A bound on a type.
public enum ComponentTypeBound {
    case eq(typeIndex: UInt32)
    case subResource
}

// MARK: - Canonical Definitions

/// A canonical definition (from binary section 8).
public enum CanonicalDefinition {
    /// Lift a core function to a component function
    case lift(
        coreFuncIndex: UInt32,
        options: [CanonicalOption],
        typeIndex: UInt32
    )
    /// Lower a component function to a core function
    case lower(
        funcIndex: UInt32,
        options: [CanonicalOption]
    )
    /// Create a new resource
    case resourceNew(typeIndex: UInt32)
    /// Drop a resource
    case resourceDrop(typeIndex: UInt32)
    /// Get resource representation
    case resourceRep(typeIndex: UInt32)
}

/// A canonical option.
public enum CanonicalOption {
    case utf8
    case utf16
    case latin1UTF16
    case memory(memoryIndex: UInt32)
    case realloc(funcIndex: UInt32)
    case postReturn(funcIndex: UInt32)
    case async
    case callback(funcIndex: UInt32)
}

// MARK: - Start Definition

/// A start definition (from binary section 9).
public struct ComponentStart {
    public let funcIndex: UInt32
    public let args: [UInt32]
    public let resultCount: UInt32

    public init(funcIndex: UInt32, args: [UInt32], resultCount: UInt32) {
        self.funcIndex = funcIndex
        self.args = args
        self.resultCount = resultCount
    }
}

// MARK: - Import/Export Definitions

/// An import definition (from binary section 10).
public struct ComponentImportDef {
    public let name: String
    public let externDesc: ComponentExternDesc

    public init(name: String, externDesc: ComponentExternDesc) {
        self.name = name
        self.externDesc = externDesc
    }
}

/// An export definition (from binary section 11).
public struct ComponentExportDef {
    public let name: String
    public let sort: ComponentDefSort
    public let index: UInt32
    public let externDesc: ComponentExternDesc?

    public init(name: String, sort: ComponentDefSort, index: UInt32, externDesc: ComponentExternDesc?) {
        self.name = name
        self.sort = sort
        self.index = index
        self.externDesc = externDesc
    }
}

/// A value definition (from binary section 12).
public struct ComponentValueDef {
    public let type: ComponentValueType
    public let value: [UInt8]  // Raw bytes, interpretation depends on type

    public init(type: ComponentValueType, value: [UInt8]) {
        self.type = type
        self.value = value
    }
}
