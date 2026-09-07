/// A protocol for limiting resource allocation.
///
/// Class-constrained so that `any ResourceLimiter` remains available under
/// Embedded Swift, which supports only class-bound existentials.
public protocol ResourceLimiter: AnyObject, Sendable {
    /// Limit the memory growth of the process to the specified number of bytes.
    ///
    /// - Parameter desired: The desired size of the memory in bytes.
    /// - Returns: `true` if the memory growth should be allowed. `false` if
    ///   the memory growth should be denied.
    func limitMemoryGrowth(to desired: Int) throws -> Bool

    /// Limit the table growth of the process to the specified number of elements.
    ///
    /// - Parameter desired: The desired size of the table in elements.
    /// - Returns: `true` if the table growth should be allowed. `false` if
    ///   the table growth should be denied.
    func limitTableGrowth(to desired: Int) throws -> Bool
}

// By default, we don't limit resource growth.
extension ResourceLimiter {
    public func limitMemoryGrowth(to desired: Int) throws -> Bool {
        return true
    }
    public func limitTableGrowth(to desired: Int) throws -> Bool {
        return true
    }
}

/// A resource limiter that permits all growth.
public final class DefaultResourceLimiter: ResourceLimiter {
    public init() {}
}
