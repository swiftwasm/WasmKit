import _CWasmKit.Platform

import struct WasmParser.WasmFeatureSet

/// A WebAssembly execution engine.
///
/// An engine is responsible storing the configuration for the execution of
/// WebAssembly code such as interpreting mode, enabled features, etc.
/// Typically, you will need a single engine instance per application.
public final class Engine {
    /// The engine configuration.
    public let configuration: EngineConfiguration
    let interceptor: EngineInterceptor?
    let funcTypeInterner: Interner<FunctionType>

    /// Create a new execution engine.
    ///
    /// - Parameters:
    ///   - configuration: The engine configuration.
    ///   - interceptor: An optional runtime interceptor to intercept execution of instructions.
    public init(configuration: EngineConfiguration = EngineConfiguration(), interceptor: EngineInterceptor? = nil) {
        self.configuration = configuration
        self.interceptor = interceptor
        self.funcTypeInterner = Interner()
    }

    /// Migration aid for the old ``Runtime/instantiate(module:)``
    @available(*, unavailable, message: "Use ``Module/instantiate(store:imports:)`` instead")
    public func instantiate(module: Module) -> Instance { fatalError() }
}

/// The configuration for the WebAssembly execution engine.
public struct EngineConfiguration: Sendable {
    /// The threading model, which determines how to dispatch instruction
    /// execution, to use for the virtual machine interpreter.
    public enum ThreadingModel: Sendable {
        /// Direct threaded code
        /// - Note: This is the default model for platforms that support
        /// `musttail` calls.
        case direct
        /// Indirect threaded code
        /// - Note: This is a fallback model for platforms that do not support
        /// `musttail` calls.
        case token

        static var useDirectThreadedCode: Bool {
            return WASMKIT_USE_DIRECT_THREADED_CODE == 1
        }

        static var defaultForCurrentPlatform: ThreadingModel {
            #if os(WASI)
                return .token
            #else
                return useDirectThreadedCode ? .direct : .token
            #endif
        }
    }

    /// The threading model to use for the virtual machine interpreter.
    public var threadingModel: ThreadingModel

    /// The compilation mode of WebAssembly modules to the internal virtual
    /// machine instruction sequence.
    public enum CompilationMode: Sendable {
        /// Eager compilation, where the module is compiled to the internal
        /// instruction sequence immediately after instantiation.
        case eager

        /// Lazy compilation, where the module is compiled to the internal
        /// instruction sequence only when the first function is called.
        case lazy
    }

    /// The compilation mode to use for WebAssembly modules.
    public var compilationMode: CompilationMode

    /// The stack size in bytes for the virtual machine interpreter. (Default: 512KB)
    ///
    /// Note: Typically, there are three kinds of stacks in a WebAssembly execution:
    /// 1. The native stack, which is used for native function calls.
    /// 2. The interpreter stack, which is used for allocating "local"
    ///    variables in the WebAssembly function and call frames of the
    ///    WebAssembly-level function calls.
    /// 3. The shadow stack, which is used by WebAssembly programs compiled
    ///    by LLVM-based compilers to implement pointers to local variables.
    ///    This stack is allocated in the WebAssembly memory space by
    ///    wasm-ld, so the interpreter does not care about it.
    ///
    /// The stack size here refers to the second stack, the interpreter stack
    /// size, so you may need to increase this value if you see
    /// "call stack exhausted" ``Trap`` errors thrown by the interpreter.
    public var stackSize: Int

    /// The WebAssembly features that can be used by Wasm modules running on this engine.
    public var features: WasmFeatureSet

    /// Initializes a new instance of `EngineConfiguration`.
    ///
    /// - Parameter threadingModel: The threading model to use for the virtual
    /// machine interpreter. If `nil`, the default threading model for the
    /// current platform will be used.
    /// - Parameter compilationMode: The compilation mode to use for WebAssembly
    /// modules. If `nil`, the default compilation mode (lazy) will be used.
    /// - Parameter stackSize: The stack size in bytes for the virtual machine
    /// interpreter. If `nil`, the default stack size (512KB) will be used.
    /// - Parameter features: The WebAssembly features that can be used by Wasm
    /// modules running on this engine.
    public init(
        threadingModel: ThreadingModel? = nil,
        compilationMode: CompilationMode? = nil,
        stackSize: Int? = nil,
        features: WasmFeatureSet = .default
    ) {
        self.threadingModel = threadingModel ?? .defaultForCurrentPlatform
        self.compilationMode = compilationMode ?? .lazy
        self.stackSize = stackSize ?? (1 << 19)
        self.features = features
    }
}

extension Engine {
    func resolveType(_ type: InternedFuncType) -> FunctionType {
        return funcTypeInterner.resolve(type)
    }
    func internType(_ type: FunctionType) -> InternedFuncType {
        return funcTypeInterner.intern(type)
    }
}
