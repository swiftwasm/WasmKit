import WasmParser

struct ModuleImports {
    let items: [Import]
    let numberOfFunctions: Int
    let numberOfGlobals: Int
    let numberOfMemories: Int
    let numberOfTables: Int

    static func build(
        from imports: [Import],
        functionTypeIndices: inout [TypeIndex],
        globalTypes: inout [GlobalType],
        memoryTypes: inout [MemoryType],
        tableTypes: inout [TableType]
    ) -> ModuleImports {
        var numberOfFunctions: Int = 0
        var numberOfGlobals: Int = 0
        var numberOfMemories: Int = 0
        var numberOfTables: Int = 0
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
            }
        }
        return ModuleImports(
            items: imports,
            numberOfFunctions: numberOfFunctions,
            numberOfGlobals: numberOfGlobals,
            numberOfMemories: numberOfMemories,
            numberOfTables: numberOfTables
        )
    }
}

/// A unit of stateless WebAssembly code, which is a direct representation of a module file. You can get one
/// by calling either ``parseWasm(bytes:features:)`` or ``parseWasm(filePath:features:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#modules>
public struct Module {
    public var types: [FunctionType] {
        translatorContext.typeSection
    }
    var functions: [GuestFunction]
    let elements: [ElementSegment]
    let data: [DataSegment]
    let start: FunctionIndex?
    public let imports: [Import]
    public let exports: [Export]
    public let customSections = [CustomSection]()

    let translatorContext: TranslatorContext
    let allocator: ISeqAllocator

    init(
        functions: [GuestFunction],
        elements: [ElementSegment],
        data: [DataSegment],
        start: FunctionIndex?,
        imports: [Import],
        exports: [Export],
        translatorContext: TranslatorContext,
        allocator: ISeqAllocator
    ) {
        self.functions = functions
        self.elements = elements
        self.data = data
        self.start = start
        self.imports = imports
        self.exports = exports
        self.translatorContext = translatorContext
        self.allocator = allocator
    }

    /// Materialize lazily-computed elements in this module
    public mutating func materializeAll() throws {
        for functionIndex in functions.indices {
            _ = try functions[functionIndex].body
        }
    }
}

extension Module {
    var internalGlobals: [Global] {
        return translatorContext.internalGlobals
    }
    var internalMemories: ArraySlice<MemoryType> {
        return translatorContext.memoryTypes[translatorContext.imports.numberOfMemories...]
    }
    var internalTables: ArraySlice<TableType> {
        return translatorContext.tableTypes[translatorContext.imports.numberOfTables...]
    }
}

// MARK: - Module Entity Indices
// <https://webassembly.github.io/spec/core/syntax/modules.html#syntax-typeidx>

/// Index type for function types within a module
public typealias TypeIndex = UInt32
/// Index type for tables within a module
public typealias FunctionIndex = UInt32
/// Index type for tables within a module
public typealias TableIndex = UInt32
/// Index type for memories within a module
public typealias MemoryIndex = UInt32
/// Index type for globals within a module
public typealias GlobalIndex = UInt32
/// Index type for elements within a module
public typealias ElementIndex = UInt32
/// Index type for data segments within a module
public typealias DataIndex = UInt32
/// Index type for labels within a function
typealias LocalIndex = UInt32
/// Index type for labels within a function
typealias LabelIndex = UInt32

// MARK: - Module Entities

/// An executable function representation in a module
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#functions>
struct GuestFunction {
    init(
        type: TypeIndex,
        locals: [WasmParser.ValueType],
        allocator: ISeqAllocator,
        body: @escaping () throws -> InstructionSequence
    ) {
        self.type = type
        self.defaultLocals = allocator.allocateDefaultLocals(locals)
        self.materializer = body
    }

    public let type: TypeIndex
    let defaultLocals: UnsafeBufferPointer<Value>
    private var _bodyStorage: InstructionSequence? = nil
    private let materializer: () throws -> InstructionSequence
    var body: InstructionSequence {
        mutating get throws {
            if let materialized = _bodyStorage {
                return materialized
            }
            let result = try materializer()
            self._bodyStorage = result
            return result
        }
    }
}
