// https://webassembly.github.io/spec/valid/conventions.html#contexts
struct Context {
	var types: [FunctionType] = []
	var functions: [FunctionType] = []
	var tables: [TableType] = []
	var memories: [MemoryType] = []
	var globals: [GlobalType] = []
	var locals: [ValueType] = []
	var labels: [ResultType] = []
	var `return`: ResultType?
}

protocol Validatable {
	func validate(with context: Context) throws
}

protocol ValidationErrorProtocol: Error, Equatable, CustomStringConvertible {}

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

// https://webassembly.github.io/spec/valid/types.html#types

// https://webassembly.github.io/spec/valid/types.html#valid-limits
extension Limits: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case maxIsSmallerThanMin(min: UInt32, max: UInt32)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.maxIsSmallerThanMin(let l), .maxIsSmallerThanMin(let r)):
				return l == r
			}
		}

		var description: String {
			switch self {
			case .maxIsSmallerThanMin(let min, let max):
				return "Limit max (\(max) is smaller than min (\(min))"
			}
		}
	}

	func validate(with _: Context) throws {
		if let max = max, max < min {
			throw Limits.ValidationError.maxIsSmallerThanMin(min: min, max: max)
		}
	}
}

// https://webassembly.github.io/spec/valid/types.html#function-types
extension FunctionType: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case tooManyResultTypes([ValueType])

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.tooManyResultTypes(let l), .tooManyResultTypes(let r)):
				return l == r
			}
		}

		var description: String {
			switch self {
			case .tooManyResultTypes(let types):
				return "Too many result types: \(types)"
			}
		}
	}

	func validate(with _: Context) throws {
		guard results.count <= 1 else {
			throw ValidationError.tooManyResultTypes(results)
		}
	}
}

// https://webassembly.github.io/spec/valid/types.html#table-types
extension TableType: Validatable {
	func validate(with context: Context) throws {
		try limits.validate(with: context)
	}
}

// https://webassembly.github.io/spec/valid/types.html#memory-types
extension MemoryType: Validatable {
	func validate(with context: Context) throws {
		try limits.validate(with: context)
	}
}

// https://webassembly.github.io/spec/valid/instructions.html#instructions

// https://webassembly.github.io/spec/valid/instructions.html#numeric-instructions
extension NumericInstruction: Validatable {
	func validate(with context: Context) throws {
	}
}

extension NumericInstruction.i32: Validatable {
	func validate(with context: Context) throws {
	}
}

extension NumericInstruction.i64: Validatable {
	func validate(with context: Context) throws {
	}
}

extension NumericInstruction.f32: Validatable {
	func validate(with context: Context) throws {
	}
}

extension NumericInstruction.f64: Validatable {
	func validate(with context: Context) throws {
	}
}

// https://webassembly.github.io/spec/valid/instructions.html#variable-instructions

extension VariableInstruction: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case invalidLocalIndex(index: LabelIndex)
		case invalidGlobalIndex(index: GlobalIndex)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidLocalIndex(let l), .invalidLocalIndex(let r)):
				return l == r
			case (.invalidGlobalIndex(let l), .invalidGlobalIndex(let r)):
				return l == r
			default:
				return false
			}
		}

		var description: String {
			switch self {
			case .invalidLocalIndex(let index):
				return "Local index is invalid: \(index)"
			case .invalidGlobalIndex(let index):
				return "Global index is invalid: \(index)"
			}
		}
	}

	func validate(with context: Context) throws {
		switch self {
		case .getLocal(let index):
			guard context.locals.contains(index: index) else {
				throw ValidationError.invalidLocalIndex(index: index)
			}
		case .setLocal(let index):
			guard context.locals.contains(index: index) else {
				throw ValidationError.invalidLocalIndex(index: index)
			}
		case .teeLocal(let index):
			guard context.locals.contains(index: index) else {
				throw ValidationError.invalidLocalIndex(index: index)
			}
		case .getGlobal(let index):
			guard context.locals.contains(index: index) else {
				throw ValidationError.invalidGlobalIndex(index: index)
			}
		case .setGlobal(let index):
			guard context.locals.contains(index: index) else {
				throw ValidationError.invalidGlobalIndex(index: index)
			}
		}
	}
}

// https://webassembly.github.io/spec/valid/instructions.html#memory-instructions
extension MemoryInstruction: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case invalidLocalIndex(index: LabelIndex)
		case invalidGlobalIndex(index: GlobalIndex)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidLocalIndex(let l), .invalidLocalIndex(let r)):
				return l == r
			case (.invalidGlobalIndex(let l), .invalidGlobalIndex(let r)):
				return l == r
			default:
				return false
			}
		}

		var description: String {
			switch self {
			case .invalidLocalIndex(let index):
				return "Local index is invalid: \(index)"
			case .invalidGlobalIndex(let index):
				return "Global index is invalid: \(index)"
			}
		}
	}

	func validate(with context: Context) throws {
		
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

// https://webassembly.github.io/spec/valid/modules.html#functions
extension Function: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case invalidTypeIndex(TypeIndex)
		case tooManyResultTypes([ValueType])

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidTypeIndex(let l), .invalidTypeIndex(let r)):
				return l == r
			case (.tooManyResultTypes(let l), .tooManyResultTypes(let r)):
				return l == r
			default:
				return false
			}
		}

		var description: String {
			switch self {
			case .invalidTypeIndex(let index):
				return "Type index is invalid: \(index)"
			case .tooManyResultTypes(let types):
				return "Too many result types: \(types)"
			}
		}
	}

	func validate(with context: Context) throws {
		guard context.types.contains(index: type) else {
			throw ValidationError.invalidTypeIndex(type)
		}
		let functionType = context.types[type]

		let c = { () -> Context in
			var c = context
			c.locals = functionType.parameters + context.locals
			c.labels = [functionType.results]
			c.`return` = functionType.results
			return c
		}()

		try body.validate(with: c)
	}
}

// https://webassembly.github.io/spec/valid/types.html#table-types

extension Table: Validatable {
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

// https://webassembly.github.io/spec/valid/modules.html#globals
extension Global: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case initializerIsNotConstant(Expression)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.initializerIsNotConstant(let l), .initializerIsNotConstant(let r)):
				return l == r
			}
		}

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
			throw ValidationError.initializerIsNotConstant(initializer)
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#element-segments
extension Element: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case invalidTableIndex(TableIndex)
		case elementTypeOfTableIsNotAny(FunctionType)
		case offsetIsNotConstant(Expression)
		case invalidFunctionIndex(FunctionIndex)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidTableIndex(let l), .invalidTableIndex(let r)):
				return l == r
			case (.elementTypeOfTableIsNotAny(let l), .elementTypeOfTableIsNotAny(let r)):
				return l == r
			case (.offsetIsNotConstant(let l), .offsetIsNotConstant(let r)):
				return l == r
			case (.invalidFunctionIndex(let l), .invalidFunctionIndex(let r)):
				return l == r
			default:
				return false
			}
		}

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
			throw ValidationError.invalidTableIndex(table)
		}

		let tableType = context.tables[table]
		guard tableType.elementType == .any else {
			throw ValidationError.elementTypeOfTableIsNotAny(.any)
		}

		try offset.validate(with: context)
		guard offset.isConstant else {
			throw ValidationError.offsetIsNotConstant(offset)
		}

		for function in initializer {
			guard context.functions.contains(index: function) else {
				throw ValidationError.invalidFunctionIndex(function)
			}
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#data-segments
extension Data: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case invalidMemoryIndex(MemoryIndex)
		case offsetIsNotConstant(Expression)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidMemoryIndex(let l), .invalidMemoryIndex(let r)):
				return l == r
			case (.offsetIsNotConstant(let l), .offsetIsNotConstant(let r)):
				return l == r
			default:
				return false
			}
		}

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
			throw ValidationError.invalidMemoryIndex(data)
		}

		try offset.validate(with: context)
		guard offset.isConstant else {
			throw ValidationError.offsetIsNotConstant(offset)
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
	enum ValidationError: ValidationErrorProtocol {
		case invalidFunctionIndex(FunctionIndex)
		case invalidTableIndex(TableIndex)
		case invalidMemoryIndex(MemoryIndex)
		case invalidGlobalIndex(GlobalIndex)
		case globalMutabilityIsNotConstant(GlobalType)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidFunctionIndex(let l), .invalidFunctionIndex(let r)):
				return l == r
			case (.invalidTableIndex(let l), .invalidTableIndex(let r)):
				return l == r
			case (.invalidMemoryIndex(let l), .invalidMemoryIndex(let r)):
				return l == r
			case (.invalidGlobalIndex(let l), .invalidGlobalIndex(let r)):
				return l == r
			case (.globalMutabilityIsNotConstant(let l), .globalMutabilityIsNotConstant(let r)):
				return l == r
			default:
				return false
			}
		}

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
				throw ValidationError.invalidFunctionIndex(index)
			}
		case let .table(index):
			guard context.tables.contains(index: index) else {
				throw ValidationError.invalidTableIndex(index)
			}
		case let .memory(index):
			guard context.memories.contains(index: index) else {
				throw ValidationError.invalidMemoryIndex(index)
			}
		case let .global(index):
			guard context.globals.contains(index: index) else {
				throw ValidationError.invalidGlobalIndex(index)
			}
			let global = context.globals[index]
			guard global.mutability == .constant else {
				throw ValidationError.globalMutabilityIsNotConstant(global)
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
	enum ValidationError: ValidationErrorProtocol {
		case invalidFunctionIndex(FunctionIndex)
		case globalMutabilityIsNotConstant(GlobalType)

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidFunctionIndex(let l), .invalidFunctionIndex(let r)):
				return l == r
			case (.globalMutabilityIsNotConstant(let l), .globalMutabilityIsNotConstant(let r)):
				return l == r
			default:
				return false
			}
		}

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
				throw ValidationError.invalidFunctionIndex(index)
			}
		case let .table(type):
			try type.limits.validate(with: context)
		case let .memory(type):
			try type.validate(with: context)
		case let .global(type):
			guard type.mutability == .constant else {
				throw ValidationError.globalMutabilityIsNotConstant(type)
			}
		}
	}
}

// https://webassembly.github.io/spec/valid/modules.html#valid-module
extension Module: Validatable {
	enum ValidationError: ValidationErrorProtocol {
		case invalidTypeIndex(TypeIndex)
		case invalidFunctionIndexForStart(FunctionIndex)
		case startFunctionTypeIsNotEmpty(FunctionType)
		case tooManyTables
		case tooManyMemories
		case namesInExportsAreNotDistinct([String])

		static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
			switch (lhs, rhs) {
			case (.invalidTypeIndex(let l), .invalidTypeIndex(let r)):
				return l == r
			case (.invalidFunctionIndexForStart(let l), .invalidFunctionIndexForStart(let r)):
				return l == r
			case (.startFunctionTypeIsNotEmpty(let l), .startFunctionTypeIsNotEmpty(let r)):
				return l == r
			case (.tooManyTables, .tooManyTables),
			     (.tooManyMemories, .tooManyMemories):
				return true
			case (.namesInExportsAreNotDistinct(let l), .namesInExportsAreNotDistinct(let r)):
				return l == r
			default:
				return false
			}
		}

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
					throw ValidationError.invalidTypeIndex(index)
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

	func validate() throws {
		let moduleFunctions: [FunctionType] = try functions.map {
			guard types.contains(index: $0.type) else {
				throw ValidationError.invalidTypeIndex($0.type)
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
				throw ValidationError.invalidFunctionIndexForStart(start)
			}
			let startFunction = context.functions[start]
			guard startFunction.parameters.isEmpty && startFunction.results.isEmpty else {
				throw ValidationError.startFunctionTypeIsNotEmpty(startFunction)
			}
		}

		for `import` in imports {
			try `import`.validate(with: context)
		}

		for export in exports {
			try export.validate(with: context)
		}

		guard context.tables.count <= 1 else {
			throw ValidationError.tooManyTables
		}

		guard context.memories.count <= 1 else {
			throw ValidationError.tooManyMemories
		}

		func isDistinct<Element: Equatable & Hashable>(_ array: [Element]) -> Bool {
			return Set(array).count == array.count

		}

		let names = exports.map { $0.name }
		guard isDistinct(names) else {
			throw ValidationError.namesInExportsAreNotDistinct(names)
		}
	}
}
