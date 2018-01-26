// https://webassembly.github.io/spec/syntax/modules.html#modules
public struct Module {
    var types: [FunctionType]
    var functions: [Function]
    var tables: [Table]
    var memories: [Memory]
    var globals: [Global]
    var elements: [Element]
    var data: [Data]
    var start: FunctionIndex?
    var imports: [Import]
    var exports: [Export]

    public init(types: [FunctionType] = [],
                functions: [Function] = [],
                tables: [Table] = [],
                memories: [Memory] = [],
                globals: [Global] = [],
                elements: [Element] = [],
                data: [Data] = [],
                start: FunctionIndex? = nil,
                imports: [Import] = [],
                exports: [Export] = []) {
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
}

extension Module: Equatable {
    public static func == (lhs: Module, rhs: Module) -> Bool {
        return (
            lhs.types == rhs.types &&
                lhs.functions == rhs.functions &&
                lhs.tables == rhs.tables &&
                lhs.memories == rhs.memories &&
                lhs.globals == rhs.globals &&
                lhs.elements == rhs.elements &&
                lhs.data == rhs.data &&
                lhs.start == rhs.start &&
                lhs.imports == rhs.imports &&
                lhs.exports == rhs.exports
        )
    }
}

public enum Section {
    case custom(name: String, bytes: [UInt8])
    case type([FunctionType])
    case `import`([Import])
    case function([TypeIndex])
    case table([Table])
    case memory([Memory])
    case global([Global])
    case export([Export])
    case start(FunctionIndex)
    case element([Element])
    case code([Code])
    case data([Data])
}

extension Section: Equatable {
    public static func == (lhs: Section, rhs: Section) -> Bool {
        switch (lhs, rhs) {
        case let (.custom(l1, l2), .custom(name: r1, bytes: r2)):
            return l1 == r1 && l2 == r2
        case let (.type(l), .type(r)):
            return l == r
        case let (.import(l), .import(r)):
            return l == r
        case let (.function(l), .function(r)):
            return l == r
        case let (.table(l), .table(r)):
            return l == r
        case let (.memory(l), .memory(r)):
            return l == r
        case let (.global(l), .global(r)):
            return l == r
        case let (.export(l), .export(r)):
            return l == r
        case let (.start(l), .start(r)):
            return l == r
        case let (.element(l), .element(r)):
            return l == r
        case let (.code(l), .code(r)):
            return l == r
        case let (.data(l), .data(r)):
            return l == r
        default:
            return false
        }
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#syntax-typeidx
public typealias TypeIndex = UInt32
public typealias FunctionIndex = UInt32
public typealias TableIndex = UInt32
public typealias MemoryIndex = UInt32
public typealias GlobalIndex = UInt32
public typealias LocalIndex = UInt32
public typealias LabelIndex = UInt32

// https://webassembly.github.io/spec/syntax/modules.html#functions
public struct Function {
    let type: TypeIndex
    let locals: [Value.Type]
    let body: Expression
}

extension Function: Equatable {
    public static func == (lhs: Function, rhs: Function) -> Bool {
        return lhs.type == rhs.type && lhs.locals == rhs.locals && lhs.body == rhs.body
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#tables

public struct Table {
    let type: TableType
}

extension Table: Equatable {
    public static func == (lhs: Table, rhs: Table) -> Bool {
        return lhs.type == rhs.type
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#memories

public struct Memory {
    let type: MemoryType
}

extension Memory: Equatable {
    public static func == (lhs: Memory, rhs: Memory) -> Bool {
        return lhs.type == rhs.type
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#globals

public struct Global {
    let type: GlobalType
    let initializer: Expression
}

extension Global: Equatable {
    public static func == (lhs: Global, rhs: Global) -> Bool {
        return (lhs.type, lhs.initializer) == (rhs.type, rhs.initializer)
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#element-segments

public struct Element {
    let table: TableIndex
    let offset: Expression
    let initializer: [FunctionIndex]
}

extension Element: Equatable {
    public static func == (lhs: Element, rhs: Element) -> Bool {
        return (lhs.table, lhs.offset) == (rhs.table, rhs.offset) && lhs.initializer == rhs.initializer
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#data-segments

public struct Data {
    let data: MemoryIndex
    let offset: Expression
    let initializer: [UInt8]
}

extension Data: Equatable {
    public static func == (lhs: Data, rhs: Data) -> Bool {
        return (lhs.data, lhs.offset) == (rhs.data, rhs.offset) && lhs.initializer == rhs.initializer
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#exports

public struct Export {
    let name: String
    let descriptor: ExportDescriptor
}

extension Export: Equatable {
    public static func == (lhs: Export, rhs: Export) -> Bool {
        return (lhs.name, lhs.descriptor) == (rhs.name, rhs.descriptor)
    }
}

public enum ExportDescriptor {
    case function(FunctionIndex)
    case table(TableIndex)
    case memory(MemoryIndex)
    case global(GlobalIndex)
}

extension ExportDescriptor: Equatable {
    public static func == (lhs: ExportDescriptor, rhs: ExportDescriptor) -> Bool {
        switch (lhs, rhs) {
        case let (.function(l), .function(r)):
            return l == r
        case let (.table(l), .table(r)):
            return l == r
        case let (.memory(l), .memory(r)):
            return l == r
        case let (.global(l), .global(r)):
            return l == r
        default:
            return false
        }
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#imports

public struct Import {
    let module: String
    let name: String
    let descripter: ImportDescriptor
}

extension Import: Equatable {
    public static func == (lhs: Import, rhs: Import) -> Bool {
        return (lhs.module, lhs.name, lhs.descripter) == (rhs.module, rhs.name, rhs.descripter)
    }
}

public enum ImportDescriptor {
    case function(TypeIndex)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}

extension ImportDescriptor: Equatable {
    public static func == (lhs: ImportDescriptor, rhs: ImportDescriptor) -> Bool {
        switch (lhs, rhs) {
        case let (.function(l), .function(r)):
            return l == r
        case let (.table(l), .table(r)):
            return l == r
        case let (.memory(l), .memory(r)):
            return l == r
        case let (.global(l), .global(r)):
            return l == r
        default:
            return false
        }
    }
}
