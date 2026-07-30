// Default system clock implementations for `WallClock`/`MonotonicClock`.
// These are the only clock types that touch the platform; the protocols in
// `Clock.swift` are platform-independent and can be implemented by users on
// platforms without system clocks.
#if os(Windows)

    import WinSDK

    /// A monotonic clock that uses the system's monotonic clock.
    public struct SystemMonotonicClock: MonotonicClock {

        public init() {
        }

        public func now() throws -> MonotonicClock.Instant {
            var counter = LARGE_INTEGER()
            guard QueryPerformanceCounter(&counter) else {
                throw PlatformErrno(windowsError: GetLastError())
            }
            return UInt64(counter.QuadPart)
        }

        public func resolution() throws -> MonotonicClock.Duration {
            var frequency = LARGE_INTEGER()
            guard QueryPerformanceFrequency(&frequency) else {
                throw PlatformErrno(windowsError: GetLastError())
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
            let unixNanoseconds = FileTime(rawValue: fileTime).unixNanoseconds
            guard unixNanoseconds >= 0 else {
                // Handle pre-1970 dates (return 0)
                return (seconds: 0, nanoseconds: 0)
            }
            let totalNanoseconds = UInt64(unixNanoseconds)
            return (seconds: totalNanoseconds / 1_000_000_000, nanoseconds: UInt32((totalNanoseconds % 1_000_000_000)))
        }

        public func resolution() throws -> WallClock.Duration {
            return (seconds: 0, nanoseconds: 100)
        }
    }

#elseif canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)

    /// A monotonic clock that uses the system's monotonic clock.
    public struct SystemMonotonicClock: MonotonicClock {
        private var underlying: PlatformClock {
            #if canImport(Darwin)
                return .rawUptime
            #elseif os(OpenBSD) || os(FreeBSD)
                return .uptime
            #else
                return .monotonic
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
        private var underlying: PlatformClock {
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

#else

    /// A monotonic clock stub for platforms without a known system clock.
    /// Inject a custom `MonotonicClock` implementation instead.
    public struct SystemMonotonicClock: MonotonicClock {
        public init() {}
        public func now() throws -> MonotonicClock.Instant { throw WASIAbi.Errno.ENOTSUP }
        public func resolution() throws -> MonotonicClock.Duration { throw WASIAbi.Errno.ENOTSUP }
    }

    /// A wall clock stub for platforms without a known system clock.
    /// Inject a custom `WallClock` implementation instead.
    public struct SystemWallClock: WallClock {
        public init() {}
        public func now() throws -> WallClock.Duration { throw WASIAbi.Errno.ENOTSUP }
        public func resolution() throws -> WallClock.Duration { throw WASIAbi.Errno.ENOTSUP }
    }

#endif
