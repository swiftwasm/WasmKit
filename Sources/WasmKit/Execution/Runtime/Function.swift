/// A WebAssembly guest function or host function
public struct Function: Equatable {
    internal let address: FunctionAddress

    /// Invokes a function of the given address with the given parameters.
    public func invoke(_ arguments: [Value] = [], runtime: Runtime) throws -> [Value] {
        try withExecution { execution in
            var stack = Stack()
            try invoke(execution: &execution, stack: &stack, with: arguments, runtime: runtime)
            try execution.run(runtime: runtime, stack: &stack)
            return try Array(stack.popTopValues())
        }
    }

    private func invoke(execution: inout ExecutionState, stack: inout Stack, with arguments: [Value], runtime: Runtime) throws {
        switch try runtime.store.function(at: address) {
        case let .host(function):
            try check(functionType: function.type, parameters: arguments)

            let parameters = stack.popValues(count: function.type.parameters.count)

            let moduleInstance = runtime.store.module(address: stack.currentFrame.module)
            let caller = Caller(runtime: runtime, instance: moduleInstance)
            let results = try function.implementation(caller, Array(parameters))
            try check(functionType: function.type, results: results)
            stack.push(values: results)

        case let .wasm(function, _):
            try check(functionType: function.type, parameters: arguments)
            stack.push(values: arguments)

            try execution.invoke(functionAddress: address, runtime: runtime, stack: &stack)
        }
    }

    private func check(functionType: FunctionType, parameters: [Value]) throws {
        let parameterTypes = parameters.map { $0.type }

        guard parameterTypes == functionType.parameters else {
            throw Trap._raw("parameters types don't match, expected \(functionType.parameters), got \(parameterTypes)")
        }
    }

    private func check(functionType: FunctionType, results: [Value]) throws {
        let resultTypes = results.map { $0.type }

        guard resultTypes == functionType.results else {
            throw Trap._raw("result types don't match, expected \(functionType.results), got \(resultTypes)")
        }
    }
}
