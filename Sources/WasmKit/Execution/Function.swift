import WasmParserCore

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
public struct Function: Equatable {
    /// The type of a host function implementation closure.
    public typealias Implementation = (borrowing Caller, [Value]) throws -> [Value]

    internal let handle: InternalFunction
    let store: Store

    internal init(handle: InternalFunction, store: Store) {
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
        store: Store,
        parameters: [ValueType], results: [ValueType] = [],
        body: @escaping Implementation
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
        store: Store,
        type: FunctionType,
        body: @escaping Implementation
    ) {
        self.init(handle: store.allocator.allocate(type: type, implementation: body, engine: store.engine), store: store)
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
    #if !$Embedded
    @discardableResult
    public func invoke(_ arguments: [Value] = []) throws -> [Value] {
        return try handle.invoke(arguments, store: store)
    }
    #else
    @discardableResult
    public func invoke(_ arguments: [Value] = []) throws(Trap) -> [Value] {
        return try handle.invoke(arguments, store: store)
    }
    #endif

    /// Invokes a function of the given address with the given parameters.
    ///
    /// - Parameter
    ///   - arguments: The arguments to pass to the function.
    /// - Throws: A trap if the function invocation fails.
    /// - Returns: The results of the function invocation.
    #if !$Embedded
    @discardableResult
    public func callAsFunction(_ arguments: [Value] = []) throws -> [Value] {
        return try invoke(arguments)
    }
    #else
    @discardableResult
    public func callAsFunction(_ arguments: [Value] = []) throws(Trap) -> [Value] {
        return try invoke(arguments)
    }
    #endif

    /// Invokes a function of the given address with the given parameters.
    ///
    /// - Parameters:
    ///   - arguments: The arguments to pass to the function.
    ///   - runtime: The runtime to use for the function invocation.
    /// - Throws: A trap if the function invocation fails.
    /// - Returns: The results of the function invocation.
    #if !$Embedded
    @available(*, deprecated, renamed: "invoke(_:)")
    @discardableResult
    public func invoke(_ arguments: [Value] = [], runtime: Runtime) throws -> [Value] {
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
    static func createOutOfBoundsError(index: Int, count: Int) -> WasmKitError {
        WasmKitError(message: .indexOutOfBounds("function", index, max: count))
    }
}

extension InternalFunction {
    #if !$Embedded
    func invoke(_ arguments: [Value], store: Store) throws -> [Value] {
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
            let caller = Caller(instanceHandle: nil, store: store)
            let results = try entity.implementation(caller, arguments)
            try check(functionType: resolvedType, results: results)
            return results
        }
    }
    #else
    func invoke(_ arguments: [Value], store: Store) throws(Trap) -> [Value] {
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
            fatalError("Host functions are not supported in embedded Swift")
        }
    }
    #endif

    private func check(expectedTypes: [ValueType], values: [Value]) -> Bool {
        guard expectedTypes.count == values.count else { return false }
        for (expected, value) in zip(expectedTypes, values) {
            switch (expected, value) {
            case (.i32, .i32), (.i64, .i64), (.f32, .f32), (.f64, .f64), (.v128, .v128),
                (.ref(.funcRef), .ref(.function)), (.ref(.externRef), .ref(.extern)),
                (.ref(.exnRef), .ref(.exception)):
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
            return (iseq, entity.numberOfNonParameterLocalSlots, entity)
        case .uncompiled:
            preconditionFailure()
        }
    }
}

struct WasmFunctionEntity {
    let type: InternedFuncType
    let instance: InternalInstance
    let index: FunctionIndex
    let numberOfNonParameterLocalSlots: Int
    var code: CodeBody

    init(index: FunctionIndex, type: InternedFuncType, code: InternalUncompiledCode, instance: InternalInstance) {
        self.type = type
        self.instance = instance
        self.code = .uncompiled(code)
        self.numberOfNonParameterLocalSlots = code.locals.reduce(into: 0) { $0 += $1.stackSlotCount }
        self.index = index
    }

    mutating func ensureCompiled(store: StoreRef) throws(Trap) -> InstructionSequence {
        switch code {
        case .uncompiled(let code):
            return try compile(store: store, code: code)
        case .compiled(let iseq), .debuggable(_, let iseq):
            return iseq
        }
    }

    @inline(never)
    mutating func compile(store: StoreRef, code: InternalUncompiledCode) throws(Trap) -> InstructionSequence {
        let store = store.value
        let engine = store.engine
        let type = self.type
        #if !$Embedded
        let isIntercepting = engine.interceptor != nil
        #else
        let isIntercepting = false
        #endif
        let iseq: InstructionSequence
        do throws(WasmKitError) {
            iseq = try code.withValue { (codeEntity: inout Code) throws(WasmKitError) -> InstructionSequence in
                try InstructionTranslator(
                    allocator: store.allocator.iseqAllocator,
                    engineConfiguration: engine.configuration,
                    funcTypeInterner: engine.funcTypeInterner,
                    module: instance,
                    type: engine.resolveType(type),
                    locals: codeEntity.locals,
                    functionIndex: index,
                    codeSize: codeEntity.expression.count,
                    isIntercepting: isIntercepting
                ).translate(code: codeEntity)
            }
        } catch let e {
            throw Trap(.message(TrapReason.Message("trap")))
        }
        self.code = .compiled(iseq)
        return iseq
    }
}

extension EntityHandle<WasmFunctionEntity> {
    @inline(never)
    @discardableResult
    func ensureCompiled(store: StoreRef) throws(Trap) -> InstructionSequence {
        switch self.code {
        case .uncompiled(let code):
            return try self.withValue { (fn: inout WasmFunctionEntity) throws(Trap) -> InstructionSequence in
                let iseq = try fn.compile(store: store, code: code)
                if fn.instance.isDebuggable {
                    fn.code = .debuggable(code, iseq)
                } else {
                    fn.code = .compiled(iseq)
                }
                return iseq
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

#if $Embedded
extension EntityHandle<WasmFunctionEntity> {
    var type: InternedFuncType { withValue { $0.type } }
    var instance: InternalInstance { withValue { $0.instance } }
    var index: FunctionIndex { withValue { $0.index } }
    var numberOfNonParameterLocalSlots: Int { withValue { $0.numberOfNonParameterLocalSlots } }
    var code: CodeBody { withValue { $0.code } }
}
#endif  // $Embedded
