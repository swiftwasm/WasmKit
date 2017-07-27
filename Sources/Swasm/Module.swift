struct Module {
	let types: [FunctionType]
	let functions: [Function]
	let tables: [Table]
	let memories: [Memory]
	let globals: [Global]
	let elements: [Element]
	let data: [Data]
	let start: FunctionIndex?
	let exports: [Export]
	let imports: [Import]
}

struct Table {
	let type: TableType
}

struct Memory {
	let type: MemoryType
}

struct Global {
	let type: GlobalType
	let initializer: Expression
}

struct Element {
	let table: TableIndex
	let offset: Expression
	let initializer: [FunctionIndex]
}

struct Data {
	let data: MemoryIndex
	let offset: Expression
	let initializer: [Byte]
}

struct Export {
	let name: Name
	let descriptor: ExportDescriptor
}

enum ExportDescriptor {
	case function(FunctionIndex)
	case table(TableIndex)
	case memory(MemoryIndex)
	case global(GlobalIndex)
}

struct Import {
	let module: Name
	let name: Name
	let descripter: ImportDescriptor
}

enum ImportDescriptor {
	case function(TypeIndex)
	case table(TableType)
	case memory(MemoryType)
	case global(GlobalType)
}
