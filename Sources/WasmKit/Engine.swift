import _CWasmKit.Platform

/// A WebAssembly execution engine.
public final class Engine {
    public let configuration: EngineConfiguration
    let interceptor: EngineInterceptor?
    let funcTypeInterner: Interner<FunctionType>

    /// Create a new execution engine.
    ///
    /// - Parameters:
    ///   - configuration: The engine configuration.
    ///   - interceptor: An optional runtime interceptor to intercept execution of instructions.
    public init(configuration: EngineConfiguration, interceptor: EngineInterceptor? = nil) {
        self.configuration = configuration
        self.interceptor = interceptor
        self.funcTypeInterner = Interner()
    }
}

public struct EngineConfiguration {
    /// The threading model, which determines how to dispatch instruction
    /// execution, to use for the virtual machine interpreter.
    public enum ThreadingModel {
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
            return useDirectThreadedCode ? .direct : .token
        }
    }

    /// The threading model to use for the virtual machine interpreter.
    public var threadingModel: ThreadingModel

    /// Initializes a new instance of `EngineConfiguration`.
    /// - Parameter threadingModel: The threading model to use for the virtual
    /// machine interpreter. If `nil`, the default threading model for the
    /// current platform will be used.
    public init(threadingModel: ThreadingModel? = nil) {
        self.threadingModel = threadingModel ?? .defaultForCurrentPlatform
    }
}

@_documentation(visibility: internal)
public protocol EngineInterceptor {
    func onEnterFunction(_ function: Function, store: Store)
    func onExitFunction(_ function: Function, store: Store)
}

/// An interceptor that multiplexes multiple interceptors
@_documentation(visibility: internal)
public class MultiplexingInterceptor: EngineInterceptor {
    private let interceptors: [EngineInterceptor]

    /// Creates a new multiplexing interceptor
    /// - Parameter interceptors: The interceptors to multiplex
    public init(_ interceptors: [EngineInterceptor]) {
        self.interceptors = interceptors
    }

    public func onEnterFunction(_ function: Function, store: Store) {
        for interceptor in interceptors {
            interceptor.onEnterFunction(function, store: store)
        }
    }

    public func onExitFunction(_ function: Function, store: Store) {
        for interceptor in interceptors {
            interceptor.onExitFunction(function, store: store)
        }
    }
}
