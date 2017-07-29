// https://webassembly.github.io/spec/syntax/modules.html#syntax-typeidx
typealias TypeIndex = UInt32
typealias FunctionIndex = UInt32
typealias TableIndex = UInt32
typealias MemoryIndex = UInt32
typealias GlobalIndex = UInt32
typealias LocalIndex = UInt32
typealias LabelIndex = UInt32

// https://webassembly.github.io/spec/syntax/types.html#value-types
protocol Value {
}

extension Int32: Value {}
extension Int64: Value {}
extension UInt32: Value {}
extension UInt64: Value {}

enum ValueType {
	case int32
	case int64
	case uint32
	case uint64
	case any
}

// https://webassembly.github.io/spec/syntax/types.html#result-types
typealias ResultType = (ValueType)

// https://webassembly.github.io/spec/syntax/types.html#function-types
struct FunctionType {
	private struct _Any: Value {}
	static let any = FunctionType(parameters: [ValueType.any], results: [ValueType.any])
	var parameters: [ValueType]
	var results: [ValueType]
}

// https://webassembly.github.io/spec/syntax/types.html#limits
struct Limits {
	let min: UInt32
	let max: UInt32?
}

// https://webassembly.github.io/spec/syntax/types.html#memory-types
typealias MemoryType = Limits

// https://webassembly.github.io/spec/syntax/types.html#table-types
struct TableType {
	var limits: Limits
	let elementType: FunctionType = .any
}

// https://webassembly.github.io/spec/syntax/types.html#global-types
enum Mutability {
	case constant
	case variable
}

// https://webassembly.github.io/spec/syntax/types.html#global-types
struct GlobalType {
	var mutability: Mutability?
	var valueType: ValueType
}

// https://webassembly.github.io/spec/syntax/types.html#external-types
enum ExternalType {
	case function(FunctionType)
	case table(TableType)
	case memory(MemoryType)
	case global(GlobalType)
}
