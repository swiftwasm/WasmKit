// https://webassembly.github.io/spec/syntax/modules.html#modules
struct Module {
    let types: [FunctionType]
    let functions: [Function]
    let tables: [Table]
    let memories: [Memory]
    let globals: [Global]
    let elements: [Element]
    let data: [Data]
    let start: FunctionIndex?
    let imports: [Import]
    let exports: [Export]
}

extension Module: Equatable {
    static func == (lhs: Module, rhs: Module) -> Bool {
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

// https://webassembly.github.io/spec/syntax/modules.html#syntax-typeidx
typealias TypeIndex = UInt32
typealias FunctionIndex = UInt32
typealias TableIndex = UInt32
typealias MemoryIndex = UInt32
typealias GlobalIndex = UInt32
typealias LocalIndex = UInt32
typealias LabelIndex = UInt32

// https://webassembly.github.io/spec/syntax/modules.html#functions
struct Function {
    let type: TypeIndex
    let locals: [Value.Type]
    let body: Expression
}

extension Function: Equatable {
    static func == (lhs: Function, rhs: Function) -> Bool {
        return lhs.type == rhs.type && lhs.locals == rhs.locals && lhs.body == rhs.body
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#tables

struct Table {
    let type: TableType
}

extension Table: Equatable {
    static func == (lhs: Table, rhs: Table) -> Bool {
        return lhs.type == rhs.type
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#memories

struct Memory {
    let type: MemoryType
}

extension Memory: Equatable {
    static func == (lhs: Memory, rhs: Memory) -> Bool {
        return lhs.type == rhs.type
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#globals

struct Global {
    let type: GlobalType
    let initializer: Expression
}

extension Global: Equatable {
    static func == (lhs: Global, rhs: Global) -> Bool {
        return (lhs.type, lhs.initializer) == (rhs.type, rhs.initializer)
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#element-segments

struct Element {
    let table: TableIndex
    let offset: Expression
    let initializer: [FunctionIndex]
}

extension Element: Equatable {
    static func == (lhs: Element, rhs: Element) -> Bool {
        return (lhs.table, lhs.offset) == (rhs.table, rhs.offset) && lhs.initializer == rhs.initializer
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#data-segments

struct Data {
    let data: MemoryIndex
    let offset: Expression
    let initializer: [Byte]
}

extension Data: Equatable {
    static func == (lhs: Data, rhs: Data) -> Bool {
        return (lhs.data, lhs.offset) == (rhs.data, rhs.offset) && lhs.initializer == rhs.initializer
    }
}

// https://webassembly.github.io/spec/syntax/modules.html#exports

struct Export {
    let name: Name
    let descriptor: ExportDescriptor
}

extension Export: Equatable {
    static func == (lhs: Export, rhs: Export) -> Bool {
        return (lhs.name, lhs.descriptor) == (rhs.name, rhs.descriptor)
    }
}

enum ExportDescriptor {
    case function(FunctionIndex)
    case table(TableIndex)
    case memory(MemoryIndex)
    case global(GlobalIndex)
}

extension ExportDescriptor: Equatable {
    static func == (lhs: ExportDescriptor, rhs: ExportDescriptor) -> Bool {
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

struct Import {
    let module: Name
    let name: Name
    let descripter: ImportDescriptor
}

extension Import: Equatable {
    static func == (lhs: Import, rhs: Import) -> Bool {
        return (lhs.module, lhs.name, lhs.descripter) == (rhs.module, rhs.name, rhs.descripter)
    }
}

enum ImportDescriptor {
    case function(TypeIndex)
    case table(TableType)
    case memory(MemoryType)
    case global(GlobalType)
}

extension ImportDescriptor: Equatable {
    static func == (lhs: ImportDescriptor, rhs: ImportDescriptor) -> Bool {
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
