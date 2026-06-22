/// A protocol for limiting resource allocation.
public protocol ResourceLimiter: Sendable {
    /// Limit the memory growth of the process to the specified number of bytes.
    func limitMemoryGrowth(to desired: Int) throws(Trap) -> Bool
    /// Limit the table growth of the process to the specified number of elements.
    func limitTableGrowth(to desired: Int) throws(Trap) -> Bool
}

// By default, we don't limit resource growth.
extension ResourceLimiter {
    public func limitMemoryGrowth(to desired: Int) throws(Trap) -> Bool { true }
    public func limitTableGrowth(to desired: Int) throws(Trap) -> Bool { true }
}

/// A default resource limiter that doesn't limit resource growth.
public struct DefaultResourceLimiter: ResourceLimiter {
    public init() {}
}
