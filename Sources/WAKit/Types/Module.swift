// https://webassembly.github.io/spec/syntax/modules.html#modules
public struct Module: AutoEquatable {
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

public enum Section: AutoEquatable {
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

// https://webassembly.github.io/spec/syntax/modules.html#syntax-typeidx
public typealias TypeIndex = UInt32
public typealias FunctionIndex = UInt32
public typealias TableIndex = UInt32
public typealias MemoryIndex = UInt32
public typealias GlobalIndex = UInt32
public typealias LocalIndex = UInt32
public typealias LabelIndex = UInt32

// https://webassembly.github.io/spec/syntax/modules.html#functions
public struct Function: AutoEquatable {
    let type: TypeIndex
    let locals: [ValueType]
    let body: Expression
}

// https://webassembly.github.io/spec/syntax/modules.html#tables

public struct Table: AutoEquatable {
    let type: TableType
}

// https://webassembly.github.io/spec/syntax/modules.html#memories

public struct Memory: AutoEquatable {
    let type: MemoryType
}

// https://webassembly.github.io/spec/syntax/modules.html#globals

public struct Global: AutoEquatable {
    let type: GlobalType
    let initializer: Expression
}

// https://webassembly.github.io/spec/syntax/modules.html#element-segments

public struct Element: AutoEquatable {
    let table: TableIndex
    let offset: Expression
    let initializer: [FunctionIndex]
}

// https://webassembly.github.io/spec/syntax/modules.html#data-segments

public struct Data: AutoEquatable {
    let data: MemoryIndex
    let offset: Expression
    let initializer: [UInt8]
}

// https://webassembly.github.io/spec/syntax/modules.html#exports

public struct Export: AutoEquatable {
    let name: String
    let descriptor: ExportDescriptor
}

public enum ExportDescriptor: AutoEquatable {
    case function(FunctionIndex)
    case table(TableIndex)
    case memory(MemoryIndex)
    case global(GlobalIndex)
}

// https://webassembly.github.io/spec/syntax/modules.html#imports

public struct Import: AutoEquatable {
    let module: String
    let name: String
    let descripter: ImportDescriptor
}

public enum ImportDescriptor: AutoEquatable {
    case function(TypeIndex)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}
