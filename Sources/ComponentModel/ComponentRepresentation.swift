import WasmTypes

// MARK: - Core Instance Definitions

/// A core instance definition.
/// `core:instance` production rule at https://github.com/WebAssembly/component-model/blob/3a00c74f6f4035240ed6cd96f25ef0b40b0577ab/design/mvp/Explainer.md#instance-definitions
package enum CoreInstanceDefinition {
    /// Instantiate a core module with arguments
    case instantiate(moduleIndex: UInt32, args: [CoreInstantiateArg])
    /// Inline exports forming an instance
    case exports([CoreInlineExport])
}

/// An argument for core module instantiation.
/// `core:instantiatearg` production rule at https://github.com/WebAssembly/component-model/blob/3a00c74f6f4035240ed6cd96f25ef0b40b0577ab/design/mvp/Explainer.md#instance-definitions
package struct CoreInstantiateArg {
    package let name: String
    package let instanceIndex: UInt32

    package init(name: String, instanceIndex: UInt32) {
        self.name = name
        self.instanceIndex = instanceIndex
    }
}

/// An inline export in a core instance.
/// `core:inlineexport` production rule at https://github.com/WebAssembly/component-model/blob/3a00c74f6f4035240ed6cd96f25ef0b40b0577ab/design/mvp/Explainer.md#instance-definitions
package struct CoreInlineExport {
    package let name: String
    package let sort: CoreDefSort
    package let index: UInt32

    package init(name: String, sort: CoreDefSort, index: UInt32) {
        self.name = name
        self.sort = sort
        self.index = index
    }
}

// MARK: - Core Alias Definitions

/// A core alias definition.
package struct CoreAlias {
    package let sort: CoreDefSort
    package let target: CoreAliasTarget

    package init(sort: CoreDefSort, target: CoreAliasTarget) {
        self.sort = sort
        self.target = target
    }
}

/// Target of a core alias.
package enum CoreAliasTarget {
    case outer(count: UInt32, index: UInt32)
}

// MARK: - Component Instance Definitions

/// A component instance definition (from binary section 5).
package enum ComponentInstanceDefinition {
    /// Instantiate a component with arguments
    case instantiate(componentIndex: UInt32, args: [ComponentInstantiateArg])
    /// Inline exports forming an instance
    case exports([ComponentInlineExport])
}

/// An argument for component instantiation.
package struct ComponentInstantiateArg {
    package let name: String
    package let sort: ComponentDefSort
    package let index: UInt32

    package init(name: String, sort: ComponentDefSort, index: UInt32) {
        self.name = name
        self.sort = sort
        self.index = index
    }
}

/// An inline export in a component instance.
package struct ComponentInlineExport {
    package let name: String
    package let sort: ComponentDefSort
    package let index: UInt32

    package init(name: String, sort: ComponentDefSort, index: UInt32) {
        self.name = name
        self.sort = sort
        self.index = index
    }
}

// MARK: - Alias Definitions

/// An alias definition (from binary section 6).
package struct ComponentAlias {
    package let sort: ComponentDefSort
    package let target: ComponentAliasTarget

    package init(sort: ComponentDefSort, target: ComponentAliasTarget) {
        self.sort = sort
        self.target = target
    }
}

/// Target of a component alias.
package enum ComponentAliasTarget {
    /// Export from a component instance
    case export(instanceIndex: UInt32, name: String)
    /// Export from a core instance
    case coreExport(instanceIndex: UInt32, name: String)
    /// Outer scope reference
    case outer(count: UInt32, index: UInt32)
}

// MARK: - Extern Descriptor Types

/// An import declaration in a type.
package struct ComponentImportDecl {
    package let name: String
    package let externDesc: ComponentExternDesc

    package init(name: String, externDesc: ComponentExternDesc) {
        self.name = name
        self.externDesc = externDesc
    }
}

/// An export declaration in a type.
package struct ComponentExportDecl {
    package let name: String
    package let externDesc: ComponentExternDesc

    package init(name: String, externDesc: ComponentExternDesc) {
        self.name = name
        self.externDesc = externDesc
    }
}

/// An extern descriptor for imports/exports.
package enum ComponentExternDesc {
    case coreModule(typeIndex: UInt32)
    case function(typeIndex: UInt32)
    case value(ComponentValueBound)
    case type(ComponentTypeBound)
    case component(typeIndex: UInt32)
    case instance(typeIndex: UInt32)
}

/// A bound on a value type.
package enum ComponentValueBound {
    case eq(valueIndex: UInt32)
    case type(ComponentDefValType)
}

/// A bound on a type.
package enum ComponentTypeBound {
    case eq(typeIndex: UInt32)
    case subResource
}

// MARK: - Canonical Definitions

/// A canonical definition (from binary section 8).
package enum CanonicalDefinition {
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
    /// A recognized async canon built-in. See ``AsyncCanonicalBuiltin``.
    case asyncBuiltin(AsyncCanonicalBuiltin)
}

/// A decoded async Component Model canon built-in.
package struct AsyncCanonicalBuiltin {
    package let opcode: CanonOpcode
    package let immediates: AsyncCanonicalImmediates
    package init(opcode: CanonOpcode, immediates: AsyncCanonicalImmediates) {
        self.opcode = opcode
        self.immediates = immediates
    }
}

/// The immediate-byte payload shapes shared across the async canon built-ins.
package enum AsyncCanonicalImmediates {
    /// `task.cancel`, `subtask.drop`, `thread.index`, `waitable-set.{new,drop}`, `waitable.join`
    case none
    /// `stream`/`future` `.new`, `.drop-readable`, `.drop-writable`
    case type(UInt32)
    /// `stream`/`future` `.read`, `.write`
    case typeWithOptions(UInt32, options: [CanonicalOption])
    /// `stream`/`future` `.cancel-read`, `.cancel-write`
    case typeWithAsyncFlag(UInt32, async: Bool)
    /// `subtask.cancel`
    case asyncFlag(Bool)
    /// `thread.yield`, `thread.suspend`
    case cancellableFlag(Bool)
    /// `waitable-set.wait`, `waitable-set.poll`
    case cancellableWithMemory(Bool, memoryIndex: UInt32)
    /// `task.return`
    case resultListWithOptions(ComponentDefValType?, options: [CanonicalOption])
    /// `context.get`, `context.set`
    case context(CanonicalContextValueType, slot: UInt32)
    /// `thread.new-indirect`
    case typeWithTable(UInt32, tableIndex: UInt32)
}

/// The core value type a `context.get`/`context.set` slot holds (ABI-restricted to i32/i64).
package enum CanonicalContextValueType {
    case i32
    case i64
}

/// A canonical option.
package enum CanonicalOption {
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
package struct ComponentStart {
    package let funcIndex: UInt32
    package let args: [UInt32]
    package let resultCount: UInt32

    package init(funcIndex: UInt32, args: [UInt32], resultCount: UInt32) {
        self.funcIndex = funcIndex
        self.args = args
        self.resultCount = resultCount
    }
}

// MARK: - Import/Export Definitions

/// An import definition (from binary section 10).
package struct ComponentImportDef {
    package let name: String
    package let externDesc: ComponentExternDesc

    package init(name: String, externDesc: ComponentExternDesc) {
        self.name = name
        self.externDesc = externDesc
    }
}

/// An export definition (from binary section 11).
package struct ComponentExportDef {
    package let name: String
    package let sort: ComponentDefSort
    package let index: UInt32
    package let externDesc: ComponentExternDesc?

    package init(name: String, sort: ComponentDefSort, index: UInt32, externDesc: ComponentExternDesc?) {
        self.name = name
        self.sort = sort
        self.index = index
        self.externDesc = externDesc
    }
}

/// A value definition (from binary section 12).
package struct ComponentValueDef {
    package let type: ComponentDefValType
    package let value: [UInt8]  // Raw bytes, interpretation depends on type

    package init(type: ComponentDefValType, value: [UInt8]) {
        self.type = type
        self.value = value
    }
}
