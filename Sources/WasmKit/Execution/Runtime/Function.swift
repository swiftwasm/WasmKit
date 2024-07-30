import WasmParser

/// A WebAssembly guest function or host function
public struct Function: Equatable {
    internal let address: FunctionAddress

    /// Invokes a function of the given address with the given parameters.
    public func invoke(_ arguments: [Value] = [], runtime: Runtime) throws -> [Value] {
        switch try runtime.store.function(at: address) {
        case let .host(function):
            try check(functionType: function.type, parameters: arguments)
            let caller = Caller(runtime: runtime, instance: nil)
            let results = try function.implementation(caller, arguments)
            try check(functionType: function.type, results: results)
            return results

        case let .wasm(function, _):
            return try withExecution { execution in
                var stack = Stack()
                defer { stack.deallocate() }
                try check(functionType: function.type, parameters: arguments)
                for (index, argument) in arguments.enumerated() {
                    stack[Instruction.Register(index)] = argument
                }
                try execution.invoke(functionAddress: address, runtime: runtime, stack: &stack)
                try execution.run(runtime: runtime, stack: &stack)
                return (0..<function.type.results.count).map { stack[Instruction.Register($0)] }
            }
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
