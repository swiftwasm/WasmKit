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

struct Table {
	let type: TableType
}

extension Table: Equatable {
	static func == (lhs: Table, rhs: Table) -> Bool {
		return lhs.type == rhs.type
	}
}

struct Memory {
	let type: MemoryType
}

extension Memory: Equatable {
	static func == (lhs: Memory, rhs: Memory) -> Bool {
		return lhs.type == rhs.type
	}
}

struct Global {
	let type: GlobalType
	let initializer: Expression
}

extension Global: Equatable {
	static func == (lhs: Global, rhs: Global) -> Bool {
		return (lhs.type, lhs.initializer) == (rhs.type, rhs.initializer)
	}
}

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

struct Code {
	let locals: [ValueType]
	let expression: Expression
}

extension Code: Equatable {
	static func == (lhs: Code, rhs: Code) -> Bool {
		return lhs.locals == rhs.locals && lhs.expression == rhs.expression
	}
}
