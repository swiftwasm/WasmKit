import SystemExtras

/// WASI wall clock interface based on WASI Preview 2 `wall-clock` interface.
///
/// See also https://github.com/WebAssembly/wasi-clocks/blob/v0.2.0/wit/wall-clock.wit
public protocol WallClock {
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
public protocol MonotonicClock {
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

#if os(Windows)

    import WinSDK
    import SystemPackage

    // MARK: - Windows

    /// A monotonic clock that uses the system's monotonic clock.
    public struct SystemMonotonicClock: MonotonicClock {

        public init() {
        }

        public func now() throws -> MonotonicClock.Instant {
            var counter = LARGE_INTEGER()
            guard QueryPerformanceCounter(&counter) else {
                throw Errno(windowsError: GetLastError())
            }
            return UInt64(counter.QuadPart)
        }

        public func resolution() throws -> MonotonicClock.Duration {
            var frequency = LARGE_INTEGER()
            guard QueryPerformanceFrequency(&frequency) else {
                throw Errno(windowsError: GetLastError())
            }
            // frequency is in counts per second
            return UInt64(1_000_000_000 / frequency.QuadPart)
        }
    }

    /// A wall clock that uses the system's wall clock.
    public struct SystemWallClock: WallClock {
        public init() {}

        public func now() throws -> WallClock.Duration {
            var fileTime = FILETIME()
            // Use GetSystemTimePreciseAsFileTime for better precision
            // https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimepreciseasfiletime
            GetSystemTimePreciseAsFileTime(&fileTime)
            // FILETIME is 100-nanosecond intervals since 1601-01-01
            // https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
            let intervals = (UInt64(fileTime.dwHighDateTime) << 32) | UInt64(fileTime.dwLowDateTime)
            // Convert from Windows epoch (1601) to Unix epoch (1970)
            // Epoch offset: 11_644_473_600 seconds * 10_000_000 (100ns intervals per second) = 116_444_736_000_000_000
            let unixEpochOffset: UInt64 = 116_444_736_000_000_000  // 100ns intervals between epochs
            guard intervals >= unixEpochOffset else {
                // Handle pre-1970 dates (return 0)
                return (seconds: 0, nanoseconds: 0)
            }
            let unixIntervals = intervals - unixEpochOffset
            // Convert 100ns intervals to nanoseconds, then to seconds/nanoseconds
            let totalNanoseconds = unixIntervals * 100
            return (seconds: totalNanoseconds / 1_000_000_000, nanoseconds: UInt32((totalNanoseconds % 1_000_000_000)))
        }

        public func resolution() throws -> WallClock.Duration {
            return (seconds: 0, nanoseconds: 100)
        }
    }

#else

    // MARK: - Unix-like platforms

    /// A monotonic clock that uses the system's monotonic clock.
    public struct SystemMonotonicClock: MonotonicClock {
        private var underlying: SystemExtras.Clock {
            #if os(Linux) || os(Android) || os(WASI)
                return .monotonic
            #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                return .rawUptime
            #elseif os(OpenBSD) || os(FreeBSD)
                return .uptime
            #else
                #error("Unsupported platform")
            #endif
        }

        public init() {}

        public func now() throws -> MonotonicClock.Instant {
            let timeSpec = try WASIAbi.Errno.translatingPlatformErrno {
                try underlying.currentTime()
            }
            return WASIAbi.Timestamp(platformTimeSpec: timeSpec)
        }

        public func resolution() throws -> MonotonicClock.Duration {
            let timeSpec = try WASIAbi.Errno.translatingPlatformErrno {
                try underlying.resolution()
            }
            return WASIAbi.Timestamp(platformTimeSpec: timeSpec)
        }
    }

    /// A wall clock that uses the system's wall clock.
    public struct SystemWallClock: WallClock {
        private var underlying: SystemExtras.Clock {
            return .realtime
        }

        public init() {}

        public func now() throws -> WallClock.Duration {
            let timeSpec = try WASIAbi.Errno.translatingPlatformErrno {
                try underlying.currentTime()
            }
            // Handle potential negative tv_sec (pre-1970 dates)
            let seconds = timeSpec.seconds >= 0 ? UInt64(timeSpec.seconds) : 0
            let nanoseconds = timeSpec.nanoseconds >= 0 ? UInt32(timeSpec.nanoseconds) : 0
            return (seconds: seconds, nanoseconds: nanoseconds)
        }

        public func resolution() throws -> WallClock.Duration {
            let timeSpec = try WASIAbi.Errno.translatingPlatformErrno {
                try underlying.resolution()
            }
            let seconds = timeSpec.seconds >= 0 ? UInt64(timeSpec.seconds) : 0
            let nanoseconds = timeSpec.nanoseconds >= 0 ? UInt32(timeSpec.nanoseconds) : 0
            return (seconds: seconds, nanoseconds: nanoseconds)
        }
    }

#endif

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
