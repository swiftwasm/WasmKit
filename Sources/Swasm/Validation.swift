protocol ValidationError: Error, CustomStringConvertible {}

protocol Validatable {
	func validate(with context: Context) throws
}

// Utility Function

protocol IndexConvertible {
	var indexValue: Int { get }
}

extension UInt32: IndexConvertible {
	var indexValue: Int {
		return Int(self)
	}
}

extension Array {
	subscript(index: IndexConvertible) -> Element {
		get {
			return self[index.indexValue]
		}
	}

	func contains(index: IndexConvertible) -> Bool {
		return indices.contains(index.indexValue)
	}
}

// https://webassembly.github.io/spec/valid/conventions.html#contexts
struct Context {
	var types: [FunctionType]
	var functions: [FunctionType]
	var tables: [TableType]
	var memories: [MemoryType]
	var globals: [GlobalType]
	var locals: [ValueType]
	var labels: [ResultType]
	var `return`: ResultType?
}

extension Module: Validatable {
	enum ModuleValidationError: ValidationError {
		case invalidTypeIndex(TypeIndex)
		case invalidFunctionIndexForStart(FunctionIndex)
		case startFunctionTypeIsNotEmpty(FunctionType)
		case tooManyTables
		case tooManyMemories
		case namesInExportsAreNotDistinct([String])

		var description: String {
			switch self {
			case .invalidTypeIndex(let index):
				return "Type index is invalid: \(index)"
			case .invalidFunctionIndexForStart(let index):
				return "Start function index is invalid: \(index)"
			case .startFunctionTypeIsNotEmpty(let type):
				return "Start function type is invalid: \(type)"
			case .tooManyTables:
				return "Too many tables"
			case .tooManyMemories:
				return "Too many memories"
			case .namesInExportsAreNotDistinct(let names):
				return "Names are not distinct: \(names)"
			}
		}
	}

	typealias ExternalTypes = (
		functions: [FunctionType],
		tables: [TableType],
		memories: [MemoryType],
		globals: [GlobalType]
	)

	func externalTypes(imports: [Import]) throws -> ExternalTypes {
		var functions = [FunctionType]()
		var tables = [TableType]()
		var memories = [MemoryType]()
		var globals = [GlobalType]()

		for `import` in imports {
			switch `import`.descripter {
			case let .function(index):
				guard types.contains(index: index) else {
					throw ModuleValidationError.invalidTypeIndex(index)
				}
				functions.append(types[index])
			case let .table(index):
				tables.append(index)
			case let .memory(index):
				memories.append(index)
			case let .global(index):
				globals.append(index)
			}
		}

		return (functions, tables, memories, globals)
	}

	// https://webassembly.github.io/spec/valid/modules.html#valid-module
	func validate() throws {
		let moduleFunctions: [FunctionType] = try functions.map {
			guard types.contains(index: $0.type) else {
				throw ModuleValidationError.invalidTypeIndex($0.type)
			}
			return types[$0.type]
		}

		let (externalFunctions, externalTables, externalMemories, externalGlobals) =
			try externalTypes(imports: imports)

		let context = Context(
			types: types,
			functions: externalFunctions + moduleFunctions,
			tables: externalTables + tables.map { $0.type },
			memories: externalMemories + memories.map { $0.type },
			globals: externalGlobals + globals.map { $0.type },
			locals: [],
			labels: [],
			return: nil
		)

		return try validate(with: context)
	}

	// https://webassembly.github.io/spec/valid/modules.html#modules
	func validate(with context: Context) throws {
		let (_, _, _, externalGlobals) = try externalTypes(imports: imports)

		for type in types {
			try type.validate(with: context)
		}

		for function in functions {
			try function.validate(with: context)
		}

		for table in tables {
			try table.validate(with: context)
		}

		for memory in memories {
			try memory.validate(with: context)
		}

		let c = Context(
			types: [],
			functions: [],
			tables: [],
			memories: [],
			globals: externalGlobals,
			locals: [],
			labels: [],
			return: nil
		)
		for global in globals {
			try global.validate(with: c)
		}

		for element in elements {
			try element.validate(with: context)
		}

		for data in data {
			try data.validate(with: context)
		}

		// https://webassembly.github.io/spec/valid/modules.html#start-function
		if let start = start {
			guard context.functions.contains(index: start) else {
				throw ModuleValidationError.invalidFunctionIndexForStart(start)
			}
			let startFunction = context.functions[start]
			guard startFunction.parameters.isEmpty && startFunction.results.isEmpty else {
				throw ModuleValidationError.startFunctionTypeIsNotEmpty(startFunction)
			}
		}

		for `import` in imports {
			try `import`.validate(with: context)
		}

		for export in exports {
			try export.validate(with: context)
		}

		guard context.tables.count <= 1 else {
			throw ModuleValidationError.tooManyTables
		}

		guard context.memories.count <= 1 else {
			throw ModuleValidationError.tooManyMemories
		}

		func isDistinct<Element: Equatable & Hashable>(_ array: [Element]) -> Bool {
			return Set(array).count == array.count

		}

		let names = exports.map { $0.name }
		guard isDistinct(names) else {
			throw ModuleValidationError.namesInExportsAreNotDistinct(names)
		}
	}
}

extension FunctionType: Validatable {
	enum FunctionTypeValidationError: ValidationError {
		case tooManyResultTypes([ValueType])

		var description: String {
			switch self {
			case .tooManyResultTypes(let types):
				return "Too many result types: \(types)"
			}
		}
	}

	func validate(with _: Context) throws {
		guard results.count <= 1 else {
			throw FunctionTypeValidationError.tooManyResultTypes(results)
		}
	}
}

extension Function: Validatable {
	enum FunctionValidationError: ValidationError {
		case invalidTypeIndex(TypeIndex)
		case tooManyResultTypes([ValueType])

		var description: String {
			switch self {
			case .invalidTypeIndex(let index):
				return "Type index is invalid: \(index)"
			case .tooManyResultTypes(let types):
				return "Too many result types: \(types)"
			}
		}
	}

	// https://webassembly.github.io/spec/valid/modules.html#functions
	func validate(with context: Context) throws {
		guard context.types.contains(index: type) else {
			throw FunctionValidationError.invalidTypeIndex(type)
		}
		let functionType = context.types[type]

		let c = try { () -> Context in
			var c = context
			c.locals = functionType.parameters + context.locals
			guard functionType.results.count <= 1 else {
				throw FunctionValidationError.tooManyResultTypes(functionType.results)
			}
			c.labels = [functionType.results]
			c.`return` = functionType.results
			return c
		}()

		try body.validate(with: c)
	}
}

// https://webassembly.github.io/spec/valid/instructions.html#expressions
extension Expression: Validatable {
	func validate(with context: Context) throws {
//		for instruction in instructions {
//			try instruction.validate(with: context)
//		}
	}
}

extension Expression {
	var isConstant: Bool {
		for instruction in instructions {
			guard instruction.isConstant else {
				return false
			}
		}
		return true
	}
}

extension Table: Validatable {

	// https://webassembly.github.io/spec/valid/types.html#table-types
	func validate(with context: Context) throws {
		try type.limits.validate(with: context)
	}

}

// https://webassembly.github.io/spec/valid/modules.html#memories
extension Memory: Validatable {
	func validate(with context: Context) throws {
		try type.validate(with: context)
	}
}

// https://webassembly.github.io/spec/valid/types.html#valid-limits
extension Limits: Validatable {
	enum LimitsValidationError: ValidationError {
		case maxIsSmallerThanMin(min: UInt32, max: UInt32)

		var description: String {
			switch self {
			case .maxIsSmallerThanMin(let min, let max):
				return "Limit max (\(max) is smaller than min (\(min))"
			}
		}
	}

	func validate(with _: Context) throws {
		if let max = max, max < min {
			throw LimitsValidationError.maxIsSmallerThanMin(min: min, max: max)
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#globals
extension Global: Validatable {
	enum GlobalValidateError: ValidationError {
		case initializerIsNotConstant(Expression)

		var description: String {
			switch self {
			case .initializerIsNotConstant(let expression):
				return "Initializer is not constant: \(expression)"
			}
		}
	}

	func validate(with context: Context) throws {
		// type.mutability is always valid
		try initializer.validate(with: context)

		guard initializer.isConstant else {
			throw GlobalValidateError.initializerIsNotConstant(initializer)
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#element-segments
extension Element: Validatable {
	enum ElementValidationError: ValidationError {
		case invalidTableIndex(TableIndex)
		case elementTypeOfTableIsNotAny(FunctionType)
		case offsetIsNotConstant(Expression)
		case invalidFunctionIndex(FunctionIndex)

		var description: String {
			switch self {
			case .invalidTableIndex(let index):
				return "Table index is invalid: \(index)"
			case .elementTypeOfTableIsNotAny(let type):
				return "Element type of table is not any but \(type)"
			case .offsetIsNotConstant(let expression):
				return "Offset is not constant: \(expression)"
			case .invalidFunctionIndex(let index):
				return "Function index is invalid: \(index)"
			}
		}
	}

	func validate(with context: Context) throws {
		guard context.tables.contains(index: table) else {
			throw ElementValidationError.invalidTableIndex(table)
		}

		let tableType = context.tables[table]
		guard tableType.elementType == .any else {
			throw ElementValidationError.elementTypeOfTableIsNotAny(.any)
		}

		try offset.validate(with: context)
		guard offset.isConstant else {
			throw ElementValidationError.offsetIsNotConstant(offset)
		}

		for function in initializer {
			guard context.functions.contains(index: function) else {
				throw ElementValidationError.invalidFunctionIndex(function)
			}
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#data-segments
extension Data: Validatable {
	enum DataValidationError: ValidationError {
		case invalidMemoryIndex(MemoryIndex)
		case offsetIsNotConstant(Expression)

		var description: String {
			switch self {
			case .invalidMemoryIndex(let index):
				return "Memory index is invalid: \(index)"
			case .offsetIsNotConstant(let expression):
				return "Offset is not constant: \(expression)"
			}
		}
	}

	func validate(with context: Context) throws {
		guard context.memories.contains(index: data) else {
			throw DataValidationError.invalidMemoryIndex(data)
		}

		try offset.validate(with: context)
		guard offset.isConstant else {
			throw DataValidationError.offsetIsNotConstant(offset)
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#exports
extension Export: Validatable {
	func validate(with context: Context) throws {
		try descriptor.validate(with: context)
	}
}

extension ExportDescriptor: Validatable {
	enum ExportDescriptorValidationError: ValidationError {
		case invalidFunctionIndex(FunctionIndex)
		case invalidTableIndex(TableIndex)
		case invalidMemoryIndex(MemoryIndex)
		case invalidGlobalIndex(GlobalIndex)
		case globalMutabilityIsNotConstant(GlobalType)

		var description: String {
			switch self {
			case .invalidFunctionIndex(let index):
				return "Function index is invalid: \(index)"
			case .invalidTableIndex(let index):
				return "Function index is invalid: \(index)"
			case .invalidMemoryIndex(let index):
				return "Memory index is invalid: \(index)"
			case .invalidGlobalIndex(let index):
				return "Global index is invalid: \(index)"
			case .globalMutabilityIsNotConstant(let type):
				return "Global is not constant but \(type)"
			}
		}
	}

	func validate(with context: Context) throws {
		switch self {
		case let .function(index):
			guard context.functions.contains(index: index) else {
				throw ExportDescriptorValidationError.invalidFunctionIndex(index)
			}
		case let .table(index):
			guard context.tables.contains(index: index) else {
				throw ExportDescriptorValidationError.invalidTableIndex(index)
			}
		case let .memory(index):
			guard context.memories.contains(index: index) else {
				throw ExportDescriptorValidationError.invalidMemoryIndex(index)
			}
		case let .global(index):
			guard context.globals.contains(index: index) else {
				throw ExportDescriptorValidationError.invalidGlobalIndex(index)
			}
			let global = context.globals[index]
			guard global.mutability == .constant else {
				throw ExportDescriptorValidationError.globalMutabilityIsNotConstant(global)
			}
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#imports
extension Import: Validatable {
	func validate(with context: Context) throws {
		try descripter.validate(with: context)
	}
}

extension ImportDescriptor: Validatable {
	enum ImportDescriptorValidationError: ValidationError {
		case invalidFunctionIndex(FunctionIndex)
		case globalMutabilityIsNotConstant(GlobalType)

		var description: String {
			switch self {
			case .invalidFunctionIndex(let index):
				return "Function index is invalid: \(index)"
			case .globalMutabilityIsNotConstant(let type):
				return "Global is not constant: \(type)"
			}
		}
	}

	func validate(with context: Context) throws {
		switch self {
		case let .function(index):
			guard context.functions.contains(index: index) else {
				throw ImportDescriptorValidationError.invalidFunctionIndex(index)
			}
		case let .table(type):
			try type.limits.validate(with: context)
		case let .memory(type):
			try type.validate(with: context)
		case let .global(type):
			guard type.mutability == .constant else {
				throw ImportDescriptorValidationError.globalMutabilityIsNotConstant(type)
			}
		}
	}
}
