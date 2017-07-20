typealias Byte = UInt8
typealias Name = String

// https://webassembly.github.io/spec/exec/runtime.html#store
struct Store {
	var functions: [FunctionInstance] = []
	var tables: [TableInstance] = []
	var memories: [MemoryInstance] = []
	var globals: [GlobalInstance] = []
}

// https://webassembly.github.io/spec/exec/runtime.html#addresses
typealias Address = Int

typealias FunctionAddress = Address
typealias TableAddress = Address
typealias MemoryAddress = Address
typealias GlobalAddress = Address

// https://webassembly.github.io/spec/exec/runtime.html#module-instances
protocol ModuleInstance {
	var types: [FunctionType] { get }
	var functionAddresses: [FunctionAddress] { get }
	var tableAddresses: [TableAddress] { get }
	var memoryAddresses: [MemoryAddress] { get }
	var globalAddresses: [GlobalAddress] { get }
	var exports: [ExportInstance] { get }
}

// https://webassembly.github.io/spec/exec/runtime.html#function-instances
struct FunctionInstance {
	let type: FunctionType
	let module: ModuleInstance
	let code: Function
}

// https://webassembly.github.io/spec/syntax/modules.html#functions
struct Function {
	let type: TypeIndex
	let locals: [Value]
	let body: Expression
}

// https://webassembly.github.io/spec/exec/runtime.html#table-instances
struct TableInstance {
	let elements: [FunctionElement]
}

// https://webassembly.github.io/spec/exec/runtime.html#syntax-funcelem
enum FunctionElement {
	case functionAddress(FunctionAddress?)
}

// https://webassembly.github.io/spec/exec/runtime.html#memory-instances
struct MemoryInstance {
	var data: [Byte]
	var max: UInt32?
}

// https://webassembly.github.io/spec/exec/runtime.html#global-instances
struct GlobalInstance {
	var value: Value
	var mutability: Mutability
}

// https://webassembly.github.io/spec/exec/runtime.html#export-instances
struct ExportInstance {
	var name: Name
	var value: ExternalValue
}

// https://webassembly.github.io/spec/exec/runtime.html#external-values
enum ExternalValue {
	case function(FunctionAddress)
	case table(TableAddress)
	case memory(MemoryAddress)
	case global(GlobalAddress)
}

// https://webassembly.github.io/spec/exec/runtime.html#stack

typealias Label = String

struct Stack {
	var values: [Value]
	var labels: [Label: Expression]
	var frame: Frame
}

struct Frame {
	var locals: [Value] = []
	let module: ModuleInstance
}
