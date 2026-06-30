@_documentation(visibility: internal)
public protocol EngineInterceptor {
    func onEnterFunction(_ function: Function)
    func onExitFunction(_ function: Function)
    func onMemoryRead(memory: UInt32, offset: UInt64, length: UInt64)
    func onMemoryWrite(memory: UInt32, offset: UInt64, length: UInt64)
    func onDataSegmentInitialized(segment: UInt32, sourceOffset: UInt64, destinationOffset: UInt64, length: UInt64)
}

public extension EngineInterceptor {
    func onEnterFunction(_ function: Function) {}
    func onExitFunction(_ function: Function) {}
    func onMemoryRead(memory: UInt32, offset: UInt64, length: UInt64) {}
    func onMemoryWrite(memory: UInt32, offset: UInt64, length: UInt64) {}
    func onDataSegmentInitialized(segment: UInt32, sourceOffset: UInt64, destinationOffset: UInt64, length: UInt64) {}
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

    public func onMemoryRead(memory: UInt32, offset: UInt64, length: UInt64) {
        for interceptor in interceptors {
            interceptor.onMemoryRead(memory: memory, offset: offset, length: length)
        }
    }

    public func onMemoryWrite(memory: UInt32, offset: UInt64, length: UInt64) {
        for interceptor in interceptors {
            interceptor.onMemoryWrite(memory: memory, offset: offset, length: length)
        }
    }

    public func onDataSegmentInitialized(segment: UInt32, sourceOffset: UInt64, destinationOffset: UInt64, length: UInt64) {
        for interceptor in interceptors {
            interceptor.onDataSegmentInitialized(
                segment: segment,
                sourceOffset: sourceOffset,
                destinationOffset: destinationOffset,
                length: length
            )
        }
    }
}
