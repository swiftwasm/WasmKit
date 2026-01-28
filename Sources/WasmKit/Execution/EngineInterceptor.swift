@_documentation(visibility: internal)
public protocol EngineInterceptor {
    associatedtype MemorySpace: GuestMemory
    func onEnterFunction(_ function: Function<MemorySpace>)
    func onExitFunction(_ function: Function<MemorySpace>)
}

/// An interceptor that multiplexes multiple interceptors
@_documentation(visibility: internal)
public class MultiplexingInterceptor<MemorySpace: GuestMemory>: EngineInterceptor<MemorySpace> {
    private let interceptors: [EngineInterceptor<MemorySpace>]

    /// Creates a new multiplexing interceptor
    /// - Parameter interceptors: The interceptors to multiplex
    public init(_ interceptors: [EngineInterceptor<MemorySpace>]) {
        self.interceptors = interceptors
    }

    public func onEnterFunction(_ function: Function<MemorySpace>) {
        for interceptor in interceptors {
            interceptor.onEnterFunction(function)
        }
    }

    public func onExitFunction(_ function: Function<MemorySpace>) {
        for interceptor in interceptors {
            interceptor.onExitFunction(function)
        }
    }
}
