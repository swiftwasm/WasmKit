@_documentation(visibility: internal)
public protocol RuntimeInterceptor {
    func onEnterFunction(_ function: Function, store: Store)
    func onExitFunction(_ function: Function, store: Store)
}

/// An interceptor that multiplexes multiple interceptors
@_documentation(visibility: internal)
public class MultiplexingInterceptor: RuntimeInterceptor {
    private let interceptors: [RuntimeInterceptor]

    /// Creates a new multiplexing interceptor
    /// - Parameter interceptors: The interceptors to multiplex
    public init(_ interceptors: [RuntimeInterceptor]) {
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