import WasmParser

struct ModuleImports: Sendable {
    let numberOfFunctions: Int
    let numberOfGlobals: Int
    let numberOfMemories: Int
    let numberOfTables: Int
    let numberOfTags: Int

    static func build(
        from imports: [Import],
        functionTypeIndices: inout [TypeIndex],
        globalTypes: inout [GlobalType],
        memoryTypes: inout [MemoryType],
        tableTypes: inout [TableType],
        tagTypes: inout [TypeIndex]
    ) -> ModuleImports {
        var numberOfFunctions: Int = 0
        var numberOfGlobals: Int = 0
        var numberOfMemories: Int = 0
        var numberOfTables: Int = 0
        var numberOfTags: Int = 0
        for item in imports {
            switch item.descriptor {
            case .function(let typeIndex):
                numberOfFunctions += 1
                functionTypeIndices.append(typeIndex)
            case .table(let tableType):
                numberOfTables += 1
                tableTypes.append(tableType)
            case .memory(let memoryType):
                numberOfMemories += 1
                memoryTypes.append(memoryType)
            case .global(let globalType):
                numberOfGlobals += 1
                globalTypes.append(globalType)
            case .tag(let typeIndex):
                numberOfTags += 1
                tagTypes.append(typeIndex)
            }
        }
        return ModuleImports(
            numberOfFunctions: numberOfFunctions,
            numberOfGlobals: numberOfGlobals,
            numberOfMemories: numberOfMemories,
            numberOfTables: numberOfTables,
            numberOfTags: numberOfTags
        )
    }
}

/// A unit of stateless WebAssembly code, which is a direct representation of a module file. You can get one
/// by calling either ``parseWasm(bytes:features:)`` or ``parseWasm(filePath:features:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#modules>
public struct Module: Sendable {
    var functions: [GuestFunction]
    let elements: [ElementSegment]
    let data: [DataSegment]
    private(set) var start: FunctionIndex?
    let globals: [WasmParser.Global]
    let tags: [WasmParser.Tag]
    public let imports: [Import]
    public let exports: [Export]
    public let customSections: [CustomSection]
    let types: TypeSection

    let moduleImports: ModuleImports
    let importedFunctionTypes: [TypeIndex]
    let memoryTypes: [MemoryType]
    let tableTypes: [TableType]
    /// The initializer of each table defined in the module, `nil` for a table
    /// whose elements start out null.
    let tableInitializers: [ConstExpression?]
    let tagTypes: [TypeIndex]
    let features: WasmFeatureSet
    let dataCount: UInt32?

    init(
        types: TypeSection,
        functions: [GuestFunction],
        elements: [ElementSegment],
        data: [DataSegment],
        start: FunctionIndex?,
        imports: [Import],
        exports: [Export],
        globals: [WasmParser.Global],
        memories: [MemoryType],
        tables: [WasmParser.Table],
        tags: [WasmParser.Tag] = [],
        customSections: [CustomSection],
        features: WasmFeatureSet,
        dataCount: UInt32?
    ) {
        self.functions = functions
        self.elements = elements
        self.data = data
        self.start = start
        self.imports = imports
        self.exports = exports
        self.globals = globals
        self.tags = tags
        self.customSections = customSections
        self.features = features
        self.dataCount = dataCount

        var importedFunctionTypes: [TypeIndex] = []
        var globalTypes: [GlobalType] = []
        var memoryTypes: [MemoryType] = []
        var tableTypes: [TableType] = []
        var tagTypes: [TypeIndex] = []

        self.moduleImports = ModuleImports.build(
            from: imports,
            functionTypeIndices: &importedFunctionTypes,
            globalTypes: &globalTypes,
            memoryTypes: &memoryTypes,
            tableTypes: &tableTypes,
            tagTypes: &tagTypes
        )
        self.types = types
        self.importedFunctionTypes = importedFunctionTypes
        self.memoryTypes = memoryTypes + memories
        self.tableTypes = tableTypes + tables.map(\.type)
        self.tableInitializers = tables.map(\.initializer)
        self.tagTypes = tagTypes + tags.map { $0.type }
    }

    /// Returns the function type that the given type index defines, or `nil` if the index is out of
    /// range or defines a non-function type.
    @_spi(Fuzzing) @_spi(OnlyForCLI)
    public func functionType(at index: UInt32) -> FunctionType? {
        try? types.functionType(at: index)
    }

    internal func resolveFunctionType(_ index: FunctionIndex) throws(WasmKitError) -> FunctionType {
        guard Int(index) < functions.count + self.moduleImports.numberOfFunctions else {
            throw WasmKitError("Function index \(index) is out of range")
        }
        if Int(index) < self.moduleImports.numberOfFunctions {
            return try types.functionType(at: importedFunctionTypes[Int(index)])
        }
        return functions[Int(index) - self.moduleImports.numberOfFunctions].type
    }

    /// Drop the start section information from this module.
    ///
    /// This is useful to guarantee that "instantiation" of a module
    /// will eventually halt.
    @_spi(Fuzzing)
    public mutating func dropStartFunction() {
        self.start = nil
    }

    /// Instantiate this module in the given imports.
    ///
    /// - Parameters:
    ///   - store: The ``Store`` to allocate the instance in.
    ///   - imports: The imports to use for instantiation. All imported entities
    ///     must be allocated in the given store.
    public func instantiate(store: Store, imports: Imports = [:]) throws -> Instance {
        Instance(handle: try self.instantiateHandle(store: store, imports: imports), store: store)
    }

    /// Returns the type of an exported function, if it exists.
    ///
    /// This is metadata only; it does not instantiate the module.
    /// TODO(yuta): Revisit Module API
    package func exportedFunctionType(named name: String) -> FunctionType? {
        guard let export = exports.first(where: { $0.name == name }),
            case .function(let index) = export.descriptor
        else { return nil }
        return try? resolveFunctionType(index)
    }

    #if WasmDebuggingSupport
        /// Instantiate this module with the given imports.
        ///
        /// - Parameters:
        ///   - store: The ``Store`` to allocate the instance in.
        ///   - imports: The imports to use for instantiation. All imported entities
        ///     must be allocated in the given store.
        ///   - isDebuggable: Whether the module should support debugging actions
        ///     (breakpoints etc) after instantiation.
        public func instantiate(store: Store, imports: Imports = [:], isDebuggable: Bool) throws -> Instance {
            Instance(handle: try self.instantiateHandle(store: store, imports: imports, isDebuggable: isDebuggable), store: store)
        }
    #endif

    /// > Note:
    /// <https://webassembly.github.io/spec/core/exec/modules.html#instantiation>
    private func instantiateHandle(store: Store, imports: Imports, isDebuggable: Bool = false) throws -> InternalInstance {
        try ModuleValidator(module: self).validate()

        // Steps 5-8.

        // Step 9.
        // Process `elem.init` evaluation during allocation

        // Step 11.
        let instance = try store.allocator.allocate(
            module: self, engine: store.engine,
            resourceLimiter: store.resourceLimiter,
            imports: imports,
            isDebuggable: isDebuggable
        )

        if let nameSection = customSections.first(where: { $0.name == "name" }) {
            // FIXME?: Just ignore parsing error of name section for now.
            // Should emit warning instead of just discarding it?
            try? store.nameRegistry.register(instance: instance, nameSection: nameSection)
        }

        let constEvalContext = ConstEvaluationContext(instance: instance)
        // Step 12-13.

        // Steps 14-15.
        try initializeActiveElementSegments(instance: instance, constEvalContext: constEvalContext)

        // Step 16.
        try initializeActiveDataSegments(instance: instance, constEvalContext: constEvalContext)

        // Step 17.
        if let startIndex = start {
            let startFunction = try instance.functions[validating: Int(startIndex)]
            _ = try startFunction.invoke([], store: store)
        }

        // Compile all functions eagerly if the engine is in eager compilation mode
        if store.engine.configuration.compilationMode == .eager {
            try instance.withValue {
                try $0.compileAllFunctions(store: store)
            }
        }

        return instance
    }

    /// Materialize lazily-computed elements in this module
    @available(*, deprecated, message: "Module materialization is no longer supported. Instantiate the module explicitly instead.")
    public mutating func materializeAll() throws {}

    // MARK: - Segment Initialization Helpers

    /// Initialize active element segments into instance tables.
    private func initializeActiveElementSegments(
        instance: InternalInstance, constEvalContext: ConstEvaluationContext
    ) throws {
        for element in elements {
            guard case .active(let tableIndex, let offset) = element.mode else { continue }
            let table = try instance.tables[validating: Int(tableIndex)]
            let offsetValue = try offset.evaluate(
                context: constEvalContext,
                expectedType: .addressType(isMemory64: table.limits.isMemory64)
            )
            try table.withValue { table in
                guard let offset = offsetValue.maybeAddressOffset(table.limits.isMemory64) else {
                    throw WasmKitError(
                        kind: .message(
                            .unexpectedOffsetInitializer(
                                expected: .addressType(isMemory64: table.limits.isMemory64),
                                got: offsetValue
                            )
                        )
                    )
                }
                let elementType = try instance.typeCanonicalizer.canonicalize(element.type)
                guard elementType.isSubtype(of: table.tableType.elementType) else {
                    throw WasmKitError(
                        kind: .message(
                            .elementSegmentTypeMismatch(
                                elementType: elementType,
                                tableElementType: table.tableType.elementType
                            )
                        )
                    )
                }
                // A 64-bit offset that does not fit in `Int` cannot address any
                // table, so report it as out-of-bounds instead of trapping the host.
                guard let destination = Int(exactly: offset) else {
                    throw Trap(.tableOutOfBounds(Int(clamping: offset)))
                }
                let references = try element.evaluateInits(context: constEvalContext, type: elementType)
                try table.initialize(
                    references, from: 0, to: destination, count: references.count
                )
            }
        }
    }

    /// Initialize active data segments into instance memories.
    private func initializeActiveDataSegments(
        instance: InternalInstance, constEvalContext: ConstEvaluationContext
    ) throws {
        for case .active(let data) in self.data {
            let memory = try instance.memories[validating: Int(data.index), MemoryEntity.createOutOfBoundsError]
            let isMemory64 = memory.withValue { $0.limit.isMemory64 }
            let offsetValue = try data.offset.evaluate(
                context: constEvalContext,
                expectedType: .addressType(isMemory64: isMemory64)
            )
            try memory.withValue { memory in
                guard let offset = offsetValue.maybeAddressOffset(isMemory64) else {
                    throw WasmKitError(
                        kind: .message(
                            .unexpectedOffsetInitializer(
                                expected: .addressType(isMemory64: isMemory64),
                                got: offsetValue
                            )
                        )
                    )
                }
                // Ditto: an offset beyond `Int.max` is out of bounds for any memory.
                guard let destination = Int(exactly: offset) else {
                    throw Trap(.memoryOutOfBounds)
                }
                try memory.write(offset: destination, bytes: data.initializer)
            }
        }
    }
}

extension Module {
    var internalMemories: ArraySlice<MemoryType> {
        return memoryTypes[moduleImports.numberOfMemories...]
    }
    var internalTables: ArraySlice<TableType> {
        return tableTypes[moduleImports.numberOfTables...]
    }
}

// MARK: - Module Entity Indices
// <https://webassembly.github.io/spec/core/syntax/modules.html#syntax-typeidx>

/// Index type for function types within a module
typealias TypeIndex = UInt32
/// Index type for tables within a module
typealias FunctionIndex = UInt32
/// Index type for tables within a module
typealias TableIndex = UInt32
/// Index type for memories within a module
typealias MemoryIndex = UInt32
/// Index type for globals within a module
typealias GlobalIndex = UInt32
/// Index type for elements within a module
typealias ElementIndex = UInt32
/// Index type for data segments within a module
typealias DataIndex = UInt32
/// Index type for labels within a function
typealias LocalIndex = UInt32
/// Index type for labels within a function
typealias LabelIndex = UInt32

// MARK: - Module Entities

/// The type definitions of a module.
///
/// This hides how the definitions are stored from the rest of the runtime, so that the storage only GC
/// types need can be opted out later.
struct TypeSection: Sendable {
    /// The recursive groups in the order the type section declares them.
    let recursiveGroups: [RecursiveGroup]
    /// The definitions of every group in order, so that a type index addresses one directly.
    private let definitions: [SubType]

    init(_ recursiveGroups: [RecursiveGroup]) {
        self.recursiveGroups = recursiveGroups
        self.definitions = recursiveGroups.flatMap(\.types)
    }

    /// The number of type indices the section defines.
    var count: Int { definitions.count }

    /// Resolves a type index that must name a function type.
    func functionType(at index: TypeIndex) throws(WasmKitError) -> FunctionType {
        guard Int(index) < definitions.count else {
            throw WasmKitError("Type index \(index) is out of range")
        }
        guard case .function(let type) = definitions[Int(index)].body else {
            throw WasmKitError("Type index \(index) does not define a function type")
        }
        return type
    }

    /// The function type of every definition, for a module that ``ModuleValidator`` accepted.
    var functionTypes: [FunctionType] {
        definitions.map {
            guard case .function(let type) = $0.body else {
                preconditionFailure("Internal consistency error: GC type definition passed validation")
            }
            return type
        }
    }
}

/// An executable function representation in a module
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#functions>
struct GuestFunction: Sendable {
    let type: FunctionType
    let code: Code
}
