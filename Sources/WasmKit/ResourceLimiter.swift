/// A protocol for limiting resource allocation.
public protocol ResourceLimiter {
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
    func limitMemoryGrowth(to desired: Int) throws -> Bool {
        return true
    }
    func limitTableGrowth(to desired: Int) throws -> Bool {
        return true
    }
}

/// A default resource limiter that doesn't limit resource growth.
struct DefaultResourceLimiter: ResourceLimiter {}
