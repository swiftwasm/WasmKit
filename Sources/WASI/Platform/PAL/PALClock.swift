// System clocks for the WASI platform layer, wrapping `clock_gettime`.
// Windows clocks use QueryPerformanceCounter/GetSystemTimePreciseAsFileTime
// directly in `PALSystemClocks.swift` and don't go through this wrapper.
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(WASI)
    import CWASIPlatform
    import WASILibc
#endif

/// A system clock in canonical form; each case maps to the platform's
/// nearest `clockid_t` (or fails with `notSupported` where none exists).
enum PlatformClock {
    /// A monotonic clock that keeps counting across system sleep where the
    /// platform offers one.
    case monotonic
    /// The wall clock.
    case realtime
    /// Darwin's raw uptime clock (`CLOCK_UPTIME_RAW`); Linux's raw
    /// monotonic clock.
    case rawUptime
    /// BSD's uptime clock.
    case uptime

    func currentTime() throws -> FileTime {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var timeSpec = timespec()
            try valueOrErrno(retryOnInterrupt: false) { clock_gettime(_clockID(), &timeSpec) }
            return FileTime(seconds: Int(timeSpec.tv_sec), nanoseconds: Int(timeSpec.tv_nsec))
        #else
            throw PlatformErrno.notSupported
        #endif
    }

    func resolution() throws -> FileTime {
        #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
            var timeSpec = timespec()
            try valueOrErrno(retryOnInterrupt: false) { clock_getres(_clockID(), &timeSpec) }
            return FileTime(seconds: Int(timeSpec.tv_sec), nanoseconds: Int(timeSpec.tv_nsec))
        #else
            throw PlatformErrno.notSupported
        #endif
    }

    #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || os(WASI)
        private func _clockID() -> clockid_t {
            #if os(WASI)
                switch self {
                case .monotonic, .rawUptime, .uptime: return wasi_platform_monotonic_clockid()
                case .realtime: return wasi_platform_realtime_clockid()
                }
            #elseif canImport(Darwin)
                switch self {
                case .monotonic: return CLOCK_MONOTONIC
                case .realtime: return CLOCK_REALTIME
                case .rawUptime: return CLOCK_UPTIME_RAW
                case .uptime: return CLOCK_UPTIME_RAW
                }
            #else
                switch self {
                case .monotonic: return CLOCK_MONOTONIC
                case .realtime: return CLOCK_REALTIME
                case .rawUptime: return CLOCK_MONOTONIC_RAW
                case .uptime: return CLOCK_MONOTONIC
                }
            #endif
        }
    #endif
}
