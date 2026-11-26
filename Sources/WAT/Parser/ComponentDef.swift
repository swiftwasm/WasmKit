#if ComponentModel

    import ComponentModel
    import WasmParser
    import WasmTypes

    extension ComponentWatParser {
        /// Key for deduplicating outer alias declarations.
        struct OuterAliasKey: Hashable {
            enum Sort: Hashable {
                case componentType
                case coreType
                case coreModule
                case component

                var aliasSort: ComponentDefSort {
                    switch self {
                    case .componentType: .type
                    case .coreType: .core(.type)
                    case .coreModule: .core(.module)
                    case .component: .component
                    }
                }

                /// The index space's name in error messages.
                var displayName: String {
                    switch self {
                    case .componentType: "Type"
                    case .coreType: "Core type"
                    case .coreModule: "Core module"
                    case .component: "Component"
                    }
                }
            }
            let sort: Sort
            let outerCount: UInt32
            let targetIndex: UInt32
        }

        struct ValueDef: NamedFieldDecl {
            var id: Name?
        }

        struct ComponentInstanceDef: NamedFieldDecl {
            var id: Name?
            var componentRef: Parser.IndexOrId?
            var arguments: [ComponentInstanceArgument]
            var exports: [ComponentInstanceExport]

            init(id: Name?, componentRef: Parser.IndexOrId?, arguments: [ComponentInstanceArgument], exports: [ComponentInstanceExport] = []) {
                self.id = id
                self.componentRef = componentRef
                self.arguments = arguments
                self.exports = exports
            }
        }

        struct ComponentInstanceExport {
            let name: ComponentExternName
            let sort: ComponentDefSort
            let ref: Parser.IndexOrId
        }

        struct ComponentInstanceArgument {
            let name: String
            let sort: ComponentDefSort
            let ref: Parser.IndexOrId
        }

        /// A core-level placeholder definition for alias-created entries in core index spaces.
        /// Used for core functions (canon lower), core memories, core tables, and core globals.
        struct CoreAliasDef: NamedFieldDecl {
            var id: Name?
            init(id: Name? = nil) {
                self.id = id
            }
        }

        /// Type index space for a component. Every type-creating
        /// declaration (type def, type alias, type import, type export) adds
        /// an entry, so that storage index == spec index at all times.
        struct TypeIndexSpace {
            struct Entry {
                let kind: EntryKind
                let name: Name?
            }
            enum EntryKind {
                /// A full type definition (from `(type ...)` or inline types)
                case definition(ComponentTypeDef)
                /// A type alias (outer or export alias that creates a new type index)
                case alias
                /// A type import (creates a type index via the import section)
                case importedType
                /// A type export with an ID (creates a type index via the export section)
                case exportedType
            }

            private(set) var entries: [Entry] = []
            private var nameToIndex: [String: Int] = [:]

            /// The current count of type indices.
            var count: Int { entries.count }

            /// Add a type definition entry, optionally binding a name.
            /// Returns the type index.
            @discardableResult
            mutating func addDefinition(_ typeDef: ComponentTypeDef) throws(WatParserError) -> Int {
                let index = entries.count
                entries.append(.init(kind: .definition(typeDef), name: typeDef.id))
                if let name = typeDef.id {
                    try bindName(name, index: index)
                }
                return index
            }

            /// Add a type alias entry (outer or export alias), optionally binding a name.
            /// Returns the type index.
            @discardableResult
            mutating func addAlias(name: Name?) throws(WatParserError) -> Int {
                let index = entries.count
                entries.append(.init(kind: .alias, name: name))
                if let name = name {
                    try bindName(name, index: index)
                }
                return index
            }

            /// Add a type import entry, optionally binding a name.
            /// Also stores the type definition for name resolution and deduplication.
            /// Returns the type index.
            @discardableResult
            mutating func addImport(name: Name?, typeDef: ComponentTypeDef) throws(WatParserError) -> Int {
                let index = entries.count
                entries.append(.init(kind: .importedType, name: name))
                if let name = name {
                    try bindName(name, index: index)
                }
                // Also store the type definition for deduplication lookups
                definitionsByIndex[index] = typeDef
                return index
            }

            /// Add an unnamed type export entry.
            /// Returns the type index.
            @discardableResult
            mutating func addExport() -> Int {
                let index = entries.count
                entries.append(.init(kind: .exportedType, name: nil))
                return index
            }

            /// Resolve a named or numeric type reference to its index.
            func resolveIndex(use: Parser.IndexOrId) throws(WatParserError) -> Int {
                switch use {
                case .id(let id, _):
                    guard let index = nameToIndex[id.value] else {
                        throw WatParserError("Unknown type \(id)", location: use.location)
                    }
                    return index
                case .index(let value, _):
                    return Int(value)
                }
            }

            /// The index bound to `name`, or nil when no entry has that name.
            func index(of name: String) -> Int? {
                nameToIndex[name]
            }

            /// Look up the type definition at the given index.
            /// Returns nil if the index refers to a non-definition entry without
            /// a stored definition, or if the index is out of bounds.
            func definition(at index: Int) -> ComponentTypeDef? {
                // Check supplementary storage first (for imports that have type defs)
                if let def = definitionsByIndex[index] {
                    return def
                }
                guard index < entries.count else { return nil }
                if case .definition(let def) = entries[index].kind { return def }
                return nil
            }

            /// Whether any entries have names bound (for name section emission check).
            var hasNames: Bool {
                !nameToIndex.isEmpty
            }

            /// Supplementary definition storage for entries that aren't `.definition`
            /// but still need definition access (e.g., type imports used for deduplication).
            private var definitionsByIndex: [Int: ComponentTypeDef] = [:]

            private mutating func bindName(_ name: Name, index: Int) throws(WatParserError) {
                guard nameToIndex[name.value] == nil else {
                    throw WatParserError("Duplicate \(name.value) identifier", location: name.location)
                }
                nameToIndex[name.value] = index
            }
        }

        /// https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#index-spaces
        package struct ComponentDef: NamedFieldDecl {
            var id: Name?

            init(
                id: Name? = nil,
                definitions: [NormalizedDefinition] = []
            ) {
                self.id = id
                self.definitions = definitions
            }

            // Listed in the order of section indices in binary encoding.
            var coreModulesMap: NameMapping<ModuleDef> = .init()
            var coreInstancesMap: NameMapping<CoreInstanceDef> = .init()
            var coreTypesMap: CoreTypesMap = .init()
            var coreFunctionsMap: NameMapping<CoreAliasDef> = .init()
            var coreMemoriesMap: NameMapping<CoreAliasDef> = .init()
            var coreTablesMap: NameMapping<CoreAliasDef> = .init()
            var coreGlobalsMap: NameMapping<CoreAliasDef> = .init()
            var coreTagsMap: NameMapping<CoreAliasDef> = .init()

            var componentFunctions: NameMapping<ComponentFuncDef> = .init()
            var valuesMap: NameMapping<ValueDef> = .init()
            /// Type index space. Every type-creating declaration (type defs,
            /// type aliases, type imports, type exports) adds an entry, so storage
            /// index == spec index at all times.
            var typeIndexSpace: TypeIndexSpace = .init()
            var componentInstancesMap: NameMapping<ComponentInstanceDef> = .init()
            var componentsMap: NameMapping<ComponentDef> = .init()

            /// All definitions in normalized order for the encoder.
            /// Built during parsing alongside the existing structures.
            var definitions: [NormalizedDefinition] = []

            /// Destructor references for resource types.
            /// Maps component type index to the (instance, export name) pair for the destructor function.
            var destructorRefs: [Int: FuncIndex] = [:]

            /// Pre-computed mapping from type indices to binary type indices.
            /// Computed during `normalizeDefinitions()`.
            var typeIndexMapping: [Int: Int] = [:]

            /// Resolve a type reference to its type index.
            func resolveTypeIndex(use: Parser.IndexOrId) throws(WatParserError) -> Int {
                try typeIndexSpace.resolveIndex(use: use)
            }

            /// The index bound to `name` in the index space of `sort`, or nil when no entry there has that name.
            func index(of name: String, in sort: OuterAliasKey.Sort) -> Int? {
                switch sort {
                case .componentType: typeIndexSpace.index(of: name)
                case .coreType: coreTypesMap.index(of: name)
                case .coreModule: coreModulesMap.index(of: name)
                case .component: componentsMap.index(of: name)
                }
            }

            func resolveIndex(use: Parser.IndexOrId, in sort: OuterAliasKey.Sort) throws(WatParserError) -> Int {
                switch sort {
                case .componentType: try typeIndexSpace.resolveIndex(use: use)
                case .coreType: try coreTypesMap.resolveIndex(use: use)
                case .coreModule: try coreModulesMap.resolveIndex(use: use)
                case .component: try componentsMap.resolveIndex(use: use)
                }
            }

            /// Adds the entry an outer alias of `sort` creates, bound to `id`, and returns its index.
            mutating func addOuterAliasEntry(_ sort: OuterAliasKey.Sort, id: Name?) throws(WatParserError) -> Int {
                switch sort {
                case .componentType:
                    try typeIndexSpace.addAlias(name: id)
                case .coreType:
                    try coreTypesMap.add(
                        CoreTypeDef(
                            id: id,
                            kind: .function(
                                WatParser.FunctionType(
                                    signature: WasmTypes.FunctionType(parameters: [], results: []),
                                    parameterNames: []
                                ))))
                case .coreModule:
                    try coreModulesMap.add(ModuleDef(id: id, wat: nil))
                case .component:
                    try componentsMap.add(ComponentDef(id: id, definitions: []))
                }
            }

            /// Adds the entry a core export alias of `sort` creates, bound to `id`, and returns its index,
            /// or nil for `.type`, `.module` and `.instance`.
            mutating func addCoreAliasEntry(_ sort: CoreDefSort, id: Name?) throws(WatParserError) -> Int? {
                switch sort {
                case .func: try coreFunctionsMap.add(CoreAliasDef(id: id))
                case .memory: try coreMemoriesMap.add(CoreAliasDef(id: id))
                case .table: try coreTablesMap.add(CoreAliasDef(id: id))
                case .global: try coreGlobalsMap.add(CoreAliasDef(id: id))
                case .tag: try coreTagsMap.add(CoreAliasDef(id: id))
                case .type, .module, .instance: nil
                }
            }

            /// Normalize the definitions array to match the canonical binary encoding order.
            /// This reorders inline exports to come after their definition batch.
            ///
            /// Input order (from parser):
            ///   [componentType($r1), export("r1", type 0), componentType($r2), export("r2", type 1)]
            ///   [type, alias, canon, export("f1"), type, alias, canon, export("f2")]
            ///
            /// Output order (normalized):
            ///   [componentType($r1), componentType($r2), export("r1", type 0), export("r2", type 1)]
            ///   [type, alias, canon, type, alias, canon, export("f1"), export("f2")]
            ///
            /// Two patterns are deferred:
            /// 1. Type exports referencing pending types
            /// 2. Non-type exports that follow a canon definition within a type batch
            mutating func normalizeDefinitions() {
                var normalized: [NormalizedDefinition] = []
                var pendingDefs: [NormalizedDefinition] = []
                // Deferred inline exports, kept across flushes until the final export batch
                var deferredInlineExports: [NormalizedDefinition] = []

                func flushPending() {
                    normalized.append(contentsOf: pendingDefs)
                    pendingDefs.removeAll()
                }

                for def in definitions {
                    switch def {
                    case .componentType:
                        // Accumulate type definitions
                        pendingDefs.append(def)

                    case .coreModule:
                        // Accumulate core module definitions for batching
                        pendingDefs.append(def)

                    case .nestedComponent:
                        // Accumulate nested component definitions for batching
                        pendingDefs.append(def)

                    case .alias:
                        // Aliases within a type batch stay in the batch
                        pendingDefs.append(def)

                    case .canon:
                        // Canon defs within a type batch stay in the batch
                        pendingDefs.append(def)

                    case .componentExport(let exportDef):
                        if exportDef.isInline {
                            // Inline exports are always deferred to the end
                            deferredInlineExports.append(def)
                        } else {
                            // Regular export: flush pending defs first, then emit
                            flushPending()
                            normalized.append(def)
                        }

                    default:
                        // Non-batch definition - flush pending and add
                        flushPending()
                        normalized.append(def)
                    }
                }

                // Flush any remaining pending definitions
                flushPending()

                // Append deferred inline exports at the end
                normalized.append(contentsOf: deferredInlineExports)

                definitions = normalized

                // Compute index mappings after normalization
                computeTypeIndexMapping()
            }

            /// Compute the mapping from type indices to binary type indices.
            /// Each type-creating definition already has the correct type index
            /// stored in it. This method simply assigns sequential binary indices
            /// as it iterates the normalized definitions.
            private mutating func computeTypeIndexMapping() {
                var indexMapping: [Int: Int] = [:]
                var currentBinaryIndex = 0

                for definition in definitions {
                    switch definition {
                    case .componentImport(let importDef):
                        if case .type(let indexOrId, _) = importDef.descriptor,
                            case .index(let idx, _) = indexOrId
                        {
                            indexMapping[Int(idx)] = currentBinaryIndex
                            currentBinaryIndex += 1
                        }

                    case .componentType(_, let typeIndex):
                        indexMapping[typeIndex] = currentBinaryIndex
                        currentBinaryIndex += 1

                    case .componentExport(let exportDef):
                        if case .type = exportDef.descriptor {
                            currentBinaryIndex += 1
                        }

                    case .alias(let aliasDef):
                        if case .type = aliasDef.sort {
                            if let typeIndex = aliasDef.typeIndex {
                                indexMapping[typeIndex] = currentBinaryIndex
                            }
                            currentBinaryIndex += 1
                        }

                    default:
                        break
                    }
                }

                typeIndexMapping = indexMapping
            }

        }

        struct ModuleDef: NamedFieldDecl {
            var id: Name?

            /// The module's content source.
            enum Content {
                /// Parsed WAT AST: encoded via `WAT.encode`.
                case wat(Wat)
                /// Pre-encoded core module binary: emitted directly.
                case binary([UInt8])
                /// Placeholder for alias modules (no encodable content).
                case placeholder
            }

            var content: Content = .placeholder

            init(id: Name? = nil, wat: Wat? = nil) {
                self.id = id
                self.content = wat.map { .wat($0) } ?? .placeholder
            }

            /// Init with pre-encoded binary content.
            init(id: Name? = nil, binary: [UInt8]) {
                self.id = id
                self.content = .binary(binary)
            }

            // Backwards-compatible accessors for existing callers.
            var wat: Wat? {
                get {
                    if case .wat(let w) = content { return w }
                    return nil
                }
                set {
                    if let w = newValue { content = .wat(w) } else { content = .placeholder }
                }
            }

            var rawBytes: [UInt8]? {
                if case .binary(let b) = content { return b }
                return nil
            }
        }

        struct CoreInstanceDef: NamedFieldDecl {
            struct Argument {
                enum Kind {
                    struct Export {
                        let name: String
                        let sort: CoreDefSort
                        let index: UInt32
                        init(name: String, sort: CoreDefSort, index: UInt32) {
                            self.name = name
                            self.sort = sort
                            self.index = index
                        }
                    }
                    case instance(Parser.IndexOrId)
                    case exports([Export])
                }

                let importName: String
                let kind: Kind
                init(importName: String, kind: Kind) {
                    self.importName = importName
                    self.kind = kind
                }
            }

            /// The form of core instance definition.
            enum Form {
                /// Instantiate form: (instantiate $module (with ...))
                case instantiate(moduleId: Parser.IndexOrId, arguments: [Argument])
                /// Exports-only form: (export "name" (func $ref))...
                /// This form is generated by desugaring inline exports.
                case exports([Argument.Kind.Export])
            }

            var id: Name?
            var form: Form
            init(id: Name? = nil, form: Form) {
                self.id = id
                self.form = form
            }

            // Convenience accessors for backward compatibility
            var moduleId: Parser.IndexOrId? {
                if case .instantiate(let moduleId, _) = form { return moduleId }
                return nil
            }

            var arguments: [Argument] {
                if case .instantiate(_, let args) = form { return args }
                return []
            }
        }

        struct CoreTypeDef: NamedFieldDecl {
            enum Kind {
                case function(WatParser.FunctionType)
                case module(CoreModuleTypeDef)
            }
            var id: Name?
            let kind: Kind
            init(id: Name? = nil, kind: Kind) {
                self.id = id
                self.kind = kind
            }
        }

        struct CoreModuleTypeDef {
            var declarations: [CoreModuleDecl]
            var localTypeBindings: [String: Int] = [:]

            init(declarations: [CoreModuleDecl], localTypeBindings: [String: Int] = [:]) {
                self.declarations = declarations
                self.localTypeBindings = localTypeBindings
            }

            func resolveTypeIndex(use: Parser.IndexOrId, globalResolver: CoreTypesMap) throws(WatParserError) -> Int {
                switch use {
                case .id(let id, _):
                    if let localDeclIndex = localTypeBindings[id.value] {
                        return localDeclIndex
                    }
                    return try globalResolver.resolveIndex(use: use)
                case .index:
                    return try globalResolver.resolveIndex(use: use)
                }
            }
        }

        enum CoreModuleDecl {
            case alias(CoreModuleAlias)
            case type(WasmTypes.FunctionType)
            case `import`(CoreModuleImport)
            case export(CoreModuleExport)
        }

        struct CoreModuleAlias {
            let sort: CoreDefSort
            let target: CoreModuleAliasTarget
            let bindingId: Name?
            init(sort: CoreDefSort, target: CoreModuleAliasTarget, bindingId: Name?) {
                self.sort = sort
                self.target = target
                self.bindingId = bindingId
            }
        }

        enum CoreModuleAliasTarget {
            case outer(componentId: Parser.IndexOrId, index: Parser.IndexOrId, resolvedIndex: Int, outerCount: Int)
        }

        /// Component-level alias definition.
        /// Syntax: (alias core export $instance "name" (core <sort> $bindingId))
        ///         (alias export $instance "name" (<sort> $bindingId))
        struct ComponentAlias {
            enum Target {
                case coreExport(instanceIndex: Parser.IndexOrId, exportName: String)
                case componentExport(instanceIndex: Parser.IndexOrId, exportName: String)
                case outer(outerCount: UInt32, targetIndex: UInt32)
            }

            let sort: ComponentDefSort
            let target: Target
            let bindingId: Name?
            /// For type-sort aliases, the type index assigned at parse time.
            /// Stored here so anonymous aliases (no bindingId) can still be mapped in
            /// computeTypeIndexMapping.
            let typeIndex: Int?

            init(sort: ComponentDefSort, target: Target, bindingId: Name?, typeIndex: Int?) {
                self.sort = sort
                self.target = target
                self.bindingId = bindingId
                self.typeIndex = typeIndex
            }
        }

        struct CoreModuleImport {
            let moduleName: String
            let name: String
            let descriptor: CoreImportDesc
            init(moduleName: String, name: String, descriptor: CoreImportDesc) {
                self.moduleName = moduleName
                self.name = name
                self.descriptor = descriptor
            }
        }

        enum CoreImportDesc {
            case `func`(typeIndex: Parser.IndexOrId)
            case global(GlobalType)
            case table(TableType)
            case memory(MemoryType)
        }

        struct CoreModuleExport {
            let name: String
            let descriptor: CoreImportDesc
            init(name: String, descriptor: CoreImportDesc) {
                self.name = name
                self.descriptor = descriptor
            }
        }

        /// Reference to a core function.
        /// Can be either a direct reference to a core function index or a reference via instance export.
        enum FuncIndex {
            /// Direct reference to a core function index: (core func $idx)
            case direct(Parser.IndexOrId)
            /// Instance export reference: (core func $inst "name")
            case export(instance: Parser.IndexOrId, exportName: String)
        }

        /// Reference to a core memory.
        /// Used in canon options: (memory $ref) or (memory $instance "export")
        enum MemoryRef {
            /// Direct reference to a core memory index: (memory $ref)
            case direct(Parser.IndexOrId)
            /// Instance export reference: (memory $instance "export")
            case export(instance: Parser.IndexOrId, exportName: String)
        }

        struct CanonDef {
            enum Option {
                case stringEncoding(ComponentStringEncoding)
                case memory(MemoryRef)
                /// Direct core memory index (after desugaring from MemoryRef)
                case memoryIndex(UInt32)
                case realloc(FuncIndex)
                case postReturn(FuncIndex)
                case `async`
                case callback(FuncIndex)
            }

            enum Kind {
                /// Canon lower with desugared component function index
                case lower(ComponentFuncIndex)
                case lift(FuncIndex)
                case resourceNew(Parser.IndexOrId)  // Type reference
                case resourceDrop(Parser.IndexOrId)  // Type reference
                case resourceRep(Parser.IndexOrId)  // Type reference
            }

            let kind: Kind
            let options: [Option]
            /// Type index for canon lift - the component function type that this lifted function has
            let liftTypeIndex: Int?

            init(kind: Kind, options: [Option], liftTypeIndex: Int?) {
                self.kind = kind
                self.options = options
                self.liftTypeIndex = liftTypeIndex
            }
        }

        struct StartDef {
            /// Reference to the component function to call
            let funcRef: Parser.IndexOrId
            /// Value index arguments passed to the function
            let args: [Parser.IndexOrId]
            /// Number of result values produced (they enter the value index space)
            let resultCount: Int
        }

        enum ExternDesc {
            case module(Parser.IndexOrId)
            case coreModule(Parser.IndexOrId)  // (core module (type $ref)): references a core type index
            case function(ComponentFuncIndex)
            case value(Parser.IndexOrId)  // (value $idx): value export by section index
            case valueType(ComponentDefValType)  // (value <valtype>): value import with inline type (🪙 gated)
            case type(Parser.IndexOrId, TypeBound?)  // type index + optional bound (for imports)
            case component(Parser.IndexOrId)
            case instance(Parser.IndexOrId)
        }

        struct ExportTypeAnnotation {
            let typeIndex: Int
            let kind: ExternDescKind
            init(typeIndex: Int, kind: ExternDescKind) {
                self.typeIndex = typeIndex
                self.kind = kind
            }
        }

        /// Component extern name: either a plain kebab-name or an interface URL.
        enum ComponentExternName: Hashable {
            case plain(String)
            case interface(String)

            var string: String {
                switch self {
                case .plain(let s), .interface(let s): return s
                }
            }
        }

        struct ExportDef {
            let exportName: ComponentExternName
            let descriptor: ExternDesc
            let typeAnnotation: ExportTypeAnnotation?  // Optional type annotation with sort
            /// True for inline export annotations (e.g., (type $t (export "t") u32))
            /// that should be deferred to the end during normalization.
            let isInline: Bool

            init(exportName: ComponentExternName, descriptor: ExternDesc, typeAnnotation: ExportTypeAnnotation? = nil, isInline: Bool = false) {
                self.exportName = exportName
                self.descriptor = descriptor
                self.typeAnnotation = typeAnnotation
                self.isInline = isInline
            }
        }

        struct ImportDef {
            let importName: ComponentExternName
            let descriptor: ExternDesc
            init(importName: ComponentExternName, descriptor: ExternDesc) {
                self.importName = importName
                self.descriptor = descriptor
            }
        }

        struct ComponentFuncDef: NamedFieldDecl {
            var id: Name?
            let paramNames: [String]
            /// The function's type index; nil for a function an export or alias creates, whose type the parser does not track.
            let type: ComponentTypeIndex?
            init(id: Name? = nil, paramNames: [String], type: ComponentTypeIndex?) {
                self.id = id
                self.paramNames = paramNames
                self.type = type
            }
        }

        struct ComponentTypeDef: NamedFieldDecl {
            enum Kind {
                case function(ComponentFuncType)
                case value(ComponentDefValType)
                case instance([ComponentDecl])
                case component([ComponentDecl])

                var isPrimitive: Bool {
                    guard case .value(let type) = self else {
                        return false
                    }

                    return type.isPrimitive
                }
            }
            var id: Name?
            let kind: Kind
            init(id: Name? = nil, kind: Kind) {
                self.id = id
                self.kind = kind
            }
        }

        /// Shared extern declaration for imports/exports in type definitions
        struct ExternDecl: Hashable {
            let name: ComponentExternName
            let descriptor: TypeExternDesc
            init(name: ComponentExternName, descriptor: TypeExternDesc) {
                self.name = name
                self.descriptor = descriptor
            }
        }

        /// Instance type declarations - matches instancedecl production
        /// instancedecl ::= <type> | <alias> | <exportdecl> | core-prefix(...)
        /// Component type declarations - matches componentdecl production
        /// componentdecl ::= <importdecl> | <instancedecl>
        enum ComponentDecl {
            case coreType(CoreTypeDef)
            case type(ComponentTypeDef)
            case alias(TypeAliasDecl)
            case `import`(ExternDecl)
            case export(ExternDecl)
        }

        /// Type bound for type imports/exports: (sub resource) or (eq $typeRef)
        /// Stores resolved type indices for Hashable conformance.
        enum TypeBound: Hashable {
            /// Type equality constraint: (eq $typeRef) - stores the resolved type index
            case eq(typeIndex: UInt32)
            /// Subtype of resource: (sub resource)
            case subResource
        }

        /// Descriptor for extern type imports/exports in component types
        enum TypeExternDesc: Hashable {
            case coreModule(id: String?, coreTypeIndex: UInt32)
            case type(id: String?, bound: TypeBound)
            case function(id: String?, typeIndex: UInt32?)
            /// Value descriptor: for value imports/exports in component types
            case value(id: String?, typeIndex: UInt32?)
            /// Instance descriptor - type index (inline types are added to componentTypes first)
            case instance(id: String?, typeIndex: UInt32?)
            case component(id: String?, typeIndex: UInt32?)
        }

        /// Local type context for tracking bindings within instance/component type definitions.
        /// Used for resolving local type references and outer alias targets.
        struct LocalTypeContext {
            init() {}

            /// Name of this type definition (if any)
            var name: String?
            /// Local type names to indices within this type definition
            var typeBindings: [String: UInt32] = [:]
            /// Instance names to indices (for component types with imports)
            var instanceBindings: [String: UInt32] = [:]
            /// Current type index counter
            var nextTypeIndex: UInt32 = 0
            /// Current instance index counter (for imports)
            var nextInstanceIndex: UInt32 = 0
            /// Current core type index counter
            var nextCoreTypeIndex: UInt32 = 0

            /// Maps (outerCount, targetTypeIndex) to their local alias indices for deduplication.
            var outerTypeAliases: [OuterAliasKey: UInt32] = [:]

            /// Pending outer alias declarations that need to be inserted.
            var pendingOuterAliases: [(sort: OuterAliasKey.Sort, outerCount: UInt32, targetTypeIndex: UInt32, localAliasIndex: UInt32)] = []

            /// Pending inline type definitions that need to be inserted.
            /// These are anonymous types created from inline type syntax in imports/exports.
            var pendingInlineTypes: [ComponentTypeDef] = []

            /// Pending inline core type definitions that need to be inserted.
            var pendingInlineCoreTypes: [CoreTypeDef] = []

            /// Register a type and optionally bind a name to its index
            mutating func registerType(name: String?) -> UInt32 {
                let index = nextTypeIndex
                if let name = name {
                    typeBindings[name] = index
                }
                nextTypeIndex += 1
                return index
            }

            /// Register an instance and optionally bind a name to its index
            mutating func registerInstance(name: String?) -> UInt32 {
                let index = nextInstanceIndex
                if let name = name {
                    instanceBindings[name] = index
                }
                nextInstanceIndex += 1
                return index
            }

            /// Resolve a type reference to its local index
            func resolveType(_ ref: Parser.IndexOrId) -> UInt32? {
                switch ref {
                case .index(let idx, _):
                    return idx
                case .id(let name, _):
                    return typeBindings[name.value]
                }
            }

            /// Resolve an instance reference to its local index
            func resolveInstance(_ ref: Parser.IndexOrId) -> UInt32? {
                switch ref {
                case .index(let idx, _):
                    return idx
                case .id(let name, _):
                    return instanceBindings[name.value]
                }
            }

            /// Get or create an outer alias for a type from an enclosing scope.
            /// `outerCount` is the de Bruijn distance from this type definition to the target scope.
            /// `targetTypeIndex` is the type index in the target scope.
            /// Returns the local type index for the alias.
            mutating func getOrCreateOuterAlias(outerCount: UInt32, targetTypeIndex: UInt32) -> UInt32 {
                let key = OuterAliasKey(sort: .componentType, outerCount: outerCount, targetIndex: targetTypeIndex)
                if let existingLocalIndex = outerTypeAliases[key] {
                    return existingLocalIndex
                }

                let localIndex = nextTypeIndex
                nextTypeIndex += 1

                outerTypeAliases[key] = localIndex
                pendingOuterAliases.append((sort: .componentType, outerCount: outerCount, targetTypeIndex: targetTypeIndex, localAliasIndex: localIndex))

                return localIndex
            }

            /// Get or create an outer alias for a core type from an enclosing scope.
            /// Returns the local core type index for the alias.
            mutating func getOrCreateOuterCoreAlias(outerCount: UInt32, targetCoreTypeIndex: UInt32) -> UInt32 {
                let key = OuterAliasKey(sort: .coreType, outerCount: outerCount, targetIndex: targetCoreTypeIndex)
                if let existingLocalIndex = outerTypeAliases[key] {
                    return existingLocalIndex
                }

                let localIndex = nextCoreTypeIndex
                nextCoreTypeIndex += 1

                outerTypeAliases[key] = localIndex
                pendingOuterAliases.append((sort: .coreType, outerCount: outerCount, targetTypeIndex: targetCoreTypeIndex, localAliasIndex: localIndex))

                return localIndex
            }

            /// Take pending outer aliases (clears the pending list)
            mutating func takePendingOuterAliases() -> [(sort: OuterAliasKey.Sort, outerCount: UInt32, targetTypeIndex: UInt32, localAliasIndex: UInt32)] {
                let aliases = pendingOuterAliases
                pendingOuterAliases = []
                return aliases
            }

            /// Add an inline type definition and return its local type index.
            /// The type will be added to pendingInlineTypes for later insertion.
            mutating func addInlineType(_ typeDef: ComponentTypeDef) -> UInt32 {
                let index = nextTypeIndex
                nextTypeIndex += 1
                pendingInlineTypes.append(typeDef)
                return index
            }

            /// Extract a composite value type into a separate type definition,
            /// returning an index reference. Primitive types and existing index
            /// references are returned unchanged.
            mutating func extractCompositeValueType(_ type: ComponentDefValType) -> ComponentDefValType {
                switch type {
                case .inlined(.primitive):
                    return type
                case .inlined(.index):
                    return type
                case .primitive(.errorContext):
                    return type
                default:
                    // Composite type (own, borrow, tuple, list, record, etc.)
                    // Extract as separate type definition
                    let typeDef = ComponentTypeDef(id: nil, kind: .value(type))
                    let idx = addInlineType(typeDef)
                    return .inlined(.index(ComponentTypeIndex(rawValue: Int(idx))))
                }
            }

            /// Extract composite value types from a function type's params and result.
            /// Returns a new function type with composite types replaced by index references.
            mutating func extractFuncTypeComposites(_ funcType: ComponentFuncType) -> ComponentFuncType {
                let params = funcType.params.map { param in
                    ComponentFuncType.Param(name: param.name, type: extractCompositeValueType(param.type))
                }
                let result = funcType.result.map { extractCompositeValueType($0) }
                return ComponentFuncType(params: params, result: result, isAsync: funcType.isAsync)
            }

            /// Take pending inline types (clears the pending list)
            mutating func takePendingInlineTypes() -> [ComponentTypeDef] {
                let types = pendingInlineTypes
                pendingInlineTypes = []
                return types
            }

            /// Whether no inline type definitions are pending, without draining them.
            var pendingInlineTypesIsEmpty: Bool {
                pendingInlineTypes.isEmpty
            }

            /// Add an inline core type definition and return its local core type index.
            mutating func addInlineCoreType(_ typeDef: CoreTypeDef) -> UInt32 {
                let index = nextCoreTypeIndex
                nextCoreTypeIndex += 1
                pendingInlineCoreTypes.append(typeDef)
                return index
            }

            /// Take pending inline core types (clears the pending list)
            mutating func takePendingInlineCoreTypes() -> [CoreTypeDef] {
                let types = pendingInlineCoreTypes
                pendingInlineCoreTypes = []
                return types
            }
        }

        /// Alias declaration inside a type definition.
        /// E.g., (alias export $instance "name" (type $binding))
        ///       (alias outer $component $typeIndex (type $binding))
        struct TypeAliasDecl {
            enum Target {
                /// Export alias: (alias export $instance "exportName" (type $binding))
                case export(instanceIndex: UInt32, exportName: String)
                /// Outer alias: (alias outer $component $typeIndex (type $binding))
                case outer(outerCount: UInt32, typeIndex: UInt32)
            }
            let target: Target
            let sort: ComponentDefSort
            let bindingId: Name?
            init(target: Target, sort: ComponentDefSort, bindingId: Name?) {
                self.target = target
                self.sort = sort
                self.bindingId = bindingId
            }
        }
    }

#endif
