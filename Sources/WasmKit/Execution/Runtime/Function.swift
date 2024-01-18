/// A WebAssembly guest function or host function
public struct Function: Equatable {
    internal let address: FunctionAddress

    /// Invokes a function of the given address with the given parameters.
    public func invoke(_ arguments: [Value] = [], runtime: Runtime) throws -> [Value] {
        var execution = ExecutionState()
        try invoke(execution: &execution, with: arguments, runtime: runtime)
        try execution.run(runtime: runtime)
        return try Array(execution.stack.popTopValues())
    }

    private func invoke(execution: inout ExecutionState, with arguments: [Value], runtime: Runtime) throws {
        switch try runtime.store.function(at: address) {
        case let .host(function):
            try check(functionType: function.type, parameters: arguments)

            let parameters = try execution.stack.popValues(count: function.type.parameters.count)

            let caller = Caller(runtime: runtime, instance: execution.stack.currentFrame.module)
            let results = try function.implementation(caller, Array(parameters))
            try check(functionType: function.type, results: results)
            execution.stack.push(values: results)

        case let .wasm(function, _):
            try check(functionType: function.type, parameters: arguments)
            execution.stack.push(values: arguments)

            try execution.invoke(functionAddress: address, runtime: runtime)
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
