/// A unit of stateless WebAssembly code, which is a direct representation of a module file. You can get one
/// by calling either ``parseWasm(bytes:features:)`` or ``parseWasm(filePath:features:)``.
/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#modules>
public struct Module {
    public internal(set) var types: [FunctionType]
    var functions: [GuestFunction]
    public internal(set) var tables: [Table]
    public internal(set) var memories: [Memory]
    public internal(set) var globals: [Global]
    public internal(set) var elements: [ElementSegment]
    public internal(set) var dataCount: UInt32?
    public internal(set) var data: [DataSegment]
    public internal(set) var start: FunctionIndex?
    public internal(set) var imports: [Import]
    public internal(set) var exports: [Export]
    public internal(set) var customSections = [CustomSection]()

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
    }

    /// Materialize lazily-computed elements in this module
    public mutating func materializeAll() throws {
        for functionIndex in functions.indices {
            _ = try functions[functionIndex].body
        }
    }
}

public struct CustomSection: Equatable {
    public let name: String
    public let bytes: ArraySlice<UInt8>
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#syntax-typeidx>
public typealias TypeIndex = UInt32
public typealias FunctionIndex = UInt32
public typealias TableIndex = UInt32
public typealias MemoryIndex = UInt32
public typealias GlobalIndex = UInt32
public typealias ElementIndex = UInt32
public typealias DataIndex = UInt32
public typealias LocalIndex = UInt32
public typealias LabelIndex = UInt32

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#functions>
struct GuestFunction {
    init(type: TypeIndex, locals: [ValueType], body: @escaping () throws -> InstructionSequence) {
        self.type = type
        // TODO: Deallocate const default locals after the module is deallocated
        let defaultLocals = UnsafeMutableBufferPointer<Value>.allocate(capacity: locals.count)
        for (index, localType) in locals.enumerated() {
            defaultLocals[index] = localType.defaultValue
        }
        self.defaultLocals = UnsafeBufferPointer(defaultLocals)
        self.materializer = body
    }

    public let type: TypeIndex
    public let defaultLocals: UnsafeBufferPointer<Value>
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

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#tables>
public struct Table: Equatable {
    public let type: TableType
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#memories>
public struct Memory: Equatable {
    public let type: MemoryType
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#globals>
public struct Global: Equatable {
    let type: GlobalType
    let initializer: Expression
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#element-segments>
public struct ElementSegment: Equatable {
    struct Flag: OptionSet {
        let rawValue: UInt32

        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        var segmentHasElemKind: Bool {
            !contains(.usesExpressions) && rawValue != 0
        }

        var segmentHasRefType: Bool {
            contains(.usesExpressions) && rawValue != 4
        }

        static let isPassiveOrDeclarative = Flag(rawValue: 1 << 0)
        static let isDeclarative = Flag(rawValue: 1 << 1)
        static let hasTableIndex = Flag(rawValue: 1 << 1)
        static let usesExpressions = Flag(rawValue: 1 << 2)
    }

    enum Mode: Equatable {
        case active(table: TableIndex, offset: InstructionSequence)
        case declarative
        case passive
    }

    public let type: ReferenceType
    let initializer: [Expression]
    let mode: Mode
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#data-segments>
public enum DataSegment: Equatable {
    public struct Active: Equatable {
        let index: MemoryIndex
        let offset: InstructionSequence
        let initializer: ArraySlice<UInt8>
    }

    case passive([UInt8])
    case active(Active)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#exports>
public struct Export: Equatable {
    public let name: String
    public let descriptor: ExportDescriptor
}

public enum ExportDescriptor: Equatable {
    case function(FunctionIndex)
    case table(TableIndex)
    case memory(MemoryIndex)
    case global(GlobalIndex)
}

/// > Note:
/// <https://webassembly.github.io/spec/core/syntax/modules.html#imports>
public struct Import: Equatable {
    public let module: String
    public let name: String
    public let descriptor: ImportDescriptor
}

public enum ImportDescriptor: Equatable {
    case function(TypeIndex)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}
