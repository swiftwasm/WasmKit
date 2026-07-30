// Default system clock implementations for `WallClock`/`MonotonicClock`.
// These are the only clock types that touch the platform; the protocols in
// `Clock.swift` are platform-independent and can be implemented by users on
// platforms without system clocks.
#if os(Windows)
    import WinSDK
#endif

/// A monotonic clock that uses the system's monotonic clock.
public struct SystemMonotonicClock: MonotonicClock {
    public init() {}

    public func now() throws -> MonotonicClock.Instant {
        #if os(Windows)
            var counter = LARGE_INTEGER()
            guard QueryPerformanceCounter(&counter) else {
                throw PlatformError.windows(GetLastError())
            }
            return UInt64(counter.QuadPart)
        #else
            let timeSpec = try WASIAbi.Errno.translatingPlatformError {
                try _preferredMonotonicClock.currentTime()
            }
            return WASIAbi.Timestamp(platformTimeSpec: timeSpec)
        #endif
    }

    public func resolution() throws -> MonotonicClock.Duration {
        #if os(Windows)
            var frequency = LARGE_INTEGER()
            guard QueryPerformanceFrequency(&frequency) else {
                throw PlatformError.windows(GetLastError())
            }
            // frequency is in counts per second
            return UInt64(1_000_000_000 / frequency.QuadPart)
        #else
            let timeSpec = try WASIAbi.Errno.translatingPlatformError {
                try _preferredMonotonicClock.resolution()
            }
            return WASIAbi.Timestamp(platformTimeSpec: timeSpec)
        #endif
    }
}

/// A wall clock that uses the system's wall clock.
public struct SystemWallClock: WallClock {
    public init() {}

    public func now() throws -> WallClock.Duration {
        #if os(Windows)
            var fileTime = FILETIME()
            // Use GetSystemTimePreciseAsFileTime for better precision
            // https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimepreciseasfiletime
            GetSystemTimePreciseAsFileTime(&fileTime)
            let time = FileTime(windowsFILETIME: fileTime)
            return _clampedDuration(seconds: time.seconds, nanoseconds: time.nanoseconds)
        #else
            let timeSpec = try WASIAbi.Errno.translatingPlatformError {
                try PlatformClock.realtime.currentTime()
            }
            return _clampedDuration(seconds: timeSpec.seconds, nanoseconds: timeSpec.nanoseconds)
        #endif
    }

    public func resolution() throws -> WallClock.Duration {
        #if os(Windows)
            return (seconds: 0, nanoseconds: 100)
        #else
            let timeSpec = try WASIAbi.Errno.translatingPlatformError {
                try PlatformClock.realtime.resolution()
            }
            return _clampedDuration(seconds: timeSpec.seconds, nanoseconds: timeSpec.nanoseconds)
        #endif
    }
}

/// The monotonic clock variant historically used per platform.
private var _preferredMonotonicClock: PlatformClock {
    #if canImport(Darwin)
        return .rawUptime
    #elseif os(OpenBSD) || os(FreeBSD)
        return .uptime
    #else
        return .monotonic
    #endif
}

/// Handles potential negative time values (pre-1970 dates) by clamping to 0.
private func _clampedDuration(seconds: Int64, nanoseconds: Int64) -> WallClock.Duration {
    (
        seconds: seconds >= 0 ? UInt64(seconds) : 0,
        nanoseconds: nanoseconds >= 0 ? UInt32(nanoseconds) : 0
    )
}
