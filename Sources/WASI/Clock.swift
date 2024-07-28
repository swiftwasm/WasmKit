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
            GetSystemTimeAsFileTime(&fileTime)
            // > the number of 100-nanosecond intervals since January 1, 1601 (UTC).
            // https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime
            let time = (UInt64(fileTime.dwLowDateTime) | UInt64(fileTime.dwHighDateTime) << 32) / 10
            return (seconds: time / 1_000_000_000, nanoseconds: UInt32(time % 1_000_000_000))
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
            #if os(Linux)
                return .monotonic
            #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                return .rawUptime
            #elseif os(WASI)
                return .monotonic
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
            #if os(Linux)
                return .boottime
            #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                return .rawMonotonic
            #elseif os(OpenBSD) || os(FreeBSD) || os(WASI)
                return .monotonic
            #else
                #error("Unsupported platform")
            #endif
        }

        public init() {}

        public func now() throws -> WallClock.Duration {
            let timeSpec = try WASIAbi.Errno.translatingPlatformErrno {
                try underlying.currentTime()
            }
            return (seconds: UInt64(timeSpec.seconds), nanoseconds: UInt32(timeSpec.nanoseconds))
        }

        public func resolution() throws -> WallClock.Duration {
            let timeSpec = try WASIAbi.Errno.translatingPlatformErrno {
                try underlying.resolution()
            }
            return (seconds: UInt64(timeSpec.seconds), nanoseconds: UInt32(timeSpec.nanoseconds))
        }
    }

#endif
