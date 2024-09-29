import WasmParser

/// A WebAssembly guest function or host function.
///
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#function-instances>
public struct Function: Equatable {
    internal let handle: InternalFunction
    let allocator: StoreAllocator

    /// The signature type of the function.
    public var type: FunctionType {
        allocator.funcTypeInterner.resolve(handle.type)
    }

    /// Invokes a function of the given address with the given parameters.
    ///
    /// - Parameters:
    ///   - arguments: The arguments to pass to the function.
    ///   - runtime: The runtime to use for the function invocation.
    /// - Throws: A trap if the function invocation fails.
    /// - Returns: The results of the function invocation.
    public func invoke(_ arguments: [Value] = [], runtime: Runtime) throws -> [Value] {
        assert(allocator === runtime.store.allocator, "Function is not from the same store as the runtime")
        return try handle.invoke(arguments, runtime: runtime)
    }
}

@available(*, deprecated, renamed: "Function", message: "Use Function instead")
public typealias FunctionInstance = Function

struct InternalFunction: Equatable, Hashable {
    private let _storage: Int

    var bitPattern: Int { _storage }

    init(bitPattern: Int) {
        _storage = bitPattern
    }

    var isWasm: Bool {
        _storage & 0b1 == 0
    }

    var type: InternedFuncType {
        if isWasm {
            return wasm.type
        } else {
            return host.type
        }
    }

    static func wasm(_ handle: EntityHandle<WasmFunctionEntity>) -> InternalFunction {
        assert(MemoryLayout<WasmFunctionEntity>.alignment >= 2)
        return InternalFunction(bitPattern: handle.bitPattern | 0b0)
    }

    static func host(_ handle: EntityHandle<HostFunctionEntity>) -> InternalFunction {
        assert(MemoryLayout<HostFunctionEntity>.alignment >= 2)
        return InternalFunction(bitPattern: handle.bitPattern | 0b1)
    }

    var wasm: EntityHandle<WasmFunctionEntity> {
        EntityHandle(unsafe: UnsafeMutablePointer(bitPattern: bitPattern & ~0b0)!)
    }
    var host: EntityHandle<HostFunctionEntity> {
        EntityHandle(unsafe: UnsafeMutablePointer(bitPattern: bitPattern & ~0b1)!)
    }
}

extension InternalFunction: ValidatableEntity {
    static func createOutOfBoundsError(index: Int, count: Int) -> any Error {
        Trap.invalidFunctionIndex(index)
    }
}

extension InternalFunction {
    func invoke(_ arguments: [Value], runtime: Runtime) throws -> [Value] {
        if isWasm {
            let entity = wasm
            let resolvedType = runtime.resolveType(entity.type)
            try check(functionType: resolvedType, parameters: arguments)
            return try executeWasm(
                runtime: runtime,
                function: self,
                type: resolvedType,
                arguments: arguments,
                callerInstance: entity.instance
            )
        } else {
            let entity = host
            let resolvedType = runtime.resolveType(entity.type)
            try check(functionType: resolvedType, parameters: arguments)
            let caller = Caller(instanceHandle: nil, runtime: runtime)
            let results = try entity.implementation(caller, arguments)
            try check(functionType: resolvedType, results: results)
            return results
        }
    }

    private func check(expectedTypes: [ValueType], values: [Value]) -> Bool {
        guard expectedTypes.count == values.count else { return false }
        for (expected, value) in zip(expectedTypes, values) {
            switch (expected, value) {
            case (.i32, .i32), (.i64, .i64), (.f32, .f32), (.f64, .f64),
                (.ref(.funcRef), .ref(.function)), (.ref(.externRef), .ref(.extern)):
                break
            default: return false
            }
        }
        return true
    }

    private func check(functionType: FunctionType, parameters: [Value]) throws {
        guard check(expectedTypes: functionType.parameters, values: parameters) else {
            throw Trap._raw("parameters types don't match, expected \(functionType.parameters), got \(parameters)")
        }
    }

    private func check(functionType: FunctionType, results: [Value]) throws {
        guard check(expectedTypes: functionType.results, values: results) else {
            throw Trap._raw("result types don't match, expected \(functionType.results), got \(results)")
        }
    }

    @inline(never)
    func ensureCompiled(runtime: RuntimeRef) throws {
        let entity = self.wasm
        switch entity.code {
        case .uncompiled(let code):
            try entity.withValue {
                let iseq = try $0.compile(runtime: runtime, code: code)
                $0.code = .compiled(iseq)
            }
        case .compiled: break
        }
    }

    func assumeCompiled() -> (
        InstructionSequence,
        locals: Int,
        instance: InternalInstance
    ) {
        let entity = self.wasm
        guard case let .compiled(iseq) = entity.code else {
            preconditionFailure()
        }
        return (iseq, entity.numberOfNonParameterLocals, entity.instance)
    }
}


struct WasmFunctionEntity {
    let type: InternedFuncType
    let instance: InternalInstance
    let index: FunctionIndex
    let numberOfNonParameterLocals: Int
    var code: CodeBody

    init(index: FunctionIndex, type: InternedFuncType, code: InternalUncompiledCode, instance: InternalInstance) {
        self.type = type
        self.instance = instance
        self.code = .uncompiled(code)
        self.numberOfNonParameterLocals = code.locals.count
        self.index = index
    }

    mutating func ensureCompiled(context: inout Execution) throws -> InstructionSequence {
        try ensureCompiled(runtime: context.runtime)
    }

    mutating func ensureCompiled(runtime: RuntimeRef) throws -> InstructionSequence {
        switch code {
        case .uncompiled(let code):
            return try compile(runtime: runtime, code: code)
        case .compiled(let iseq):
            return iseq
        }
    }

    @inline(never)
    mutating func compile(runtime: RuntimeRef, code: InternalUncompiledCode) throws -> InstructionSequence {
        let type = self.type
        var translator = try InstructionTranslator(
            allocator: runtime.value.store.allocator.iseqAllocator,
            runtimeConfiguration: runtime.value.configuration,
            funcTypeInterner: runtime.value.funcTypeInterner,
            module: instance,
            type: runtime.value.resolveType(type),
            locals: code.locals,
            functionIndex: index,
            codeSize: code.expression.count,
            intercepting: runtime.value.interceptor != nil
        )
        let iseq = try code.withValue { code in
            try translator.translate(code: code, instance: instance)
        }
        self.code = .compiled(iseq)
        return iseq
    }
}

typealias InternalUncompiledCode = EntityHandle<Code>

enum CodeBody {
    case uncompiled(InternalUncompiledCode)
    case compiled(InstructionSequence)
}

extension Reference {
    static func function(from value: InternalFunction) -> Reference {
        // TODO: Consider having internal reference representation instead
        //       of public one in WasmTypes
        return .function(value.bitPattern)
    }
}
