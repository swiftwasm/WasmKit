/// WASI wall clock interface based on WASI Preview 2 `wall-clock` interface.
///
/// See also https://github.com/WebAssembly/wasi-clocks/blob/v0.2.0/wit/wall-clock.wit
public protocol WallClock: Sendable {
    /// An instant in time, in seconds and nanoseconds.
    typealias Duration = (
        seconds: UInt64,
        nanoseconds: UInt32
    )

    /// Read the current value of the clock.
    func now() throws -> Duration

    /// Query the resolution of the clock.
    ///
    /// The nanoseconds field of the output is always less than 1000000000.
    func resolution() throws -> Duration
}

/// WASI monotonic clock interface based on WASI Preview 2 `monotonic-clock` interface.
///
/// See also https://github.com/WebAssembly/wasi-clocks/blob/v0.2.0/wit/monotonic-clock.wit
public protocol MonotonicClock: Sendable {
    /// An instant in time, in nanoseconds.
    typealias Instant = UInt64
    /// A duration of time, in nanoseconds.
    typealias Duration = UInt64

    /// Read the current value of the clock.
    func now() throws -> Instant

    /// Query the resolution of the clock. Returns the duration of time
    /// corresponding to a clock tick.
    func resolution() throws -> Duration
}

// MARK: - Internal Helper

extension WASIAbi.Timestamp {
    /// Get the current wall clock time in nanoseconds since Unix epoch.
    /// This is an internal helper for use within the WASI module.
    internal static func currentWallClock() -> WASIAbi.Timestamp {
        let clock = SystemWallClock()
        do {
            let duration = try clock.now()
            return WASIAbi.Timestamp(wallClockDuration: duration)
        } catch {
            // Fallback: return 0 on error
            return 0
        }
    }
}
