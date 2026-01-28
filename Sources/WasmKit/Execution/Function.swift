import WasmParser

import struct WasmTypes.FunctionType

/// A WebAssembly guest function or host function.
///
/// > Note:
/// <https://webassembly.github.io/spec/core/exec/runtime.html#function-instances>
///
/// ## Examples
///
/// This example section shows how to interact with WebAssembly process with ``Function``.
///
/// ### Print Int32 given by WebAssembly process
///
/// ```swift
/// Function(store: store, parameters: [.i32]) { _, args in
///     print(args[0])
///     return []
/// }
/// ```
///
/// ### Print a UTF-8 string passed by a WebAssembly module instance
///
/// ```swift
/// Function(store: store, parameters: [.i32, .i32]) { caller, args in
///     let (stringPtr, stringLength) = (Int(args[0].i32), Int(args[1].i32))
///     guard let memory = caller.instance?.exports[memory: "memory"] else {
///         fatalError("Missing \"memory\" export")
///     }
///     let bytesRange = stringPtr..<(stringPtr + stringLength)
///     print(String(decoding: memory.data[bytesRange], as: UTF8.self))
///     return []
/// }
/// ```
public struct Function<MemorySpace: GuestMemory>: Equatable {
    internal let handle: InternalFunction
    let store: Store<MemorySpace>

    internal init(handle: InternalFunction, store: Store<MemorySpace>) {
        self.handle = handle
        self.store = store
    }

    /// Creates a new function instance backed by a native host function.
    ///
    /// - Parameters:
    ///   - store: The store to allocate the function in.
    ///   - parameters: The types of the function parameters.
    ///   - results: The types of the function results.
    ///   - body: The implementation of the function.
    public init(
        store: Store<MemorySpace>,
        parameters: [ValueType], results: [ValueType] = [],
        body: @escaping (Caller<MemorySpace>, [Value]) throws(Trap) -> [Value]
    ) {
        self.init(store: store, type: FunctionType(parameters: parameters, results: results), body: body)
    }

    /// Creates a new function instance backed by a native host function.
    ///
    /// - Parameters:
    ///   - store: The store to allocate the function in.
    ///   - type: The signature type of the function.
    ///   - body: The implementation of the function.
    public init(
        store: Store<MemorySpace>,
        type: FunctionType,
        body: @escaping (Caller<MemorySpace>, [Value]) throws(Trap) -> [Value]
    ) {
        let wrappedBody: (InternalCaller, [Value]) throws(Trap) -> [Value] = { internalCaller, args in
            let caller = Caller<MemorySpace>(internalCaller: internalCaller, store: store)
            return try body(caller, args)
        }
        self.init(handle: store.allocator.allocate(type: type, implementation: wrappedBody, engine: store.engine), store: store)
    }

    /// The signature type of the function.
    public var type: FunctionType {
        store.allocator.funcTypeInterner.resolve(handle.type)
    }

    /// Invokes a function of the given address with the given parameters.
    ///
    /// - Parameters:
    ///   - arguments: The arguments to pass to the function.
    /// - Throws: A trap if the function invocation fails.
    /// - Returns: The results of the function invocation.
    @discardableResult
    public func invoke(_ arguments: [Value] = []) throws(Trap) -> [Value] {
        return try handle.invoke(arguments, store: store)
    }

    /// Invokes a function of the given address with the given parameters.
    ///
    /// - Parameter
    ///   - arguments: The arguments to pass to the function.
    /// - Throws: A trap if the function invocation fails.
    /// - Returns: The results of the function invocation.
    @discardableResult
    public func callAsFunction(_ arguments: [Value] = []) throws(Trap) -> [Value] {
        return try invoke(arguments)
    }

    #if !$Embedded
    /// Invokes a function of the given address with the given parameters.
    ///
    /// - Parameters:
    ///   - arguments: The arguments to pass to the function.
    ///   - runtime: The runtime to use for the function invocation.
    /// - Throws: A trap if the function invocation fails.
    /// - Returns: The results of the function invocation.
    @available(*, deprecated, renamed: "invoke(_:)")
    @discardableResult
    public func invoke(_ arguments: [Value] = [], runtime: Runtime) throws(Trap) -> [Value] {
        return try invoke(arguments)
    }
    #endif
}

@available(*, deprecated, renamed: "Function", message: "Use Function instead")
public typealias FunctionInstance = Function

struct InternalFunction: Equatable, Hashable {
    private let _storage: Int

    var bitPattern: Int { _storage }

    init(bitPattern: Int) {
        _storage = bitPattern
    }

    /// Returns `true` if the function is defined as a Wasm function in its original module.
    /// Returns `false` if the function is implemented by the host.
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
    static func createOutOfBoundsError(index: Int, count: Int) -> ValidationError {
        ValidationError(.indexOutOfBounds("function", index, max: count))
    }
}

extension InternalFunction {
    func invoke<MemorySpace: GuestMemory>(_ arguments: [Value], store: Store<MemorySpace>) throws(Trap) -> [Value] {
        if isWasm {
            let entity = wasm
            let resolvedType = store.engine.resolveType(entity.type)
            try check(functionType: resolvedType, parameters: arguments)
            return try executeWasm(
                store: store,
                function: self,
                type: resolvedType,
                arguments: arguments
            )
        } else {
            let entity = host
            let resolvedType = store.engine.resolveType(entity.type)
            try check(functionType: resolvedType, parameters: arguments)
            let caller = InternalCaller(instanceHandle: nil, allocator: store.allocator, engine: store.engine)
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

    private func check(functionType: FunctionType, parameters: [Value]) throws(Trap) {
        guard check(expectedTypes: functionType.parameters, values: parameters) else {
            throw Trap(.parameterTypesMismatch(expected: functionType.parameters, got: parameters))
        }
    }

    private func check(functionType: FunctionType, results: [Value]) throws(Trap) {
        guard check(expectedTypes: functionType.results, values: results) else {
            throw Trap(.resultTypesMismatch(expected: functionType.results, got: results))
        }
    }

    func assumeCompiled() -> (
        InstructionSequence,
        locals: Int,
        function: EntityHandle<WasmFunctionEntity>
    ) {
        let entity = self.wasm
        switch entity.code {
        case .compiled(let iseq), .debuggable(_, let iseq):
            return (iseq, entity.numberOfNonParameterLocals, entity)
        case .uncompiled:
            preconditionFailure()
        }
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

    mutating func ensureCompiled<M: GuestMemory>(store: StoreRef<M>) throws(InstructionTranslatorError) -> InstructionSequence {
        switch code {
        case .uncompiled(let code):
            return try compile(store: store, code: code)
        case .compiled(let iseq), .debuggable(_, let iseq):
            return iseq
        }
    }

    @inline(never)
    mutating func compile<M: GuestMemory>(store: StoreRef<M>, code: InternalUncompiledCode) throws(InstructionTranslatorError) -> InstructionSequence {
        let store = store.value
        let engine = store.engine
        let type = self.type
        #if hasFeature(Embedded)
        let isIntercepting = false
        #else
        let isIntercepting = engine.interceptor != nil
        #endif
        var translator = try InstructionTranslator(
            allocator: store.allocator.iseqAllocator,
            engineConfiguration: engine.configuration,
            funcTypeInterner: engine.funcTypeInterner,
            module: instance,
            type: engine.resolveType(type),
            locals: code.locals,
            functionIndex: index,
            codeSize: code.expression.count,
            isIntercepting: isIntercepting
        )
        let iseq = try code.withValue { (code: inout Code) throws(InstructionTranslatorError) in
            try translator.translate(code: code)
        }
        self.code = .compiled(iseq)
        return iseq
    }
}

extension EntityHandle<WasmFunctionEntity> {
    @inline(never)
    @discardableResult
    func ensureCompiled<M: GuestMemory>(store: StoreRef<M>) throws(Trap) -> InstructionSequence {
        switch self.code {
        case .uncompiled(let code):
            do throws(InstructionTranslatorError) {
                return try self.withValue { (entity: inout WasmFunctionEntity) throws(InstructionTranslatorError) in
                    let iseq = try entity.compile(store: store, code: code)
                    if entity.instance.isDebuggable {
                        entity.code = .debuggable(code, iseq)
                    } else {
                        entity.code = .compiled(iseq)
                    }
                    return iseq
                }
            } catch {
                // Convert InstructionTranslatorError to Trap
                switch error {
                case .translation(let translationError):
                    throw Trap(.message(.init("Translation error: \(translationError)")))
                case .validation(let validationError):
                    throw Trap(.validationError(validationError))
                case .wasmParserError(let parserError):
                    throw Trap(.message(.init("Parser error: \(parserError)")))
                }
            }
        case .compiled(let iseq), .debuggable(_, let iseq):
            return iseq
        }
    }
}

typealias InternalUncompiledCode = EntityHandle<Code>

/// A compiled instruction sequence.
struct InstructionSequence {
    let instructions: UnsafeMutableBufferPointer<CodeSlot>
    /// The maximum height of the value stack during execution of this function.
    /// This height does not count the locals.
    let maxStackHeight: Int

    /// The constant value pool associated with this instruction sequence.
    /// See ``FrameHeaderLayout`` for how they are laid out on the stack.
    let constants: UnsafeBufferPointer<UntypedValue>

    init(instructions: UnsafeMutableBufferPointer<CodeSlot>, maxStackHeight: Int, constants: UnsafeBufferPointer<UntypedValue>) {
        self.instructions = instructions
        self.maxStackHeight = maxStackHeight
        self.constants = constants
    }

    var baseAddress: UnsafeMutablePointer<CodeSlot> {
        self.instructions.baseAddress!
    }
}

enum CodeBody {
    case uncompiled(InternalUncompiledCode)
    case compiled(InstructionSequence)
    case debuggable(InternalUncompiledCode, InstructionSequence)
}

extension Reference {
    static func function(from value: InternalFunction) -> Reference {
        // TODO: Consider having internal reference representation instead
        //       of public one in WasmTypes
        return .function(value.bitPattern)
    }
}
