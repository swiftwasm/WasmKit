#if ComponentModel
    import ComponentModel
    import WasmParser

    // MARK: - Component Imports

    /// A set of entities used to import values when instantiating a component.
    ///
    /// A `ComponentImports` instance is used to define values that are imported by a
    /// WebAssembly component. The values can be functions, values, types, instances, or modules.
    public struct ComponentImports {
        private var definitions: [String: InternalComponentExternalValue] = [:]

        /// Initializes a new empty instance of `ComponentImports`.
        public init() {}

        /// Define a value to be imported by the given name.
        public mutating func define(name: String, _ value: ComponentExternalValue) {
            definitions[name] = value.internalize()
        }

        /// Define a function to be imported by the given name.
        public mutating func define(name: String, function: ComponentFunction) {
            definitions[name] = .function(function.handle)
        }

        /// Define an instance to be imported by the given name.
        public mutating func define(name: String, instance: ComponentInstance) {
            definitions[name] = .instance(instance.handle)
        }

        /// Define a core module instance to be imported by the given name.
        public mutating func define(name: String, coreInstance: Instance) {
            definitions[name] = .coreInstance(coreInstance.handle)
        }

        /// Define a core module definition to be imported by the given name.
        public mutating func define(name: String, coreModule: Module) {
            definitions[name] = .coreModule(coreModule)
        }

        /// Lookup a value to be imported by the given name.
        func lookup(name: String) -> InternalComponentExternalValue? {
            definitions[name]
        }
    }

    // MARK: - Component Linker

    /// Resolves component imports and performs instantiation.
    ///
    /// The `ComponentLoader` is responsible for taking a parsed component definition
    /// and creating a runtime `ComponentInstance` by:
    /// 1. Resolving imports from the provided `ComponentImports`
    /// 2. Instantiating nested core modules
    /// 3. Creating lifted component functions via canonical definitions
    /// 4. Building the exports map
    public struct ComponentLoader {
        let store: Store

        /// Creates a new component linker for the given store.
        public init(store: Store) {
            self.store = store
        }

        /// Instantiate a component with the given imports.
        ///
        /// - Parameters:
        ///   - component: The parsed component definition to instantiate.
        ///   - imports: The imports to satisfy the component's import requirements.
        /// - Returns: A new `ComponentInstance`.
        /// - Throws: A `ComponentLoaderError` if instantiation fails.
        public func instantiate(
            component: ParsedComponent,
            imports: ComponentImports = ComponentImports()
        ) throws -> ComponentInstance {
            // Step 0: Validate imports
            try validateImports(component.imports, against: imports)

            var context = InstantiationContext(
                store: store,
                imports: imports,
                resolveType: component.resolveType
            )

            // Step 0.5: Track module definitions in modules index space
            for coreModule in component.coreModules {
                context.coreModules.append(coreModule.module)
            }

            // Step 0.6: Process imports to populate index spaces
            // Imported instances populate the component instances index space
            // Imported functions populate the component functions index space
            for importDef in component.imports {
                try processImport(importDef, context: &context)
            }

            // Step 1: Process definitions in semantic order
            // Binary sections can appear in section-ID order, but semantic dependencies
            // require processing in this order:
            // 1. Nested component definitions (just track them)
            // 2. Component instances (instantiate nested components)
            // 3. Component function aliases (from component instances, including imported)
            // 4. Canon.lower (creates coreFunctions from componentFunctions)
            // 5. Core instances (instantiate core modules, may reference coreFunctions from canon.lower)
            // 6. Core function aliases (from core instances)
            // 7. Canon.lift (creates componentFunctions from core instance exports)

            // Step 1.0: Track nested component definitions (not instantiated yet)
            for nestedComponent in component.nestedComponents {
                context.nestedComponentDefs.append(nestedComponent)
            }

            // Step 1.1: Process component instance definitions (instantiate nested components)
            for instanceDef in component.componentInstances {
                try processComponentInstanceDef(instanceDef, context: &context)
            }

            // Step 1.2: Process component function aliases (from component instances, including imported)
            for alias in component.aliases {
                if case .func = alias.sort {
                    try processAlias(alias, context: &context)
                }
            }

            // Step 1.3: Process canon.lower definitions (creates core functions from component functions)
            for canonDef in component.canonicalDefinitions {
                if case .lower = canonDef.kind {
                    let coreFunction = try processCanonLower(
                        canonDef,
                        context: &context
                    )
                    context.coreFunctions.append(coreFunction)
                }
            }

            // Step 1.4: Process all core instance definitions
            for instanceDef in component.coreInstanceDefs {
                try processCoreInstanceDef(instanceDef, context: &context)
            }

            // Step 1.5: Process core function aliases (from core instances)
            for alias in component.aliases {
                if case .core(let coreSort) = alias.sort, coreSort == .func {
                    try processAlias(alias, context: &context)
                }
            }

            // Step 1.6: Process canon.lift definitions (creates component functions from core instance exports)
            for canonDef in component.canonicalDefinitions {
                if case .lift = canonDef.kind {
                    let componentFunction = try processCanonLift(
                        canonDef,
                        context: &context
                    )
                    context.componentFunctions.append(componentFunction)
                }
            }

            // Step 2: Build exports map
            let exports = try buildExports(
                from: component.exports,
                context: &context
            )

            // Step 3: Allocate the component instance
            let entity = ComponentInstanceEntity(
                coreInstances: context.coreInstances,
                exports: exports,
                functions: context.componentFunctions,
                nestedComponents: context.nestedComponents
            )

            let handle = store.allocator.allocate(componentInstance: entity)
            return ComponentInstance(handle: handle, store: store)
        }
    }

    // MARK: - Instantiation Context

    /// Internal context used during component instantiation.
    struct InstantiationContext {
        let store: Store
        let imports: ComponentImports

        /// Core module definitions (from modules index space)
        var coreModules: [Module] = []

        /// Core module instances created during instantiation (from core instances index space)
        var coreInstances: [InternalInstance] = []

        /// Core functions created from canonical lower definitions (from core functions index space)
        var coreFunctions: [InternalFunction] = []

        /// Imported component instances (from component instances index space, populated by imports)
        var importedInstances: [InternalComponentInstance] = []

        /// Component functions from imports, aliases, and canonical lift definitions
        var componentFunctions: [InternalComponentFunction] = []

        /// Nested component definitions (from components index space)
        var nestedComponentDefs: [ParsedComponent] = []

        /// Type resolver for canonical ABI operations
        let resolveType: (ComponentTypeIndex) throws -> ComponentValueType

        /// Nested component instances (from component instances index space)
        var nestedComponents: [InternalComponentInstance] = []
    }

    // MARK: - Parsed Component Representation

    /// A parsed component ready for instantiation.
    /// This represents the output of parsing a component WAT/binary file.
    public struct ParsedComponent {
        /// Core modules embedded in this component
        public var coreModules: [ParsedCoreModule] = []

        /// Core instance definitions (from core instances index space)
        /// This includes both inline exports and module instantiations in binary order.
        public var coreInstanceDefs: [ParsedCoreInstanceDef] = []

        /// Nested components embedded in this component (recursively parsed)
        public var nestedComponents: [ParsedComponent] = []

        /// Component instance definitions (instantiate or inline exports)
        public var componentInstances: [ParsedComponentInstanceDef] = []

        /// Canonical definitions (lift/lower)
        public var canonicalDefinitions: [ParsedCanonicalDefinition] = []

        /// Aliases that populate index spaces
        public var aliases: [ParsedAlias] = []

        /// Interleaved definitions that must be processed in binary order.
        /// This preserves the semantic ordering of definitions that have dependencies.
        public var orderedDefinitions: [ParsedOrderedDefinition] = []

        /// Component exports
        public var exports: [ParsedComponentExport] = []

        /// Component imports
        public var imports: [ParsedComponentImport] = []

        /// Component type definitions for type resolution during lowering/lifting
        public var componentTypes: [ComponentTypeDef] = []

        public init() {}

        /// Resolve a ComponentTypeIndex to its ComponentValueType definition.
        /// This is used during canonical ABI lowering/lifting to resolve nested types.
        public func resolveType(_ index: ComponentTypeIndex) throws -> ComponentValueType {
            let idx = Int(index.rawValue)
            guard idx < componentTypes.count else {
                throw CanonicalABIError(description: "Type index \(idx) out of bounds (have \(componentTypes.count) types)")
            }
            let typeDef = componentTypes[idx]
            guard case .definedValue(let valueType) = typeDef else {
                throw CanonicalABIError(description: "Type index \(idx) is not a defined value type")
            }
            return valueType
        }
    }

    /// A definition that must be processed in binary order.
    /// Used to preserve semantic ordering for definitions with dependencies.
    public enum ParsedOrderedDefinition {
        /// A core instance definition
        case coreInstance(index: Int)
        /// An alias definition
        case alias(index: Int)
        /// A canonical definition (lift or lower)
        case canon(index: Int)
    }

    /// A core instance definition.
    public enum ParsedCoreInstanceDef {
        /// Instantiate a core module with arguments
        case instantiate(moduleIndex: Int, args: [ParsedCoreInstantiateArg])
        /// Inline exports forming an instance
        case exports([ParsedCoreInlineExport])
    }

    /// An argument for core module instantiation.
    public struct ParsedCoreInstantiateArg {
        /// The import name to satisfy
        public let name: String
        /// The core instance index providing the exports
        public let instanceIndex: Int

        public init(name: String, instanceIndex: Int) {
            self.name = name
            self.instanceIndex = instanceIndex
        }
    }

    /// An inline export in a core instance.
    public struct ParsedCoreInlineExport {
        /// The export name
        public let name: String
        /// The sort of the export
        public let sort: CoreDefSort
        /// The index in the corresponding core index space
        public let index: Int

        public init(name: String, sort: CoreDefSort, index: Int) {
            self.name = name
            self.sort = sort
            self.index = index
        }
    }

    /// A component instance definition.
    public enum ParsedComponentInstanceDef {
        /// Instantiate a nested component with arguments
        case instantiate(componentIndex: Int, args: [ParsedComponentInstantiateArg])
        /// Inline exports forming an instance
        case exports([ParsedComponentInlineExport])
    }

    /// An argument for component instantiation.
    public struct ParsedComponentInstantiateArg {
        /// The import name to satisfy
        public let name: String
        /// The sort of the argument
        public let sort: ComponentDefSort
        /// The index in the corresponding index space
        public let index: Int

        public init(name: String, sort: ComponentDefSort, index: Int) {
            self.name = name
            self.sort = sort
            self.index = index
        }
    }

    /// An inline export in a component instance.
    public struct ParsedComponentInlineExport {
        /// The export name
        public let name: String
        /// The sort of the export
        public let sort: ComponentDefSort
        /// The index in the corresponding index space
        public let index: Int

        public init(name: String, sort: ComponentDefSort, index: Int) {
            self.name = name
            self.sort = sort
            self.index = index
        }
    }

    /// A core module embedded within a component.
    public struct ParsedCoreModule {
        /// The parsed core module
        public let module: Module

        /// Optional name for this module
        public let name: String?

        /// Import arguments for instantiation
        public var instantiateArgs: [ParsedInstantiateArg] = []

        public init(module: Module, name: String? = nil) {
            self.module = module
            self.name = name
        }
    }

    /// An argument for core module instantiation.
    public struct ParsedInstantiateArg {
        /// The import name to satisfy
        public let importName: String

        /// The source of the import value
        public let source: ParsedInstantiateArgSource

        public init(importName: String, source: ParsedInstantiateArgSource) {
            self.importName = importName
            self.source = source
        }
    }

    /// The source of an instantiate argument.
    public enum ParsedInstantiateArgSource {
        /// From another core instance's exports
        case coreInstance(index: Int)

        /// From a component import
        case componentImport(name: String)
    }

    /// A canonical definition (lift or lower).
    public struct ParsedCanonicalDefinition {
        /// The kind of canonical definition
        public let kind: ParsedCanonicalKind

        /// Canon options
        public var options: ParsedCanonOptions

        public init(kind: ParsedCanonicalKind, options: ParsedCanonOptions = ParsedCanonOptions()) {
            self.kind = kind
            self.options = options
        }
    }

    /// The kind of canonical definition.
    public enum ParsedCanonicalKind {
        /// Lift a core function to a component function
        case lift(coreInstanceIndex: Int, functionName: String, type: ComponentFuncType)

        /// Lower a component function to a core function
        case lower(componentFunctionIndex: Int)
    }

    /// Parsed canonical options.
    public struct ParsedCanonOptions {
        /// Memory to use for string/list operations
        public var memory: ParsedCanonMemory?

        /// Realloc function for allocation
        public var realloc: ParsedCanonFunc?

        /// Post-return cleanup function
        public var postReturn: ParsedCanonFunc?

        /// String encoding
        public var stringEncoding: ComponentStringEncoding = .utf8

        public init() {}
    }

    /// Reference to a memory for canonical options.
    public struct ParsedCanonMemory {
        public let coreInstanceIndex: Int
        public let memoryName: String

        public init(coreInstanceIndex: Int, memoryName: String) {
            self.coreInstanceIndex = coreInstanceIndex
            self.memoryName = memoryName
        }
    }

    /// Reference to a function for canonical options.
    public struct ParsedCanonFunc {
        public let coreInstanceIndex: Int
        public let functionName: String

        public init(coreInstanceIndex: Int, functionName: String) {
            self.coreInstanceIndex = coreInstanceIndex
            self.functionName = functionName
        }
    }

    /// A component export definition.
    public struct ParsedComponentExport {
        /// The export name
        public let name: String

        /// The kind of export
        public let kind: ParsedComponentExportKind

        public init(name: String, kind: ParsedComponentExportKind) {
            self.name = name
            self.kind = kind
        }
    }

    /// The kind of component export.
    public enum ParsedComponentExportKind {
        /// Export a component function
        case function(index: Int)

        /// Export a value
        case value(ComponentValue)

        /// Export a type
        case type(ComponentTypeIndex)

        /// Export a nested component instance
        case instance(index: Int)

        /// Export a core module definition (from modules index space)
        case coreModule(moduleIndex: Int)

        /// Export a core module instance (from core instances index space)
        case coreInstance(instanceIndex: Int)
    }

    /// A component import definition.
    public struct ParsedComponentImport {
        /// The import name
        public let name: String

        /// The expected type of the import
        public let kind: ParsedComponentImportKind

        public init(name: String, kind: ParsedComponentImportKind) {
            self.name = name
            self.kind = kind
        }
    }

    /// The kind of component import.
    public enum ParsedComponentImportKind {
        /// Import a function
        case function(ComponentFuncType)

        /// Import a value
        case value(ComponentValueType)

        /// Import an instance
        case instance

        /// Import a module
        case module
    }

    /// An alias definition that populates an index space.
    public struct ParsedAlias {
        /// The sort of the alias (what kind of thing it creates)
        public let sort: ComponentDefSort

        /// The source of the alias
        public let source: ParsedAliasSource

        public init(sort: ComponentDefSort, source: ParsedAliasSource) {
            self.sort = sort
            self.source = source
        }
    }

    /// The source of an alias.
    public enum ParsedAliasSource {
        /// Alias from a component instance export
        case componentInstanceExport(instanceIndex: Int, name: String)
        /// Alias from a core instance export
        case coreInstanceExport(instanceIndex: Int, name: String)
        /// Alias from outer scope
        case outer(count: Int, index: Int)
    }

    // MARK: - Component Link Error

    /// Errors that can occur during component linking.
    public enum ComponentLoaderError: Error {
        /// A required import was not provided
        case missingImport(name: String)

        /// An import has an incompatible type
        case incompatibleImport(name: String, expected: String, got: String)

        /// A core module index is out of bounds (modules index space)
        case invalidCoreModuleIndex(Int)

        /// A core instance index is out of bounds (core instances index space)
        case invalidCoreInstanceIndex(Int)

        /// A core function index is out of bounds (core functions index space)
        case invalidCoreFunctionIndex(Int)

        /// A component index is out of bounds (components index space)
        case invalidComponentIndex(Int)

        /// A component function index is out of bounds
        case invalidComponentFunctionIndex(Int)

        /// Failed to resolve a core function export
        case coreExportNotFound(instanceIndex: Int, name: String)

        /// Failed to resolve a core memory export
        case coreMemoryNotFound(instanceIndex: Int, name: String)

        /// Canon lift requires a memory but none was provided
        case missingCanonMemory

        /// General instantiation failure
        case instantiationFailed(String)
    }

    // MARK: - Private Implementation

    extension ComponentLoader {
        /// Process an import definition to populate the appropriate index space.
        private func processImport(
            _ importDef: ParsedComponentImport,
            context: inout InstantiationContext
        ) throws {
            guard let value = context.imports.lookup(name: importDef.name) else {
                throw ComponentLoaderError.missingImport(name: importDef.name)
            }

            switch (importDef.kind, value) {
            case (.instance, .instance(let instance)):
                // Instance imports add to imported instances index space
                context.importedInstances.append(instance)
            case (.function, .function(let function)):
                // Function imports add to component functions index space
                context.componentFunctions.append(function)
            default:
                // Other imports validated in validateImports, nothing to track here
                break
            }
        }

        /// Process an alias to populate the appropriate index space.
        private func processAlias(
            _ alias: ParsedAlias,
            context: inout InstantiationContext
        ) throws {
            switch alias.sort {
            case .func:
                // Function alias - extract function from instance export
                let componentFunc = try resolveComponentFunctionAlias(alias, context: &context)
                context.componentFunctions.append(componentFunc)
            case .instance:
                // Instance alias - not yet implemented
                break
            case .core(let coreSort):
                // Core aliases from core instance exports
                switch coreSort {
                case .func:
                    // Core function alias from core instance export
                    let coreFunc = try resolveCoreFunctionAlias(alias, context: &context)
                    context.coreFunctions.append(coreFunc)
                case .memory:
                    // Core memory aliases are resolved when needed (in canon options)
                    break
                default:
                    break
                }
            case .type, .component, .value:
                // Type/component/value aliases don't add to runtime context
                break
            }
        }

        /// Resolve a core function alias from a core instance export.
        private func resolveCoreFunctionAlias(
            _ alias: ParsedAlias,
            context: inout InstantiationContext
        ) throws -> InternalFunction {
            switch alias.source {
            case .coreInstanceExport(let instanceIndex, let name):
                // Get the core instance
                guard instanceIndex < context.coreInstances.count else {
                    throw ComponentLoaderError.invalidCoreInstanceIndex(instanceIndex)
                }
                let coreInstance = Instance(handle: context.coreInstances[instanceIndex], store: store)

                // Get the function export from the core instance
                guard let function = coreInstance.exports[function: name] else {
                    throw ComponentLoaderError.coreExportNotFound(instanceIndex: instanceIndex, name: name)
                }
                return function.handle

            case .componentInstanceExport:
                throw ComponentLoaderError.instantiationFailed(
                    "Component instance export alias for core function not supported"
                )

            case .outer:
                throw ComponentLoaderError.instantiationFailed(
                    "Outer alias for core function not yet supported"
                )
            }
        }

        /// Resolve a component function alias from an instance export.
        private func resolveComponentFunctionAlias(
            _ alias: ParsedAlias,
            context: inout InstantiationContext
        ) throws -> InternalComponentFunction {
            switch alias.source {
            case .componentInstanceExport(let instanceIndex, let name):
                // Get the instance from the component instance index space
                // Component instance index space includes:
                // 1. Imported instances (indices 0..importedInstances.count-1)
                // 2. Nested component instances (indices importedInstances.count..)
                let instanceHandle: InternalComponentInstance
                if instanceIndex < context.importedInstances.count {
                    instanceHandle = context.importedInstances[instanceIndex]
                } else {
                    let nestedIndex = instanceIndex - context.importedInstances.count
                    guard nestedIndex < context.nestedComponents.count else {
                        throw ComponentLoaderError.instantiationFailed(
                            "Component instance index \(instanceIndex) out of bounds for alias (imports: \(context.importedInstances.count), nested: \(context.nestedComponents.count))"
                        )
                    }
                    instanceHandle = context.nestedComponents[nestedIndex]
                }
                let instance = ComponentInstance(handle: instanceHandle, store: store)

                // Get the function export from the instance
                guard let function = instance.exports[function: name] else {
                    throw ComponentLoaderError.instantiationFailed(
                        "Function '\(name)' not found in instance \(instanceIndex)"
                    )
                }
                return function.handle

            case .coreInstanceExport:
                throw ComponentLoaderError.instantiationFailed(
                    "Core instance export alias for component function not supported"
                )

            case .outer:
                throw ComponentLoaderError.instantiationFailed(
                    "Outer alias for component function not yet supported"
                )
            }
        }

        /// Process a core instance definition (inline exports or module instantiation).
        private func processCoreInstanceDef(
            _ instanceDef: ParsedCoreInstanceDef,
            context: inout InstantiationContext
        ) throws {
            switch instanceDef {
            case .instantiate(let moduleIndex, let args):
                guard moduleIndex < context.coreModules.count else {
                    throw ComponentLoaderError.invalidCoreModuleIndex(moduleIndex)
                }

                let module = context.coreModules[moduleIndex]

                // Build imports from the args
                var imports = Imports()
                for arg in args {
                    guard arg.instanceIndex < context.coreInstances.count else {
                        throw ComponentLoaderError.invalidCoreInstanceIndex(arg.instanceIndex)
                    }
                    let sourceInstance = Instance(handle: context.coreInstances[arg.instanceIndex], store: store)
                    imports.define(module: arg.name, sourceInstance.exports)
                }

                let instance = try module.instantiate(store: store, imports: imports)
                context.coreInstances.append(instance.handle)

            case .exports(let exports):
                // Create a synthetic instance from inline exports
                // This builds an instance by collecting exports from different sources
                var instanceExports: [String: ExternalValue] = [:]
                for export in exports {
                    let value = try resolveCoreInlineExport(export, context: &context)
                    instanceExports[export.name] = value
                }

                // Create a synthetic core instance with these exports
                // We need to create a pseudo-instance that holds these exports
                let syntheticInstance = try createSyntheticCoreInstance(exports: instanceExports, context: &context)
                context.coreInstances.append(syntheticInstance)
            }
        }

        /// Resolve a core inline export to its external value.
        private func resolveCoreInlineExport(
            _ export: ParsedCoreInlineExport,
            context: inout InstantiationContext
        ) throws -> ExternalValue {
            switch export.sort {
            case .func:
                // Function from core functions index space
                guard export.index < context.coreFunctions.count else {
                    throw ComponentLoaderError.invalidCoreFunctionIndex(export.index)
                }
                return .function(Function(handle: context.coreFunctions[export.index], store: store))

            case .memory:
                // Memory from some core instance
                throw ComponentLoaderError.instantiationFailed("Inline memory exports not yet supported")

            case .table:
                throw ComponentLoaderError.instantiationFailed("Inline table exports not yet supported")

            case .global:
                throw ComponentLoaderError.instantiationFailed("Inline global exports not yet supported")

            case .type:
                throw ComponentLoaderError.instantiationFailed("Inline type exports not yet supported")

            case .module:
                throw ComponentLoaderError.instantiationFailed("Inline module exports not yet supported")

            case .instance:
                throw ComponentLoaderError.instantiationFailed("Inline instance exports not yet supported")
            }
        }

        /// Create a synthetic core instance from inline exports.
        private func createSyntheticCoreInstance(
            exports: [String: ExternalValue],
            context: inout InstantiationContext
        ) throws -> InternalInstance {
            // Convert ExternalValue to InternalExternalValue
            var internalExports: [String: InternalExternalValue] = [:]
            for (name, value) in exports {
                switch value {
                case .function(let func_):
                    internalExports[name] = .function(func_.handle)
                case .table(let table):
                    internalExports[name] = .table(table.handle)
                case .memory(let memory):
                    internalExports[name] = .memory(memory.handle)
                case .global(let global):
                    internalExports[name] = .global(global.handle)
                case .tag(let tag):
                    internalExports[name] = .tag(tag.handle)
                }
            }

            return store.allocator.allocateSyntheticCoreInstance(exports: internalExports)
        }

        /// Build core imports for a core module from the instantiation context.
        private func buildCoreImports(
            for coreModule: ParsedCoreModule,
            context: inout InstantiationContext
        ) throws -> Imports {
            var imports = Imports()

            for arg in coreModule.instantiateArgs {
                switch arg.source {
                case .coreInstance(let index):
                    guard index < context.coreInstances.count else {
                        throw ComponentLoaderError.invalidCoreInstanceIndex(index)
                    }
                    let sourceInstance = Instance(handle: context.coreInstances[index], store: store)
                    // Copy all exports from the source instance to satisfy the import
                    imports.define(module: arg.importName, sourceInstance.exports)

                case .componentImport(let name):
                    guard let importValue = context.imports.lookup(name: name) else {
                        throw ComponentLoaderError.missingImport(name: name)
                    }
                    // Component imports need to be converted to core imports
                    if case .coreInstance(let moduleHandle) = importValue {
                        let moduleInstance = Instance(handle: moduleHandle, store: store)
                        imports.define(module: arg.importName, moduleInstance.exports)
                    } else {
                        throw ComponentLoaderError.incompatibleImport(
                            name: name,
                            expected: "coreInstance",
                            got: String(describing: importValue)
                        )
                    }
                }
            }

            return imports
        }

        /// Process a component instance definition.
        private func processComponentInstanceDef(
            _ instanceDef: ParsedComponentInstanceDef,
            context: inout InstantiationContext
        ) throws {
            switch instanceDef {
            case .instantiate(let componentIndex, let args):
                guard componentIndex < context.nestedComponentDefs.count else {
                    throw ComponentLoaderError.invalidComponentIndex(componentIndex)
                }

                let nestedComponent = context.nestedComponentDefs[componentIndex]

                // Build imports for the nested component from the args
                var nestedImports = ComponentImports()
                for arg in args {
                    let value = try resolveComponentInstantiateArg(arg, context: &context)
                    nestedImports.define(name: arg.name, value)
                }

                // Recursively instantiate the nested component
                let nestedInstance = try instantiate(component: nestedComponent, imports: nestedImports)
                context.nestedComponents.append(nestedInstance.handle)

            case .exports(let exports):
                // Create an instance from inline exports
                var exportMap: [String: InternalComponentExternalValue] = [:]
                for export in exports {
                    let value = try resolveInlineExport(export, context: &context)
                    exportMap[export.name] = value
                }

                let entity = ComponentInstanceEntity(
                    coreInstances: [],
                    exports: exportMap,
                    functions: [],
                    nestedComponents: []
                )
                let handle = store.allocator.allocate(componentInstance: entity)
                context.nestedComponents.append(handle)
            }
        }

        /// Resolve a component instantiate argument to an external value.
        private func resolveComponentInstantiateArg(
            _ arg: ParsedComponentInstantiateArg,
            context: inout InstantiationContext
        ) throws -> ComponentExternalValue {
            switch arg.sort {
            case .core(let coreSort):
                switch coreSort {
                case .instance:
                    guard arg.index < context.coreInstances.count else {
                        throw ComponentLoaderError.invalidCoreInstanceIndex(arg.index)
                    }
                    return .coreInstance(Instance(handle: context.coreInstances[arg.index], store: store))

                case .module:
                    guard arg.index < context.coreModules.count else {
                        throw ComponentLoaderError.invalidCoreModuleIndex(arg.index)
                    }
                    return .coreModule(context.coreModules[arg.index])

                default:
                    throw ComponentLoaderError.instantiationFailed(
                        "Unsupported core sort in component instantiate arg: \(coreSort)"
                    )
                }

            case .func:
                guard arg.index < context.componentFunctions.count else {
                    throw ComponentLoaderError.invalidComponentFunctionIndex(arg.index)
                }
                return .function(ComponentFunction(handle: context.componentFunctions[arg.index], store: store))

            case .instance:
                guard arg.index < context.nestedComponents.count else {
                    throw ComponentLoaderError.instantiationFailed(
                        "Invalid component instance index: \(arg.index)"
                    )
                }
                return .instance(ComponentInstance(handle: context.nestedComponents[arg.index], store: store))

            case .value, .type, .component:
                throw ComponentLoaderError.instantiationFailed(
                    "Unsupported sort in component instantiate arg: \(arg.sort)"
                )
            }
        }

        /// Resolve an inline export to an internal external value.
        private func resolveInlineExport(
            _ export: ParsedComponentInlineExport,
            context: inout InstantiationContext
        ) throws -> InternalComponentExternalValue {
            switch export.sort {
            case .core(let coreSort):
                switch coreSort {
                case .instance:
                    guard export.index < context.coreInstances.count else {
                        throw ComponentLoaderError.invalidCoreInstanceIndex(export.index)
                    }
                    return .coreInstance(context.coreInstances[export.index])

                case .module:
                    guard export.index < context.coreModules.count else {
                        throw ComponentLoaderError.invalidCoreModuleIndex(export.index)
                    }
                    return .coreModule(context.coreModules[export.index])

                case .func:
                    guard export.index < context.coreFunctions.count else {
                        throw ComponentLoaderError.instantiationFailed(
                            "Invalid core function index: \(export.index)"
                        )
                    }
                    // Core functions from canon.lower need to be wrapped for export
                    // Create a temporary coreInstance to hold the function
                    // This is a workaround - ideally we'd have a proper core function external value
                    throw ComponentLoaderError.instantiationFailed(
                        "Core function inline export not yet fully supported"
                    )

                default:
                    throw ComponentLoaderError.instantiationFailed(
                        "Unsupported core sort in inline export: \(coreSort)"
                    )
                }

            case .func:
                guard export.index < context.componentFunctions.count else {
                    throw ComponentLoaderError.invalidComponentFunctionIndex(export.index)
                }
                return .function(context.componentFunctions[export.index])

            case .instance:
                guard export.index < context.nestedComponents.count else {
                    throw ComponentLoaderError.instantiationFailed(
                        "Invalid component instance index: \(export.index)"
                    )
                }
                return .instance(context.nestedComponents[export.index])

            case .value, .type, .component:
                throw ComponentLoaderError.instantiationFailed(
                    "Unsupported sort in inline export: \(export.sort)"
                )
            }
        }

        /// Process a canon.lift definition to create a component function.
        private func processCanonLift(
            _ canonDef: ParsedCanonicalDefinition,
            context: inout InstantiationContext
        ) throws -> InternalComponentFunction {
            guard case .lift(let coreInstanceIndex, let functionName, let type) = canonDef.kind else {
                throw ComponentLoaderError.instantiationFailed("Expected canon.lift definition")
            }

            guard coreInstanceIndex < context.coreInstances.count else {
                throw ComponentLoaderError.invalidCoreInstanceIndex(coreInstanceIndex)
            }

            let coreInstance = Instance(handle: context.coreInstances[coreInstanceIndex], store: store)
            guard let coreFunction = coreInstance.exports[function: functionName] else {
                throw ComponentLoaderError.coreExportNotFound(
                    instanceIndex: coreInstanceIndex,
                    name: functionName
                )
            }

            // Resolve canon options
            let canonOptions = try resolveCanonOptions(canonDef.options, context: &context)

            // Create a placeholder component instance handle for now
            // This will be updated when we have the actual component instance
            let placeholderEntity = ComponentInstanceEntity.empty
            let placeholderHandle = store.allocator.allocate(componentInstance: placeholderEntity)

            let entity = ComponentFunctionEntity(
                type: type,
                coreFunction: coreFunction.handle,
                canonOptions: canonOptions,
                instance: placeholderHandle,
                resolveType: context.resolveType
            )

            return store.allocator.allocate(componentFunction: entity)
        }

        /// Process a canon.lower definition to create a core function.
        /// This wraps a component function so it can be called from core wasm modules.
        private func processCanonLower(
            _ canonDef: ParsedCanonicalDefinition,
            context: inout InstantiationContext
        ) throws -> InternalFunction {
            guard case .lower(let componentFunctionIndex) = canonDef.kind else {
                throw ComponentLoaderError.instantiationFailed("Expected canon.lower definition")
            }

            guard componentFunctionIndex < context.componentFunctions.count else {
                throw ComponentLoaderError.invalidComponentFunctionIndex(componentFunctionIndex)
            }

            let componentFunction = ComponentFunction(
                handle: context.componentFunctions[componentFunctionIndex],
                store: store
            )
            let funcType = componentFunction.type

            // Convert component function type to core function type
            let coreFuncType = flattenComponentFuncType(funcType)

            // Create a host function that wraps the component function
            // When called, it:
            // 1. Lifts core arguments to component values
            // 2. Calls the component function
            // 3. Lowers component results to core values
            let wrappedFunction = Function(store: store, type: coreFuncType) { [componentFunction] _, coreArgs in
                // Lift core arguments to component values
                var componentArgs: [ComponentValue] = []
                var argIndex = 0
                for param in funcType.params {
                    let componentValue = try param.type.liftFlatCoreValue(coreArgs[argIndex])
                    componentArgs.append(componentValue)
                    argIndex += 1
                }

                // Call the component function
                let results = try componentFunction.invoke(componentArgs)

                // Lower component results to core values
                var coreResults: [Value] = []
                if let resultType = funcType.result {
                    for result in results {
                        let lowered = try lowerFlat(result, paramType: resultType)
                        coreResults.append(contentsOf: lowered)
                    }
                }

                return coreResults
            }

            return wrappedFunction.handle
        }

        /// Resolve canonical options to runtime references.
        private func resolveCanonOptions(
            _ options: ParsedCanonOptions,
            context: inout InstantiationContext
        ) throws -> CanonOptions {
            var memory: InternalMemory?
            var realloc: InternalFunction?
            var postReturn: InternalFunction?

            if let memoryRef = options.memory {
                guard memoryRef.coreInstanceIndex < context.coreInstances.count else {
                    throw ComponentLoaderError.invalidCoreInstanceIndex(memoryRef.coreInstanceIndex)
                }
                let coreInstance = Instance(handle: context.coreInstances[memoryRef.coreInstanceIndex], store: store)
                guard let mem = coreInstance.exports[memory: memoryRef.memoryName] else {
                    throw ComponentLoaderError.coreMemoryNotFound(
                        instanceIndex: memoryRef.coreInstanceIndex,
                        name: memoryRef.memoryName
                    )
                }
                memory = mem.handle
            }

            if let reallocRef = options.realloc {
                guard reallocRef.coreInstanceIndex < context.coreInstances.count else {
                    throw ComponentLoaderError.invalidCoreInstanceIndex(reallocRef.coreInstanceIndex)
                }
                let coreInstance = Instance(handle: context.coreInstances[reallocRef.coreInstanceIndex], store: store)
                guard let func_ = coreInstance.exports[function: reallocRef.functionName] else {
                    throw ComponentLoaderError.coreExportNotFound(
                        instanceIndex: reallocRef.coreInstanceIndex,
                        name: reallocRef.functionName
                    )
                }
                realloc = func_.handle
            }

            if let postReturnRef = options.postReturn {
                guard postReturnRef.coreInstanceIndex < context.coreInstances.count else {
                    throw ComponentLoaderError.invalidCoreInstanceIndex(postReturnRef.coreInstanceIndex)
                }
                let coreInstance = Instance(handle: context.coreInstances[postReturnRef.coreInstanceIndex], store: store)
                guard let func_ = coreInstance.exports[function: postReturnRef.functionName] else {
                    throw ComponentLoaderError.coreExportNotFound(
                        instanceIndex: postReturnRef.coreInstanceIndex,
                        name: postReturnRef.functionName
                    )
                }
                postReturn = func_.handle
            }

            return CanonOptions(
                memory: memory,
                realloc: realloc,
                postReturn: postReturn,
                stringEncoding: options.stringEncoding
            )
        }

        /// Build the exports map from parsed export definitions.
        private func buildExports(
            from exports: [ParsedComponentExport],
            context: inout InstantiationContext
        ) throws -> [String: InternalComponentExternalValue] {
            var result: [String: InternalComponentExternalValue] = [:]

            for export in exports {
                let value: InternalComponentExternalValue
                switch export.kind {
                case .function(let index):
                    guard index < context.componentFunctions.count else {
                        throw ComponentLoaderError.invalidComponentFunctionIndex(index)
                    }
                    value = .function(context.componentFunctions[index])

                case .value(let runtimeValue):
                    value = .value(runtimeValue)

                case .type(let typeIndex):
                    value = .type(typeIndex)

                case .instance(let index):
                    guard index < context.nestedComponents.count else {
                        throw ComponentLoaderError.instantiationFailed(
                            "Invalid nested component index: \(index)"
                        )
                    }
                    value = .instance(context.nestedComponents[index])

                case .coreModule(let moduleIndex):
                    guard moduleIndex < context.coreModules.count else {
                        throw ComponentLoaderError.invalidCoreModuleIndex(moduleIndex)
                    }
                    value = .coreModule(context.coreModules[moduleIndex])

                case .coreInstance(let instanceIndex):
                    guard instanceIndex < context.coreInstances.count else {
                        throw ComponentLoaderError.invalidCoreInstanceIndex(instanceIndex)
                    }
                    value = .coreInstance(context.coreInstances[instanceIndex])
                }

                result[export.name] = value
            }

            return result
        }

        /// Validate that the provided imports satisfy the component's import requirements.
        private func validateImports(
            _ requiredImports: [ParsedComponentImport],
            against providedImports: ComponentImports
        ) throws {
            for required in requiredImports {
                guard let provided = providedImports.lookup(name: required.name) else {
                    throw ComponentLoaderError.missingImport(name: required.name)
                }

                // Validate the kind matches
                switch (required.kind, provided) {
                case (.function, .function):
                    #warning("Function type compatibility not covered yet in `ComponentLoader.validateImports")
                    break

                case (.value, .value):
                    #warning("Value type compatibility not covered yet in `ComponentLoader.validateImports")
                    break

                case (.instance, .instance):
                    // Instance imports don't have detailed type checking yet
                    break

                case (.module, .coreModule):
                    // Module imports don't have detailed type checking yet
                    break

                case (.function, _):
                    throw ComponentLoaderError.incompatibleImport(
                        name: required.name,
                        expected: "function",
                        got: provided.tagDescription
                    )

                case (.value, _):
                    throw ComponentLoaderError.incompatibleImport(
                        name: required.name,
                        expected: "value",
                        got: provided.tagDescription
                    )

                case (.instance, _):
                    throw ComponentLoaderError.incompatibleImport(
                        name: required.name,
                        expected: "instance",
                        got: provided.tagDescription
                    )

                case (.module, _):
                    throw ComponentLoaderError.incompatibleImport(
                        name: required.name,
                        expected: "module",
                        got: provided.tagDescription
                    )
                }
            }
        }
    }

    // MARK: - ComponentExternalValue Internalization

    extension ComponentExternalValue {
        /// Convert a public external value to its internal representation.
        func internalize() -> InternalComponentExternalValue {
            switch self {
            case .function(let function):
                return .function(function.handle)
            case .value(let value):
                return .value(value)
            case .type(let typeIndex):
                return .type(typeIndex)
            case .instance(let instance):
                return .instance(instance.handle)
            case .coreModule(let module):
                return .coreModule(module)
            case .coreInstance(let moduleInstance):
                return .coreInstance(moduleInstance.handle)
            }
        }
    }

#endif
