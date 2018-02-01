enum InvocationError: Error {
	case genericError
	case invalidArgumentsCount
	case invalidArgumentType
}

extension Runtime {
	public func invoke(function functionAddress: FunctionAddress, arguments values: [Value]) throws -> Value {
		let function = store.functions[functionAddress]
		if let parameters = function.type.parameters {
			guard parameters.count == values.count else {
				throw InvocationError.invalidArgumentsCount
			}
			for (parameter, value) in zip(parameters, values) {
				guard value.isA(parameter) else {
					throw InvocationError.invalidArgumentType
				}
			}
		}

        guard let resultType = function.type.results?.first else {
            throw InvocationError.genericError
        }

		for value in values {
			stack.push(.value(value))
		}

		try invoke(function: function)

        let value = try stack.popValue(of: resultType)

		return value
	}

	// http://webassembly.github.io/spec/core/exec/instructions.html#invocation-of-function-address
	func invoke(function: FunctionInstance) throws {
		guard let results = function.type.results, results.count >= 1 else {
			throw InvocationError.genericError
		}

		guard let parameters = function.type.parameters else {
			throw InvocationError.genericError
		}

		let values = try parameters.map { type in try stack.popValue(of: type) }
		let locals = function.code.locals.map { type in type.zero }
		let frame = Frame(module: function.module, locals: values + locals)
		stack.push(.activation(frame))
		let expression = Expression(instructions: [ControlInstruction.block(results, function.code.body)])
		try expression.execute(stack: &stack)
	}
}
