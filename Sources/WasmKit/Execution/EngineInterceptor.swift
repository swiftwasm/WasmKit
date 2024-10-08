@_documentation(visibility: internal)
public protocol EngineInterceptor {
    func onEnterFunction(_ function: Function)
    func onExitFunction(_ function: Function)
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

    public func onEnterFunction(_ function: Function) {
        for interceptor in interceptors {
            interceptor.onEnterFunction(function)
        }
    }

    public func onExitFunction(_ function: Function) {
        for interceptor in interceptors {
            interceptor.onExitFunction(function)
        }
    }
}
