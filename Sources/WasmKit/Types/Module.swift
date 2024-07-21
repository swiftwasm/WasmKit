import WasmParser

/// A unit of stateless WebAssembly code, which is a direct representation of a module file. You can get one
/// by calling either ``parseWasm(bytes:features:)`` or ``parseWasm(filePath:features:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#modules>
public struct Module {
    public internal(set) var types: [FunctionType]
    var functions: [GuestFunction]
    var tables: [Table]
    var memories: [Memory]
    var globals: [Global]
    var elements: [ElementSegment]
    var data: [DataSegment]
    var start: FunctionIndex?
    public internal(set) var imports: [Import]
    public internal(set) var exports: [Export]
    public internal(set) var customSections = [CustomSection]()
    let allocator: ISeqAllocator

    init(
        types: [FunctionType] = [],
        functions: [GuestFunction] = [],
        tables: [Table] = [],
        memories: [Memory] = [],
        globals: [Global] = [],
        elements: [ElementSegment] = [],
        data: [DataSegment] = [],
        start: FunctionIndex? = nil,
        imports: [Import] = [],
        exports: [Export] = []
    ) {
        self.types = types
        self.functions = functions
        self.tables = tables
        self.memories = memories
        self.globals = globals
        self.elements = elements
        self.data = data
        self.start = start
        self.imports = imports
        self.exports = exports
        self.allocator = ISeqAllocator()
    }

    /// Materialize lazily-computed elements in this module
    public mutating func materializeAll() throws {
        for functionIndex in functions.indices {
            _ = try functions[functionIndex].body
        }
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
